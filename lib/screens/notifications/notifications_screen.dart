import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/notification_model.dart';
import '../../models/blood_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../providers/blood_request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().listenToNotifications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final bloodProvider = context.watch<BloodRequestProvider>();

    // Combine notifications and blood requests as "Alerts"
    final bloodAlerts = bloodProvider.nearbyRequests.map((r) => NotificationModel(
      id: r.id,
      title: '🩸 ${r.bloodGroup} Needed Urgently',
      message: '${r.hospitalName} needs ${r.unitsRequired} units for ${r.patientName}.',
      type: NotificationType.urgent,
      createdAt: r.createdAt,
      isRead: false,
    )).toList();

    final allAlerts = [...bloodAlerts, ...notifProvider.notifications];
    allAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Emergency Alerts', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20)),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        actions: [
          if (notifProvider.unreadCount > 0)
            IconButton(
              onPressed: () {
                final user = context.read<AuthProvider>().user;
                if (user != null) notifProvider.markAllRead(user.id);
              },
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              tooltip: 'Mark all read',
            )
        ],
      ),
      body: Column(
        children: [
          _statsHeader(bloodAlerts.length, notifProvider.unreadCount),
          Expanded(
            child: allAlerts.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: allAlerts.length,
                    itemBuilder: (context, index) {
                      final n = allAlerts[index];
                      return _alertCard(n, bloodProvider, context.read<AuthProvider>());
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statsHeader(int activeReqs, int unreadNotifs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(activeReqs.toString(), 'Active Requests'),
          Container(width: 1, height: 30, color: Colors.white24),
          _statItem(unreadNotifs.toString(), 'Unread Alerts'),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _alertCard(NotificationModel n, BloodRequestProvider bloodProvider, AuthProvider authProvider) {
    bool isUrgent = n.type == NotificationType.urgent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(
          color: isUrgent ? AppTheme.primaryRed.withValues(alpha: 0.2) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!n.isRead) context.read<NotificationProvider>().markRead(n.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconFor(n.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(n.title, 
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.gray900)),
                          ),
                          Text(n.timeAgo, 
                            style: const TextStyle(fontSize: 10, color: AppTheme.gray400, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(n.message, 
                        style: TextStyle(fontSize: 12, color: AppTheme.gray600, height: 1.4, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w500)),
                      if (isUrgent) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.primaryRed),
                            const SizedBox(width: 4),
                            const Text('Emergency Request Near You', 
                              style: TextStyle(fontSize: 10, color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (() {
                              final req = bloodProvider.nearbyRequests.firstWhereOrNull((r) => r.id == n.id);
                              return req != null && req.requestedBy != authProvider.user?.id;
                            }())
                            GestureDetector(
                              onTap: () {
                                final request = bloodProvider.nearbyRequests.firstWhereOrNull((r) => r.id == n.id);
                                if (request != null) {
                                  _onRespond(context, request);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('View Action →', 
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRespond(BuildContext context, BloodRequestModel request) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
    );

    final authService = AuthService();
    final solicitor = await authService.getUserById(request.requestedBy);

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (solicitor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch solicitor details'), backgroundColor: AppTheme.primaryRed));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Solicitor Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryRed),
              title: Text(solicitor.name),
              subtitle: const Text('Requester Name'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryRed),
              title: Text(solicitor.phone),
              subtitle: const Text('Contact Number'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.primaryRed),
              title: Text(solicitor.location),
              subtitle: const Text('Location'),
            ),
            const SizedBox(height: 8),
            // Distance Calculation and Maps Button
            FutureBuilder(
              future: LocationService().getCurrentPosition(),
              builder: (context, snapshot) {
                final donorPos = snapshot.hasData ? snapshot.data : null;
                final double? destLat = request.latitude ?? solicitor.latitude;
                final double? destLng = request.longitude ?? solicitor.longitude;

                if (donorPos != null && destLat != null && destLng != null) {
                  final dist = LocationService().distanceBetween(
                    donorPos.latitude,
                    donorPos.longitude,
                    destLat,
                    destLng,
                  );

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${dist.toStringAsFixed(1)} KM AWAY FROM YOU',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryRed,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = 'https://www.google.com/maps/dir/?api=1&origin=${donorPos.latitude},${donorPos.longitude}&destination=$destLat,$destLng&travelmode=driving';
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.directions_rounded, size: 18),
                              label: const Text('Navigate in Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final encodedAddress = Uri.encodeComponent(solicitor.location);
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.directions_outlined, size: 18),
                        label: const Text('Get Directions to Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryRed,
                          side: BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.gray200),
          const SizedBox(height: 16),
          const Text('All clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray400)),
          const Text('No pending alerts to show.', style: TextStyle(color: AppTheme.gray200)),
        ],
      ),
    );
  }

  Widget _iconFor(NotificationType type) {
    IconData icon;
    Color color;
    Color bg;
    switch (type) {
      case NotificationType.urgent: 
        icon = Icons.emergency_rounded; color = AppTheme.primaryRed; bg = AppTheme.lightRed; break;
      case NotificationType.success: 
        icon = Icons.check_circle_rounded; color = AppTheme.green; bg = AppTheme.lightGreen; break;
      case NotificationType.info: 
        icon = Icons.info_rounded; color = AppTheme.blue; bg = AppTheme.lightBlue; break;
      case NotificationType.warning: 
        icon = Icons.warning_amber_rounded; color = AppTheme.orange; bg = AppTheme.lightOrange; break;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
