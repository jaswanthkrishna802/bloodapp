import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  final Map<String, int> _stock = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        setState(() {
          for (var group in AppConstants.bloodGroups) {
            _stock[group] = user.bloodStock?[group] ?? 0;
          }
        });
      }
    });
  }

  void _increment(String group) {
    setState(() {
      _stock[group] = (_stock[group] ?? 0) + 1;
    });
  }

  void _decrement(String group) {
    setState(() {
      final current = _stock[group] ?? 0;
      if (current > 0) {
        _stock[group] = current - 1;
      }
    });
  }

  Future<void> _saveInventory() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await auth.updateBloodStock(_stock);
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blood inventory updated successfully!'),
          backgroundColor: AppTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          _header(context, user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Manage Blood Inventory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Update the available units for each blood group so donors and patients can see your real-time stock.',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                ),
                const SizedBox(height: 20),
                
                ...AppConstants.bloodGroups.map((group) => _stockRow(group)),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Inventory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, user) {
    final name = user?.name ?? 'Hospital';
    final location = user?.location ?? '';

    return Container(
      color: AppTheme.primaryRed,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16, right: 16, bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🏥 $name',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('📍 $location',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
      ]),
    );
  }

  Widget _stockRow(String group) {
    final units = _stock[group] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lightRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              group,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _stepperBtn(Icons.remove, () => _decrement(group)),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$units',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              _stepperBtn(Icons.add, () => _increment(group)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Icon(icon, size: 18, color: AppTheme.gray800),
      ),
    );
  }
}
