import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'search/blood_search_screen.dart';

import 'hospital/hospital_dashboard_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import 'blood_request/emergency_request_screen.dart';
import 'stats/blood_statistics_screen.dart';
import 'stats/state_directory_screen.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../utils/interaction_popup_helper.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().addListener(_onNotificationStateChanged);
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<NotificationProvider>().removeListener(_onNotificationStateChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onNotificationStateChanged() {
    if (!mounted) return;
    final notifProvider = context.read<NotificationProvider>();
    final interactionNotifs = notifProvider.notifications.where((n) => 
      (n.title == 'Donor Interaction' || n.title == 'Response Update') && !n.isRead).toList();

    for (final n in interactionNotifs) {
      InteractionPopupHelper.show(context, n);
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isHospital = user?.role == 'hospital' || user?.role == 'blood_bank';

    final screens = [
      HomeScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      const BloodSearchScreen(),
      isHospital ? const HospitalDashboardScreen() : const EmergencyRequestScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
      const BloodStatisticsScreen(),
      const StateDirectoryScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(isHospital),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        isHospital: isHospital,
        onTap: _onNavigate,
      ),
    );
  }

  Widget _buildDrawer(bool isHospital) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(32))),
      child: Column(
        children: [
          _drawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                _drawerItem(0, Icons.home_rounded, 'Home Dashboard'),
                _drawerItem(1, Icons.search_rounded, 'Search Donors'),
                _drawerItem(2, isHospital ? Icons.inventory_2_rounded : Icons.emergency_rounded, isHospital ? 'Inventory' : 'Emergency SOS'),
                _drawerItem(3, Icons.notifications_rounded, 'Alerts & History'),
                _drawerItem(4, Icons.person_rounded, 'My Profile'),
                _drawerItem(5, Icons.pie_chart_rounded, 'City Statistics'),
                _drawerItem(6, Icons.map_rounded, 'State Directory'),
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 1, color: AppTheme.gray100),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.primaryRed),
                  title: const Text('Logout', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader() {
    final user = context.watch<AuthProvider>().user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: const Icon(Icons.person, size: 36, color: AppTheme.primaryRed),
            ),
          ),
          const SizedBox(height: 20),
          Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppTheme.primaryRed : AppTheme.gray400),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryRed : AppTheme.gray800,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        onTap: () => _onNavigate(index),
      ),
    );
  }
}
