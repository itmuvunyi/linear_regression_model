# AI-Based Solar Power Generation Prediction System

## 1. Project Mission
Leverage artificial intelligence, environmental simulation technologies, and sustainable innovation to build intelligent machine learning solutions that predict solar power generation, optimizing clean energy grid planning and accelerating the transition towards sustainable electricity production.

## 2. Dataset Description and Source
- **Source**: Historical Solar Power Plant Telemetry (`spg.csv`)
- **Size**: 4,213 observations, 21 continuous features.
- **Variables**: Meteorological factors (surface temperature, relative humidity, pressure, cloud cover layers, shortwave radiation, wind vectors) and solar geometry (angle of incidence, solar zenith, azimuth).
- **Target Variable ($Y$)**: `generated_power_kw` representing instantaneous solar panel power output in Kilowatts (kW).

## 3. Problem Statement
Solar photovoltaic production is highly intermittent and strongly dependent on atmospheric conditions and orbital solar geometry. Unpredictable solar output creates grid instability and challenges clean energy integration. This system provides accurate regression modeling to forecast solar power generation, supporting energy traders, farm operators, and smart grid managers.

## 4. Machine Learning Approach
- **Multivariate Supervised Regression**: Benchmarked Linear Regression, Stochastic Gradient Descent (SGD) Regressor, Decision Tree Regressor, and Random Forest Regressor.
- **Custom Optimization**: Engineered a batch Gradient Descent linear regression model built from scratch calculating train/test loss curves across epochs.
- **Preprocessing**: Feature scaling with `StandardScaler` ($\mu=0, \sigma=1$) to stabilize gradient updates across features spanning different numerical orders of magnitude.

## 5. Feature Engineering Explanation
- **Pruned Features**: Dropped highly collinear upper-atmosphere wind features (`wind_speed_80_m_above_gnd`, `wind_speed_900_mb`, `wind_direction_80_m_above_gnd`, `wind_direction_900_mb`), redundant cloud breakdown layers, and sparse precipitation variables (>95% zeros).
- **Derived Features**:
  - `clear_sky_index`: $(100 - \text{total\_cloud\_cover\_sfc}) / 100.0$ (proportional clear sky transparency).
  - `effective_irradiance`: $\text{shortwave\_radiation\_backwards\_sfc} \times \cos(\text{zenith\_rad})$, modeling direct solar irradiance perpendicular to panel orientation.

## 6. Model Comparison Results

| Model | MSE | RMSE | R² Score |
|---|---|---|---|
| **Random Forest Regression** | **173,344.77** | **416.35** | **0.8102** |
| Linear Regression | 255,899.55 | 505.87 | 0.7199 |
| SGD Regression | 256,630.51 | 506.59 | 0.7191 |
| Decision Tree Regression | 259,854.27 | 509.76 | 0.7155 |

## 7. Best Model Selection Rationale
**Random Forest Regression** achieved the best overall performance ($R^2 = 0.8102$, $\text{RMSE} = 416.35\text{ kW}$). Solar energy generation exhibits non-linear relationships and threshold effects (e.g., zero generation at night when zenith $> 90^\circ$). Ensemble decision trees capture these non-linear physical boundaries without suffering from high variance or extreme feature sensitivity.

## 8. Public API URL
- **Production API**: `https://solar-power-prediction-api.onrender.com`
- **Local API**: `http://localhost:8000`

## 9. Swagger Documentation URL
- **Interactive OpenAPI Documentation**: `http://localhost:8000/docs`
- **Render Production Docs**: `https://solar-power-prediction-api.onrender.com/docs`

## 10. Flutter Application Setup Instructions
1. Navigate to Flutter app folder:
   ```bash
   cd summative/FlutterApp
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run app on target device (e.g. Chrome, Android Emulator, Windows):
   ```bash
   flutter run -d chrome
   ```

## 11. How to Run Locally Using UV

1. **Install UV** (if not present):
   ```bash
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

2. **Sync Dependencies**:
   ```bash
   uv sync
   ```

3. **Run FastAPI Prediction Service**:
   ```bash
   uv run uvicorn summative.API.prediction:app --host 0.0.0.0 --port 8000 --reload
   ```

4. **Run FastAPI Retraining Service**:
   ```bash
   uv run uvicorn summative.API.retrain:app --host 0.0.0.0 --port 8001 --reload
   ```

5. **Run Jupyter Notebook**:
   ```bash
   uv run jupyter lab
   ```
