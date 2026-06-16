import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/blood_request_provider.dart';
import '../../models/blood_request_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<BloodRequestProvider>();
    final myRequests = requestProvider.myRequests;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('My Request History',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.gray900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.gray900,
      ),
      body: myRequests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myRequests.length,
              itemBuilder: (context, index) {
                final request = myRequests[index];
                return _RequestHistoryCard(request: request);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: AppTheme.gray200),
          const SizedBox(height: 24),
          const Text('No Requests Yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray800)),
          const SizedBox(height: 8),
          const Text('Your blood request history will appear here.',
              style: TextStyle(color: AppTheme.gray400)),
        ],
      ),
    );
  }
}

// ─── Stateful Card (handles async donor fetch) ────────────────────────────────
class _RequestHistoryCard extends StatefulWidget {
  final BloodRequestModel request;
  const _RequestHistoryCard({required this.request});

  @override
  State<_RequestHistoryCard> createState() => _RequestHistoryCardState();
}

class _RequestHistoryCardState extends State<_RequestHistoryCard> {
  UserModel? _donor;
  bool _loadingDonor = false;

  BloodRequestModel get request => widget.request;

  @override
  void initState() {
    super.initState();
    if (request.status == RequestStatus.accepted &&
        request.acceptedDonorId != null) {
      _fetchDonor();
    }
  }

  Future<void> _fetchDonor() async {
    setState(() => _loadingDonor = true);
    try {
      final donor =
          await FirestoreService().getUserById(request.acceptedDonorId!);
      if (mounted) setState(() => _donor = donor);
    } finally {
      if (mounted) setState(() => _loadingDonor = false);
    }
  }

  void _showDonorSheet() {
    if (_donor == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DonorDetailSheet(donor: _donor!, request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(request.createdAt);
    final timeStr = DateFormat('hh:mm a').format(request.createdAt);

    Color statusColor;
    String statusText;

    switch (request.status) {
      case RequestStatus.pending:
        statusColor = AppTheme.orange;
        statusText = 'PENDING';
        break;
      case RequestStatus.accepted:
        statusColor = AppTheme.blue;
        statusText = 'ACCEPTED';
        break;
      case RequestStatus.fulfilled:
        statusColor = AppTheme.green;
        statusText = 'FULFILLED';
        break;
      case RequestStatus.cancelled:
        statusColor = AppTheme.gray400;
        statusText = 'CANCELLED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Main info row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(request.bloodGroup,
                        style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.patientName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.gray900)),
                      Text(request.hospitalName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray400,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.gray50),

          // ── Bottom row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.gray400),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.gray400),
                    const SizedBox(width: 6),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                if (request.status == RequestStatus.pending)
                  TextButton(
                    onPressed: () {
                      context
                          .read<BloodRequestProvider>()
                          .updateStatus(request.id, RequestStatus.cancelled);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryRed,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),

          // ── Donor banner (accepted only) ──────────────────────
          if (request.status == RequestStatus.accepted &&
              request.acceptedDonorId != null) ...[
            const Divider(height: 1, color: AppTheme.gray50),
            _loadingDonor
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.blue),
                    ),
                  )
                : _donor == null
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: _showDonorSheet,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.blue.withValues(alpha: 0.08),
                                AppTheme.blue.withValues(alpha: 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.blue.withValues(alpha: 0.2),
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppTheme.blue.withValues(alpha: 0.15),
                                child: Text(
                                  _donor!.name.isNotEmpty
                                      ? _donor!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppTheme.blue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Donor Accepted',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.blue,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 2),
                                    Text(_donor!.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.gray900)),
                                    Text(
                                        '${_donor!.bloodGroup}  •  ${_donor!.city}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.gray600)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.blue, size: 20),
                            ],
                          ),
                        ),
                      ),
          ],
        ],
      ),
    );
  }
}

// ─── Donor Detail Bottom Sheet ────────────────────────────────────────────────
class _DonorDetailSheet extends StatelessWidget {
  final UserModel donor;
  final BloodRequestModel request;
  const _DonorDetailSheet({required this.donor, required this.request});

  Future<void> _openMaps(double donorLat, double donorLng, double reqLat, double reqLng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=$donorLat,$donorLng&destination=$reqLat,$reqLng&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Avatar + name
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.blue.withValues(alpha: 0.12),
            child: Text(
              donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(donor.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.gray900)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(donor.bloodGroup,
                style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),

          const SizedBox(height: 12),

          // Distance info
          Builder(
            builder: (context) {
              return FutureBuilder(
                future: LocationService().getCurrentPosition(),
                builder: (context, snapshot) {
                  // Fallback: If request coordinates missing, use requester's (this user) current pos? 
                  // No, here we are requester looking at donor.
                  // We need donor's lat/lng and OUR hospital lat/lng (stored in request).
                  
                  final double? donorLat = donor.latitude;
                  final double? donorLng = donor.longitude;
                  final double? reqLat = request.latitude;
                  final double? reqLng = request.longitude;

                  if (donorLat == null || donorLng == null || reqLat == null || reqLng == null) {
                    return const SizedBox.shrink();
                  }

                  final dist = LocationService().distanceBetween(
                    donorLat,
                    donorLng,
                    reqLat,
                    reqLng,
                  );

                  return Column(
                    children: [
                      Text(
                        '${dist.toStringAsFixed(1)} km away from destination',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.blue),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _openMaps(donorLat, donorLng, reqLat, reqLng),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.blue.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_rounded, size: 16, color: AppTheme.blue),
                              SizedBox(width: 6),
                              Text('Get Directions in Maps',
                                  style: TextStyle(
                                      color: AppTheme.blue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // Detail tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _infoTile(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: donor.phone,
                    color: AppTheme.green,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: donor.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number copied'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }),
                const SizedBox(height: 10),
                _infoTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: donor.email,
                    color: AppTheme.blue),
                const SizedBox(height: 10),
                _infoTile(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: '${donor.city}, ${donor.state}',
                    color: AppTheme.orange),
                const SizedBox(height: 10),
                _infoTile(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Total Donations',
                    value: '${donor.totalDonations} donations',
                    color: AppTheme.primaryRed),
                if (donor.rating > 0) ...[
                  const SizedBox(height: 10),
                  _infoTile(
                      icon: Icons.star_rounded,
                      label: 'Rating',
                      value: donor.rating.toStringAsFixed(1),
                      color: const Color(0xFFF59E0B)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Call button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: donor.phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${donor.phone} copied to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text('Copy Number: ${donor.phone}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray900)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy_rounded, size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
