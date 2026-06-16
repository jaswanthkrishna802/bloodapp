import 'package:flutter/material.dart';
import '../models/blood_request_model.dart';
import '../theme/app_theme.dart';

class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    switch (urgency) {
      case UrgencyLevel.critical:
        bg = AppTheme.lightRed; text = AppTheme.primaryRed; label = 'CRITICAL';
      case UrgencyLevel.urgent:
        bg = AppTheme.lightOrange; text = AppTheme.orange; label = 'URGENT';
      case UrgencyLevel.normal:
        bg = AppTheme.lightGreen; text = AppTheme.green; label = 'NORMAL';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: text)),
    );
  }
}
