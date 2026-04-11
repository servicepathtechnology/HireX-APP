import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../network/dio_client.dart';

/// Background message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'hirex_high_importance',
    'HireX Notifications',
    description: 'HireX important notifications',
    importance: Importance.high,
  );

  Future<void> initialize(DioClient dioClient) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Setup local notifications for foreground
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Register token
    await _registerToken(dioClient);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) async {
      await _sendTokenToBackend(dioClient, token);
    });
  }

  Future<void> _registerToken(DioClient dioClient) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(dioClient, token);
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(DioClient dioClient, String token) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await dioClient.instance.post(
        '/api/v1/notifications/fcm-token',
        data: {'token': token, 'platform': platform},
      );
      debugPrint('[FCM] Token registered');
    } catch (e) {
      debugPrint('[FCM] Token send failed: $e');
    }
  }

  Future<void> deregisterToken(DioClient dioClient) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await dioClient.instance.delete(
          '/api/v1/notifications/fcm-token',
          data: {'token': token, 'platform': platform},
        );
      }
    } catch (e) {
      debugPrint('[FCM] Token deregister failed: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Handle notification tap navigation — call on app start and onMessageOpenedApp.
  static void handleMessageNavigation(RemoteMessage message, GoRouter router) {
    final data = message.data;
    final type = data['type'] as String?;
    final submissionId = data['submission_id'] as String?;
    final threadId = data['thread_id'] as String?;
    final taskId = data['task_id'] as String?;

    switch (type) {
      case 'submission_scored':
        if (submissionId != null) {
          router.push('/candidate/submissions/$submissionId/score-explanation');
        }
        break;
      case 'shortlisted':
        router.push('/candidate/pipeline');
        break;
      case 'stage_changed':
      case 'task_closed':
        router.push('/candidate/pipeline');
        break;
      case 'new_message':
        if (threadId != null) {
          router.push('/messages/$threadId');
        }
        break;
      case 'ai_scoring_complete':
        if (taskId != null) {
          router.push('/recruiter/tasks/$taskId/submissions');
        }
        break;
      case 'hired':
        router.push('/candidate/profile');
        break;
      // ── Part 1 — 1v1 Live Challenges ──────────────────────────────────────
      case 'challenge_invite':
        router.push('/challenges/1v1');
        break;
      case 'challenge_accepted':
        final matchId = data['match_id'] as String?;
        if (matchId != null) router.push('/challenges/1v1/$matchId');
        break;
      case 'challenge_declined':
        router.push('/challenges/1v1');
        break;
      case 'invite_expired':
        router.push('/challenges/1v1');
        break;
      case 'match_starting':
        final startingMatchId = data['match_id'] as String?;
        if (startingMatchId != null) router.push('/challenges/1v1/$startingMatchId');
        break;
      case 'match_result_ready':
        final resultMatchId = data['match_id'] as String?;
        if (resultMatchId != null) router.push('/challenges/1v1/$resultMatchId/result');
        break;
      case 'elo_tier_changed':
        router.push('/challenges/1v1');
        break;
      default:
        router.push('/notifications');
    }
  }

  /// Check for initial message (app killed, notification tapped).
  Future<void> checkInitialMessage(GoRouter router) async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      handleMessageNavigation(message, router);
    }

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessageNavigation(message, router);
    });
  }
}
