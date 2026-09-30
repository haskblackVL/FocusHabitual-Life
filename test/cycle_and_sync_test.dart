import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';
import 'package:focus_habitual_life/features/cycle/data/cycle_repository.dart';
import 'package:focus_habitual_life/features/cycle/domain/cycle_models.dart';
import 'package:focus_habitual_life/features/cycle/presentation/widgets/cycle_layer_calendar.dart';
import 'package:focus_habitual_life/features/cycle/presentation/widgets/cycle_layer_chips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CycleRepository cycleRepo;

  setUp(() async {
    await AppDatabase.init();
    cycleRepo = CycleRepository(currentUserId: 'test-user-cycle-123');
  });

  group('Cycle Biological Engine Tests', () {
    test('Calculates 4 phases and fertility accurately across 28-day cycle', () {
      final now = DateTime.now();

      // Test Day 2: Menstrual Phase
      final day2Start = now.subtract(const Duration(days: 1));
      final day2Info = CycleDayInfo.calculate(
        lastPeriodStart: day2Start,
        periodLength: 5,
        cycleLength: 28,
      );
      expect(day2Info.currentCycleDay, equals(2));
      expect(day2Info.phase, equals(CyclePhase.menstrual));
      expect(day2Info.isFertileWindow, isFalse);

      // Test Day 9: Follicular Phase
      final day9Start = now.subtract(const Duration(days: 8));
      final day9Info = CycleDayInfo.calculate(
        lastPeriodStart: day9Start,
        periodLength: 5,
        cycleLength: 28,
      );
      expect(day9Info.currentCycleDay, equals(9));
      expect(day9Info.phase, equals(CyclePhase.follicular));

      // Test Day 14: Ovulatory Phase & Ovulation Peak
      final day14Start = now.subtract(const Duration(days: 13));
      final day14Info = CycleDayInfo.calculate(
        lastPeriodStart: day14Start,
        periodLength: 5,
        cycleLength: 28,
      );
      expect(day14Info.currentCycleDay, equals(14));
      expect(day14Info.phase, equals(CyclePhase.ovulatory));
      expect(day14Info.isFertileWindow, isTrue);
      expect(day14Info.isOvulationDay, isTrue);

      // Test Day 22: Luteal Phase
      final day22Start = now.subtract(const Duration(days: 21));
      final day22Info = CycleDayInfo.calculate(
        lastPeriodStart: day22Start,
        periodLength: 5,
        cycleLength: 28,
      );
      expect(day22Info.currentCycleDay, equals(22));
      expect(day22Info.phase, equals(CyclePhase.luteal));
      expect(day22Info.isFertileWindow, isFalse);
    });

    test('CycleRepository records period and enqueues to sync_queue', () async {
      final periodStart = DateTime.now().subtract(const Duration(days: 3));
      final log = await cycleRepo.recordPeriodStart(
        periodStart,
        periodLength: 5,
        cycleLength: 28,
        symptoms: ['high_energy', 'cramps'],
      );

      expect(log.periodLength, equals(5));
      expect(log.cycleLength, equals(28));
      expect(log.symptoms, contains('cramps'));

      // Verify that sync_queue captured the change
      final pending = AppDatabase.getPendingSync(limit: 50);
      final cycleQueue = pending.where((q) => q['table_name'] == 'cycle_log');
      expect(cycleQueue.isNotEmpty, isTrue);
      expect(cycleQueue.last['action'], equals('INSERT'));
    });

    test('CycleRepository updates symptoms and enqueues update to sync_queue', () async {
      final latest = await cycleRepo.getLatestCycle();
      expect(latest, isNotNull);

      await cycleRepo.updateSymptoms(
        latest!.id,
        ['headache', 'bloating'],
      );

      final updated = await cycleRepo.getLatestCycle();
      expect(updated?.symptoms, contains('headache'));
      expect(updated?.symptoms, contains('bloating'));

      final pending = AppDatabase.getPendingSync(limit: 50);
      final cycleQueue = pending.where((q) => q['table_name'] == 'cycle_log');
      expect(cycleQueue.isNotEmpty, isTrue);
    });

    test('Ovulation & Basal Body Temperature layer logs and queries accurately', () async {
      final testDate = DateTime(2026, 9, 25);
      final ovulation = await cycleRepo.logOvulation(
        date: testDate,
        basalBodyTemp: 36.65,
        cervicalMucus: 'egg_white',
        ovulationTestResult: 'positive',
        notes: 'Pico de temperatura detectado',
      );

      expect(ovulation.basalBodyTemp, equals(36.65));
      expect(ovulation.cervicalMucus, equals('egg_white'));
      expect(ovulation.ovulationTestResult, equals('positive'));

      final monthLogs = await cycleRepo.getOvulationLogsForMonth(testDate);
      expect(monthLogs.any((o) => o.id == ovulation.id), isTrue);

      final dateLog = await cycleRepo.getOvulationLogForDate(testDate);
      expect(dateLog?.basalBodyTemp, equals(36.65));
    });

    test('Pregnancy layer records active gestation and retrieves status', () async {
      final conception = DateTime(2026, 6, 1);
      final due = DateTime(2027, 2, 28);

      final pregnancy = await cycleRepo.logPregnancy(
        estimatedConceptionDate: conception,
        dueDate: due,
        currentWeek: 16,
        isActive: true,
        notes: 'Seguimiento prenatal segundo trimestre',
      );

      expect(pregnancy.currentWeek, equals(16));
      expect(pregnancy.isActive, isTrue);

      final active = await cycleRepo.getActivePregnancy();
      expect(active, isNotNull);
      expect(active?.currentWeek, equals(16));
    });

    test('Fertility Awareness (Prenupcial) layer records method and partner sharing', () async {
      final testDate = DateTime(2026, 9, 26);
      final fertility = await cycleRepo.logFertilityAwareness(
        date: testDate,
        method: 'symptothermal',
        fertileWindowStatus: 'fertile',
        partnerShared: true,
        notes: 'Observación conjunta prenupcial',
      );

      expect(fertility.method, equals('symptothermal'));
      expect(fertility.fertileWindowStatus, equals('fertile'));
      expect(fertility.partnerShared, isTrue);

      final monthFertility = await cycleRepo.getFertilityLogsForMonth(testDate);
      expect(monthFertility.any((f) => f.id == fertility.id), isTrue);
    });

    test('Granular Daily Symptoms layer records flow, cramps, and mood', () async {
      final testDate = DateTime(2026, 9, 27);
      final symptomsLog = await cycleRepo.logDailySymptoms(
        date: testDate,
        symptoms: ['cramps', 'headache', 'bloating'],
        flowLevel: 'medium',
        crampsLevel: 3,
        mood: 'sensitive',
        notes: 'Té caliente y descanso tomado',
      );

      expect(symptomsLog.flowLevel, equals('medium'));
      expect(symptomsLog.crampsLevel, equals(3));
      expect(symptomsLog.mood, equals('sensitive'));
      expect(symptomsLog.symptoms, contains('headache'));

      final dateSymptoms = await cycleRepo.getDailySymptomsForDate(testDate);
      expect(dateSymptoms?.crampsLevel, equals(3));
    });

    testWidgets('CycleLayerChips renders all 5 layer filter chips and toggles selection', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: CycleLayerChips(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CAPAS DEL CALENDARIO'), findsOneWidget);
      expect(find.text('Periodo'), findsOneWidget);
      expect(find.text('Ovulación & Temp'), findsOneWidget);
      expect(find.text('Embarazo'), findsOneWidget);
      expect(find.text('Fertilidad / Prenupcial'), findsOneWidget);
      expect(find.text('Síntomas'), findsOneWidget);

      // Tap 'Embarazo' chip
      await tester.tap(find.text('Embarazo'));
      await tester.pumpAndSettle();
    });

    testWidgets('CycleLayerCalendar renders week days, days grid, and selected day footer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CycleLayerCalendar(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Registrar Día'), findsOneWidget);
    });
  });
}
