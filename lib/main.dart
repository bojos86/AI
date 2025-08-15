import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_parser.dart';

void main() {
  runApp(const BBKOcrUatApp());
}

class BBKOcrUatApp extends StatelessWidget {
  const BBKOcrUatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBK OCR UAT',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const OcrHomePage(),
    );
  }
}

class OcrHomePage extends StatefulWidget {
  const OcrHomePage({super.key});
  @override
  State<OcrHomePage> createState() => _OcrHomePageState();
}

class _OcrHomePageState extends State<OcrHomePage> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer();
  File? _image;
  String _raw = '';
  ParsedFields? _parsed;
  bool _busy = false;

  Future<void> _pick(ImageSource src) async {
    setState(() {
      _busy = true;
      _raw = '';
      _parsed = null;
    });
    try {
      final x = await _picker.pickImage(source: src, imageQuality: 85);
      if (x == null) {
        setState(() => _busy = false);
        return;
      }
      final file = File(x.path);
      final input = InputImage.fromFile(file);
      final res = await _recognizer.processImage(input);
      final text = res.text;
      setState(() {
        _image = file;
        _raw = text;
        _parsed = OcrParser.parse(text);
      });
    } catch (e) {
      setState(() {
        _raw = 'ERROR: $e';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Widget _chip(FieldCheck c) {
    return Chip(
      label: Text(c.ok ? 'OK' : c.message),
      backgroundColor: c.ok ? Colors.green.shade600 : Colors.red.shade700,
      labelStyle: const TextStyle(color: Colors.white),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _parsed;
    return Scaffold(
      appBar: AppBar(title: const Text('BBK OCR UAT')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            if (p != null) _ParsedCard(parsed: p) else
              const Text('Upload or Scan to extract fields.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Raw OCR text'),
              initiallyExpanded: false,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _raw.isEmpty ? '(empty)' : _raw,
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedCard extends StatelessWidget {
  const _ParsedCard({required this.parsed});
  final ParsedFields parsed;

  @override
  Widget build(BuildContext context) {
    final ibanC = OcrParser.checkIbanKW(parsed.iban);
    final bicC = OcrParser.checkBic(parsed.bic);
    final acctC = OcrParser.checkAccount12(parsed.accountNo);
    final amtC = OcrParser.checkAmount(parsed.amount);
    final curC = OcrParser.checkCurrency(parsed.currency);

    Widget row(String label, String? value, FieldCheck? check) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value ?? '-', style: const TextStyle(fontFamily: 'monospace'))),
            if (check != null) const SizedBox(width: 8),
            if (check != null) _status(check),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('IBAN (KW,30)', parsed.iban, ibanC),
            row('BIC/SWIFT', parsed.bic, bicC),
            row('Account No.', parsed.accountNo, acctC),
            row('Amount', parsed.amount, amtC),
            row('Currency', parsed.currency, curC),
            row('Beneficiary', parsed.beneficiary, null),
            row('Ben Bank', parsed.benBank, null),
            row('Purpose', parsed.purpose, null),
            row('Charges', parsed.charges, null),
          ],
        ),
      ),
    );
  }

  Widget _status(FieldCheck c) {
    return Container(
      decoration: BoxDecoration(
        color: c.ok ? Colors.green.shade600 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        c.ok ? 'OK' : c.message,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
