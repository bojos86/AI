import 'dart:math';

class ParsedFields {
  final String? iban;
  final String? bic;
  final String? accountNo;
  final String? amount;
  final String? currency;
  final String? beneficiary;
  final String? benBank;
  final String? purpose;
  final String? charges;

  ParsedFields({
    this.iban,
    this.bic,
    this.accountNo,
    this.amount,
    this.currency,
    this.beneficiary,
    this.benBank,
    this.purpose,
    this.charges,
  });
}

class FieldCheck {
  final bool ok;
  final String message;
  FieldCheck(this.ok, this.message);
}

class OcrParser {
  static ParsedFields parse(String raw) {
    final text = raw.replaceAll('\u00A0', ' ').replaceAll('\r', '\n');

    // IBAN (KW – 30)
    final ibanReg = RegExp(r'\bK[Ww][A-Za-z0-9]{28}\b');
    final iban = _normalize(ibanReg.firstMatch(text)?.group(0));

    // BIC/SWIFT (8 أو 11)
    final bicReg = RegExp(r'\b[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?\b');
    final bic = bicReg.firstMatch(text.toUpperCase())?.group(0);

    // حساب (12 أرقام)
    final acctReg = RegExp(r'\b\d{12}\b');
    final accountNo = acctReg.firstMatch(text)?.group(0);

    // العملة
    final currReg = RegExp(r'\b(KWD|USD|EUR|GBP|AED|SAR|QAR|BHD|OMR)\b', caseSensitive: false);
    final currency = currReg.firstMatch(text.toUpperCase())?.group(0)?.toUpperCase();

    // المبلغ (أخذ أول رقم كبير)
    final amtReg = RegExp(r'(\d{1,3}(?:[,\s]\d{3})+|\d+)(?:[.,]\d{1,2})?');
    String? amount = amtReg.firstMatch(text.replaceAll(',', ''))?.group(0);
    if (amount != null) amount = amount.replaceAll(RegExp(r'[^\d.]'), '');

    // Beneficiary Name
    String? beneficiary;
    final ben1 = RegExp(r'Beneficiary Name[:\s\-]*([^\n]+)', caseSensitive: false).firstMatch(text);
    if (ben1 != null) beneficiary = ben1.group(1)?.trim();
    beneficiary ??= RegExp(r'\bM/s\.?\s+[A-Za-z0-9].{0,60}', caseSensitive: false).firstMatch(text)?.group(0)?.trim();

    // Beneficiary Bank
    String? benBank;
    final bank1 = RegExp(r'(Beneficiary Bank|Ben(?:eficiary)? Bank)[:\s\-]*([^\n]+)', caseSensitive: false).firstMatch(text);
    if (bank1 != null) benBank = bank1.group(2)?.trim();

    // Purpose / Details of payment
    String? purpose;
    final pur1 = RegExp(r'(Purpose|Details of payment|Payment details)[:\s\-]*([^\n]+)', caseSensitive: false).firstMatch(text);
    if (pur1 != null) purpose = pur1.group(2)?.trim();

    // Charges (OUR/SHA/BEN)
    String? charges;
    final chg = RegExp(r'\b(OUR|SHA|BEN)\b', caseSensitive: false).firstMatch(text.toUpperCase());
    if (chg != null) charges = chg.group(1)?.toUpperCase();

    return ParsedFields(
      iban: iban,
      bic: bic,
      accountNo: accountNo,
      amount: amount,
      currency: currency,
      beneficiary: beneficiary,
      benBank: benBank,
      purpose: purpose,
      charges: charges,
    );
  }

  // Checks
  static FieldCheck checkIbanKW(String? iban) {
    if (iban == null) return FieldCheck(false, 'not found');
    final s = _normalize(iban);
    if (!s.startsWith('KW')) return FieldCheck(false, 'must start KW');
    if (s.length != 30) return FieldCheck(false, 'length != 30');
    if (!_ibanMod97(s)) return FieldCheck(false, 'mod97 fail');
    return FieldCheck(true, 'OK');
  }

  static FieldCheck checkBic(String? bic) {
    if (bic == null) return FieldCheck(false, 'not found');
    final ok = RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(bic);
    return FieldCheck(ok, ok ? 'OK' : 'invalid');
  }

  static FieldCheck checkAccount12(String? acc) {
    if (acc == null) return FieldCheck(false, 'not found');
    return FieldCheck(RegExp(r'^\d{12}$').hasMatch(acc), RegExp(r'^\d{12}$').hasMatch(acc) ? 'OK' : '12 digits');
    }

  static FieldCheck checkAmount(String? a) {
    if (a == null) return FieldCheck(false, 'not found');
    final ok = double.tryParse(a) != null;
    return FieldCheck(ok, ok ? 'OK' : 'invalid');
  }

  static FieldCheck checkCurrency(String? c) {
    if (c == null) return FieldCheck(false, 'not found');
    final ok = RegExp(r'^[A-Z]{3}$').hasMatch(c);
    return FieldCheck(ok, ok ? 'OK' : '3 letters');
  }

  // Helpers
  static String _normalize(String? s) => (s ?? '').replaceAll('
