import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Categories of thinkers and masters of discipline.
enum ThinkerCategory {
  stoic('stoic', 'Estoicos', Icons.account_balance_rounded, AppTheme.accentEmerald),
  greek('greek', 'Grecia clásica', Icons.auto_stories_rounded, AppTheme.primaryContainer),
  lateRoman('late_roman', 'Roma tardía', Icons.temple_buddhist_rounded, Color(0xFF6366F1)),
  spartanWarrior('spartan_warrior', 'Esparta & Guerreros', Icons.shield_rounded, AppTheme.error),
  easternMeditator('eastern_meditator', 'Oriente & Meditadores', Icons.self_improvement_rounded, Color(0xFF0D9488)),
  medievalMystic('medieval_mystic', 'Medievales & Místicos', Icons.church_rounded, AppTheme.accentAmber),
  modern('modern', 'Modernos', Icons.psychology_rounded, Color(0xFF8B5CF6)),
  contemporary('contemporary', 'Contemporáneos', Icons.lightbulb_rounded, Color(0xFFEC4899)),
  mexicanLatam('mexican_latam', 'México & Latam', Icons.public_rounded, Color(0xFF10B981));

  const ThinkerCategory(this.code, this.label, this.icon, this.accentColor);

  final String code;
  final String label;
  final IconData icon;
  final Color accentColor;

  static ThinkerCategory fromCode(String code) {
    return ThinkerCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => ThinkerCategory.stoic,
    );
  }
}

/// Domain model representing a philosopher, thinker, or discipline master.
@immutable
class Thinker {
  const Thinker({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.eraLabel,
    this.origin,
    required this.keyIdea,
    this.keyWork,
    this.requiresReligious = false,
    this.unlockXp = 0,
    this.isUnlocked = true,
    this.isFavorite = false,
  });

  final String id;
  final String slug;
  final String name;
  final String category; // ThinkerCategory.code
  final String eraLabel;
  final String? origin;
  final String keyIdea;
  final String? keyWork;
  final bool requiresReligious;
  final int unlockXp;
  final bool isUnlocked;
  final bool isFavorite;

  ThinkerCategory get categoryEnum => ThinkerCategory.fromCode(category);

  Thinker copyWith({
    String? id,
    String? slug,
    String? name,
    String? category,
    String? eraLabel,
    String? origin,
    String? keyIdea,
    String? keyWork,
    bool? requiresReligious,
    int? unlockXp,
    bool? isUnlocked,
    bool? isFavorite,
  }) {
    return Thinker(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      category: category ?? this.category,
      eraLabel: eraLabel ?? this.eraLabel,
      origin: origin ?? this.origin,
      keyIdea: keyIdea ?? this.keyIdea,
      keyWork: keyWork ?? this.keyWork,
      requiresReligious: requiresReligious ?? this.requiresReligious,
      unlockXp: unlockXp ?? this.unlockXp,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Thinker.fromMap(Map<String, dynamic> map, {bool isUnlocked = true, bool isFavorite = false}) {
    return Thinker(
      id: map['id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'stoic',
      eraLabel: map['era_label']?.toString() ?? '',
      origin: map['origin']?.toString(),
      keyIdea: map['key_idea']?.toString() ?? '',
      keyWork: map['key_work']?.toString(),
      requiresReligious: (map['requires_religious'] == 1 || map['requires_religious'] == true),
      unlockXp: (map['unlock_xp'] as num?)?.toInt() ?? 0,
      isUnlocked: isUnlocked,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'category': category,
      'era_label': eraLabel,
      'origin': origin,
      'key_idea': keyIdea,
      'key_work': keyWork,
      'requires_religious': requiresReligious ? 1 : 0,
      'unlock_xp': unlockXp,
    };
  }
}
