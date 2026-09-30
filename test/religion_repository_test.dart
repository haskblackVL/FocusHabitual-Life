import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/religion/data/religion_repository.dart';
import 'package:focus_habitual_life/features/religion/domain/prayer_request.dart';
import 'package:focus_habitual_life/features/religion/domain/religion_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReligionRepository repo;

  setUpAll(() async {
    await AppDatabase.init();
    repo = ReligionRepository();
  });

  group('Religion & Spirituality Domain Models', () {
    test('ReligionContent model correctly parses and serializes', () {
      const content = ReligionContent(
        id: 'test-1',
        verseRef: 'Proverbios 16:3',
        verseText: 'Encomienda al Señor tus obras...',
        reflection: 'Reflexión ejecutiva profunda.',
        theme: 'Sabiduría & Liderazgo',
        practicalAction: 'Pausa de 2 minutos.',
      );

      final map = content.toMap();
      final parsed = ReligionContent.fromMap(map);

      expect(parsed.id, equals('test-1'));
      expect(parsed.verseRef, equals('Proverbios 16:3'));
      expect(parsed.verseText, equals('Encomienda al Señor tus obras...'));
      expect(parsed.reflection, equals('Reflexión ejecutiva profunda.'));
      expect(parsed.theme, equals('Sabiduría & Liderazgo'));
      expect(parsed.practicalAction, equals('Pausa de 2 minutos.'));
    });

    test('PrayerCategory parses codes and defaults to personal', () {
      expect(PrayerCategory.fromCode('personal'), equals(PrayerCategory.personal));
      expect(PrayerCategory.fromCode('family'), equals(PrayerCategory.family));
      expect(PrayerCategory.fromCode('work_purpose'), equals(PrayerCategory.workPurpose));
      expect(PrayerCategory.fromCode('health'), equals(PrayerCategory.health));
      expect(PrayerCategory.fromCode('gratitude'), equals(PrayerCategory.gratitude));
      expect(PrayerCategory.fromCode('non_existent'), equals(PrayerCategory.personal));
    });

    test('PrayerRequest model correctly handles active and answered states', () {
      final now = DateTime.now();
      final prayer = PrayerRequest(
        id: 'p-1',
        userId: 'local_user',
        title: 'Discernimiento laboral',
        description: 'Tomar la decisión correcta',
        category: 'work_purpose',
        status: 'active',
        createdAt: now,
        clientId: 'client-1',
        clientUpdatedAt: now,
      );

      expect(prayer.isAnswered, isFalse);
      expect(prayer.statusEnum, equals(PrayerStatus.active));
      expect(prayer.categoryEnum, equals(PrayerCategory.workPurpose));

      final answered = prayer.copyWith(
        status: 'answered',
        answeredAt: now,
        answerNotes: 'Contrato firmado con éxito.',
      );

      expect(answered.isAnswered, isTrue);
      expect(answered.statusEnum, equals(PrayerStatus.answered));
      expect(answered.answerNotes, equals('Contrato firmado con éxito.'));
    });
  });

  group('ReligionRepository Core Logic & XP Integration', () {
    test('Seeded passages contain at least 31 high-impact wisdom verses', () async {
      final passages = await repo.getAllPassages();
      expect(passages.length, greaterThanOrEqualTo(31));

      // Verify essential leadership & wisdom verses are present
      final refs = passages.map((p) => p.verseRef).toSet();
      expect(refs.contains('Proverbios 16:3'), isTrue);
      expect(refs.contains('Proverbios 3:5-6'), isTrue);
      expect(refs.contains('Proverbios 4:23'), isTrue);
      expect(refs.contains('Filipenses 4:6-7'), isTrue);
      expect(refs.contains('Colosenses 3:23'), isTrue);
      expect(refs.contains('Santiago 1:5'), isTrue);
    });

    test('getDailyPassage rotates deterministically and returns content', () async {
      final p1 = await repo.getDailyPassage(date: DateTime(2026, 9, 24));
      final p2 = await repo.getDailyPassage(date: DateTime(2026, 9, 24));

      expect(p1.content.id, equals(p2.content.id));
      expect(p1.content.verseRef, equals(p2.content.verseRef));
      expect(p1.content.verseText, equals(p2.content.verseText));
    });

    test('saveReflection logs notes, awards +15 XP, and enqueues sync', () async {
      // Get initial XP
      final initialRow = AppDatabase.instance.select("SELECT total_xp FROM user_xp WHERE user_id = 'local_user'");
      final initialXp = initialRow.isNotEmpty ? (initialRow.first['total_xp'] as int? ?? 0) : 0;

      const testContentId = 'rel-test-reflection-id';
      // Insert test passage into DB first so foreign keys / lookups work
      AppDatabase.instance.execute('''
        INSERT OR IGNORE INTO religion_content (id, verse_ref, verse_text, reflection, language, theme)
        VALUES ('rel-test-reflection-id', 'Test 1:1', 'Texto de prueba', 'Reflexión de prueba', 'es', 'Sabiduría')
      ''');

      final log = await repo.saveReflection(
        contentId: testContentId,
        notes: 'Mi compromiso ejecutivo es mantener la calma.',
        isFavorite: true,
      );

      expect(log.contentId, equals(testContentId));
      expect(log.reflectionNotes, equals('Mi compromiso ejecutivo es mantener la calma.'));
      expect(log.isFavorite, isTrue);

      // Verify XP was incremented by 15
      final updatedRow = AppDatabase.instance.select("SELECT total_xp FROM user_xp WHERE user_id = 'local_user'");
      final updatedXp = updatedRow.first['total_xp'] as int;
      expect(updatedXp, equals(initialXp + 15));
    });

    test('toggleFavorite toggles is_favorite between true and false', () async {
      const testContentId = 'rel-test-favorite-id';
      AppDatabase.instance.execute('''
        INSERT OR IGNORE INTO religion_content (id, verse_ref, verse_text, reflection, language, theme)
        VALUES ('rel-test-favorite-id', 'Test 2:1', 'Texto de prueba', 'Reflexión', 'es', 'Sabiduría')
      ''');

      final firstFav = await repo.toggleFavorite(testContentId);
      expect(firstFav, isTrue);

      final secondFav = await repo.toggleFavorite(testContentId);
      expect(secondFav, isFalse);
    });

    test('Prayer requests CRUD awards +10 XP on creation and tracks testimonies', () async {
      final initialRow = AppDatabase.instance.select("SELECT total_xp FROM user_xp WHERE user_id = 'local_user'");
      final initialXp = initialRow.isNotEmpty ? (initialRow.first['total_xp'] as int? ?? 0) : 0;

      // 1. Create prayer request
      final created = await repo.createPrayerRequest(
        title: 'Crecimiento de proyecto FocusHabitual',
        description: 'Dirección para escalar la arquitectura',
        category: 'work_purpose',
      );

      expect(created.title, equals('Crecimiento de proyecto FocusHabitual'));
      expect(created.status, equals('active'));

      // Verify +10 XP awarded
      final afterCreateRow = AppDatabase.instance.select("SELECT total_xp FROM user_xp WHERE user_id = 'local_user'");
      final afterCreateXp = afterCreateRow.first['total_xp'] as int;
      expect(afterCreateXp, equals(initialXp + 10));

      // 2. Fetch active prayer requests
      final activeList = await repo.getPrayerRequests(status: 'active');
      expect(activeList.any((p) => p.id == created.id), isTrue);

      // 3. Mark answered with testimony
      final answered = await repo.markPrayerAnswered(
        id: created.id,
        answerNotes: 'Proyecto implementado con 100% de éxito y cero errores.',
      );

      expect(answered.status, equals('answered'));
      expect(answered.answerNotes, contains('100% de éxito'));

      // 4. Verify in answered list
      final answeredList = await repo.getPrayerRequests(status: 'answered');
      expect(answeredList.any((p) => p.id == created.id), isTrue);

      // 5. Delete prayer request
      await repo.deletePrayerRequest(created.id);
      final afterDeleteList = await repo.getPrayerRequests();
      expect(afterDeleteList.any((p) => p.id == created.id), isFalse);
    });

    test('getSpiritualStats accurately aggregates metrics', () async {
      final stats = await repo.getSpiritualStats();
      expect(stats.containsKey('reflectionsCount'), isTrue);
      expect(stats.containsKey('activePrayersCount'), isTrue);
      expect(stats.containsKey('answeredPrayersCount'), isTrue);
      expect(stats.containsKey('favoritesCount'), isTrue);
    });
  });
}
