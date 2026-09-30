import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/features/auth/data/auth_repository.dart';
import 'package:focus_habitual_life/features/auth/domain/user_profile.dart';

void main() {
  group('UserProfile Domain Tests', () {
    test('guest factory creates default guest profile', () {
      final guest = UserProfile.guest();
      expect(guest.id, equals('local_user'));
      expect(guest.fullName, equals('Usuario FocusHabitual'));
      expect(guest.gender, equals('male'));
      expect(guest.isMale, isTrue);
      expect(guest.isFemale, isFalse);
      expect(guest.onboardingCompleted, isTrue);
    });

    test('toJson and fromJson preserves data fields accurately', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'user_123',
        fullName: 'Carl Friedrich Gauss',
        gender: 'male',
        isReligious: true,
        locale: 'de-DE',
        timezone: 'Europe/Berlin',
        onboardingCompleted: true,
        premiumTier: 'premium',
        createdAt: now,
      );

      final json = profile.toJson();
      expect(json['id'], equals('user_123'));
      expect(json['full_name'], equals('Carl Friedrich Gauss'));
      expect(json['gender'], equals('male'));
      expect(json['is_religious'], isTrue);
      expect(json['onboarding_completed'], isTrue);

      final reconstructed = UserProfile.fromJson(json);
      expect(reconstructed.id, equals(profile.id));
      expect(reconstructed.fullName, equals(profile.fullName));
      expect(reconstructed.isReligious, isTrue);
      expect(reconstructed.onboardingCompleted, isTrue);
    });

    test('gender flags adapt properly', () {
      const femaleProfile = UserProfile(id: 'fem_1', gender: 'female');
      expect(femaleProfile.isFemale, isTrue);
      expect(femaleProfile.isMale, isFalse);
    });
  });

  group('AuthRepository Tests', () {
    test('guest mode toggle operates in memory', () {
      final repo = AuthRepository();
      expect(repo.isGuestMode, isFalse);

      repo.setGuestMode(true);
      expect(repo.isGuestMode, isTrue);
      expect(repo.isAuthenticated, isTrue);

      repo.setGuestMode(false);
      expect(repo.isGuestMode, isFalse);
    });

    test('getProfile returns guest profile when guest mode is active', () async {
      final repo = AuthRepository();
      repo.setGuestMode(true);

      final profile = await repo.getProfile();
      expect(profile.id, equals('local_user'));
      expect(profile.fullName, equals('Usuario FocusHabitual'));
    });
  });
}
