# Solar Power Prediction System - Flutter Mobile Application

A cross-platform Flutter application providing real-time AI-based solar power generation prediction using FastAPI backend telemetry.

## Features
- **Intuitive Visual Layout**: Clean dark-mode UI tailored for solar energy operators.
- **Strict Client-Side Validation**: Ensures numerical format and realistic range checks on all inputs before network dispatch.
- **RESTful API Integration**: Sends HTTP `POST` requests to FastAPI `/predict` endpoint.
- **Dynamic Configuration**: Supports custom FastAPI backend host URLs (e.g. `http://10.0.2.2:8000` for Android emulator or `http://localhost:8000` for Web/Desktop).
- **Graceful Error Handling**: Manages network timeouts, bad request payloads, and API connection failures.

## Prerequisites
- Flutter SDK (`>= 3.0.0`)
- Dart SDK (`>= 3.0.0`)
- Running instance of FastAPI backend (`prediction.py`)

## Running the Application

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Launch on Android Emulator**:
   ```bash
   flutter run -d android
   ```

3. **Launch on Web / Chrome**:
   ```bash
   flutter run -d chrome
   ```

4. **Launch on Desktop**:
   ```bash
   flutter run -d windows
   ```

## Target API Endpoint
The app targets:
- `POST /predict`
- Payload schema:
  ```json
  {
    "temperature_2_m_above_gnd": 22.5,
    "relative_humidity_2_m_above_gnd": 35.0,
    "mean_sea_level_pressure_MSL": 1018.5,
    "total_cloud_cover_sfc": 12.0,
    "shortwave_radiation_backwards_sfc": 480.0,
    "wind_speed_10_m_above_gnd": 8.5,
    "wind_direction_10_m_above_gnd": 195.0,
    "angle_of_incidence": 32.0,
    "zenith": 42.5,
    "azimuth": 168.0
  }
  ```
