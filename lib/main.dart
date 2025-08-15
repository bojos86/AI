import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const BbkOcrUatApp());

class BbkOcrUatApp extends StatelessWidget {
  const BbkOcrUatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBK OCR UAT',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3450FF),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BBK OCR UAT')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome 👋\nChoose how you want to fill the transfer details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Paste / Scan Text (MT103)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasteParseScreen()),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Manual Entry (Strict Form)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransferFormScreen()),
              ),
            ),
            const Spacer(),
            const Center(child: Text('v1.0 • UAT Build')),
          ],
        ),
      ),
    );
  }
}

/* ===========================
 * VALIDATION & HELPERS
 * ===========================
*/

final _ibanRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$'); // generic
final _ibanKWRegex = RegExp(r'^KW[0-9]{2}[A-Z0-9]{26}$');      // Kuwait 30 total
final _bic8or11 = RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$');
final _currency3 = RegExp(r'^[A-Z]{2,3}$');
final _digitsOnly = RegExp(r'^[0-9]+$');
final _amountRx = RegExp(r'^\d{1,12}([.,]\d{1,2})?$');

String? validateIbanKW(String value) {
  final v = value.trim().replaceAll(' ', '').toUpperCase();
  if (v.isEmpty) return 'Required';
  if (v.length != 30 || !_ibanKWRegex.hasMatch(v)) return 'KW IBAN must be 30 chars';
  if (!ibanMod97Valid(v)) return 'Invalid IBAN (mod97)';
  return null;
}

bool ibanMod97Valid(String iban) {
  // move first 4 chars to end
  final re = (iban.substring(4) + iban.substring(0, 4)).toUpperCase();
  // convert letters to numbers (A=10 ... Z=35)
  final sb = StringBuffer();
  for (var rune in re.runes) {
    final c = String.fromCharCode(rune);
    if (RegExp(r'[A-Z]').hasMatch(c)) {
      sb.write(10 + (c.codeUnitAt(0) - 'A'.codeUnitAt(0)));
    } else {
      sb.write(c);
    }
  }
  // compute mod 97 in chunks
  var remainder = 0;
  final s = sb.toString();
  const chunk = 9;
  for (var i = 0; i < s.length; i += chunk) {
    final part = '$remainder${s.substring(i, min(i + chunk, s.length))}';
    remainder = int.parse(part) % 97;
  }
  return remainder == 1;
}

String? validateAccount12(String v) {
  final s = v.trim();
  if (s.isEmpty) return 'Required';
  if (!_digitsOnly.hasMatch(s) || s.length != 12) return 'Account must be 12 digits';
  return null;
}

String? validateBic(String v) {
  final s = v.trim().toUpperCase();
  if (s.isEmpty) return 'Required';
  if (!_bic8or11.hasMatch(s)) return 'BIC must be 8 or 11';
  return null;
}

String? validateAmount(String v) {
  final s = v.trim();
  if (s.isEmpty) return 'Required';
  if (!_amountRx.hasMatch(s)) return 'Invalid amount';
  return null;
}

String? validateCurrency(String v) {
  final s = v.trim().toUpperCase();
  if (s.isEmpty) return 'Required';
  if (!_currency3.hasMatch(s)) return 'Use ISO code (e.g., KWD, USD)';
  return null;
}

/* ===========================
 * TRANSFER FORM
 * ===========================
*/

