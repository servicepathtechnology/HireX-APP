import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/errors/app_exception.dart';

/// Onboarding wizard state — drives the PageView across all 6 steps.
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.selectedRole,
    this.fullName,
    this.city,
    this.headline,
    this.companyName,
    this.companySize,
    this.roleAtCompany,
    this.selectedSkills = const [],
    this.careerGoal,
    this.hiringDomains = const [],
    this.avatarFile,
    this.isLoading = false,
    this.error,
  });

  final int currentStep;
  final String? selectedRole;
  final String? fullName;
  final String? city;
  final String? headline;
  final String? companyName;
  final String? companySize;
  final String? roleAtCompany;
  final List<String> selectedSkills;
  final String? careerGoal;
  final List<String> hiringDomains;
  final File? avatarFile;
  final bool isLoading;
  final String? error;

  bool get isCandidate => selectedRole == 'candidate';
  bool get isRecruiter => selectedRole == 'recruiter';

  OnboardingState copyWith({
    int? currentStep,
    String? selectedRole,
    String? fullName,
    String? city,
    String? headline,
    String? companyName,
    String? companySize,
    String? roleAtCompany,
    List<String>? selectedSkills,
    String? careerGoal,
    List<String>? hiringDomains,
    File? avatarFile,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedRole: selectedRole ?? this.selectedRole,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      headline: headline ?? this.headline,
      companyName: companyName ?? this.companyName,
      companySize: companySize ?? this.companySize,
      roleAtCompany: roleAtCompany ?? this.roleAtCompany,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      careerGoal: careerGoal ?? this.careerGoal,
      hiringDomains: hiringDomains ?? this.hiringDomains,
      avatarFile: avatarFile ?? this.avatarFile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() => state = const OnboardingState();

  void setRole(String role) => state = state.copyWith(selectedRole: role);

  void setBasicInfo({String? fullName, String? city, String? headline,
      String? companyName, String? companySize, String? roleAtCompany}) {
    state = state.copyWith(
      fullName: fullName,
      city: city,
      headline: headline,
      companyName: companyName,
      companySize: companySize,
      roleAtCompany: roleAtCompany,
    );
  }

  void toggleSkill(String skill) {
    final skills = List<String>.from(state.selectedSkills);
    if (skills.contains(skill)) {
      skills.remove(skill);
    } else if (skills.length < 10) {
      skills.add(skill);
    }
    state = state.copyWith(selectedSkills: skills);
  }

  void setCareerGoal(String goal) => state = state.copyWith(careerGoal: goal);

  void toggleHiringDomain(String domain) {
    final domains = List<String>.from(state.hiringDomains);
    if (domains.contains(domain)) {
      domains.remove(domain);
    } else {
      domains.add(domain);
    }
    state = state.copyWith(hiringDomains: domains);
  }

  void setAvatarFile(File file) => state = state.copyWith(avatarFile: file);

  /// Extract user-friendly error message from exception.
  String _extractError(dynamic e) {
    if (e is DioException && e.error is NetworkException) {
      return (e.error as NetworkException).message;
    }
    if (e is AppException) return e.message;
    return e.toString();
  }

  /// Saves current step data to the backend.
  Future<void> saveRoleToBackend() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authNotifierProvider.notifier).updateUser({'role': state.selectedRole});
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> saveBasicInfoToBackend() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fields = <String, dynamic>{};
      if (state.fullName != null) fields['full_name'] = state.fullName;
      if (state.isCandidate) {
        if (state.city != null && state.city!.isNotEmpty) fields['city'] = state.city;
        if (state.headline != null && state.headline!.isNotEmpty) fields['headline'] = state.headline;
      } else {
        if (state.companyName != null) fields['company_name'] = state.companyName;
        if (state.companySize != null) fields['company_size'] = state.companySize;
        if (state.roleAtCompany != null) fields['role_at_company'] = state.roleAtCompany;
      }
      if (fields.isNotEmpty) {
        await ref.read(authNotifierProvider.notifier).updateUser(fields);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Non-fatal — save locally and let user continue. Will sync on next login.
      state = state.copyWith(isLoading: false, error: null);
    }
  }

  Future<void> saveSkillsToBackend() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authNotifierProvider.notifier).updateUser({
        'skill_tags': state.selectedSkills,
        if (state.careerGoal != null) 'career_goal': state.careerGoal,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> saveRecruiterInfoToBackend() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authNotifierProvider.notifier).updateUser({
        'hiring_domains': state.hiringDomains,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authNotifierProvider.notifier).updateUser({'onboarding_complete': true});
    } catch (e) {
      // Non-fatal — if backend is down, we still navigate forward.
      // The router will re-check onboarding_complete on next cold start.
      state = state.copyWith(isLoading: false, error: null);
      return;
    }
    // Seed skill scores — fire and forget, never block navigation
    unawaited(
      ref.read(dioClientProvider).instance
          .post('/api/v1/scores/seed')
          .catchError((_) {}),
    );
    state = state.copyWith(isLoading: false);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
