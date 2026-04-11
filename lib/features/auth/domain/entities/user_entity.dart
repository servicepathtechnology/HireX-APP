/// Domain entity for a HireX user.
/// Pure Dart — no Flutter or Firebase imports.
class UserEntity {
  const UserEntity({
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
  final CandidateProfileEntity? candidateProfile;
  final RecruiterProfileEntity? recruiterProfile;

  bool get isCandidate => role == 'candidate';
  bool get isRecruiter => role == 'recruiter';
}

class CandidateProfileEntity {
  const CandidateProfileEntity({
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
}

class RecruiterProfileEntity {
  const RecruiterProfileEntity({
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
}
