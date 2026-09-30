/// Domain model for biblical & spiritual reflection content.
class ReligionContent {
  const ReligionContent({
    required this.id,
    required this.verseRef,
    required this.verseText,
    this.reflection,
    this.dateAssigned,
    this.language = 'es',
    this.theme = 'Sabiduría & Liderazgo',
    this.practicalAction,
    this.readingPath = 'proverbios_31',
  });

  final String id;
  final String verseRef;
  final String verseText;
  final String? reflection;
  final String? dateAssigned;
  final String language;
  final String theme;
  final String? practicalAction;
  final String? readingPath;

  factory ReligionContent.fromMap(Map<String, dynamic> map) {
    return ReligionContent(
      id: map['id'] as String,
      verseRef: map['verse_ref'] as String,
      verseText: map['verse_text'] as String,
      reflection: map['reflection'] as String?,
      dateAssigned: map['date_assigned'] as String?,
      language: (map['language'] as String?) ?? 'es',
      theme: (map['theme'] as String?) ?? 'Sabiduría & Liderazgo',
      practicalAction: map['practical_action'] as String?,
      readingPath: (map['reading_path'] as String?) ?? 'proverbios_31',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'verse_ref': verseRef,
      'verse_text': verseText,
      'reflection': reflection,
      'date_assigned': dateAssigned,
      'language': language,
      'theme': theme,
      'practical_action': practicalAction,
      'reading_path': readingPath,
    };
  }

  ReligionContent copyWith({
    String? id,
    String? verseRef,
    String? verseText,
    String? reflection,
    String? dateAssigned,
    String? language,
    String? theme,
    String? practicalAction,
    String? readingPath,
  }) {
    return ReligionContent(
      id: id ?? this.id,
      verseRef: verseRef ?? this.verseRef,
      verseText: verseText ?? this.verseText,
      reflection: reflection ?? this.reflection,
      dateAssigned: dateAssigned ?? this.dateAssigned,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      practicalAction: practicalAction ?? this.practicalAction,
      readingPath: readingPath ?? this.readingPath,
    );
  }
}

/// User devotional reading log, notes, and favorite status.
class ReligionUserLog {
  const ReligionUserLog({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.readAt,
    this.reflectionNotes,
    this.isFavorite = false,
    required this.createdAt,
    required this.clientId,
    required this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String contentId;
  final DateTime readAt;
  final String? reflectionNotes;
  final bool isFavorite;
  final DateTime createdAt;
  final String clientId;
  final DateTime clientUpdatedAt;

  factory ReligionUserLog.fromMap(Map<String, dynamic> map) {
    return ReligionUserLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      contentId: map['content_id'] as String,
      readAt: DateTime.parse(map['read_at'] as String),
      reflectionNotes: map['reflection_notes'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      clientId: map['client_id'] as String,
      clientUpdatedAt: DateTime.parse(map['client_updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'read_at': readAt.toIso8601String(),
      'reflection_notes': reflectionNotes,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  ReligionUserLog copyWith({
    String? id,
    String? userId,
    String? contentId,
    DateTime? readAt,
    String? reflectionNotes,
    bool? isFavorite,
    DateTime? createdAt,
    String? clientId,
    DateTime? clientUpdatedAt,
  }) {
    return ReligionUserLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      readAt: readAt ?? this.readAt,
      reflectionNotes: reflectionNotes ?? this.reflectionNotes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }
}

/// Composite object providing scripture + user interaction state.
class DailyDevotional {
  const DailyDevotional({
    required this.content,
    this.userLog,
  });

  final ReligionContent content;
  final ReligionUserLog? userLog;

  bool get isCompleted => userLog != null;
  bool get isFavorite => userLog?.isFavorite ?? false;
  String? get reflectionNotes => userLog?.reflectionNotes;
}
