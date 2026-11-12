import 'package:docnook/app/shell.dart';
import 'package:docnook/features/home/presentation/home_screen.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/onboarding/presentation/onboarding_screen.dart';
import 'package:docnook/features/settings/presentation/settings_screen.dart';
import 'package:docnook/features/tools/presentation/tools_screen.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/viewer_host.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({bool onboarded = true}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: onboarded ? '/home' : '/welcome',
  // Any unknown location (stale deep link, file URI) goes Home instead of
  // showing an error page.
  errorBuilder: (_, _) => const _BadRoute(),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/files', builder: (_, _) => const FilesScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/tools', builder: (_, _) => const ToolsScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/view',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final request = state.extra;
        if (request is! OpenRequest) return const _BadRoute();
        return ViewerHost(key: ValueKey(request), request: request);
      },
    ),
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const SettingsScreen(),
    ),
  ],
);

/// Shown only if a route is opened without its arguments (e.g. after the
/// system restores a killed process); goes straight back home.
class _BadRoute extends StatelessWidget {
  const _BadRoute();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
    return const Scaffold();
  }
}
