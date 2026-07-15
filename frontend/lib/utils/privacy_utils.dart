String maskMobileNumber(Object? rawValue) {
  final raw = '${rawValue ?? ''}'.trim();
  if (raw.isEmpty) return '';
  if (raw.contains('X') || raw.contains('•') || raw.contains('*')) return raw;

  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  final local = digits.length > 10
      ? digits.substring(digits.length - 10)
      : digits;
  final countryDigits = digits.length > 10
      ? digits.substring(0, digits.length - 10)
      : '';

  final maskedLocal = local.length <= 3
      ? '${local.substring(0, 1)}${List.filled(local.length - 1, 'X').join()}'
      : '${local.substring(0, 2)}${List.filled(local.length - 3, 'X').join()}${local.substring(local.length - 1)}';

  if (countryDigits.isNotEmpty) return '+$countryDigits $maskedLocal';
  return maskedLocal;
}
