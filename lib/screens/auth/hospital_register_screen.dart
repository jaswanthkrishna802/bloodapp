import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_utils.dart';
import '../main_navigation.dart';

class HospitalRegisterScreen extends StatefulWidget {
  const HospitalRegisterScreen({super.key});
  @override
  State<HospitalRegisterScreen> createState() =>
      _HospitalRegisterScreenState();
}

class _HospitalRegisterScreenState extends State<HospitalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  String? _selectedState;
  List<String> _states = [];
  String _type = 'hospital'; // hospital | blood_bank
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _states = LocationUtils.allStates;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    _addressCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose(); _pincodeCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: AppTheme.primaryRed,
      ));
      return;
    }
    final location =
        '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} - ${_pincodeCtrl.text.trim()}';
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      bloodGroup: 'N/A',
      location: location,
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      role: _type,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: AppTheme.primaryRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        title: const Text('Hospital Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── TYPE SELECTOR ─────────────────────────────
            _sectionLabel('Type of Facility',
                Icons.local_hospital_rounded, AppTheme.blue),
            const SizedBox(height: 12),
            Row(children: [
              _typeBtn('hospital', Icons.local_hospital_rounded, 'Hospital'),
              const SizedBox(width: 10),
              _typeBtn('blood_bank', Icons.water_drop_rounded, 'Blood Bank'),
            ]),
            const SizedBox(height: 20),

            // ── FACILITY INFO ─────────────────────────────
            _sectionLabel('Facility Information',
                Icons.business_rounded, AppTheme.blue),
            const SizedBox(height: 12),
            _field(
              controller: _nameCtrl,
              label: 'Hospital / Blood Bank Name',
              icon: Icons.business_rounded,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Enter facility name' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _regNoCtrl,
              label: 'Registration Number',
              icon: Icons.numbers_rounded,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Enter registration number' : null,
            ),
            const SizedBox(height: 20),

            // ── CONTACT INFO ──────────────────────────────
            _sectionLabel('Contact Information',
                Icons.contact_phone_rounded, AppTheme.blue),
            const SizedBox(height: 12),
            _field(
              controller: _emailCtrl,
              label: 'Official Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v!.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v!.length >= 10 ? null : 'Enter a valid phone number',
            ),
            const SizedBox(height: 20),

            // ── ADDRESS ───────────────────────────────────
            _sectionLabel('Address Details',
                Icons.location_on_rounded, AppTheme.green),
            const SizedBox(height: 12),
            _field(
              controller: _addressCtrl,
              label: 'Address Line',
              icon: Icons.home_rounded,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  decoration: _dropdownDecoration('State', Icons.map_rounded),
                  items: _states.map((s) => DropdownMenuItem<String>(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedState = v;
                      _cityCtrl.text = '';
                      _stateCtrl.text = v ?? '';
                    });
                  },
                  validator: (v) => v == null ? 'Select state' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _field(
                  controller: _cityCtrl,
                  label: 'City',
                  icon: Icons.location_city_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Enter city' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _field(
              controller: _pincodeCtrl,
              label: 'Pincode',
              icon: Icons.pin_drop_rounded,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v!.length == 6 ? null : 'Enter 6 digit pincode',
            ),
            const SizedBox(height: 20),

            // ── PASSWORD ──────────────────────────────────
            _sectionLabel('Set Password', Icons.lock_rounded, AppTheme.orange),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              validator: (v) =>
                  v!.length >= 6 ? null : 'Minimum 6 characters',
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon:
                    const Icon(Icons.lock_rounded, color: AppTheme.gray400),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.gray400),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                filled: true,
                fillColor: AppTheme.gray50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.blue, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              validator: (v) =>
                  v!.isEmpty ? 'Confirm your password' : null,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.gray400),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.gray400),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: AppTheme.gray50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.blue, width: 1.5)),
              ),
            ),
            const SizedBox(height: 28),
            auth.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.blue))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    onPressed: _register,
                    child: const Text('Register Facility →'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color)),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.gray400, size: 20),
        filled: true,
        fillColor: AppTheme.gray50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.gray200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.gray200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.blue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryRed)),
      ),
    );
  }

  Widget _typeBtn(String type, IconData icon, String label) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppTheme.lightBlue : Colors.white,
            border: Border.all(
                color: active ? AppTheme.blue : AppTheme.gray200,
                width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: active ? AppTheme.blue : AppTheme.gray400, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppTheme.blue : AppTheme.gray600)),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.gray400, size: 20),
      filled: true,
      fillColor: AppTheme.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.gray200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.gray200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.blue, width: 1.5)),
    );
  }
}
