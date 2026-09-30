import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/thinker.dart';
import '../controllers/thinkers_controller.dart';
import 'thinker_detail_sheet.dart';

/// Card displaying a philosopher / thinker in the library list.
class ThinkerCard extends ConsumerWidget {
  const ThinkerCard({super.key, required this.thinker});

  final Thinker thinker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = thinker.categoryEnum;
    final isFav = thinker.isFavorite;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFav
              ? AppTheme.accentRose.withValues(alpha: 0.3)
              : AppTheme.outlineVariant.withValues(alpha: 0.8),
          width: isFav ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ThinkerDetailSheet.show(context, thinker),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Badge + Heart Action
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 12, color: cat.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          cat.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cat.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ref.read(thinkersRepositoryProvider).toggleFavorite(
                            thinkerId: thinker.id,
                            isFavorite: !isFav,
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: isFav ? AppTheme.accentRose : AppTheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Thinker Name
              Text(
                thinker.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),

              // Era & Origin
              Row(
                children: [
                  Text(
                    thinker.eraLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (thinker.origin != null) ...[
                    Text(
                      ' · ${thinker.origin}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Key Idea with Quotation Styling
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: cat.accentColor, width: 3),
                  ),
                ),
                child: Text(
                  '«${thinker.keyIdea}»',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),

              if (thinker.keyWork != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 14, color: AppTheme.outline),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        thinker.keyWork!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
