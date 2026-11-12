import 'dart:async';

import 'package:docnook/app/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars; the theme makes them transparent.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  registerLicenses();
  runApp(const ProviderScope(child: DocNookApp()));
}
