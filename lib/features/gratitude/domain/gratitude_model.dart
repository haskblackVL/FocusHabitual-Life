import 'package:flutter/foundation.dart';

/// Represents a daily gratitude & stoic reflection entry.
@immutable
class GratitudeEntry {
  const GratitudeEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.item1,
    this.item2,
    this.item3,
    this.reflection,
    this.promptUsed,
    required this.createdAt,
    this.clientId,
    this.clientUpdatedAt,
  });

  final String id;
  final String userId;
  final String entryDate; // YYYY-MM-DD
  final String item1;
  final String? item2;
  final String? item3;
  final String? reflection;
  final String? promptUsed;
  final DateTime createdAt;
  final String? clientId;
  final DateTime? clientUpdatedAt;

  List<String> get items => [
        item1,
        if (item2 != null && item2!.trim().isNotEmpty) item2!.trim(),
        if (item3 != null && item3!.trim().isNotEmpty) item3!.trim(),
      ];

  int get filledItemsCount => items.length;

  /// Combined formatted string for cloud synchronization (conforming to schema.sql).
  String get combinedContent {
    final buffer = StringBuffer();
    buffer.writeln('1. $item1');
    if (item2 != null && item2!.trim().isNotEmpty) {
      buffer.writeln('2. ${item2!.trim()}');
    }
    if (item3 != null && item3!.trim().isNotEmpty) {
      buffer.writeln('3. ${item3!.trim()}');
    }
    if (reflection != null && reflection!.trim().isNotEmpty) {
      buffer.writeln('\nReflexión: ${reflection!.trim()}');
    }
    return buffer.toString().trim();
  }

  factory GratitudeEntry.fromRow(Map<String, dynamic> row) {
    return GratitudeEntry(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? 'local_user',
      entryDate: row['entry_date'] as String,
      item1: row['item1'] as String,
      item2: row['item2'] as String?,
      item3: row['item3'] as String?,
      reflection: row['reflection'] as String?,
      promptUsed: row['prompt_used'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      clientId: row['client_id'] as String?,
      clientUpdatedAt: row['client_updated_at'] != null
          ? DateTime.tryParse(row['client_updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'user_id': userId,
      'entry_date': entryDate,
      'item1': item1,
      'item2': item2,
      'item3': item3,
      'reflection': reflection,
      'prompt_used': promptUsed,
      'created_at': createdAt.toIso8601String(),
      'client_id': clientId ?? id,
      'client_updated_at': (clientUpdatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  GratitudeEntry copyWith({
    String? item1,
    String? item2,
    String? item3,
    String? reflection,
    String? promptUsed,
    DateTime? clientUpdatedAt,
  }) {
    return GratitudeEntry(
      id: id,
      userId: userId,
      entryDate: entryDate,
      item1: item1 ?? this.item1,
      item2: item2 ?? this.item2,
      item3: item3 ?? this.item3,
      reflection: reflection ?? this.reflection,
      promptUsed: promptUsed ?? this.promptUsed,
      createdAt: createdAt,
      clientId: clientId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    );
  }
}

/// Curated philosophical wisdom quote for the day.
class StoicQuote {
  const StoicQuote({
    required this.quote,
    required this.author,
    required this.school,
  });

  final String quote;
  final String author;
  final String school;

  static const List<StoicQuote> curatedQuotes = [
    StoicQuote(
      quote: 'No nos afecta lo que sucede, sino lo que pensamos acerca de lo que sucede.',
      author: 'Epicteto',
      school: 'Estoicismo',
    ),
    StoicQuote(
      quote: 'Cuando te levantes por la mañana, piensa en el privilegio precioso de estar vivo: respirar, pensar, disfrutar, amar.',
      author: 'Marco Aurelio',
      school: 'Meditaciones',
    ),
    StoicQuote(
      quote: 'La verdadera felicidad consiste en disfrutar del presente sin la ansiosa dependencia del futuro.',
      author: 'Séneca',
      school: 'Cartas a Lucilio',
    ),
    StoicQuote(
      quote: 'La tranquilidad no es otra cosa que el buen orden y gobierno de la propia mente.',
      author: 'Marco Aurelio',
      school: 'Meditaciones',
    ),
    StoicQuote(
      quote: 'No es que tengamos poco tiempo vital, sino que desperdiciamos una inmensa cantidad.',
      author: 'Séneca',
      school: 'De la brevedad de la vida',
    ),
    StoicQuote(
      quote: 'El hierro se oxida por falta de uso; el agua pierde su frescura por estancamiento; la inacción marchita el vigor intelectual.',
      author: 'Leonardo da Vinci',
      school: 'Renacimiento & Enfoque',
    ),
    StoicQuote(
      quote: 'La riqueza suprema no radica en acumular posesiones, sino en reducir las dependencias innecesarias.',
      author: 'Epicteto',
      school: 'Enquiridión',
    ),
    StoicQuote(
      quote: 'El alma se tiñe del color de sus pensamientos.',
      author: 'Marco Aurelio',
      school: 'Meditaciones',
    ),
    StoicQuote(
      quote: 'Sufrimos más a menudo en la imaginación que en la realidad.',
      author: 'Séneca',
      school: 'Cartas a Lucilio',
    ),
    StoicQuote(
      quote: 'Primero conócete a ti mismo; luego adórnate en consecuencia.',
      author: 'Epicteto',
      school: 'Disertaciones',
    ),
  ];

  static StoicQuote forDate(DateTime date) {
    final index = (date.year * 365 + date.month * 31 + date.day) % curatedQuotes.length;
    return curatedQuotes[index];
  }
}
