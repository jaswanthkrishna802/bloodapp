import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/blood_request_provider.dart';
import '../../models/blood_request_model.dart';
import '../../theme/app_theme.dart';

class MyDonationsScreen extends StatelessWidget {
  const MyDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<BloodRequestProvider>();
    final myDonations = requestProvider.myDonations;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('My Donations', 
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.gray900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.gray900,
      ),
      body: myDonations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myDonations.length,
              itemBuilder: (context, index) {
                final request = myDonations[index];
                return _donationHistoryCard(context, request);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_rounded, size: 80, color: AppTheme.gray200),
          const SizedBox(height: 24),
          const Text('No Donations Yet', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray800)),
          const SizedBox(height: 8),
          const Text('Your successful blood donations will appear here.', 
            style: TextStyle(color: AppTheme.gray400)),
        ],
      ),
    );
  }

  Widget _donationHistoryCard(BuildContext context, BloodRequestModel request) {
    final dateStr = DateFormat('MMM dd, yyyy').format(request.createdAt);
    final timeStr = DateFormat('hh:mm a').format(request.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(request.bloodGroup, 
                      style: const TextStyle(color: AppTheme.green, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.patientName, 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
                      Text(request.hospitalName, 
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray400, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('ACCEPTED', 
                    style: TextStyle(color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.gray50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.gray400),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.gray400),
                    const SizedBox(width: 6),
                    Text(timeStr, style: const TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
