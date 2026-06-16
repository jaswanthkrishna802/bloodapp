import 'package:flutter/material.dart';
import '../models/blood_request_model.dart';
import '../theme/app_theme.dart';
import 'urgency_badge.dart';

class BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback? onRespond;

  const BloodRequestCard({super.key, required this.request, this.onRespond});

  Color get _borderColor {
    switch (request.urgency) {
      case UrgencyLevel.critical: return AppTheme.primaryRed;
      case UrgencyLevel.urgent: return AppTheme.orange;
      case UrgencyLevel.normal: return AppTheme.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _borderColor, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(request.bloodGroup,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _borderColor)),
              const Spacer(),
              UrgencyBadge(urgency: request.urgency),
            ],
          ),
          const SizedBox(height: 4),
          Text('🏥 ${request.hospitalName}',
            style: const TextStyle(fontSize: 11, color: AppTheme.gray600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('📍 ${request.distanceKm?.toStringAsFixed(1) ?? "0.0"} km · ${request.unitsRequired} units',
                style: const TextStyle(fontSize: 10, color: AppTheme.gray400)),
              const Spacer(),
              if (onRespond != null)
              GestureDetector(
                onTap: onRespond,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Respond →',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _borderColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
