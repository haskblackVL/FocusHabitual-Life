import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../domain/cycle_models.dart';
import '../controllers/cycle_controller.dart';

/// Notion / Things 3 executive style layer filter chips for the cycle calendar.
class CycleLayerChips extends ConsumerWidget {
  const CycleLayerChips({super.key});

  static Color _getLayerColor(CycleLayer layer) {
    switch (layer) {
      case CycleLayer.period:
        return AppTheme.accentRose;
      case CycleLayer.ovulation:
        return AppTheme.accentAmber;
      case CycleLayer.pregnancy:
        return const Color(0xFFAB47BC); // Soft Royal Violet
      case CycleLayer.fertility:
        return AppTheme.accentEmerald;
      case CycleLayer.symptoms:
        return AppTheme.accentSky;
    }
  }

  static IconData _getLayerIcon(CycleLayer layer) {
    switch (layer) {
      case CycleLayer.period:
        return Icons.water_drop_rounded;
      case CycleLayer.ovulation:
        return Icons.thermostat_rounded;
      case CycleLayer.pregnancy:
        return Icons.pregnant_woman_rounded;
      case CycleLayer.fertility:
        return Icons.volunteer_activism_rounded;
      case CycleLayer.symptoms:
        return Icons.healing_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayers = ref.watch(cycleActiveLayersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CAPAS DEL CALENDARIO',
              style: AppTheme.labelCaps(
                color: AppTheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
            if (activeLayers.length < CycleLayer.values.length)
              InkWell(
                onTap: () => ref.read(cycleActiveLayersProvider.notifier).showAll(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ver Todas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CycleLayer.values.map((layer) {
              final isSelected = activeLayers.contains(layer);
              final layerColor = _getLayerColor(layer);
              final icon = _getLayerIcon(layer);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(cycleActiveLayersProvider.notifier).toggleLayer(layer);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? layerColor.withValues(alpha: 0.12)
                          : AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? layerColor.withValues(alpha: 0.6)
                            : AppTheme.outlineVariant,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? layerColor : AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          layer.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: layerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
