import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/analytics_repository.dart';
import '../../domain/analytics_data.dart';

/// Provider for AnalyticsRepository.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return AnalyticsRepository(currentUserId: user?.id);
});

/// Notifier managing currently selected time horizon filter (week, month, year).
class AnalyticsTimeRangeNotifier extends Notifier<TimeRange> {
  @override
  TimeRange build() => TimeRange.week;

  void setRange(TimeRange range) => state = range;
}

final analyticsTimeRangeProvider =
    NotifierProvider<AnalyticsTimeRangeNotifier, TimeRange>(
  AnalyticsTimeRangeNotifier.new,
);

/// Async notifier managing the computed analytics summary.
final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsSummary>(
  AnalyticsController.new,
);

class AnalyticsController extends AsyncNotifier<AnalyticsSummary> {
  AnalyticsRepository get _repo => ref.read(analyticsRepositoryProvider);

  @override
  FutureOr<AnalyticsSummary> build() async {
    final range = ref.watch(analyticsTimeRangeProvider);
    final repo = ref.watch(analyticsRepositoryProvider);
    return repo.getSummary(range);
  }

  /// Sets the active time range filter and triggers re-computation.
  void setTimeRange(TimeRange range) {
    ref.read(analyticsTimeRangeProvider.notifier).setRange(range);
  }

  /// Explicitly reloads metrics from local SQLite.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final range = ref.read(analyticsTimeRangeProvider);
    state = await AsyncValue.guard(() => _repo.getSummary(range));
  }
}
