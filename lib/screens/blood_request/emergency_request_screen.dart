import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/blood_request_model.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _patientCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _bloodGroup = 'A+';
  int _units = 1;
  UrgencyLevel _urgency = UrgencyLevel.critical;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _contactCtrl.text = user.phone;
      _bloodGroup = user.bloodGroup;
    }
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _hospitalCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<BloodRequestProvider>().loading;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _alertBanner(),
                  const SizedBox(height: 24),
                  _sectionTitle('PATIENT INFORMATION'),
                  _formCard([
                    _textField(_patientCtrl, 'Patient Full Name', Icons.person_outline_rounded),
                    _bloodGroupSelector(),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('LOCATION & CONTACT'),
                  _formCard([
                    _textField(_hospitalCtrl, 'Hospital Name', Icons.local_hospital_outlined),
                    _textField(_contactCtrl, 'Emergency Contact', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('REQUEST DETAILS'),
                  _formCard([
                    _unitSelector(),
                    _urgencySelector(),
                  ]),
                  const SizedBox(height: 40),
                  _submitButton(loading),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.primaryRed,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.emergency_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.accentRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Broadcasting this request will alert all eligible donors within 50km immediately.',
              style: TextStyle(
                color: AppTheme.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.gray600,
        ),
      ),
    );
  }

  Widget _formCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) Divider(height: 1, color: AppTheme.gray100, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.gray400, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
        ),
      ),
    );
  }

  Widget _bloodGroupSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blood Group', style: TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.bloodGroups.map((g) {
              final sel = _bloodGroup == g;
              return GestureDetector(
                onTap: () => setState(() => _bloodGroup = g),
                child: Container(
                  width: 65,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primaryRed : AppTheme.gray50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppTheme.primaryRed : AppTheme.gray100),
                  ),
                  child: Center(
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : AppTheme.gray800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _unitSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Units Required', style: TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w600)),
              Text('$_units Units', style: const TextStyle(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final unit = i + 1;
              final sel = _units == unit;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _units = unit),
                  child: Container(
                    height: 40,
                    margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryRed : AppTheme.gray50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        unit < 5 ? '$unit' : '5+',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : AppTheme.gray800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _urgencySelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Urgency Level', style: TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _urgencyBtn(UrgencyLevel.critical, '🚨 Critical'),
              const SizedBox(width: 8),
              _urgencyBtn(UrgencyLevel.urgent, '⚡ Urgent'),
              const SizedBox(width: 8),
              _urgencyBtn(UrgencyLevel.normal, '✅ Normal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _urgencyBtn(UrgencyLevel level, String label) {
    final sel = _urgency == level;
    Color color;
    switch (level) {
      case UrgencyLevel.critical: color = AppTheme.primaryRed; break;
      case UrgencyLevel.urgent: color = AppTheme.orange; break;
      case UrgencyLevel.normal: color = AppTheme.green; break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = level),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: sel ? color : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? color : color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(bool loading) {

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded),
                  SizedBox(width: 8),
                  Text(
                    'BROADCAST EMERGENCY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submit() async {
    final patient = _patientCtrl.text.trim();
    final hospital = _hospitalCtrl.text.trim();
    final contact = _contactCtrl.text.trim();

    if (patient.isEmpty || hospital.isEmpty || contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all details'),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<BloodRequestProvider>();
    
    if (auth.user == null) return;

    final request = BloodRequestModel(
      id: '',
      patientName: patient,
      bloodGroup: _bloodGroup,
      hospitalName: hospital,
      hospitalLocation: auth.user!.location,
      unitsRequired: _units,
      urgency: _urgency,
      requestedBy: auth.user!.id,
      createdAt: DateTime.now(),
      latitude: auth.user!.latitude,
      longitude: auth.user!.longitude,
    );

    final ok = await provider.createRequest(request);

    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppTheme.green, size: 64),
              SizedBox(height: 16),
              Text('Alert Broadcasted', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text(
            'Your emergency request has been sent to all donors in your area. Please stay by your phone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gray600, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Maybe navigate to home?
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryRed)),
            ),
          ],
        ),
      );
      
      _patientCtrl.clear();
      _hospitalCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Broadcast failed'),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
