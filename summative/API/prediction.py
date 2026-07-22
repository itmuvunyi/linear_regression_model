import os
import joblib
import numpy as np
import pandas as pd
from typing import List
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Define FastAPI application
app = FastAPI(
    title="Solar Power Generation Prediction API",
    description="Production API for solar farm energy output forecasting and sustainability optimization.",
    version="1.0.0"
)

# Explicitly allowed origin domains
ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1",
    "http://10.0.2.2",
    "http://10.0.2.2:8000",
]

# Comprehensive CORS Regex: Allows local testing (localhost, 127.0.0.1, 10.0.2.2 on any port) 
# AND public production deployments (*.onrender.com, *.vercel.app)
ALLOWED_ORIGIN_REGEX = r"https?://(localhost|127\.0\.0\.1|10\.0\.2\.2|.*\.onrender\.com|.*\.vercel\.app)(:\d+)?"

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Load production model and scaler artifacts
MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
MODEL_PATH = os.path.join(MODEL_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.pkl")

model = None
scaler = None

def load_artifacts():
    global model, scaler
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
    else:
        raise RuntimeError(f"Model or Scaler artifact missing in directory: {MODEL_DIR}")

@app.on_event("startup")
def startup_event():
    load_artifacts()

class SolarPredictionInput(BaseModel):
    temperature_2_m_above_gnd: float = Field(
        ..., ge=-30.0, le=60.0,
        description="Air temperature 2 meters above ground level in degrees Celsius (°C)."
    )
    relative_humidity_2_m_above_gnd: float = Field(
        ..., ge=0.0, le=100.0,
        description="Relative humidity 2 meters above ground level percentage (0 to 100%)."
    )
    mean_sea_level_pressure_MSL: float = Field(
        ..., ge=850.0, le=1100.0,
        description="Mean sea level pressure in hectopascals (hPa)."
    )
    total_cloud_cover_sfc: float = Field(
        ..., ge=0.0, le=100.0,
        description="Total surface cloud cover percentage (0 to 100%)."
    )
    shortwave_radiation_backwards_sfc: float = Field(
        ..., ge=0.0, le=1200.0,
        description="Shortwave solar radiation incident on surface (W/m²)."
    )
    wind_speed_10_m_above_gnd: float = Field(
        ..., ge=0.0, le=150.0,
        description="Wind speed 10 meters above ground level (m/s or km/h)."
    )
    wind_direction_10_m_above_gnd: float = Field(
        ..., ge=0.0, le=360.0,
        description="Wind direction 10 meters above ground level in degrees (0 to 360°)."
    )
    angle_of_incidence: float = Field(
        ..., ge=0.0, le=180.0,
        description="Solar angle of incidence on solar panel surface in degrees (0 to 180°)."
    )
    zenith: float = Field(
        ..., ge=0.0, le=180.0,
        description="Solar zenith angle in degrees (0 to 180°)."
    )
    azimuth: float = Field(
        ..., ge=0.0, le=360.0,
        description="Solar azimuth angle in degrees (0 to 360°)."
    )

class SolarPredictionOutput(BaseModel):
    predicted_solar_power: float = Field(
        ..., description="Predicted solar power output in Kilowatts (kW)."
    )

@app.get("/", tags=["Health Check"])
def root():
    return {
        "status": "online",
        "system": "AI Solar Power Generation Prediction System",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.post("/predict", response_model=SolarPredictionOutput, tags=["Prediction"])
def predict(payload: SolarPredictionInput):
    """
    Accepts meteorological and solar angle parameters, validates inputs, transforms features,
    and returns predicted solar power output in Kilowatts (kW).
    """
    global model, scaler
    if model is None or scaler is None:
        load_artifacts()
        
    try:
        clear_sky_index = (100.0 - payload.total_cloud_cover_sfc) / 100.0
        zenith_rad = np.radians(payload.zenith)
        effective_irradiance = payload.shortwave_radiation_backwards_sfc * np.cos(zenith_rad)

        feature_dict = {
            'temperature_2_m_above_gnd': payload.temperature_2_m_above_gnd,
            'relative_humidity_2_m_above_gnd': payload.relative_humidity_2_m_above_gnd,
            'mean_sea_level_pressure_MSL': payload.mean_sea_level_pressure_MSL,
            'total_cloud_cover_sfc': payload.total_cloud_cover_sfc,
            'shortwave_radiation_backwards_sfc': payload.shortwave_radiation_backwards_sfc,
            'wind_speed_10_m_above_gnd': payload.wind_speed_10_m_above_gnd,
            'wind_direction_10_m_above_gnd': payload.wind_direction_10_m_above_gnd,
            'angle_of_incidence': payload.angle_of_incidence,
            'zenith': payload.zenith,
            'azimuth': payload.azimuth,
            'clear_sky_index': clear_sky_index,
            'effective_irradiance': effective_irradiance
        }

        input_df = pd.DataFrame([feature_dict])
        input_scaled = scaler.transform(input_df)
        prediction = float(model.predict(input_scaled)[0])
        
        prediction = max(0.0, round(prediction, 4))
        
        return SolarPredictionOutput(predicted_solar_power=prediction)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction error: {str(e)}"
        )
