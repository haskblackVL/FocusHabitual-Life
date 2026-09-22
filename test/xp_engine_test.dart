import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/core/gamification/xp_engine.dart';

void main() {
  group('XpEngine Tests', () {
    test('calculateLevel matches schema.sql formula: floor(sqrt(xp/100)) + 1', () {
      expect(XpEngine.calculateLevel(0), equals(1));
      expect(XpEngine.calculateLevel(50), equals(1));
      expect(XpEngine.calculateLevel(99), equals(1));
      expect(XpEngine.calculateLevel(100), equals(2));
      expect(XpEngine.calculateLevel(399), equals(2));
      expect(XpEngine.calculateLevel(400), equals(3));
      expect(XpEngine.calculateLevel(900), equals(4));
      expect(XpEngine.calculateLevel(1600), equals(5));
    });

    test('xpForLevel calculates exact threshold for each level', () {
      expect(XpEngine.xpForLevel(1), equals(0));
      expect(XpEngine.xpForLevel(2), equals(100));
      expect(XpEngine.xpForLevel(3), equals(400));
      expect(XpEngine.xpForLevel(4), equals(900));
    });

    test('calculateLevelProgress returns normalized value between 0.0 and 1.0', () {
      expect(XpEngine.calculateLevelProgress(0), equals(0.0));
      expect(XpEngine.calculateLevelProgress(50), equals(0.5));
      expect(XpEngine.calculateLevelProgress(100), equals(0.0));
      // Level 2 range is 100 to 400 (range = 300). At 250 XP, earned = 150 -> 150/300 = 0.5
      expect(XpEngine.calculateLevelProgress(250), closeTo(0.5, 0.01));
    });

    test('getLevelTitle returns inspiring polymath titles', () {
      expect(XpEngine.getLevelTitle(1), contains('Polímata'));
      expect(XpEngine.getLevelTitle(3), contains('Disciplina'));
      expect(XpEngine.getLevelTitle(6), contains('Enfoque'));
    });
  });
}
