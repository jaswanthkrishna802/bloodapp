import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  StreamSubscription? _sub;
  String? _lastUserId;
  
  void listenToNotifications(String userId) {
    if (_lastUserId == userId && _sub != null) return;
    
    _sub?.cancel();
    _lastUserId = userId;
    _sub = _db.getNotifications(userId).listen((notifs) {
      _notifications = notifs;
      _unreadCount = notifs.where((n) => !n.isRead).length;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> markRead(String notifId) async {
    await _db.markNotificationRead(notifId);
  }

  Future<void> markAllRead(String userId) async {
    for (final n in _notifications.where((n) => !n.isRead)) {
      await _db.markNotificationRead(n.id);
    }
  }
}
