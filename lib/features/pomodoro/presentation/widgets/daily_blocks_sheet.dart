import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../../../core/local_db/database.dart';
import '../../domain/pomodoro_models.dart';
import '../controllers/pomodoro_controller.dart';

/// Bottom sheet displaying the Daily Focus Planner blocks.
class DailyBlocksSheet extends ConsumerStatefulWidget {
  const DailyBlocksSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DailyBlocksSheet(),
    );
  }

  @override
  ConsumerState<DailyBlocksSheet> createState() => _DailyBlocksSheetState();
}

class _DailyBlocksSheetState extends ConsumerState<DailyBlocksSheet> {
  List<Map<String, dynamic>> _blocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  void _loadBlocks() {
    try {
      final items = AppDatabase.getDefaultDailyBlockItems();
      setState(() {
        _blocks = items;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(pomodoroProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planificador de Bloques',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Plan de Implementación Inmediata',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PLANTILLA REUTILIZABLE',
                    style: AppTheme.labelCaps(fontSize: 9, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _blocks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _blocks[index];
                    final startTime = item['start_time'] as String? ?? '08:00';
                    final duration = item['duration_minutes'] as int? ?? 25;
                    final modeKey = item['mode_key'] as String? ?? 'classic';
                    final workTypeKey = item['work_type'] as String? ?? 'shallow_work';
                    final label = item['label'] as String? ?? 'Bloque';
                    final isDeepWork = workTypeKey == 'deep_work';

                    return InkWell(
                      onTap: () {
                        final mode = PomodoroTimerMode.fromKey(modeKey);
                        final workType = WorkType.fromKey(workTypeKey);
                        notifier.setWorkType(workType);
                        notifier.setMode(mode);
                        notifier.setTag(label);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDeepWork
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : AppTheme.outlineVariant.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDeepWork
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    startTime,
                                    style: AppTheme.numeric(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDeepWork ? AppTheme.primary : AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${duration}m',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDeepWork
                                              ? AppTheme.primary.withValues(alpha: 0.15)
                                              : AppTheme.accentEmerald.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isDeepWork ? 'DEEP WORK' : 'MANTENIMIENTO',
                                          style: AppTheme.labelCaps(
                                            fontSize: 8,
                                            color: isDeepWork ? AppTheme.primary : AppTheme.accentEmerald,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        modeKey.toUpperCase(),
                                        style: AppTheme.labelCaps(
                                          fontSize: 9,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.play_circle_outline_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _showAddBlockDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Añadir Bloque Personalizado',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBlockDialog() {
    final labelCtrl = TextEditingController(text: 'Deep Work — Desarrollo core');
    final timeCtrl = TextEditingController(text: '14:00');
    final durationCtrl = TextEditingController(text: '50');
    PomodoroTimerMode selectedMode = PomodoroTimerMode.extended;
    WorkType selectedWorkType = WorkType.deepWork;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Nuevo Bloque de Enfoque',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÍTULO DEL BLOQUE',
                    style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HORA INICIO', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: timeCtrl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.surfaceContainerLow,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MINUTOS', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.surfaceContainerLow,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text('TIPO DE ESFUERZO', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Deep Work'),
                          selected: selectedWorkType == WorkType.deepWork,
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedWorkType = WorkType.deepWork);
                          },
                          selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selectedWorkType == WorkType.deepWork ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Mantenimiento'),
                          selected: selectedWorkType == WorkType.shallowWork,
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedWorkType = WorkType.shallowWork);
                          },
                          selectedColor: AppTheme.accentEmerald.withValues(alpha: 0.2),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selectedWorkType == WorkType.shallowWork ? AppTheme.accentEmerald : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text('MODO TEMPORIZADOR', style: AppTheme.labelCaps(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PomodoroTimerMode>(
                    initialValue: selectedMode,
                    dropdownColor: AppTheme.surfaceContainerLow,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: PomodoroTimerMode.values.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          m.name,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMode = val;
                          if (val.workMinutes != null) {
                            durationCtrl.text = val.workMinutes.toString();
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.outline)),
              ),
              ElevatedButton(
                onPressed: () {
                  final dur = int.tryParse(durationCtrl.text) ?? selectedMode.workMinutes ?? 25;
                  AppDatabase.addDailyBlockItem(
                    startTime: timeCtrl.text.trim(),
                    durationMinutes: dur,
                    modeKey: selectedMode.key,
                    workType: selectedWorkType.key,
                    label: labelCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _loadBlocks();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Añadir',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
