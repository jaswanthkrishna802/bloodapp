import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    
    final auth = context.read<AuthProvider>();
    
    // If the auth status is still unknown (Firebase is initializing), 
    // we should wait or listen for the first non-unknown status.
    if (auth.status == AuthStatus.unknown) {
      // Create a one-time listener to wait for the status to change
      void listener() {
        if (auth.status != AuthStatus.unknown) {
          auth.removeListener(listener);
          _navigate(); // Call navigate again now that we have a status
        }
      }
      auth.addListener(listener);
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
          auth.isLoggedIn ? const MainNavigation() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Smart Blood Connect',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('Save Lives with Smart Blood Donation',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 48),
              SizedBox(
                width: 48,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white30, color: Colors.white,
                  minHeight: 3, borderRadius: BorderRadius.circular(4)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
