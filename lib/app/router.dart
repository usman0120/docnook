import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/shell.dart';
import 'package:docnook/features/home/presentation/home_screen.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/tools/presentation/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/home',
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
      path: '/settings',
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      ),
    ),
  ],
);
