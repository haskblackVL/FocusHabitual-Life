import 'package:flutter/foundation.dart';

/// User Profile model mirroring `public.profiles` in Supabase.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.gender = 'male',
    this.isReligious = false,
    this.locale = 'es-MX',
    this.timezone = 'America/Mexico_City',
    this.avatarUrl,
    this.onboardingCompleted = false,
    this.premiumTier = 'free',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final bool isReligious;
  final String locale;
  final String timezone;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final String premiumTier; // 'free', 'premium'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isMale => gender == 'male';
  bool get isFemale => gender == 'female';

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? gender,
    bool? isReligious,
    String? locale,
    String? timezone,
    String? avatarUrl,
    bool? onboardingCompleted,
    String? premiumTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      isReligious: isReligious ?? this.isReligious,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      premiumTier: premiumTier ?? this.premiumTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'local_user',
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String? ?? 'male',
      isReligious: json['is_religious'] as bool? ?? false,
      locale: json['locale'] as String? ?? 'es-MX',
      timezone: json['timezone'] as String? ?? 'America/Mexico_City',
      avatarUrl: json['avatar_url'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      premiumTier: json['premium_tier'] as String? ?? 'free',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'full_name': fullName,
      'gender': gender,
      'is_religious': isReligious,
      'locale': locale,
      'timezone': timezone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'onboarding_completed': onboardingCompleted,
      'premium_tier': premiumTier,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Default fallback guest/local profile.
  factory UserProfile.guest() {
    return const UserProfile(
      id: 'local_user',
      fullName: 'Usuario FocusHabitual',
      gender: 'male',
      isReligious: false,
      onboardingCompleted: true,
    );
  }
}

/// Lightweight authenticated user session representation for local operations.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.userMetadata,
  });

  final String id;
  final String email;
  final Map<String, dynamic>? userMetadata;
}

