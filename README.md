# Diabetes Glucose Prediction — Regression, API and Mobile App

## Mission

This project predicts a patient's **blood glucose level**, the key clinical
marker used to diagnose diabetes risk from routine health metrics (BMI,
age, blood pressure, insulin, pregnancies, pedigree function, diagnosis
history) giving a more nuanced risk signal than a binary diabetes flag.

## Dataset

[Healthcare-Diabetes.csv](https://www.kaggle.com/datasets/nanditapore/healthcare-diabetes/data) 

## Project structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb        # data cleaning, EDA, model training
│   │   ├── best_glucose_model.pkl    # trained model bundle (model + scaler + features)
│   │   └── Healthcare-Diabetes.csv   # dataset
│   ├── API/
│   │   ├── prediction.py             # FastAPI app (/predict, /retrain, /health)
│   │   ├── best_glucose_model.pkl
│   │   └── Healthcare-Diabetes.csv
│   ├── FlutterApp/
│   │   └── regression_app/           # Flutter project root
│   │       ├── lib/main.dart         # single-page Flutter app
│   │       ├── lib/constants.dart    # API URL, validation ranges, labels
│   │       └── pubspec.yaml
│   ├── pyproject.toml                # Python deps, managed with uv
│   └── uv.lock
└── .gitignore
```

## Task 1 — Regression Model

**Data cleaning:** removed duplicate rows (dataset had ~1990 duplicates
padding the original 768-row dataset) and fixed disguised missing values 
`Glucose`, `BloodPressure`, `SkinThickness`, `Insulin`, and `BMI` use `0` as
a placeholder for missing readings which were imputed with the group median
by diagnosis outcome.

**Target:** `Glucose` (continuous). **Features:** `BMI`, `Age`,
`BloodPressure`, `Pregnancies`, `Insulin`, `DiabetesPedigreeFunction`,
`Outcome`. `SkinThickness` was dropped (weaker correlation with Glucose
specifically than DiabetesPedigreeFunction and the least reliably collected
field in the raw data).

**Models compared:** Linear Regression, Ridge, Lasso, SGD Regression
(gradient descent), Random Forest, and Decision Tree — six models spanning
both linear and tree-based approaches, evaluated on MSE and R² on a held-out
test set. Gradient descent was also run as an explicit epoch-by-epoch loop
to plot train/test loss curves. Ridge Regression performed best (lowest test
MSE); the tree-based models underperformed the linear family here which
indicates the true relationship between these features and Glucose is close
to linear. The best model is saved to `best_glucose_model.pkl` and a
prediction is demonstrated on a single row of the test set before saving.

See `multivariate.ipynb` for the full walkthrough, visualizations and
written interpretation at each step.

## Task 2 — API

FastAPI service (`summative/API/prediction.py`) exposing:

- `POST /predict` — Pydantic-validated patient input (typed + range-constrained
  per field), returns predicted glucose level and a NORMAL/ELEVATED risk flag
- `POST /retrain` — upload a new labeled CSV to append to the training data
  and retrain the model, replacing the saved bundle if a better model results
- `GET /health` — liveness check

**CORS:** configured with an explicit allowlist (not a wildcard) specific
localhost ports used by Flutter Web's dev server plus the deployed API's own
domain, restricted to `GET`/`POST` methods and a `Content-Type`-only header
allowlist with credentials disabled (no cookies/sessions are used). Native
Android/iOS builds of the Flutter app are unaffected either way since CORS
is a browser-only enforcement mechanism. Full reasoning is in the code
comments above the middleware in `prediction.py`.

**Local run:** `uv run uvicorn prediction:app --reload` from inside
`summative/API/`, then open `http://127.0.0.1:8000/docs`.

**Deployed Swagger UI:** `https://diabetes-glucose-api.onrender.com/docs`

## Task 3 — Flutter App

Single-page app (`summative/FlutterApp/regression_app/lib/main.dart`) with
one text field per model input (BMI, Age, BloodPressure, Pregnancies,
Insulin, DiabetesPedigreeFunction, Outcome), a **Predict** button and a
display area showing the predicted glucose value and risk flag or a
validation/network error.

### Running the mobile app

1. From `summative/FlutterApp/regression_app/`, run `flutter pub get` to
   install dependencies (platform folders are already scaffolded).
2. Confirm `ApiConfig.baseUrl` near the top of `lib/constants.dart` points to
   the deployed API (`https://diabetes-glucose-api.onrender.com`) rather than
   `10.0.2.2` or `127.0.0.1`.
3. Run `flutter run` and select a physical device or emulator (not Chrome/web
   this must run as a mobile app).
4. Enter values in all 7 fields and tap **Predict**.

Full setup notes: `summative/FlutterApp/regression_app/README.md`.

## Setup (Python side)

```bash
cd summative
uv sync
```

installs everything from `summative/pyproject.toml`/`uv.lock` into
`summative/.venv`.

## Video Demo

`[https://youtu.be/eMnLxkuM2O8]`