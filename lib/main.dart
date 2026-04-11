import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/analytics/analytics_service.dart';
import 'core/deep_link/deep_link_handler.dart';
import 'core/error/sentry_service.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env vars
  await dotenv.load(fileName: '.env');

  // Hive — must be initialized before any provider reads it
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('settings');
  await Hive.openBox<dynamic>('cache');

  // Firebase
  await Firebase.initializeApp();

  // Forward all Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Sentry wraps runApp — catches unhandled exceptions in production
  await SentryService.initialize(() async {
    await AnalyticsService.instance.initialize();
    runApp(const ProviderScope(child: HireXApp()));
  });
}

class HireXApp extends ConsumerStatefulWidget {
  const HireXApp({super.key});

  @override
  ConsumerState<HireXApp> createState() => _HireXAppState();
}

class _HireXAppState extends ConsumerState<HireXApp> {
  bool _servicesInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (!_servicesInitialized) {
      _servicesInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // FCM push notifications
        final dioClient = DioClient();
        await FCMService.instance.initialize(dioClient);
        await FCMService.instance.checkInitialMessage(router);

        // Branch.io deep linking — callback navigates via router
        await DeepLinkHandler.instance.initialize(
          onLinkReceived: (link) {
            // Build the resolved path and navigate
            var path = link.route;
            link.params.forEach((key, value) {
              path = path.replaceAll(':$key', value);
            });
            router.go(path);
          },
        );

        // iOS ATT prompt — must be shown before any tracking
        if (Platform.isIOS) {
          await _requestTrackingPermission();
        }
      });
    }

    return MaterialApp.router(
      title: 'HireX',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _requestTrackingPermission() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 500));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        final allowed = result == TrackingStatus.authorized;
        AnalyticsService.instance.setTrackingEnabled(allowed);
        debugPrint('[ATT] Tracking authorized: $allowed');
      } else {
        AnalyticsService.instance
            .setTrackingEnabled(status == TrackingStatus.authorized);
      }
    } catch (e) {
      debugPrint('[ATT] Error: $e');
    }
  }
}
