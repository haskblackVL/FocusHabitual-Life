import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand_logo.dart';
import 'controllers/nofap_controller.dart';
import 'widgets/cooling_protocol_sheet.dart';

/// Full Executive Precision NoFap & Self-Mastery Screen.
class NofapScreen extends ConsumerStatefulWidget {
  const NofapScreen({super.key});

  @override
  ConsumerState<NofapScreen> createState() => _NofapScreenState();
}

class _NofapScreenState extends ConsumerState<NofapScreen> {
  final _reasonInputController = TextEditingController();

  @override
  void dispose() {
    _reasonInputController.dispose();
    super.dispose();
  }

  void _showRelapseDialog() {
    String selectedReason = 'both';
    final triggerController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.refresh_rounded, color: AppTheme.accentAmber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Registrar Recaída',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El reinicio no borra tu aprendizaje neuroquímico. Identifica el detonante para fortalecer tu protocolo.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipo de evento:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'both', child: Text('Pornografía + Masturbación')),
                    DropdownMenuItem(value: 'porn', child: Text('Solo Pornografía')),
                    DropdownMenuItem(value: 'masturbation', child: Text('Solo Masturbación')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: triggerController,
                  decoration: const InputDecoration(
                    labelText: 'Detonante principal',
                    hintText: 'Ej. Insomnio, soledad, estrés laboral...',
                    prefixIcon: Icon(Icons.flash_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota de aprendizaje',
                    hintText: '¿Qué haré diferente la próxima vez?',
                    prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                await ref.read(nofapControllerProvider.notifier).recordRelapse(
                      reason: selectedReason,
                      trigger: triggerController.text.trim(),
                      note: noteController.text.trim(),
                    );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Racha reiniciada. Firmeza y disciplina hacia adelante.'),
                    backgroundColor: AppTheme.onSurface,
                  ),
                );
              },
              child: const Text('Confirmar y Reiniciar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReasonSheet() {
    _reasonInputController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Añadir Motivo Ancla',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Tu ancla psicológica para recordar en momentos de vulnerabilidad.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonInputController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej. Mayor claridad mental y respeto propio...',
                prefixIcon: Icon(Icons.anchor_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final txt = _reasonInputController.text.trim();
                if (txt.isNotEmpty) {
                  ref.read(nofapReasonsProvider.notifier).addReason(txt);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Guardar Motivo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(nofapControllerProvider);
    final reasonsAsync = ref.watch(nofapReasonsProvider);
    final historyAsync = ref.watch(nofapHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
            border: const Border(
              bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const FocusHabitualLogo(size: 30),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autodominio & NoFap',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'REINICIO NEUROQUÍMICO 90 DÍAS',
                        style: AppTheme.labelCaps(
                          fontSize: 9,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.school_outlined),
                    tooltip: 'Educación Neuroquímica',
                    onPressed: () => context.push('/nofap-education'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Military / Executive Telemetry Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RACHA ACTIVA EN VIVO',
                        style: AppTheme.labelCaps(
                          fontSize: 11,
                          color: AppTheme.accentEmerald,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Digital Clock Matrix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeSegment(streak.daysDisplay, 'DÍAS'),
                      _buildColonDivider(),
                      _buildTimeSegment(streak.hoursDisplay, 'HORAS'),
                      _buildColonDivider(),
                      _buildTimeSegment(streak.minutesDisplay, 'MIN'),
                      _buildColonDivider(),
                      _buildTimeSegment(streak.secondsDisplay, 'SEG'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 90-Day Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reinicio Dopaminérgico (Meta: 90 Días)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${streak.percent90Days}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: streak.progress90Days,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Mastery Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await ref.read(nofapControllerProvider.notifier).recordCheckin();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Impulso superado! +15 XP acreditados a tu perfil.'),
                            backgroundColor: AppTheme.accentEmerald,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Impulso Superado (+15 XP)'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.error,
                  ),
                  onPressed: () => CoolingProtocolSheet.show(context),
                  icon: const Icon(Icons.ac_unit_rounded),
                  tooltip: 'Protocolo SOS',
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.outlineVariant,
                    foregroundColor: AppTheme.onSurfaceVariant,
                  ),
                  onPressed: _showRelapseDialog,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Registrar Recaída',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Anchor Reasons Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Motivos Ancla',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddReasonSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reasons List
            reasonsAsync.when(
              data: (reasons) {
                if (reasons.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Text(
                      'No tienes motivos ancla registrados. Añade tu por qué para fortalecerte ante impulsos.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }
                return Column(
                  children: reasons.map((reason) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.anchor_rounded, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason.reasonText,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.outline),
                            onPressed: () => ref.read(nofapReasonsProvider.notifier).deleteReason(reason.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Relapse History & Patterns
            Text(
              'Historial de Recaídas & Patrones',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppTheme.accentEmerald, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Historial limpio. Mantén el enfoque y la consistencia.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: history.map((item) {
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.occurredAt);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.reasonLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.error,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.outline),
                              ),
                            ],
                          ),
                          if (item.note != null && item.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.note!,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSegment(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.labelCaps(
            fontSize: 9,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildColonDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        ':',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.outline,
        ),
      ),
    );
  }
}
