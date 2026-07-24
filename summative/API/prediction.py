"""
prediction.py

FastAPI service for the diabetes glucose-level regression model.
Combines the trained-model loading/prediction logic and the training/
retraining pipeline in a single file, per the required project structure.

Endpoints:
    POST /predict   - predict glucose level from patient metrics
    POST /retrain    - upload new labeled data (CSV) and retrain the model
    GET  /health     - simple liveness check

Run locally (with uv):
    uv run uvicorn prediction:app --reload

Swagger UI: http://127.0.0.1:8000/docs
"""

import io
import os

import numpy as np
import pandas as pd
import joblib

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LinearRegression, Ridge, Lasso, SGDRegressor
from sklearn.metrics import mean_squared_error, r2_score

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best_glucose_model.pkl")
DATA_STORE_PATH = os.path.join(BASE_DIR, "data_store.csv")

FEATURES = ["BMI", "Age", "BloodPressure", "Pregnancies", "Insulin", "DiabetesPedigreeFunction", "Outcome"]
TARGET = "Glucose"
FAKE_ZERO_COLS = ["Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI"]
REQUIRED_COLS = FEATURES + [TARGET]

# ---------------------------------------------------------------------------
# Data cleaning + training pipeline (mirrors the Task 1 notebook)
# ---------------------------------------------------------------------------
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """Drop Id/duplicates and fix disguised zero-as-missing values."""
    df = df.drop(columns=["Id"], errors="ignore")
    df = df.drop_duplicates().reset_index(drop=True)

    cols = [c for c in FAKE_ZERO_COLS if c in df.columns]
    df[cols] = df[cols].replace(0, np.nan)
    if "Outcome" in df.columns:
        df[cols] = df.groupby("Outcome")[cols].transform(lambda x: x.fillna(x.median()))
    else:
        df[cols] = df[cols].fillna(df[cols].median())
    return df


def train_and_save(df: pd.DataFrame) -> dict:
    """Clean, train all 4 candidate models, pick the best by test MSE, save it."""
    df = clean_data(df)

    missing = [c for c in REQUIRED_COLS if c not in df.columns]
    if missing:
        raise ValueError(f"Uploaded data is missing required columns: {missing}")

    X = df[FEATURES]
    y = df[TARGET]

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

    candidates = {
        "LinearRegression": LinearRegression(),
        "Ridge": Ridge(alpha=1.0),
        "Lasso": Lasso(alpha=0.1),
        "SGDRegressor": SGDRegressor(max_iter=1000, tol=1e-3, random_state=42),
    }

    metrics = {}
    best_name, best_model, best_mse = None, None, float("inf")
    for name, model in candidates.items():
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        mse = mean_squared_error(y_test, preds)
        r2 = r2_score(y_test, preds)
        metrics[name] = {"mse": mse, "r2": r2}
        if mse < best_mse:
            best_name, best_model, best_mse = name, model, mse

    bundle = {
        "model": best_model,
        "scaler": scaler,
        "features": FEATURES,
        "target": TARGET,
        "n_training_rows": len(df),
    }
    joblib.dump(bundle, MODEL_PATH)

    return {"best_model": best_name, "metrics": metrics, "n_training_rows": len(df)}


def load_bundle() -> dict:
    return joblib.load(MODEL_PATH)


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Diabetes Glucose Prediction API",
    description="Predicts blood glucose level from routine patient health metrics, "
                 "used as a continuous risk indicator for diabetes screening.",
    version="1.0.0",
)

# CORS configuration
# ---------------------------------------------------------------------------
# This API is called from a Flutter mobile app, which - depending on how it's
# built (Flutter Web vs. native iOS/Android) - may send requests from a
# browser-based origin subject to CORS, or from a native app context where
# CORS doesn't apply at all (CORS is a *browser* enforcement mechanism only).
#
# We allow all origins ("*") because:
#   - This is a public coursework demo API with no user accounts, cookies,
#     or sensitive session data - there is nothing origin-specific to protect.
#   - The Flutter app may be tested from Flutter Web (localhost, or a
#     preview URL that changes between runs) as well as from Swagger UI
#     directly in the browser, so a fixed origin allowlist would break testing.
# We restrict methods to GET/POST (the only ones this API uses) and disable
# credentialed requests (no cookies/auth tokens are involved), rather than
# leaving that wide open too.
#
# In a production deployment handling real patient data, this would instead
# be locked down to an explicit list of trusted origins (e.g. the deployed
# Flutter Web domain only), with credentials handled via tokens, not left
# wide open.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Request/response schemas
# ---------------------------------------------------------------------------
class PatientInput(BaseModel):
    BMI: float = Field(..., ge=10.0, le=70.0, description="Body Mass Index (kg/m^2)")
    Age: int = Field(..., ge=1, le=120, description="Age in years")
    BloodPressure: int = Field(..., ge=30, le=140, description="Diastolic blood pressure (mm Hg)")
    Pregnancies: int = Field(..., ge=0, le=20, description="Number of pregnancies")
    Insulin: float = Field(..., ge=0.0, le=900.0, description="2-Hour serum insulin (mu U/ml)")
    DiabetesPedigreeFunction: float = Field(..., ge=0.0, le=3.0, description="Diabetes pedigree function score")
    Outcome: int = Field(..., ge=0, le=1, description="Existing diabetes diagnosis: 0 = no, 1 = yes")

    class Config:
        json_schema_extra = {
            "example": {
                "BMI": 28.5,
                "Age": 35,
                "BloodPressure": 72,
                "Pregnancies": 2,
                "Insulin": 130.0,
                "DiabetesPedigreeFunction": 0.5,
                "Outcome": 0,
            }
        }


class PredictionResponse(BaseModel):
    predicted_glucose: float
    risk_flag: str


class RetrainResponse(BaseModel):
    message: str
    best_model: str
    n_training_rows: int
    metrics: dict


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict(patient: PatientInput):
    try:
        bundle = load_bundle()
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Model not found. Train the model before calling /predict.")

    x = pd.DataFrame([patient.model_dump()])[bundle["features"]]
    x_scaled = bundle["scaler"].transform(x)
    prediction = float(bundle["model"].predict(x_scaled)[0])

    risk_flag = "ELEVATED" if prediction >= 140 else "NORMAL"

    return PredictionResponse(predicted_glucose=round(prediction, 1), risk_flag=risk_flag)


@app.post("/retrain", response_model=RetrainResponse)
async def retrain(file: UploadFile = File(...)):
    """
    Upload a CSV of new labeled patient data (same columns as the original
    training set, including the Glucose target) to retrain the model.

    New rows are appended to the existing accumulated dataset on disk, so
    each retrain call builds on all data seen so far, not just the new file.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only .csv files are supported.")

    contents = await file.read()
    try:
        new_df = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV: {e}")

    try:
        existing_df = pd.read_csv(DATA_STORE_PATH)
        combined_df = pd.concat([existing_df, new_df], ignore_index=True)
    except FileNotFoundError:
        combined_df = new_df

    combined_df.to_csv(DATA_STORE_PATH, index=False)

    try:
        result = train_and_save(combined_df)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return RetrainResponse(
        message="Model retrained successfully with accumulated data.",
        best_model=result["best_model"],
        n_training_rows=result["n_training_rows"],
        metrics=result["metrics"],
    )