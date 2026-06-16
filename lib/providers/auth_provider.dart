import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notifService = NotificationService();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _user = await _authService.getUserById(firebaseUser.uid);
      _status = AuthStatus.authenticated;
      if (_user != null) {
        await _notifService.saveToken(firebaseUser.uid);
        await _notifService.subscribeToBloodGroup(_user!.bloodGroup);
        _updateLocation(firebaseUser.uid);
      }
    }
    notifyListeners();
  }


  Future<void> _updateLocation(String uid) async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      await _firestoreService.updateDonorLocation(uid, pos.latitude, pos.longitude);
    }
  }

  Future<bool> register({
    required String name, required String email, required String password,
    required String phone, required String bloodGroup,
    required String location, required String city, required String state, required String role,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.registerWithEmail(
        name: name, email: email, password: password,
        phone: phone, bloodGroup: bloodGroup,
        location: location, city: city, state: state, role: role);
      
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.loginWithEmail(email, password);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Update profile fields and refresh local user
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _firestoreService.updateUserProfile(_user!.id, data);
    // Refresh user from Firestore
    final updated = await _authService.getUserById(_user!.id);
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
  }

  Future<void> updateBloodStock(Map<String, int> stock) async {
    if (_user == null) return;
    await _firestoreService.updateBloodStock(_user!.id, stock);
    // Refresh user from Firestore
    final updated = await _authService.getUserById(_user!.id);
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability([bool? forcedValue]) async {
    if (_user == null) return;
    
    final oldUser = _user!;
    final newVal = forcedValue ?? !oldUser.isAvailable;
    
    // Skip if value is already what we want
    if (newVal == oldUser.isAvailable) return;

    // 🚀 OPTIMISTIC UPDATE: Update local state immediately
    _user = _user!.copyWith(isAvailable: newVal);
    notifyListeners();

    try {
      await _authService.updateAvailability(oldUser.id, newVal);
    } catch (e) {
      // ❌ REVERT if backend fails
      _user = oldUser;
      _error = "Failed to update availability: ${e.toString()}";
      notifyListeners();
    }
  }

  void _setLoading(bool val) { _loading = val; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
