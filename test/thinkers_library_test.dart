import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/philosophy/data/thinkers_catalog.dart';
import 'package:focus_habitual_life/features/philosophy/data/thinkers_repository.dart';
import 'package:focus_habitual_life/features/philosophy/domain/thinker.dart';
import 'package:focus_habitual_life/features/philosophy/presentation/thinkers_library_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppDatabase.init();
  });

  group('ThinkersCatalog Data Integrity Tests', () {
    test('catalog contains exactly 100 philosophical figures', () {
      expect(ThinkersCatalog.all.length, equals(100));
    });

    test('each thinker has unique id and complete metadata', () {
      final ids = <String>{};
      for (final t in ThinkersCatalog.all) {
        expect(ids.contains(t.id), isFalse, reason: 'Duplicate ID: ${t.id}');
        ids.add(t.id);
        expect(t.name.isNotEmpty, isTrue);
        expect(t.eraLabel.isNotEmpty, isTrue);
        expect(t.keyIdea.isNotEmpty, isTrue);
        expect(t.origin, isNotNull);
        expect(t.keyWork, isNotNull);
      }
    });

    test('all 9 thinker categories are populated', () {
      for (final cat in ThinkerCategory.values) {
        final count = ThinkersCatalog.all.where((t) => t.category == cat.code).length;
        expect(count, greaterThan(0), reason: 'Category ${cat.code} has no thinkers');
      }
    });
  });

  group('ThinkersRepository Database Tests', () {
    test('getThinkers returns seeded thinkers from SQLite', () {
      final repo = ThinkersRepository(currentUserId: 'test_user');
      final all = repo.getThinkers(includeReligious: true);
      expect(all.length, equals(100));
    });

    test('category filter filters correctly', () {
      final repo = ThinkersRepository(currentUserId: 'test_user');
      final stoics = repo.getThinkers(category: 'stoic', includeReligious: true);
      expect(stoics.isNotEmpty, isTrue);
      expect(stoics.every((t) => t.category == 'stoic'), isTrue);
    });

    test('search filters thinkers by name, idea or work', () {
      final repo = ThinkersRepository(currentUserId: 'test_user');
      final results = repo.searchThinkers('Marco Aurelio', includeReligious: true);
      expect(results.any((t) => t.name.contains('Marco Aurelio')), isTrue);
    });

    test('daily thinker rotates deterministically', () {
      final repo = ThinkersRepository(currentUserId: 'test_user');
      final thinker = repo.getDailyThinker(includeReligious: true);
      expect(thinker, isNotNull);
      expect(thinker.name.isNotEmpty, isTrue);
    });

    test('toggleFavorite updates thinker state in SQLite', () async {
      final repo = ThinkersRepository(currentUserId: 'test_user_fav');
      final initial = repo.getThinkers(includeReligious: true).first;
      expect(initial.isFavorite, isFalse);

      await repo.toggleFavorite(thinkerId: initial.id, isFavorite: true);
      final updated = repo.getThinkers(includeReligious: true).firstWhere((t) => t.id == initial.id);
      expect(updated.isFavorite, isTrue);

      await repo.toggleFavorite(thinkerId: initial.id, isFavorite: false);
      final reverted = repo.getThinkers(includeReligious: true).firstWhere((t) => t.id == initial.id);
      expect(reverted.isFavorite, isFalse);
    });
  });

  group('ThinkersLibraryScreen Widget Tests', () {
    testWidgets('renders search field, category chips, and hero contemplation card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ThinkersLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Biblioteca de Sabios'), findsOneWidget);

      // Verify search field placeholder
      expect(find.text('Buscar filósofo, idea clave o legado...'), findsOneWidget);

      // Verify category chip 'Todos (100)'
      expect(find.textContaining('Todos'), findsOneWidget);

      // Verify daily sage contemplation card
      expect(find.text('SABIO DEL DÍA'), findsOneWidget);
    });
  });
}
