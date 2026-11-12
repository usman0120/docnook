import 'dart:async';

import 'package:docnook/app/app.dart';
import 'package:docnook/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars; the theme makes them transparent.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  registerLicenses();
  final overrides = await bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const DocNookApp()));
}
