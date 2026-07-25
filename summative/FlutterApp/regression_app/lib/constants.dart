/// API configuration for the diabetes prediction app.
class ApiConfig {
  
  static const String baseUrl = 'https://diabetes-glucose-api.onrender.com';

  /// The prediction endpoint path.
  static const String predictPath = '/predict';

  /// Full prediction URL.
  static String get predictUrl => '$baseUrl$predictPath';
}

/// Input field labels and validation rules.
class InputFields {
  static const String bmiLabel = 'BMI';
  static const String ageLabel = 'Age';
  static const String bpLabel = 'Blood Pressure (mm Hg)';
  static const String pregnanciesLabel = 'Pregnancies';
  static const String insulinLabel = 'Insulin (mu U/ml)';
  static const String pedigreeLabel = 'Diabetes Pedigree Function';
  static const String outcomeLabel = 'Outcome (0 = no diabetes, 1 = diabetes)';
}

/// JSON keys sent to the API and received in the response.
class ApiKeys {
  // Request keys
  static const String bmi = 'BMI';
  static const String age = 'Age';
  static const String bloodPressure = 'BloodPressure';
  static const String pregnancies = 'Pregnancies';
  static const String insulin = 'Insulin';
  static const String diabetesPedigreeFunction = 'DiabetesPedigreeFunction';
  static const String outcome = 'Outcome';

  // Response keys
  static const String predictedGlucose = 'predicted_glucose';
  static const String riskFlag = 'risk_flag';
}

/// Validation ranges matching the backend Pydantic model.
class ValidationRanges {
  static const double bmiMin = 10.0;
  static const double bmiMax = 70.0;
  static const int ageMin = 1;
  static const int ageMax = 120;
  static const int bpMin = 30;
  static const int bpMax = 140;
  static const int pregnanciesMin = 0;
  static const int pregnanciesMax = 20;
  static const double insulinMin = 0.0;
  static const double insulinMax = 900.0;
  static const double pedigreeMin = 0.0;
  static const double pedigreeMax = 3.0;
  static const int outcomeMin = 0;
  static const int outcomeMax = 1;
}

/// Error messages used throughout the app.
class ErrorMessages {
  static const String networkError =
      'Network error. Please check your connection and try again.';
  static const String serverError =
      'Server error. Please try again later.';
  static const String invalidInput =
      'Please enter valid numeric values.';
  static const String invalidAge =
      'Please enter a valid age (1–120).';
  static const String invalidBmi =
      'Please enter a valid BMI (10–70).';
  static const String invalidBp =
      'Please enter a valid blood pressure (30–140).';
  static const String invalidPregnancies =
      'Please enter a valid number of pregnancies (0–20).';
  static const String invalidInsulin =
      'Please enter a valid insulin level (0–900).';
  static const String invalidPedigree =
      'Please enter a valid pedigree function (0–3).';
  static const String invalidOutcome =
      'Outcome must be 0 (no diabetes) or 1 (diabetes).';
  static const String predictionFailed =
      'Failed to get prediction. Please try again.';
}