class TransferData {
  String bbkDebit = '';     // 12
  String iban = '';         // KW 30
  String bic = '';          // 8/11
  String amount = '';       // 68,701.05
  String currency = 'KWD';  // ISO
  String beneficiaryName = '';
  String beneficiaryBank = '';
  String accountNo = '';    // 12
  String purpose = '';
  String charges = 'OUR';   // OUR/SHA/BEN
}

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key, this.initial});
  final TransferData? initial;

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final data = TransferData();

  final _debit = TextEditingController();
  final _iban = TextEditingController();
  final _bic = TextEditingController();
  final _amt = TextEditingController();
  final _ccy = TextEditingController(text: 'KWD');
  final _benName = TextEditingController();
  final _benBank = TextEditingController();
  final _acct = TextEditingController();
  final _purpose = TextEditingController();
  final _charges = TextEditingController(text: 'OUR');

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final i = widget.initial!;
      _debit.text = i.bbkDebit;
      _iban.text = i.iban;
      _bic.text = i.bic;
      _amt.text = i.amount;
      _ccy.text = i.currency;
      _benName.text = i.beneficiaryName;
      _benBank.text = i.beneficiaryBank;
      _acct.text = i.accountNo;
      _purpose.text = i.purpose;
      _charges.text = i.charges;
    }
  }

  @override
  void dispose() {
    _debit.dispose();
    _iban.dispose();
    _bic.dispose();
    _amt.dispose();
    _ccy.dispose();
    _benName.dispose();
    _benBank.dispose();
    _acct.dispose();
    _purpose.dispose();
    _charges.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final out = TransferData()
        ..bbkDebit = _debit.text.trim()
        ..iban = _iban.text.trim().replaceAll(' ', '').toUpperCase()
        ..bic = _bic.text.trim().toUpperCase()
        ..amount = _amt.text.trim().replaceAll(',', '')
        ..currency = _ccy.text.trim().toUpperCase()
        ..beneficiaryName = _benName.text.trim()
        ..beneficiaryBank = _benBank.text.trim()
        ..accountNo = _acct.text.trim()
        ..purpose = _purpose.text.trim()
        ..charges = _charges.text.trim().toUpperCase();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreviewScreen(data: out)),
      );
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Entry (Strict)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _debit,
              decoration: _dec('BBK DEBIT (12)'),
              keyboardType: TextInputType.number,
              validator: validateAccount12,
              maxLength: 12,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _iban,
              decoration: _dec('IBAN (KW, 30)', hint: 'KW..'),
              textCapitalization: TextCapitalization.characters,
              validator: validateIbanKW,
              maxLength: 30,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bic,
              decoration: _dec('BIC/SWIFT (8/11)'),
              textCapitalization: TextCapitalization.characters,
              validator: validateBic,
              maxLength: 11,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amt,
                    decoration: _dec('Amount', hint: '68701.05'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: validateAmount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ccy,
                    decoration: _dec('Currency', hint: 'KWD'),
                    textCapitalization: TextCapitalization.characters,
                    validator: validateCurrency,
                    maxLength: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _benName,
              decoration: _dec('Beneficiary Name'),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _benBank,
              decoration: _dec('Beneficiary Bank'),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _acct,
              decoration: _dec('Account No. (12)'),
              keyboardType: TextInputType.number,
              validator: validateAccount12,
              maxLength: 12,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purpose,
              decoration: _dec('Purpose'),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _charges.text.toUpperCase(),
              items: const [
                DropdownMenuItem(value: 'OUR', child: Text('OUR')),
                DropdownMenuItem(value: 'SHA', child: Text('SHA')),
                DropdownMenuItem(value: 'BEN', child: Text('BEN')),
              ],
              onChanged: (v) => _charges.text = v ?? 'OUR',
              decoration: _dec('Charges'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Preview / Export'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================
 * PASTE / PARSE SCREEN
 * ===========================
*/

class PasteParseScreen extends StatefulWidget {
  const PasteParseScreen({super.key});

  @override
  State<PasteParseScreen> createState() => _PasteParseScreenState();
}

class _PasteParseScreenState extends State<PasteParseScreen> {
  final text = TextEditingController();
  TransferData? parsed;
  String? error;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void _parse() {
    final raw = text.text;
    error = null;
    try {
      final d = TransferData();
      // Try finders with simple regex (tolerant)
      String pick(RegExp rx) =>
          rx.firstMatch(raw)?.group(1)?.trim() ?? '';

      d.iban = pick(RegExp(r'\b(KW[A-Z0-9 ]{28})\b')).replaceAll(' ', '');
      d.bic = pick(RegExp(r'\
