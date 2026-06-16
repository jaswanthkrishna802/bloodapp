import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class BloodStatisticsScreen extends StatefulWidget {
  const BloodStatisticsScreen({super.key});

  @override
  State<BloodStatisticsScreen> createState() => _BloodStatisticsScreenState();
}

class _BloodStatisticsScreenState extends State<BloodStatisticsScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final provider = context.read<BloodRequestProvider>();

    // Extract pincode from location or city (6-digit number)
    final pincodeRegex = RegExp(r'\b\d{6}\b');
    final locMatch = pincodeRegex.firstMatch(user.location);
    final cityMatch = pincodeRegex.firstMatch(user.city);

    final searchQuery = cityMatch?.group(0) ??
        locMatch?.group(0) ??
        (user.city.isEmpty ? user.location : user.city);

    await provider.fetchCityUsers(searchQuery);

    final users = provider.cityUsers;
    final Map<String, int> counts = {};

    for (var u in users) {
      String category;
      if (u.role == 'hospital') {
        category = 'Hospitals';
      } else if (u.role == 'blood_bank') {
        category = 'Blood Banks';
      } else {
        // For individual users (donors/patients), group by blood group
        category = u.bloodGroup.isNotEmpty ? u.bloodGroup : 'Unknown';
      }
      counts[category] = (counts[category] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _stats = counts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('City Blood Statistics',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _stats.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoCard(user?.city.isNotEmpty == true
                          ? user!.city
                          : (user?.location ?? 'Your City')),
                      const SizedBox(height: 32),
                      const Text(
                        'City Distribution',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.gray900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Real-time data for donors and medical facilities in your area.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.gray600,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),
                      _buildPieChart(),
                      const SizedBox(height: 40),
                      _buildLegend(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(String city) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statistics for',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text(city,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${_stats.values.fold(0, (a, b) => a + b)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              Text('Total Records',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final List<PieChartSectionData> sections = [];
    final List<String> groups = _stats.keys.toList()..sort();

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final count = _stats[group]!;

      sections.add(
        PieChartSectionData(
          color: _getColor(i),
          value: count.toDouble(),
          title: group,
          radius: 100,
          titleStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (event is FlTapUpEvent &&
                  response != null &&
                  response.touchedSection != null) {
                final index = response.touchedSection!.touchedSectionIndex;
                if (index >= 0 && index < groups.length) {
                  _showDonorList(groups[index]);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _showDonorList(String category) {
    final provider = context.read<BloodRequestProvider>();
    final users = provider.cityUsers.where((u) {
      if (category == 'Hospitals') return u.role == 'hospital';
      if (category == 'Blood Banks') return u.role == 'blood_bank';
      // For blood groups, match individual users (donors/patients)
      return u.bloodGroup == category &&
          u.role != 'hospital' &&
          u.role != 'blood_bank';
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (category == 'Hospitals' || category == 'Blood Banks'
                                  ? AppTheme.blue
                                  : AppTheme.primaryRed)
                              .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category == 'Hospitals'
                          ? Icons.local_hospital_rounded
                          : category == 'Blood Banks'
                              ? Icons.water_drop_rounded
                              : Icons.person_rounded,
                      color:
                          category == 'Hospitals' || category == 'Blood Banks'
                              ? AppTheme.blue
                              : AppTheme.primaryRed,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(category,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('No records found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _userListItem(user);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userListItem(UserModel user) {
    final isMedical = user.role == 'hospital' || user.role == 'blood_bank';
    final color = isMedical ? AppTheme.blue : AppTheme.primaryRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              isMedical
                  ? Icons.local_hospital_rounded
                  : user.role == 'donor'
                      ? Icons.person
                      : Icons.person_outline,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color)),
                Text(user.location,
                    style:
                        const TextStyle(color: AppTheme.gray400, fontSize: 12)),
              ],
            ),
          ),
          if (user.role == 'donor')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isAvailable
                    ? AppTheme.green.withValues(alpha: 0.1)
                    : AppTheme.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isAvailable ? 'Available' : 'Busy',
                style: TextStyle(
                  color: user.isAvailable ? AppTheme.green : AppTheme.gray600,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (isMedical || user.role == 'donor' || user.role == 'patient')
            Text(user.bloodGroup,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final List<String> groups = _stats.keys.toList()..sort();
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: groups.asMap().entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: _getColor(e.key), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '${e.value}: ${_stats[e.value]}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray800),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getColor(int index) {
    const colors = [
      AppTheme.primaryRed,
      AppTheme.blue,
      AppTheme.orange,
      AppTheme.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: AppTheme.gray200),
          const SizedBox(height: 24),
          const Text('No Data Available',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gray800)),
          const SizedBox(height: 8),
          const Text('Try searching for a different city.',
              style: TextStyle(color: AppTheme.gray400)),
        ],
      ),
    );
  }
}
