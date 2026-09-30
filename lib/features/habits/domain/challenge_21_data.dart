import 'package:flutter/foundation.dart';
import 'habit.dart';

/// Represents a single day node in the 7-day week view for the 21-Day Challenge.
@immutable
class ChallengeDayNode {
  const ChallengeDayNode({
    required this.dayLabel,
    required this.date,
    required this.challengeDayNumber,
    required this.isDone,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
  });

  final String dayLabel;
  final DateTime date;
  final int? challengeDayNumber;
  final bool isDone;
  final bool isToday;
  final bool isPast;
  final bool isFuture;
}

/// Represents the active state and telemetry for the 21-Day Challenge.
@immutable
class Challenge21Data {
  const Challenge21Data({
    required this.habit,
    required this.isCompletedToday,
    required this.currentDayNumber,
    required this.totalDaysCompleted,
    required this.streakCount,
    required this.weekNodes,
  });

  final Habit habit;
  final bool isCompletedToday;
  final int currentDayNumber;
  final int totalDaysCompleted;
  final int streakCount;
  final List<ChallengeDayNode> weekNodes;

  double get progress => (totalDaysCompleted / 21.0).clamp(0.0, 1.0);
  int get progressPercent => (progress * 100).round();
}
