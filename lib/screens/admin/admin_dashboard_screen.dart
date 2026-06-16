import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _donutChart(),
                const SizedBox(height: 14),
                _hospitalStockCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: const Color(0xFF1A237E),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Smart Blood Connect · Tamil Nadu', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text('⚙️  Admin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('2,847', 'Total Donors'),
              const SizedBox(width: 10),
              _stat('143', 'Active Requests'),
              const SizedBox(width: 10),
              _stat('28', 'Hospitals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _donutChart() {
    final sections = [
      PieChartSectionData(value: 24, color: AppTheme.blue, title: 'A+', radius: 52, titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 20, color: AppTheme.green, title: 'B+', radius: 52, titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 38, color: AppTheme.primaryRed, title: 'O+', radius: 52, titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 10, color: const Color(0xFF6A1B9A), title: 'AB+', radius: 52, titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 5, color: AppTheme.orange, title: 'O-', radius: 52, titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 3, color: const Color(0xFF00838F), title: 'Other', radius: 52, titleStyle: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.gray200, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('District Blood Stock Overview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2))),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        Text('${s.title} ${s.value.toInt()}%', style: const TextStyle(fontSize: 10, color: AppTheme.gray600)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalStockCard() {
    final hospitals = MockData.hospitalStocks;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.gray200, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hospital Stock Levels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
          const SizedBox(height: 12),
          ...hospitals.map((h) => _hospitalRow(h)),
        ],
      ),
    );
  }

  Widget _hospitalRow(Map<String, Object> h) {
    final level = (h['level'] as num).toDouble();
    final color = level > 0.6 ? AppTheme.green : level > 0.35 ? AppTheme.orange : AppTheme.primaryRed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(h['name'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray800))),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level,
                backgroundColor: AppTheme.gray100,
                color: color,
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${h['units']}u', style: const TextStyle(fontSize: 10, color: AppTheme.gray400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
