import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/blood_request_provider.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';

class InteractionPopupHelper {
  static final Set<String> _shownIds = {};

  static void show(BuildContext context, NotificationModel notification) {
    if (_shownIds.contains(notification.id)) return;
    _shownIds.add(notification.id);

    bool isDonorInteraction = notification.title == 'Donor Interaction';

    
    IconData icon;
    Color color;
    
    if (isDonorInteraction) {
      icon = Icons.volunteer_activism_rounded;
      color = AppTheme.blue;
    } else {
      bool isAccepted = notification.message.contains('ACCEPTED');
      icon = isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded;
      color = isAccepted ? AppTheme.green : AppTheme.primaryRed;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                notification.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.gray900),
              ),
              const SizedBox(height: 16),
              Text(
                notification.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppTheme.gray600, height: 1.6),
              ),
              const SizedBox(height: 32),
              if (isDonorInteraction)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final user = context.read<AuthProvider>().user;
                              context.read<BloodRequestProvider>().respondToInteraction(
                                originalNotif: notification,
                                accepted: true,
                                requesterName: user?.name ?? 'Requester',
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Accept Offer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final user = context.read<AuthProvider>().user;
                              context.read<BloodRequestProvider>().respondToInteraction(
                                originalNotif: notification,
                                accepted: false,
                                requesterName: user?.name ?? 'Requester',
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                              foregroundColor: AppTheme.primaryRed,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Decide Later', style: TextStyle(color: AppTheme.gray400, fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.read<NotificationProvider>().markRead(notification.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
