import 'package:docnook/app/shell.dart';
import 'package:docnook/features/home/presentation/home_screen.dart';
import 'package:docnook/features/library/presentation/collection_screen.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/onboarding/presentation/onboarding_screen.dart';
import 'package:docnook/features/scan/presentation/camera_screen.dart';
import 'package:docnook/features/scan/presentation/scan_export_screen.dart';
import 'package:docnook/features/scan/presentation/scan_launcher.dart';
import 'package:docnook/features/scan/presentation/scan_review_screen.dart';
import 'package:docnook/features/search/presentation/search_screen.dart';
import 'package:docnook/features/settings/presentation/legal_screen.dart';
import 'package:docnook/features/settings/presentation/settings_screen.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
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
      path: '/search',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const SearchScreen(),
    ),
    GoRoute(
      path: '/collection/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const _BadRoute();
        return CollectionScreen(id: id, name: state.extra as String? ?? '');
      },
    ),
    GoRoute(
      path: '/scan/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const _BadRoute();
        return ScanReviewScreen(sessionId: id);
      },
      routes: [
        GoRoute(
          path: 'export',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return const _BadRoute();
            return ScanExportScreen(sessionId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/scan-camera',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra;
        if (args is! ScanCameraArgs) return const _BadRoute();
        return ScanCameraScreen(args: args);
      },
    ),
    GoRoute(
      path: '/tool/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final tool = ToolId.byName(state.pathParameters['id'] ?? '');
        if (tool == null) return const _BadRoute();
        final extra = state.extra;
        return ToolFlowScreen(
          key: ValueKey(state.pageKey),
          tool: tool,
          initial: extra is List<ToolInput> ? extra : const [],
        );
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
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const LegalScreen(LegalPage.privacy),
    ),
    GoRoute(
      path: '/settings/terms',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const LegalScreen(LegalPage.terms),
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
