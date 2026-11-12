import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/router.dart';
import 'package:docnook/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DocNookApp extends StatefulWidget {
  const DocNookApp({super.key});

  @override
  State<DocNookApp> createState() => _DocNookAppState();
}

class _DocNookAppState extends State<DocNookApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
}
