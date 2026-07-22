import os
import joblib
import numpy as np
import pandas as pd
from typing import List
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score

app = FastAPI(
    title="Solar Power Model Retraining API",
    description="Endpoint for dynamic continuous retraining of solar power prediction models.",
    version="1.0.0"
)

ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1",
    "http://10.0.2.2",
    "http://10.0.2.2:8000",
]

ALLOWED_ORIGIN_REGEX = r"http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?"

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
MODEL_PATH = os.path.join(MODEL_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.pkl")

BASE_DATASET_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "spg.csv"))

class RetrainRecord(BaseModel):
    temperature_2_m_above_gnd: float = Field(..., ge=-30.0, le=60.0)
    relative_humidity_2_m_above_gnd: float = Field(..., ge=0.0, le=100.0)
    mean_sea_level_pressure_MSL: float = Field(..., ge=850.0, le=1100.0)
    total_cloud_cover_sfc: float = Field(..., ge=0.0, le=100.0)
    shortwave_radiation_backwards_sfc: float = Field(..., ge=0.0, le=1200.0)
    wind_speed_10_m_above_gnd: float = Field(..., ge=0.0, le=150.0)
    wind_direction_10_m_above_gnd: float = Field(..., ge=0.0, le=360.0)
    angle_of_incidence: float = Field(..., ge=0.0, le=180.0)
    zenith: float = Field(..., ge=0.0, le=180.0)
    azimuth: float = Field(..., ge=0.0, le=360.0)
    generated_power_kw: float = Field(..., ge=0.0, description="Actual observed solar power output in kW.")

class RetrainResponse(BaseModel):
    message: str
    records_received: int
    total_dataset_size: int
    mse: float
    rmse: float
    r2_score: float

@app.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
def retrain_model(new_records: List[RetrainRecord]):
    """
    Accepts new solar generation records, merges with existing dataset,
    retrains StandardScaler and RandomForestRegressor, updates saved artifacts.
    """
    if not new_records:
        raise HTTPException(status_code=400, detail="No new records provided for retraining.")

    try:
        if os.path.exists(BASE_DATASET_PATH):
            df_existing = pd.read_csv(BASE_DATASET_PATH)
        else:
            df_existing = pd.DataFrame()

        new_data = [r.dict() for r in new_records]
        df_new = pd.DataFrame(new_data)

        df_combined = pd.concat([df_existing, df_new], ignore_index=True)

        df_combined['clear_sky_index'] = (100.0 - df_combined['total_cloud_cover_sfc']) / 100.0
        df_combined['zenith_rad'] = np.radians(df_combined['zenith'])
        df_combined['effective_irradiance'] = df_combined['shortwave_radiation_backwards_sfc'] * np.cos(df_combined['zenith_rad'])

        selected_features = [
            'temperature_2_m_above_gnd',
            'relative_humidity_2_m_above_gnd',
            'mean_sea_level_pressure_MSL',
            'total_cloud_cover_sfc',
            'shortwave_radiation_backwards_sfc',
            'wind_speed_10_m_above_gnd',
            'wind_direction_10_m_above_gnd',
            'angle_of_incidence',
            'zenith',
            'azimuth',
            'clear_sky_index',
            'effective_irradiance'
        ]

        X = df_combined[selected_features]
        y = df_combined['generated_power_kw']

        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        new_scaler = StandardScaler()
        X_train_scaled = new_scaler.fit_transform(X_train)
        X_test_scaled = new_scaler.transform(X_test)

        new_model = RandomForestRegressor(n_estimators=100, max_depth=12, random_state=42)
        new_model.fit(X_train_scaled, y_train)

        preds = new_model.predict(X_test_scaled)
        mse = float(mean_squared_error(y_test, preds))
        rmse = float(np.sqrt(mse))
        r2 = float(r2_score(y_test, preds))

        os.makedirs(MODEL_DIR, exist_ok=True)
        joblib.dump(new_model, MODEL_PATH)
        joblib.dump(new_scaler, SCALER_PATH)

        return RetrainResponse(
            message="Model successfully retrained and deployed.",
            records_received=len(new_records),
            total_dataset_size=len(df_combined),
            mse=round(mse, 4),
            rmse=round(rmse, 4),
            r2_score=round(r2, 4)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Retraining error: {str(e)}"
        )
