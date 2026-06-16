import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';


class StateDirectoryScreen extends StatefulWidget {
  const StateDirectoryScreen({super.key});

  @override
  State<StateDirectoryScreen> createState() => _StateDirectoryScreenState();
}

class _StateDirectoryScreenState extends State<StateDirectoryScreen> {
  String? _selectedState;
  final List<String> _indianStates = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", 
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", 
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", 
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", 
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Puducherry"
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BloodRequestProvider>();
    final users = provider.stateUsers;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('State Directory', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: provider.loading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
              : _selectedState == null
                ? _buildEmptyState('Select a state to view local donors and hospitals.')
                : users.isEmpty
                  ? _buildEmptyState('No records found for $_selectedState.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isHospital = user.role == 'hospital' || user.role == 'blood_bank';
                        return isHospital ? _hospitalCard(user) : _userCard(user);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search by State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.gray600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: InputDecoration(
              hintText: 'Choose a State',
              prefixIcon: const Icon(Icons.map_rounded, color: AppTheme.primaryRed),
              filled: true,
              fillColor: AppTheme.gray50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedState = val);
                context.read<BloodRequestProvider>().searchByState(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _userCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Center(
            child: Text(user.bloodGroup, style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_city_rounded, size: 14, color: AppTheme.gray400),
              const SizedBox(width: 4),
              Text(user.city, style: const TextStyle(color: AppTheme.gray600, fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: user.isAvailable ? AppTheme.green.withValues(alpha: 0.1) : AppTheme.gray200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.isAvailable ? 'Available' : 'Busy',
            style: TextStyle(color: user.isAvailable ? AppTheme.green : AppTheme.gray600, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _hospitalCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.blue.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.local_hospital_rounded, color: AppTheme.blue),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.blue)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_city_rounded, size: 14, color: AppTheme.blue),
              const SizedBox(width: 4),
              Text(user.city, style: const TextStyle(color: AppTheme.blue, fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('HOSPITAL', style: TextStyle(color: AppTheme.blue, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Icon(Icons.verified_user_rounded, color: AppTheme.blue.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: AppTheme.gray200),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.gray400, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
