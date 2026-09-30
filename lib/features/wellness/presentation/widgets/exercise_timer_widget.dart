import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme.dart';
import '../../domain/challenge_data.dart';

/// Interactive multi-exercise countdown timer supporting sequential exercise sessions
/// with a 10-second preparation countdown before each exercise starts.
class ExerciseTimerWidget extends StatefulWidget {
  final int initialMinutes;
  final List<ExerciseStep>? steps;
  final VoidCallback? onCompleted;
  final ValueChanged<int>? onStepChanged;
  final int initialStepIndex;

  const ExerciseTimerWidget({
    super.key,
    this.initialMinutes = 5,
    this.steps,
    this.onCompleted,
    this.onStepChanged,
    this.initialStepIndex = 0,
  });

  @override
  State<ExerciseTimerWidget> createState() => _ExerciseTimerWidgetState();
}

class _ExerciseTimerWidgetState extends State<ExerciseTimerWidget> {
  // Legacy / fallback single timer fields
  late int _totalSeconds;
  late int _secondsRemaining;

  // Multi-step session fields
  late List<ExerciseStep> _steps;
  late int _currentStepIndex;
  bool _isPreparing = true;
  late int _prepSecondsRemaining;
  late int _exerciseSecondsRemaining;
  bool _isSessionFinished = false;

  Timer? _timer;
  bool _isRunning = false;

  bool get _hasSteps => _steps.isNotEmpty;

  ExerciseStep get _currentStep =>
      _steps[_currentStepIndex.clamp(0, _steps.length - 1)];

  @override
  void initState() {
    super.initState();
    _steps = widget.steps ?? [];
    _currentStepIndex = widget.initialStepIndex.clamp(
      0,
      _steps.isEmpty ? 0 : _steps.length - 1,
    );

    if (_hasSteps) {
      _initStep(_currentStepIndex);
    } else {
      _totalSeconds = widget.initialMinutes * 60;
      _secondsRemaining = _totalSeconds;
    }
  }

  void _initStep(int index) {
    _currentStepIndex = index.clamp(0, _steps.length - 1);
    final step = _currentStep;
    _isPreparing = true;
    _prepSecondsRemaining = step.preparationSeconds; // 10s default
    _exerciseSecondsRemaining = step.durationSeconds;
    _isSessionFinished = false;
  }

