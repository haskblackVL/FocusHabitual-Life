import 'package:flutter/foundation.dart';

/// Event type for self-mastery logs.
enum NofapEventType {
  checkin,
  relapse,
  coolingSession;

  String get dbValue {
    switch (this) {
      case NofapEventType.checkin:
        return 'checkin';
      case NofapEventType.relapse:
        return 'relapse';
      case NofapEventType.coolingSession:
        return 'cooling_session';
    }
  }

  static NofapEventType fromDb(String val) {
    switch (val) {
      case 'relapse':
        return NofapEventType.relapse;
      case 'cooling_session':
        return NofapEventType.coolingSession;
      case 'checkin':
      default:
        return NofapEventType.checkin;
    }
  }
}

/// Represents the real-time active streak state.
@immutable
class NofapStreakState {
  const NofapStreakState({
    required this.streakStartDate,
    required this.now,
    this.totalRelapses = 0,
  });

  final DateTime streakStartDate;
  final DateTime now;
  final int totalRelapses;

  Duration get elapsed {
    final diff = now.difference(streakStartDate);
    return diff.isNegative ? Duration.zero : diff;
  }

  int get days => elapsed.inDays;
  int get hours => elapsed.inHours % 24;
  int get minutes => elapsed.inMinutes % 60;
  int get seconds => elapsed.inSeconds % 60;

  double get progress90Days => (days / 90.0).clamp(0.0, 1.0);
  int get percent90Days => (progress90Days * 100).round();

  String get daysDisplay => days.toString();
  String get hoursDisplay => hours.toString().padLeft(2, '0');
  String get minutesDisplay => minutes.toString().padLeft(2, '0');
  String get secondsDisplay => seconds.toString().padLeft(2, '0');

  NofapStreakState copyWith({
    DateTime? streakStartDate,
    DateTime? now,
    int? totalRelapses,
  }) {
    return NofapStreakState(
      streakStartDate: streakStartDate ?? this.streakStartDate,
      now: now ?? this.now,
      totalRelapses: totalRelapses ?? this.totalRelapses,
    );
  }
}

/// Represents an anchor reason to maintain self-mastery.
@immutable
class NofapReason {
  const NofapReason({
    required this.id,
    required this.reasonText,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String reasonText;
  final DateTime createdAt;
  final bool isActive;

  factory NofapReason.fromRow(Map<String, dynamic> row) {
    return NofapReason(
      id: row['id'] as String,
      reasonText: row['reason_text'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      isActive: (row['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reason_text': reasonText,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive ? 1 : 0,
  };
}

/// Historical relapse event for analytical review and patterns.
@immutable
class NofapRelapseItem {
  const NofapRelapseItem({
    required this.id,
    required this.occurredAt,
    this.relapseReason,
    this.note,
    this.clientId,
  });

  final String id;
  final DateTime occurredAt;
  final String? relapseReason;
  final String? note;
  final String? clientId;

  factory NofapRelapseItem.fromRow(Map<String, dynamic> row) {
    return NofapRelapseItem(
      id: row['id'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      relapseReason: row['relapse_reason'] as String?,
      note: row['note'] as String?,
      clientId: row['client_id'] as String?,
    );
  }

  String get reasonLabel {
    switch (relapseReason) {
      case 'porn':
        return 'Pornografía';
      case 'masturbation':
        return 'Masturbación';
      case 'both':
        return 'Pornografía y Masturbación';
      default:
        return 'Recaída';
    }
  }
}

