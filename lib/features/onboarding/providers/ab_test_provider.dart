import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A/B test variant for onboarding flow.
/// 'A' = full 6-step onboarding (control)
/// 'B' = 3-step onboarding (shorter)
final abTestProvider = Provider<String>((ref) {
  const boxKey = 'onboarding_ab_variant';
  try {
    final box = Hive.box('settings');
    final existing = box.get(boxKey) as String?;
    if (existing != null) return existing;
    // 50/50 random assignment
    final variant = Random().nextBool() ? 'A' : 'B';
    box.put(boxKey, variant);
    return variant;
  } catch (_) {
    return 'A'; // fallback to control
  }
});
