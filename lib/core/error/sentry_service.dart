import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  SentryService._();

  static Future<void> initialize(AppRunner appRunner) async {
    final dsn = dotenv.env['SENTRY_DSN'] ?? '';
    final env = dotenv.env['APP_ENV'] ?? 'development';

    if (dsn.isEmpty || env == 'development') {
      // Skip Sentry in dev — just run the app
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = env;
        options.tracesSampleRate = 0.2;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
      },
      appRunner: appRunner,
    );
  }

  static void setUser(String userId, String email) {
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: userId, email: email)),
    );
  }

  static void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  static void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category ?? 'user_action',
      data: data,
    ));
  }

  static Future<void> captureException(dynamic exception, StackTrace? stackTrace) async {
    if (kDebugMode) {
      debugPrint('[Sentry] Exception: $exception');
      return;
    }
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }
}

typedef AppRunner = Future<void> Function();
