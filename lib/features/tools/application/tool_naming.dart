import 'dart:async';

import 'package:docnook/app/providers.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How tool outputs are named (Settings → Output → File naming).
enum FileNaming {
  /// `Report_signed`
  suffix,

  /// `Report_signed_2026-11-14`
  dated,
}

/// True when output names end with the date. Kept loaded for the whole
/// session (the app root watches it) so tool screens can read it at once.
final datedNamesProvider = NotifierProvider<DatedNames, bool>(DatedNames.new);

class DatedNames extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref
        .read(settingsRepositoryProvider)
        .watch(SettingsRepository.keyFileNaming)
        .listen((v) => state = v == FileNaming.dated.name);
    ref.onDispose(() => unawaited(sub.cancel()));
    return false;
  }
}
