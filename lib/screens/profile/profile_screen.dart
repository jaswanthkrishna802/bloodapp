import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    final isHospital = user.role == 'hospital' || user.role == 'blood_bank';

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: CustomScrollView(
        slivers: [
          _sliverHeader(context, user, isHospital),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isHospital) _statsRow(user),
                  const SizedBox(height: 24),
                  
                  _availabilityCard(context, user),
                  const SizedBox(height: 20),

                  if (!isHospital) ...[
                    _sectionHeader('Personal Information', Icons.person_outlined),
                    _infoCard([
                      _infoRow(Icons.email_outlined, 'Email', user.email),
                      _infoRow(Icons.phone_outlined, 'Phone', user.phone),
                      _infoRow(Icons.badge_outlined, 'Role', _formatRole(user.role)),
                    ]),
                    const SizedBox(height: 24),
                    
                    _sectionHeader('Blood Details', Icons.water_drop_outlined),
                    _infoCard([
                      _infoRow(Icons.bloodtype_outlined, 'Blood Group', user.bloodGroup, isPrimary: true),
                      _infoRow(Icons.volunteer_activism_outlined, 'Total Donations', '${user.totalDonations} times'),
                      _infoRow(Icons.star_outlined, 'Rating', user.rating > 0 ? '${user.rating} / 5.0' : 'New Member'),
                    ]),
                  ] else ...[
                    _sectionHeader('Hospital Information', Icons.local_hospital_outlined),
                    _infoCard([
                      _infoRow(Icons.business_outlined, 'Hospital Name', user.name),
                      _infoRow(Icons.email_outlined, 'Email', user.email),
                      _infoRow(Icons.phone_outlined, 'Phone', user.phone),
                    ]),
                  ],

                  const SizedBox(height: 24),
                  _sectionHeader('Location', Icons.location_on_outlined),
                  _infoCard([
                    _infoRow(Icons.map_outlined, 'Address', user.location),
                    _infoRow(Icons.location_city_outlined, 'State', user.state),
                  ]),

                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _editProfile(context, user),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.gray200),
                            foregroundColor: AppTheme.gray800,
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleLogout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.primaryRed,
                            elevation: 0,
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliverHeader(BuildContext context, UserModel user, bool isHospital) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isHospital ? AppTheme.blue : AppTheme.primaryRed,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getInitials(user.name),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isHospital ? AppTheme.blue : AppTheme.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isHospital ? 'Healthcare Partner' : 'Blood Donor',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(UserModel user) {
    return Row(
      children: [
        _statItem('Donations', '${user.totalDonations}', Icons.favorite),
        _statItem('Rating', '${user.rating}', Icons.star),
        _statItem('Type', user.bloodGroup, Icons.water_drop),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
          ],
        ),
      ),
    );
  }

  Widget _availabilityCard(BuildContext context, UserModel user) {
    final auth = context.watch<AuthProvider>();
    final available = user.isAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: available 
            ? [AppTheme.green.withValues(alpha: 0.1), AppTheme.green.withValues(alpha: 0.05)]
            : [AppTheme.gray400.withValues(alpha: 0.1), AppTheme.gray400.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: available ? AppTheme.green.withValues(alpha: 0.2) : AppTheme.gray400.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: available ? AppTheme.green : AppTheme.gray400,
              shape: BoxShape.circle,
            ),
            child: Icon(
              available ? Icons.check_circle : Icons.do_not_disturb_on,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available ? 'Available for Donation' : 'Currently Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available ? AppTheme.green : AppTheme.gray800,
                  ),
                ),
                Text(
                  available ? 'Visible to those in need' : 'Hidden from search results',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            activeThumbColor: AppTheme.green,
            onChanged: (val) => auth.toggleAvailability(val),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gray600),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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

  Widget _infoRow(IconData icon, String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isPrimary ? AppTheme.primaryRed : AppTheme.gray400),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: AppTheme.gray600)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppTheme.primaryRed : AppTheme.gray900,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return parts[0][0] + parts[1][0];
    return parts[0].substring(0, 2).toUpperCase();
  }

  String _formatRole(String role) {
    if (role == 'donor') return 'Donor';
    if (role == 'hospital') return 'Hospital';
    return role.substring(0, 1).toUpperCase() + role.substring(1);
  }

  void _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _editProfile(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final locationCtrl = TextEditingController(text: user.location);
    final stateCtrl = TextEditingController(text: user.state);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stateCtrl,
              decoration: const InputDecoration(labelText: "State", prefixIcon: Icon(Icons.map_outlined)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await context.read<AuthProvider>().updateProfile({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'location': locationCtrl.text,
                  'state': stateCtrl.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