  @override
  void didUpdateWidget(covariant ExerciseTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps != oldWidget.steps) {
      _steps = widget.steps ?? [];
      if (!_isRunning) {
        if (_hasSteps) {
          _initStep(widget.initialStepIndex);
        } else {
          _totalSeconds = widget.initialMinutes * 60;
          _secondsRemaining = _totalSeconds;
        }
        setState(() {});
      }
    } else if (!_hasSteps && oldWidget.initialMinutes != widget.initialMinutes && !_isRunning) {
      _totalSeconds = widget.initialMinutes * 60;
      _secondsRemaining = _totalSeconds;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_hasSteps) {
        // Fallback simple timer
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          HapticFeedback.heavyImpact();
          widget.onCompleted?.call();
        }
        return;
      }

      // Multi-step session flow
      if (_isPreparing) {
        if (_prepSecondsRemaining > 1) {
          setState(() => _prepSecondsRemaining--);
        } else {
          // Transition from 10s preparation to active exercise!
          HapticFeedback.mediumImpact();
          setState(() {
            _isPreparing = false;
            _prepSecondsRemaining = 0;
          });
        }
      } else {
        if (_exerciseSecondsRemaining > 1) {
          setState(() => _exerciseSecondsRemaining--);
        } else {
          // Exercise completed!
          HapticFeedback.heavyImpact();
          if (_currentStepIndex < _steps.length - 1) {
            // Auto advance to next exercise's 10s preparation
            setState(() {
              _currentStepIndex++;
              _initStep(_currentStepIndex);
            });
            widget.onStepChanged?.call(_currentStepIndex);
          } else {
            // Whole routine is completed!
            _timer?.cancel();
            setState(() {
              _isRunning = false;
              _isSessionFinished = true;
              _exerciseSecondsRemaining = 0;
            });
            widget.onCompleted?.call();
          }
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_hasSteps) {
        _initStep(_currentStepIndex);
      } else {
        _secondsRemaining = _totalSeconds;
      }
    });
  }

  void _skipPreparation() {
    if (!_isPreparing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isPreparing = false;
      _prepSecondsRemaining = 0;
    });
    if (!_isRunning) {
      _startTimer();
    }
  }

  void _nextStep() {
    if (!_hasSteps || _currentStepIndex >= _steps.length - 1) return;
    HapticFeedback.selectionClick();
    final wasRunning = _isRunning;
    _timer?.cancel();
    setState(() {
      _currentStepIndex++;
      _initStep(_currentStepIndex);
    });
    widget.onStepChanged?.call(_currentStepIndex);
    if (wasRunning) {
      _startTimer();
    }
  }

  void _previousStep() {
    if (!_hasSteps || _currentStepIndex <= 0) return;
    HapticFeedback.selectionClick();
    final wasRunning = _isRunning;
    _timer?.cancel();
    setState(() {
      _currentStepIndex--;
      _initStep(_currentStepIndex);
    });
    widget.onStepChanged?.call(_currentStepIndex);
    if (wasRunning) {
      _startTimer();
    }
  }

  void _jumpToStep(int index) {
    if (!_hasSteps || index == _currentStepIndex) return;
    HapticFeedback.selectionClick();
    final wasRunning = _isRunning;
    _timer?.cancel();
    setState(() {
      _currentStepIndex = index;
      _initStep(_currentStepIndex);
    });
    widget.onStepChanged?.call(_currentStepIndex);
    if (wasRunning) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSteps) {
      return _buildSimpleTimer(context);
    }
    return _buildMultiStepSessionTimer(context);
  }

  /// Multi-exercise flow with 10s preparation badge, animated countdown dial & controls
  Widget _buildMultiStepSessionTimer(BuildContext context) {
    final step = _currentStep;
    final totalPrep = step.preparationSeconds > 0 ? step.preparationSeconds : 10;
    final totalEx = step.durationSeconds > 0 ? step.durationSeconds : 40;

    final prepProgress = _isPreparing
        ? ((totalPrep - _prepSecondsRemaining) / totalPrep).clamp(0.0, 1.0)
        : 1.0;
    final exProgress = !_isPreparing
        ? ((totalEx - _exerciseSecondsRemaining) / totalEx).clamp(0.0, 1.0)
        : 0.0;

    final prepColor = const Color(0xFFFFB300); // Amber 600
    final activeColor = AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isPreparing
              ? prepColor.withValues(alpha: 0.35)
              : activeColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Step Counter & Phase Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PASO ${_currentStepIndex + 1} DE ${_steps.length}',
                  style: AppTheme.labelCaps(
                    color: AppTheme.onSurface,
                    letterSpacing: 0.08,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isSessionFinished
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : (_isPreparing
                          ? prepColor.withValues(alpha: 0.15)
                          : activeColor.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSessionFinished
                        ? AppTheme.success.withValues(alpha: 0.4)
                        : (_isPreparing
                            ? prepColor.withValues(alpha: 0.4)
                            : activeColor.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSessionFinished
                          ? Icons.check_circle_rounded
                          : (_isPreparing
                              ? Icons.hourglass_top_rounded
                              : Icons.fitness_center_rounded),
                      size: 14,
                      color: _isSessionFinished
                          ? AppTheme.success
                          : (_isPreparing ? prepColor : activeColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSessionFinished
                          ? '¡SESIÓN COMPLETA!'
                          : (_isPreparing ? '¡PREPÁRATE! (10s)' : 'EN EJECUCIÓN'),
                      style: AppTheme.labelCaps(
                        color: _isSessionFinished
                            ? AppTheme.success
                            : (_isPreparing ? prepColor : activeColor),
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Current Exercise Title & Category in focus
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          if (step.category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                step.category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.05,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Circular Countdown Dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: _isSessionFinished
                      ? 1.0
                      : (_isPreparing ? prepProgress : exProgress),
                  strokeWidth: 9,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isSessionFinished
                        ? AppTheme.success
                        : (_isPreparing ? prepColor : activeColor),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSessionFinished) ...[
                    const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 36),
                    const SizedBox(height: 4),
                    Text(
                      '¡LISTO!',
                      style: AppTheme.numeric(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                  ] else if (_isPreparing) ...[
                    Text(
                      '${_prepSecondsRemaining}s',
                      style: AppTheme.numeric(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: prepColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'PREPARACIÓN',
                      style: AppTheme.labelCaps(
                        color: prepColor,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${_exerciseSecondsRemaining ~/ 60}:${(_exerciseSecondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: AppTheme.numeric(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _isRunning ? 'ACTIVO' : 'PAUSADO',
                      style: AppTheme.labelCaps(
                        color: _isRunning ? activeColor : AppTheme.onSurfaceVariant,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Instructions or Preparation Hint Box
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isPreparing
                ? Container(
                    key: const ValueKey('prep_box'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: prepColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: prepColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.self_improvement_rounded, color: prepColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Ajusta tu postura e inhala con calma',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: prepColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _skipPreparation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: prepColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 14, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  'Comenzar ya (Saltar 10s)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('exercise_box'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: Text(
                      step.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Horizontal Sequence Step Dots (interactive)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final isCurrent = i == _currentStepIndex;
              final isPassed = i < _currentStepIndex || _isSessionFinished;

              return GestureDetector(
                onTap: () => _jumpToStep(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 24 : 10,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (_isPreparing ? prepColor : activeColor)
                        : (isPassed ? AppTheme.success : AppTheme.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Playback & Step Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Step Button
              IconButton.outlined(
                onPressed: _currentStepIndex > 0 ? _previousStep : null,
                icon: const Icon(Icons.skip_previous_rounded, size: 22),
                tooltip: 'Ejercicio anterior',
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),

              // Play / Pause Main Button
              FilledButton.icon(
                onPressed: _isSessionFinished ? _resetTimer : _toggleTimer,
                style: FilledButton.styleFrom(
                  backgroundColor: _isSessionFinished
                      ? AppTheme.success
                      : (_isPreparing ? prepColor : activeColor),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  _isSessionFinished
                      ? Icons.replay_rounded
                      : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  size: 22,
                ),
                label: Text(
                  _isSessionFinished
                      ? 'Repetir Sesión'
                      : (_isRunning ? 'Pausar' : 'Iniciar Sesión'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Next Step Button
              IconButton.outlined(
                onPressed: _currentStepIndex < _steps.length - 1 ? _nextStep : null,
                icon: const Icon(Icons.skip_next_rounded, size: 22),
                tooltip: 'Siguiente ejercicio',
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fallback single timer for simple meditation or generic countdown
  Widget _buildSimpleTimer(BuildContext context) {
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final progress = _totalSeconds > 0
        ? (1.0 - (_secondsRemaining / _totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$mins:$secs',
                    style: AppTheme.numeric(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isRunning
                        ? 'EN CURSO'
                        : (_secondsRemaining == 0 ? 'COMPLETADO' : 'TEMPORIZADOR'),
                    style: AppTheme.labelCaps(
                      color: _isRunning ? AppTheme.primary : AppTheme.onSurfaceVariant,
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Reiniciar',
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _toggleTimer,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                label: Text(
                  _isRunning ? 'Pausar' : 'Iniciar Sesión',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
