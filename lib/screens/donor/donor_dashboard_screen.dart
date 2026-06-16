import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});
  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BloodRequestProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final requestProvider = context.watch<BloodRequestProvider>();
    final requests = requestProvider.nearbyRequests;

    return Scaffold(
      body: Column(
        children: [
          _header(context, user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _nextDonationCard(user),
                const SizedBox(height: 14),
                const SectionHeader(title: 'Nearby Requests'),
                const SizedBox(height: 10),
                if (requests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('No requests nearby', style: TextStyle(color: AppTheme.gray400))))
                else
                  ...requests.take(3).map((r) => _requestCard(context, r)),
                const SizedBox(height: 14),
                const SectionHeader(title: 'Donation History'),
                const SizedBox(height: 10),
                _historyCard(user),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, UserModel? user) {
    final name = user?.name ?? 'Donor';
    final blood = user?.bloodGroup ?? '--';
    final location = user?.location ?? '';
    final donations = user?.totalDonations ?? 0;
    final rating = user?.rating ?? 0.0;
    final available = user?.isAvailable ?? false;

    return Container(
      color: AppTheme.green,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🩸 Hi, $name',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('$blood · ${available ? "Active" : "Inactive"} · $location',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          Switch(
            value: available,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white38,
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
            onChanged: (val) => context.read<AuthProvider>().toggleAvailability(val),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _stat('$donations', 'Donations'),
          const SizedBox(width: 10),
          _stat('${donations * 3}', 'Units Given'),
          const SizedBox(width: 10),
          _stat(rating > 0 ? '⭐ $rating' : '⭐ -', 'Rating'),
        ]),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _nextDonationCard(UserModel? user) {
    final lastDonated = user?.lastDonation;
    String nextDate = 'Ready to donate!';
    if (lastDonated != null) {
      final next = lastDonated.add(const Duration(days: 90));
      nextDate = '${next.day} ${_month(next.month)} ${next.year}';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: AppTheme.blue, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Next eligible donation',
            style: TextStyle(fontSize: 11, color: AppTheme.blue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(nextDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.blue)),
        ]),
      ]),
    );
  }

  Widget _requestCard(BuildContext context, BloodRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200, width: 0.5)),
      child: Row(children: [
        Text(request.bloodGroup,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryRed)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.hospitalName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
          Text('📍 ${request.distanceKm != null ? request.distanceKm!.toStringAsFixed(1) : "?"} km · ${request.unitsRequired} units · ${request.urgencyLabel}',
            style: const TextStyle(fontSize: 10, color: AppTheme.gray400)),
        ])),
        if (request.requestedBy != context.read<AuthProvider>().user?.id)
        Row(children: [
          _btn('✓', AppTheme.green, Colors.white,
            () => context.read<BloodRequestProvider>().updateStatus(request.id, RequestStatus.accepted)),
          const SizedBox(width: 6),
          _btn('✕', AppTheme.gray100, AppTheme.gray600,
            () => context.read<BloodRequestProvider>().updateStatus(request.id, RequestStatus.cancelled)),
        ]),
      ]),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg))),
    );
  }

  Widget _historyCard(UserModel? user) {
    final donations = user?.totalDonations ?? 0;
    if (donations == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gray200, width: 0.5)),
        child: const Center(child: Text('No donations yet', style: TextStyle(color: AppTheme.gray400))));
    }
    final last = user?.lastDonation;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200, width: 0.5)),
      child: Column(children: [
        _historyRow(
          last != null ? '${last.day} ${_month(last.month)} ${last.year}' : '-',
          'Last donation · ${user?.bloodGroup ?? ''} blood'),
        const Divider(height: 1, color: AppTheme.gray100),
        _historyRow('Total', '$donations donations · ${donations * 3} units given'),
      ]),
    );
  }

  Widget _historyRow(String date, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
        Text(detail, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.green)),
      ]),
    );
  }

  String _month(int m) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m];
  }
}
