import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regression_app/lib/main.dart';


void main() {
  testWidgets('Diabetes Predictor App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DiabetesPredictorApp());

    // Verify that the app bar title is displayed.
    expect(find.text('Glucose Predictor'), findsWidgets);

    // Verify that all 7 input field labels are present.
    expect(find.text('BMI'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Blood Pressure (mm Hg)'), findsOneWidget);
    expect(find.text('Pregnancies'), findsOneWidget);
    expect(find.text('Insulin (mu U/ml)'), findsOneWidget);
    expect(find.text('Diabetes Pedigree Function'), findsOneWidget);
    expect(find.text('Outcome (0 = no diabetes, 1 = diabetes)'), findsOneWidget);

    // Verify that the Predict button is present.
    expect(find.text('Predict'), findsOneWidget);

    // Verify the header description text.
    expect(
      find.text('Enter patient metrics to estimate blood glucose level.'),
      findsOneWidget,
    );
  });

  testWidgets('Form validation - empty fields show Required errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DiabetesPredictorApp());

    // The Predict button is below the fold; scroll down to it and tap.
    await tester.scrollUntilVisible(
      find.text('Predict'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    // Verify "Required" appears for all 7 fields.
    expect(find.text('Required'), findsNWidgets(7));
  });

  testWidgets('Form validation - out-of-range values show errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DiabetesPredictorApp());

    // Enter out-of-range values in the first two fields.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '5');   // BMI – too low (min 10)
    await tester.enterText(fields.at(1), '0');   // Age – too low (min 1)

    // Scroll down to the Predict button and tap it.
    await tester.scrollUntilVisible(
      find.text('Predict'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    // Verify the custom validation error messages from constants.
    expect(
      find.text('Please enter a valid BMI (10–70).'),
      findsOneWidget,
    );
    expect(
      find.text('Please enter a valid age (1–120).'),
      findsOneWidget,
    );
  });
}

