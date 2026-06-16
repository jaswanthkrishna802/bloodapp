import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'user_register_screen.dart';
import 'hospital_register_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.gray900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.gray900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join our community to start saving lives today. Choose your account type to proceed.',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600, height: 1.5),
                ),
                const SizedBox(height: 40),

                _TypeCard(
                  icon: Icons.person_add_outlined,
                  iconColor: AppTheme.primaryRed,
                  iconBg: AppTheme.lightRed,
                  title: 'Donor / Patient',
                  subtitle: 'Become a part of the life-saving network.',
                  description: 'Ideal for individuals who want to donate blood or request help during emergencies.',
                  points: const [
                    'Find donors within 50km radius',
                    'Request blood in one tap',
                    'Digital donation tracking',
                  ],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserRegisterScreen()),
                  ),
                ),

                const SizedBox(height: 20),

                _TypeCard(
                  icon: Icons.local_hospital_outlined,
                  iconColor: AppTheme.blue,
                  iconBg: AppTheme.lightBlue,
                  title: 'Hospital / Blood Bank',
                  subtitle: 'Manage stock and emergency requests.',
                  description: 'Designed for medical facilities to manage blood inventories and donor connections.',
                  points: const [
                    'Manage real-time blood stock',
                    'Post facility-wide requests',
                    'Direct donor communication',
                  ],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HospitalRegisterScreen()),
                  ),
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Secure & Encrypted Registration',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gray400),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String description;
  final List<String> points;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.points,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.gray100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.gray900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.gray400, size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: AppTheme.gray600, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.gray100),
            const SizedBox(height: 16),
            ...points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppTheme.green, size: 16),
                      const SizedBox(width: 8),
                      Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
