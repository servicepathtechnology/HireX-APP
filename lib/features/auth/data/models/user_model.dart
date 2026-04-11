import '../../domain/entities/user_entity.dart';

/// Data model — maps JSON from the API to domain entities.
class UserModel {
  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    this.phone,
    this.role,
    this.avatarUrl,
    required this.onboardingComplete,
    required this.isVerified,
    required this.isActive,
    this.candidateProfile,
    this.recruiterProfile,
  });

  final String id;
  final String firebaseUid;
  final String email;
  final String fullName;
  final String? phone;
  final String? role;
  final String? avatarUrl;
  final bool onboardingComplete;
  final bool isVerified;
  final bool isActive;
  final CandidateProfileModel? candidateProfile;
  final RecruiterProfileModel? recruiterProfile;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        firebaseUid: json['firebase_uid'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        candidateProfile: json['candidate_profile'] != null
            ? CandidateProfileModel.fromJson(json['candidate_profile'] as Map<String, dynamic>)
            : null,
        recruiterProfile: json['recruiter_profile'] != null
            ? RecruiterProfileModel.fromJson(json['recruiter_profile'] as Map<String, dynamic>)
            : null,
      );

  UserEntity toEntity() => UserEntity(
        id: id,
        firebaseUid: firebaseUid,
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        avatarUrl: avatarUrl,
        onboardingComplete: onboardingComplete,
        isVerified: isVerified,
        isActive: isActive,
        candidateProfile: candidateProfile?.toEntity(),
        recruiterProfile: recruiterProfile?.toEntity(),
      );
}

class CandidateProfileModel {
  const CandidateProfileModel({
    this.headline,
    this.bio,
    this.city,
    this.githubUrl,
    this.linkedinUrl,
    this.portfolioUrl,
    this.skillTags = const [],
    this.careerGoal,
    this.skillScore = 0,
  });

  final String? headline;
  final String? bio;
  final String? city;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final List<String> skillTags;
  final String? careerGoal;
  final int skillScore;

  factory CandidateProfileModel.fromJson(Map<String, dynamic> json) => CandidateProfileModel(
        headline: json['headline'] as String?,
        bio: json['bio'] as String?,
        city: json['city'] as String?,
        githubUrl: json['github_url'] as String?,
        linkedinUrl: json['linkedin_url'] as String?,
        portfolioUrl: json['portfolio_url'] as String?,
        skillTags: (json['skill_tags'] as List<dynamic>?)?.cast<String>() ?? [],
        careerGoal: json['career_goal'] as String?,
        skillScore: json['skill_score'] as int? ?? 0,
      );

  CandidateProfileEntity toEntity() => CandidateProfileEntity(
        headline: headline,
        bio: bio,
        city: city,
        githubUrl: githubUrl,
        linkedinUrl: linkedinUrl,
        portfolioUrl: portfolioUrl,
        skillTags: skillTags,
        careerGoal: careerGoal,
        skillScore: skillScore,
      );
}

class RecruiterProfileModel {
  const RecruiterProfileModel({
    this.companyName,
    this.companySize,
    this.roleAtCompany,
    this.hiringDomains = const [],
    this.companyWebsite,
  });

  final String? companyName;
  final String? companySize;
  final String? roleAtCompany;
  final List<String> hiringDomains;
  final String? companyWebsite;

  factory RecruiterProfileModel.fromJson(Map<String, dynamic> json) => RecruiterProfileModel(
        companyName: json['company_name'] as String?,
        companySize: json['company_size'] as String?,
        roleAtCompany: json['role_at_company'] as String?,
        hiringDomains: (json['hiring_domains'] as List<dynamic>?)?.cast<String>() ?? [],
        companyWebsite: json['company_website'] as String?,
      );

  RecruiterProfileEntity toEntity() => RecruiterProfileEntity(
        companyName: companyName,
        companySize: companySize,
        roleAtCompany: roleAtCompany,
        hiringDomains: hiringDomains,
        companyWebsite: companyWebsite,
      );
}
