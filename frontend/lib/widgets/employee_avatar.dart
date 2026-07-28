import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

/// Employee photo with an initials fallback for missing or broken URLs.
class EmployeeAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadius? borderRadius;

  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderRadius,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = (photoUrl ?? '').trim();
    final apiUri = Uri.parse(ApiConfig.baseUrl);
    final url = rawUrl.startsWith('/')
        ? apiUri.replace(path: rawUrl, query: null, fragment: null).toString()
        : rawUrl;
    final validUrl = url.isNotEmpty && url.toLowerCase() != 'null';
    final fallback = Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w900,
          fontSize: radius * .65,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: backgroundColor,
        child: validUrl
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : fallback,
      ),
    );
  }
}
