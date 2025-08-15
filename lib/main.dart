import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBK OCR Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OCRHomePage(),
    );
  }
}

class OCRHomePage extends StatelessWidget {
  const OCRHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BBK OCR UAT")),
      body: const Center(child: Text("OCR App Ready")),
    );
  }
}
