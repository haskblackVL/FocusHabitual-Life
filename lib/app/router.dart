import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/security/module_security_gate.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/onboarding/onboarding_screen.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/cycle/presentation/woman_cycle_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/gratitude/presentation/gratitude_screen.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/habits/presentation/master_habits_catalog_screen.dart';
import '../features/launcher/presentation/launcher_screen.dart';
import '../features/nofap/presentation/nofap_education_screen.dart';
import '../features/nofap/presentation/nofap_screen.dart';
import '../features/pomodoro/presentation/pomodoro_screen.dart';
import '../features/religion/presentation/religion_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/wellness/presentation/wellness_screen.dart';
import '../features/philosophy/presentation/thinkers_library_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Riverpod provider for GoRouter configuration.
final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final isAuth = authRepo.isAuthenticated;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isAuth ? '/launcher' : '/login',
    refreshListenable: authRepo,
    redirect: (context, state) {
      final isCurrentlyAuth = authRepo.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/onboarding' || loc == '/login';

      if (!isCurrentlyAuth && !isAuthRoute) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/nofap',
        builder: (context, state) => const ModuleSecurityGate(
          moduleKey: 'nofap',
          moduleTitle: 'NoFap & Autocontrol',
          child: NofapScreen(),
        ),
      ),
      GoRoute(
        path: '/nofap-education',
        builder: (context, state) => const NofapEducationScreen(),
      ),
      GoRoute(
        path: '/cycle',
        builder: (context, state) => const ModuleSecurityGate(
          moduleKey: 'cycle',
          moduleTitle: 'Salud & Ciclos',
          child: WomanCycleScreen(),
        ),
      ),
      GoRoute(
        path: '/gratitude',
        builder: (context, state) => const GratitudeScreen(),
      ),
      GoRoute(
        path: '/habits-catalog',
        builder: (context, state) => const MasterHabitsCatalogScreen(),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const ModuleSecurityGate(
          moduleKey: 'finance',
          moduleTitle: 'Finanzas',
          child: FinanceScreen(),
        ),
      ),
      GoRoute(
        path: '/religion',
        builder: (context, state) => const ReligionScreen(),
      ),
      GoRoute(
        path: '/wellness',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '0') ?? 0;
          return WellnessScreen(initialTabIndex: initialTab);
        },
      ),
      GoRoute(
        path: '/thinkers',
        builder: (context, state) => const ThinkersLibraryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/launcher',
                builder: (context, state) => const LauncherScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (context, state) => const HabitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pomodoro',
                builder: (context, state) => const PomodoroScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Scaffold shell with elegant Bottom Navigation.
class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE2E7FF), width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded),
              label: 'Hábitos',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_empty_rounded),
              selectedIcon: Icon(Icons.hourglass_full_rounded),
              label: 'Pomodoro',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Score',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded),
              selectedIcon: Icon(Icons.tune),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
