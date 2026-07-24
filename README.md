# Diabetes Glucose Prediction — [Regression, API and Mobile App]

A regression model that predicts a patient's **blood glucose level** from
routine health metrics, deployed as a REST API and consumed by a Flutter
mobile app.

## Mission

Rather than predicting the binary diabetes `Outcome` label directly (a
classification problem), this project predicts **blood glucose level**. The
key clinical marker used to diagnose and monitor diabetes risk. A continuous
glucose estimate is more clinically useful than a yes/no flag: it can be
compared against standard thresholds (≥140 mg/dL = elevated/pre-diabetic
range) to produce a nuanced, actionable risk signal from routine metrics
alone (BMI, age, blood pressure, pregnancies, insulin, pedigree function,
existing diagnosis status).

## Project structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb        # Task 1: data cleaning, EDA, model training
│   │   ├── best_glucose_model.pkl    # trained model bundle (model + scaler + features)
│   │   └── Healthcare-Diabetes.csv   # dataset (Kaggle)
│   ├── API/
│   │   ├── prediction.py             # Task 2: FastAPI app (/predict, /retrain, /health)
│   │   ├── best_glucose_model.pkl
│   │   └── Healthcare-Diabetes.csv
│   └── FlutterApp/
│       ├── lib/main.dart             # Task 3: single-page Flutter app
│       └── pubspec.yaml
├── pyproject.toml                    # Python deps, managed with uv
├── uv.lock
└── .gitignore
```

## Task 1 — Regression Model

**Dataset:** [Healthcare-Diabetes.csv](https://www.kaggle.com/datasets/nanditapore/healthcare-diabetes/data)

**Data cleaning:** removed duplicate rows (dataset had ~1990 duplicates
padding the original 768-row dataset), and fixed disguised missing values —
`Glucose`, `BloodPressure`, `SkinThickness`, `Insulin`, and `BMI` use `0` as
a placeholder for missing readings, which were imputed with the group median
by diagnosis outcome.

**Target:** `Glucose` (continuous). **Features:** `BMI`, `Age`,
`BloodPressure`, `Pregnancies`, `Insulin`, `DiabetesPedigreeFunction`,
`Outcome`. `SkinThickness` was dropped (weak correlation with Glucose
specifically, and the least reliably collected field in the raw data).

**Models compared:** Linear Regression, Ridge, Lasso, and SGD Regression
(gradient descent), evaluated on MSE and R² on a held-out test set. Gradient
descent was also run as an explicit epoch-by-epoch loop to plot train/test
loss curves. The best-performing model (by test MSE) is saved to
`best_glucose_model.pkl`.

See `multivariate.ipynb` for the full walkthrough, visualizations and
written interpretation at each step.

## Task 2 — API

FastAPI service (`summative/API/prediction.py`) exposing:

- `POST /predict` — Pydantic-validated patient input (typed + range-constrained
  per field), returns predicted glucose level and a NORMAL/ELEVATED risk flag
- `POST /retrain` — upload a new labeled CSV to append to the training data
  and retrain the model, replacing the saved bundle if a better model results
- `GET /health` — liveness check

CORS is configured with `allow_origins=["*"]`, reasoned in the code comments:
this is a public coursework demo API with no auth/session data to protect,
and needs to accept requests from Swagger UI, Flutter Web and native
mobile testing alike.

**Local run:** `uv run uvicorn prediction:app --reload` from inside
`summative/API/`, then open `http://127.0.0.1:8000/docs`.

**Deployed Swagger UI:** `https://diabetes-glucose-api.onrender.com/docs`

## Task 3 — Flutter App

Single-page app (`summative/FlutterApp/lib/main.dart`) with one text field
per model input, a **Predict** button, and a display area showing the
predicted glucose value + risk flag, or a validation/network error. See
`FlutterApp/README.md` for setup (`flutter create .` scaffolding step) and
how to point it at a local vs. deployed API URL.

## Setup (Python side)

```bash
uv sync
```

installs everything from `pyproject.toml`/`uv.lock` into `.venv`.

## Video Demo

`[PASTE YOUR VIDEO LINK HERE]`