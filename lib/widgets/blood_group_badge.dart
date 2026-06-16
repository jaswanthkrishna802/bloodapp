import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final double fontSize;
  final EdgeInsets? padding;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.fontSize = 14,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        bloodGroup,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryRed,
        ),
      ),
    );
  }
}
