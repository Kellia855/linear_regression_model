import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants.dart';

void main() {
  runApp(const DiabetesPredictorApp());
}

class DiabetesPredictorApp extends StatelessWidget {
  const DiabetesPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucose Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all 7 input fields
  final _bmiController = TextEditingController();
  final _ageController = TextEditingController();
  final _bpController = TextEditingController();
  final _pregnanciesController = TextEditingController();
  final _insulinController = TextEditingController();
  final _pedigreeController = TextEditingController();
  final _outcomeController = TextEditingController();

  bool _isLoading = false;
  String _resultText = '';
  bool _isSuccessResult = false;

  @override
  void dispose() {
    _bmiController.dispose();
    _ageController.dispose();
    _bpController.dispose();
    _pregnanciesController.dispose();
    _insulinController.dispose();
    _pedigreeController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resultText = '';
      _isSuccessResult = false;
    });

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              ApiKeys.bmi: double.parse(_bmiController.text.trim()),
              ApiKeys.age: int.parse(_ageController.text.trim()),
              ApiKeys.bloodPressure: int.parse(_bpController.text.trim()),
              ApiKeys.pregnancies: int.parse(_pregnanciesController.text.trim()),
              ApiKeys.insulin: double.parse(_insulinController.text.trim()),
              ApiKeys.diabetesPedigreeFunction:
                  double.parse(_pedigreeController.text.trim()),
              ApiKeys.outcome: int.parse(_outcomeController.text.trim()),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final glucose = data[ApiKeys.predictedGlucose];
        final riskFlag = data[ApiKeys.riskFlag];
        setState(() {
          _resultText = 'Predicted Glucose: $glucose mg/dL\nRisk: $riskFlag';
          _isSuccessResult = true;
        });
      } else if (response.statusCode == 422) {
        // Pydantic validation error
        final data = json.decode(response.body);
        _showError('Invalid input: ${_formatValidationError(data)}');
      } else {
        _showError('Server error (${response.statusCode}): ${response.body}');
      }
    } on FormatException {
      _showError(ErrorMessages.invalidInput);
    } on http.ClientException {
      _showError(ErrorMessages.networkError);
    } catch (e) {
      _showError('Could not reach the server. Check the API URL and your connection.\n($e)');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatValidationError(dynamic data) {
    try {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail[0];
        final loc = (first['loc'] as List).last;
        final msg = first['msg'];
        return '$loc - $msg';
      }
      return detail.toString();
    } catch (_) {
      return 'one or more values are out of the allowed range.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _resultText = message;
      _isSuccessResult = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool allowDecimal = true,
    required num min,
    required num max,
    String? errorMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? 'e.g. ${(min + max) ~/ 2}',
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          if (!allowDecimal)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          final parsed = num.tryParse(value.trim());
          if (parsed == null) {
            return 'Enter a valid number';
          }
          if (parsed < min || parsed > max) {
            return errorMessage ?? 'Must be between $min and $max';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Predictor'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter patient metrics to estimate blood glucose level.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input fields card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNumberField(
                          controller: _bmiController,
                          label: InputFields.bmiLabel,
                          icon: Icons.monitor_weight,
                          min: ValidationRanges.bmiMin,
                          max: ValidationRanges.bmiMax,
                          errorMessage: ErrorMessages.invalidBmi,
                        ),
                        _buildNumberField(
                          controller: _ageController,
                          label: InputFields.ageLabel,
                          icon: Icons.calendar_today,
                          allowDecimal: false,
                          min: ValidationRanges.ageMin,
                          max: ValidationRanges.ageMax,
                          errorMessage: ErrorMessages.invalidAge,
                        ),
                        _buildNumberField(
                          controller: _bpController,
                          label: InputFields.bpLabel,
                          icon: Icons.favorite_border,
                          allowDecimal: false,
                          min: ValidationRanges.bpMin,
                          max: ValidationRanges.bpMax,
                          errorMessage: ErrorMessages.invalidBp,
                        ),
                        _buildNumberField(
                          controller: _pregnanciesController,
                          label: InputFields.pregnanciesLabel,
                          icon: Icons.child_care,
                          allowDecimal: false,
                          min: ValidationRanges.pregnanciesMin,
                          max: ValidationRanges.pregnanciesMax,
                          errorMessage: ErrorMessages.invalidPregnancies,
                        ),
                        _buildNumberField(
                          controller: _insulinController,
                          label: InputFields.insulinLabel,
                          icon: Icons.biotech,
                          min: ValidationRanges.insulinMin,
                          max: ValidationRanges.insulinMax,
                          errorMessage: ErrorMessages.invalidInsulin,
                        ),
                        _buildNumberField(
                          controller: _pedigreeController,
                          label: InputFields.pedigreeLabel,
                          icon: Icons.assessment,
                          min: ValidationRanges.pedigreeMin,
                          max: ValidationRanges.pedigreeMax,
                          errorMessage: ErrorMessages.invalidPedigree,
                        ),
                        _buildNumberField(
                          controller: _outcomeController,
                          label: InputFields.outcomeLabel,
                          icon: Icons.health_and_safety,
                          allowDecimal: false,
                          min: ValidationRanges.outcomeMin,
                          max: ValidationRanges.outcomeMax,
                          errorMessage: ErrorMessages.invalidOutcome,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Predict button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _predict,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.analytics_outlined),
                    label: Text(_isLoading ? 'Predicting...' : 'Predict'),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Result card
                if (_resultText.isNotEmpty)
                  Card(
                    color: _isSuccessResult
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isSuccessResult
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 28,
                            color: _isSuccessResult
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _resultText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _isSuccessResult
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

