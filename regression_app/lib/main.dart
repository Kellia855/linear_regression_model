import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(DiabetesApp());

class DiabetesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PredictPage(),
    );
  }
}

class PredictPage extends StatefulWidget {
  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final ageController = TextEditingController();
  final bmiController = TextEditingController();
  final bpController = TextEditingController();
  String result = "";

  Future<void> predict() async {
    final response = await http.post(
      Uri.parse("https://your-api-url.onrender.com/predict"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "age": int.parse(ageController.text),
        "bmi": double.parse(bmiController.text),
        "bp": double.parse(bpController.text),
        "s1": 0.0, "s2": 0.0, "s3": 0.0, "s4": 0.0, "s5": 0.0, "s6": 0.0
      }),
    );
    setState(() {
      result = json.decode(response.body)["prediction"].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Diabetes Prediction")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: ageController, decoration: InputDecoration(labelText: "Age")),
            TextField(controller: bmiController, decoration: InputDecoration(labelText: "BMI")),
            TextField(controller: bpController, decoration: InputDecoration(labelText: "Blood Pressure")),
            ElevatedButton(onPressed: predict, child: Text("Predict")),
            Text("Result: $result"),
          ],
        ),
      ),
    );
  }
}
