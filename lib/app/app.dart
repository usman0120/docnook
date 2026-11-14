import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/app/router.dart';
import 'package:docnook/app/theme/app_theme.dart';
import 'package:docnook/data/platform/platform_channel.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/scan/presentation/scan_launcher.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final themePreferenceProvider = StreamProvider<ThemePreference>(
  (ref) => ref.watch(settingsRepositoryProvider).watchTheme(),
);

class DocNookApp extends ConsumerStatefulWidget {
  const DocNookApp({super.key});

  @override
  ConsumerState<DocNookApp> createState() => _DocNookAppState();
}

class _DocNookAppState extends ConsumerState<DocNookApp> {
  late final GoRouter _router = buildRouter(
    onboarded: ref.read(onboardedProvider),
  );
  StreamSubscription<IncomingEvent>? _incoming;

  @override
  void initState() {
    super.initState();
    _incoming = ref.read(platformProvider).incoming.listen(_onIncoming);
    // Library refresh and text indexing start after the first frame, so
    // they never delay opening the app (NFR-PERF-01).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryProvider);
      ref.read(indexerProvider).kick();
    });
  }

  void _onIncoming(IncomingEvent event) {
    switch (event) {
      case ViewEvent(:final file):
        unawaited(
          _router.push(
            '/view',
            extra: OpenRequest.fromIncoming(file, source: DocSource.intent),
          ),
        );
      case ShareEvent(:final files):
        // One shared file opens directly; several go to Merge.
        if (files.length > 1) {
          _router.go('/tools');
          unawaited(
            _router.push(
              '/tool/merge',
              extra: [
                for (final f in files)
                  ToolInput(
                    uri: f.uri,
                    name: f.name ?? 'file',
                    mime: f.mime,
                    size: f.size,
                  ),
              ],
            ),
          );
          break;
        }
        unawaited(
          _router.push(
            '/view',
            extra: OpenRequest.fromIncoming(
              files.first,
              source: DocSource.intent,
            ),
          ),
        );
      case ShortcutEvent(:final id):
        _router.go(switch (id) {
          'merge' => '/tools',
          _ => '/home',
        });
        if (id == 'merge') unawaited(_router.push('/tool/merge'));
        if (id == 'scan') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = rootNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              unawaited(startScan(context, ref, ScanMode.document));
            }
          });
        }
      case SharedTextEvent():
        break;
    }
  }

  @override
  void dispose() {
    unawaited(_incoming?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        ref.watch(themePreferenceProvider).value ?? ThemePreference.system;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayFor(context),
        // Text may scale to 200% (NFR-A11Y-01) but no further, so layouts
        // tested at 200% hold on every phone.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Registers bundled font licences with the licence page (BLUEPRINT 4.5).
void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/licenses/fonts-OFL.txt');
    yield LicenseEntryWithLineBreaks(const [
      'Inter',
      'Source Serif 4',
      'JetBrains Mono',
    ], text);
  });
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'assets/licenses/fonts-Noto-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Noto Sans',
      'Noto Serif',
      'Noto Sans Mono',
    ], text);
  });
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'assets/licenses/phosphor-MIT.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Phosphor Icons'], text);
  });
}
