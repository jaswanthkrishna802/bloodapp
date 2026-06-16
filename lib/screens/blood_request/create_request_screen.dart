import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/blood_request_model.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _patientCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  String _bloodGroup = 'AB-';
  int _units = 3;
  UrgencyLevel _urgency = UrgencyLevel.critical;

  @override
  void dispose() { _patientCtrl.dispose(); _hospitalCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Blood Request'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _patientCtrl, decoration: const InputDecoration(labelText: 'Patient Name')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group Required'),
              items: AppConstants.bloodGroups.map((g) =>
                DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryRed)))).toList(),
              onChanged: (v) => setState(() => _bloodGroup = v!),
            ),
            const SizedBox(height: 14),
            TextField(controller: _hospitalCtrl, decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_rounded))),
            const SizedBox(height: 20),
            const Text('UNITS REQUIRED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final unit = i + 1;
                final sel = _units == unit;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _units = unit),
                    child: Container(
                      height: 44,
                      margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.lightRed : Colors.white,
                        border: Border.all(color: sel ? AppTheme.primaryRed : AppTheme.gray200, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(unit < 5 ? '$unit' : '5+',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: sel ? AppTheme.primaryRed : AppTheme.gray400)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text('URGENCY LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _urgencyBtn(UrgencyLevel.critical, '🚨 Critical', AppTheme.primaryRed, AppTheme.lightRed),
                const SizedBox(width: 8),
                _urgencyBtn(UrgencyLevel.urgent, '⚡ Urgent', AppTheme.orange, AppTheme.lightOrange),
                const SizedBox(width: 8),
                _urgencyBtn(UrgencyLevel.normal, '✅ Normal', AppTheme.green, AppTheme.lightGreen),
              ],
            ),
            const SizedBox(height: 28),
            
            context.watch<BloodRequestProvider>().loading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submit,
                  child: const Text('🚨  Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final patient = _patientCtrl.text.trim();
    final hospital = _hospitalCtrl.text.trim();

    if (patient.isEmpty || hospital.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppTheme.primaryRed));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood request submitted successfully!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to submit request'), backgroundColor: AppTheme.primaryRed));
    }
  }

  Widget _urgencyBtn(UrgencyLevel level, String label, Color color, Color bg) {
    final sel = _urgency == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = level),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: sel ? color : bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : color)),
          ),
        ),
      ),
    );
  }
}
