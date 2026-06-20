import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aswenna/services/api_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase safely (wraps in try-catch in case google-services.json is missing)
      if (kIsWeb) {
        // Web initialization if required
      } else {
        await Firebase.initializeApp();
      }

      // Request permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Handle FCM Token registration
      await registerDeviceToken();

      // Listen for foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message received: ${message.notification?.title}');
        }
      });

      // Handle app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('App opened via notification: ${message.notification?.title}');
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Notification initialization skipped or failed: $e');
        print('To enable Firebase FCM notifications, please add the required google-services.json/GoogleService-Info.plist file.');
      }
    }
  }

  static Future<void> registerDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Registration Token: $token');
        }
        // Save FCM token to backend
        await ApiService.registerFcmToken(token);
      }

      // Any token refresh updates
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await ApiService.registerFcmToken(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register FCM token: $e');
      }
    }
  }
}
