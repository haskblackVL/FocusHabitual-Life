import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import 'security_controller.dart';

/// Provider for dynamic application title reflecting Discreet Mode alias if active.
final discreetAppTitleProvider = Provider<String>((ref) {
  final settings = ref.watch(securityControllerProvider);
  if (settings.discreetModeEnabled) {
    return settings.discreetAppAlias;
  }
  return 'FocusHabitual Life';
});

/// Executive privacy mask widget that protects confidential content when Discreet Mode is active.
/// Provides an intuitive tap-to-reveal toggle with smooth animation.
class DiscreetMaskWidget extends ConsumerStatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const DiscreetMaskWidget({
    super.key,
    required this.child,
    this.title = 'Contenido Confidencial',
    this.subtitle = 'Toca para revelar información',
    this.padding,
    this.borderRadius = 16,
  });

  @override
  ConsumerState<DiscreetMaskWidget> createState() => _DiscreetMaskWidgetState();
}

class _DiscreetMaskWidgetState extends ConsumerState<DiscreetMaskWidget> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(securityControllerProvider);

    // If discreet mode is disabled, render child directly
    if (!settings.discreetModeEnabled) {
      return widget.child;
    }

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: _isRevealed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _isRevealed = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_off_outlined,
                        size: 13,
                        color: AppTheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ocultar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          widget.child,
        ],
      ),
      secondChild: InkWell(
        onTap: () {
          setState(() {
            _isRevealed = true;
          });
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.visibility_off_rounded,
                  color: AppTheme.primaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Revelar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
