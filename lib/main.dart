import 'package:flutter/material.dart';

void main() => runApp(const BBKOCRUATApp());

class BBKOCRUATApp extends StatelessWidget {
  const BBKOCRUATApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBK OCR UAT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5B95)),
        useMaterial3: true,
      ),
      home: const UATHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UATHome extends StatefulWidget {
  const UATHome({super.key});
  @override
  State<UATHome> createState() => _UATHomeState();
}

class _UATHomeState extends State<UATHome> {
  // Source text (paste here instead of OCR to keep build simple & stable)
  final srcCtrl = TextEditingController();

  // Fields
  final debitCtrl = TextEditingController();     // BBK DEBIT (12)
  final ibanCtrl = TextEditingController();      // KW + 30 + mod97
  final bicCtrl = TextEditingController();       // 8/11
  final amountCtrl = TextEditingController();    // number
  final ccyCtrl = TextEditingController(text: "KWD");
  final benNameCtrl = TextEditingController();
  final benBankCtrl = TextEditingController();
  final acctCtrl = TextEditingController();      // 12
  final purposeCtrl = TextEditingController();
  final chargesCtrl = TextEditingController();   // OUR/SHA/BEN

  @override
  void dispose() {
    srcCtrl.dispose();
    debitCtrl.dispose();
    ibanCtrl.dispose();
    bicCtrl.dispose();
    amountCtrl.dispose();
    ccyCtrl.dispose();
    benNameCtrl.dispose();
    benBankCtrl.dispose();
    acctCtrl.dispose();
    purposeCtrl.dispose();
    chargesCtrl.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  // BBK DEBIT: exactly 12 alnum (often digits)
  static bool _isDebit12(String s) => RegExp(r'^[A-Z0-9]{12}$').hasMatch(s);

  // IBAN KW: must be KW, length 30, mod97 == 1
  static bool _isKWIBAN30(String s) {
    final t = s.replaceAll(' ', '').toUpperCase();
    if (!t.startsWith('KW') || t.length != 30) return false;
    return _ibanMod97(t) == 1;
  }

  // ISO 13616 mod97
  static int _ibanMod97(String iban) {
    final rearr = (iban.substring(4) + iban.substring(0, 4)).toUpperCase();
    final sb = StringBuffer();
    for (final ch in rearr.runes) {
      final c = String.fromCharCode(ch);
      if (RegExp(r'[A-Z]').hasMatch(c)) {
        sb.write((c.codeUnitAt(0) - 55).toString()); // A=10 … Z=35
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        sb.write(c);
      } else {
        // ignore spaces
      }
    }
    // compute mod iteratively to avoid bigints
    var rem = 0;
    final digits = sb.toString();
    for (int i = 0; i < digits.length; i++) {
      rem = (rem * 10 + (digits.codeUnitAt(i) - 48)) % 97;
    }
    return rem;
  }

  // BIC 8 or 11
  static bool _isBIC(String s) =>
      RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(s);

  // Amount: up to 2 decimals
  static bool _isAmount(String s) => RegExp(r'^\d{1,15}(\.\d{1,2})?$').hasMatch(s);

  // Currency: 3 letters
  static bool _isCCY(String s) => RegExp(r'^[A-Z]{3}$').hasMatch(s);

  // Account 12 digits
  static bool _isAcct12(String s) => RegExp(r'^\d{12}$').hasMatch(s);

  // Charges OUR/SHA/BEN (accept also OU/SH/BE)
  static bool _isCharges(String s) {
    final t = s.trim().toUpperCase();
    return ['OUR','SHA','BEN','OU','SH','BE'].contains(t);
  }

  // ---------- Parsing from source text ----------
  void _parse() {
    final t = srcCtrl.text;
    String? pick(RegExp re) => re.firstMatch(t)?.group(1);

    // Try to find fields
    final iban = pick(RegExp(r'\b(KW[0-9A-Z ]{28})\b', caseSensitive: false))?.replaceAll(' ', '');
    final bic = pick(RegExp(r'\b([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)\b'));
    final ccy = pick(RegExp(r'\b([A-Z]{3})\b'));
    // Amount formats e.g. "KWD 68,701/051" or "68701.51" etc.
    final amtRaw = pick(RegExp(r'(?:(?:AMOUNT|AMT|KWD)\s*)?([0-9]{1,3}(?:[,\s][0-9]{3})*(?:[./][0-9]{1,2})|[0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false));
    String? normAmount(String? s) {
      if (s == null) return null;
      var x = s.replaceAll(RegExp(r'[, ]'), '');
      x = x.replaceAll('/', '.'); // handle 701/05 → 701.05
      if (_isAmount(x)) return x;
      return null;
    }
    final amt = normAmount(amtRaw);

    final acct = pick(RegExp(r'(?:ACCOUNT(?:\s*NO\.?)?[:\s\-]*)(\d{12})', caseSensitive: false)) ??
        pick(RegExp(r'\b(\d{12})\b'));
    final debit = pick(RegExp(r'\bBBK\s*DEBIT[:\s\-]*([A-Z0-9]{12})', caseSensitive: false)) ??
        pick(RegExp(r'\b([A-Z0-9]{12})\b'));
    final benName = pick(RegExp(r'(?:BENEFICIARY\s*NAME[:\s\-]*)(.+)', caseSensitive: false));
    final benBank = pick(RegExp(r'(?:BEN\s*BANK[:\s\-]*)([A-Z0-9]{2,20})', caseSensitive: false));
    final charges = pick(RegExp(r'(OUR|SHA|BEN|OU|SH|BE)', caseSensitive: false));
    final purpose = pick(RegExp(r'(?:PURPOSE|REMARKS|DETAILS)[:\s\-]*(.+)', caseSensitive: false));

    setState(() {
      if (iban != null) ibanCtrl.text = iban.toUpperCase();
      if (bic != null) bicCtrl.text = bic.toUpperCase();
      if (amt != null) amountCtrl.text = amt;
      if (ccy != null && _isCCY(ccy.toUpperCase())) ccyCtrl.text = ccy.toUpperCase();
      if (acct != null) acctCtrl.text = acct;
      if (debit != null) debitCtrl.text = debit.toUpperCase();
      if (benName != null) benNameCtrl.text = _singleLine(benName);
      if (benBank != null) benBankCtrl.text = benBank.toUpperCase();
      if (charges != null) chargesCtrl.text = charges.toUpperCase();
      if (purpose != null) purposeCtrl.text = _singleLine(purpose);
    });
  }

  String _singleLine(String s) =>
      s.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required bool Function(String) validator,
    String hint = '',
    TextInputType? type,
    int? maxLen,
    bool upper = true,
  }) {
    final ok = validator(ctrl.text.trim());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            maxLength: maxLen,
            onChanged: (_) => setState((){}),
            inputFormatters: upper ? [UpperCaseTextFormatter()] : null,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(ok ? 'OK' : 'ERR',
                      style: TextStyle(color: ok ? Colors.green.shade900 : Colors.red.shade900)),
                  backgroundColor: ok ? Colors.green.shade100 : Colors.red.shade100,
                  side: BorderSide(color: ok ? Colors.green.shade300 : Colors.red.shade300),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 60),
            ),
          ),
        ),
      ],
    );
  }

  void _clearAll() {
    for (final c in [
      debitCtrl, ibanCtrl, bicCtrl, amountCtrl, ccyCtrl,
      benNameCtrl, benBankCtrl, acctCtrl, purposeCtrl, chargesCtrl
    ]) {
      c.clear();
    }
    ccyCtrl.text = 'KWD';
    setState((){});
  }

  void _loadSample() {
    srcCtrl.text = '''
:20: SAMPLE REF
:32A: 240815KWD68701/51
:50K: BBK DEBIT 22LBBK123456
:57A: ABCDKWKWXXX
:59: ACCOUNT NO. 123456789012
Beneficiary Name: M/s. Globemed Kuwait For Health Insurance
Ben Bank: BU
Purpose: Claims Admin
Charges: OUR
IBAN: KW81 BBOK 0000 0000 0000 0000 0000 00
''';
    _parse();
  }

  @override
  Widget build(BuildContext context) {
    final okAll = _isDebit12(debitCtrl.text.trim())
        && _isKWIBAN30(ibanCtrl.text.trim())
        && _isBIC(bicCtrl.text.trim())
        && _isAmount(amountCtrl.text.trim())
        && _isCCY(ccyCtrl.text.trim())
        && benNameCtrl.text.trim().isNotEmpty
        && benBankCtrl.text.trim().isNotEmpty
        && _isAcct12(acctCtrl.text.trim())
        && purposeCtrl.text.trim().isNotEmpty
        && _isCharges(chargesCtrl.text.trim());

    return Scaffold(
      appBar: AppBar(
        title: const Text('BBK OCR UAT'),
        actions: [
          IconButton(
            tooltip: 'Paste sample & parse',
            onPressed: _loadSample,
            icon: const Icon(Icons.auto_fix_high),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Paste MT103-like text (no camera in UAT build):',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: srcCtrl,
            minLines: 6,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Paste text here…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                onPressed: _parse,
                icon: const Icon(Icons.document_scanner),
                tooltip: 'Parse',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Parsed fields (strict rules):',
              style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 8),
          _field(
            label: 'BBK DEBIT (12)',
            ctrl: debitCtrl,
            validator: _isDebit12,
            hint: 'e.g. 22LBBK123456',
            maxLen: 12,
          ),

          _field(
            label: 'IBAN (KW, 30)',
            ctrl: ibanCtrl,
            validator: _isKWIBAN30,
            hint: 'KW + 30 chars, mod97=1',
            maxLen: 30,
          ),

          _field(
            label: 'BIC/SWIFT (8/11)',
            ctrl: bicCtrl,
            validator: _isBIC,
            hint: 'e.g. ABCDKWKW or ABCDKWKWXXX',
            maxLen: 11,
          ),

          _field(
            label: 'Amount',
            ctrl: amountCtrl,
            validator: _isAmount,
            hint: 'e.g. 68701.51',
            type: const TextInputType.numberWithOptions(decimal: true),
            upper: false,
          ),

          _field(
            label: 'Currency',
            ctrl: ccyCtrl,
            validator: _isCCY,
            hint: 'KWD',
            maxLen: 3,
          ),

          _field(
            label: 'Beneficiary',
            ctrl: benNameCtrl,
            validator: (s) => s.trim().isNotEmpty,
            hint: 'Full name',
          ),

          _field(
            label: 'Ben Bank',
            ctrl: benBankCtrl,
            validator: (s) => s.trim().isNotEmpty,
            hint: 'Code/Name',
            maxLen: 20,
          ),

          _field(
            label: 'Account No.',
            ctrl: acctCtrl,
            validator: _isAcct12,
            hint: '12 digits',
            type: TextInputType.number,
            maxLen: 12,
            upper: false,
          ),

          _field(
            label: 'Purpose',
            ctrl: purposeCtrl,
            validator: (s) => s.trim().isNotEmpty,
            hint: 'Payment details',
          ),

          _field(
            label: 'Charges',
            ctrl: chargesCtrl,
            validator: _isCharges,
            hint: 'OUR / SHA / BEN',
            maxLen: 3,
          ),

          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(okAll ? Icons.verified : Icons.error_outline,
                  color: okAll ? Colors.green : Colors.red),
              title: Text(okAll ? 'All fields valid.' : 'Fix invalid fields above.'),
              subtitle: const Text('Strict: IBAN KW length=30 & mod97, Account=12, BIC 8/11, Amount format.'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Uppercase formatter for text fields
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
