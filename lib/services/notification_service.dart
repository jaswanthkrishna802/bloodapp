import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔥 Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // REQUIRED in background

  debugPrint('📩 Background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 Initialize notifications
  Future<void> initialize() async {
    try {
      // 🔔 Request permission (Android 13+ & iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔐 Permission status: ${settings.authorizationStatus}');

      // 🔥 Set background handler
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // 📩 Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📥 Foreground message: ${message.notification?.title}');
      });

      // 📲 When app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 App opened from notification');
      });

    } catch (e) {
      debugPrint('❌ Notification init error: $e');
    }
  }

  /// 💾 Save FCM token to Firestore
  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _db.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));

        debugPrint('✅ Token saved: $token');
      }

      // 🔄 Token refresh listener
      _messaging.onTokenRefresh.listen((newToken) async {
        await _db.collection('users').doc(userId).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));

        debugPrint('🔄 Token updated');
      });

    } catch (e) {
      debugPrint('❌ Token save error: $e');
    }
  }

  /// 🩸 Subscribe to blood group topic
  Future<void> subscribeToBloodGroup(String bloodGroup) async {
    try {
      final topic = 'blood_${bloodGroup.replaceAll('+', 'pos').replaceAll('-', 'neg')}';

      await _messaging.subscribeToTopic(topic);
      await _messaging.subscribeToTopic('emergency_all');

      debugPrint('✅ Subscribed to $topic');

    } catch (e) {
      debugPrint('❌ Subscription error: $e');
    }
  }

  /// ❌ Unsubscribe
  Future<void> unsubscribeFromBloodGroup(String bloodGroup) async {
    try {
      final topic = 'blood_${bloodGroup.replaceAll('+', 'pos').replaceAll('-', 'neg')}';

      await _messaging.unsubscribeFromTopic(topic);

      debugPrint('❌ Unsubscribed from $topic');

    } catch (e) {
      debugPrint('❌ Unsubscribe error: $e');
    }
  }
}
