import 'package:flutter/material.dart';

class PayslipColors {
  static const primaryNavy = Color(0xFF031121);
  static const secondaryNavy = Color(0xFF0A2A5E);
  static const accentCyan = Color(0xFF00B4D8);
  static const background = Color(0xFFF8FAFC);
  static const text = Color(0xFF1B2230);
}

class PayslipCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PayslipCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class PayslipInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const PayslipInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: PayslipColors.text, fontSize: 12, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

String money(Object? value) {
  final parsed = value is num ? value : num.tryParse('$value') ?? 0;
  return 'Rs ${parsed.toStringAsFixed(2)}';
}
