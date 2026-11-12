import 'dart:io';

import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/files/app_paths.dart';
import 'package:docnook/data/files/thumbnail_cache.dart';
import 'package:docnook/data/platform/platform_channel.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Long-lived services. Created once in `main` and overridden in tests.
final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError(),
);
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);
final jobRunnerProvider = Provider<JobRunner>((ref) => JobRunner());
final platformProvider = Provider<PlatformChannel>((ref) => PlatformChannel());

final thumbnailCacheProvider = Provider<ThumbnailCache>(
  (ref) => ThumbnailCache(ref.watch(appPathsProvider)),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final openDocumentProvider = Provider<OpenDocument>(
  (ref) => OpenDocument(
    paths: ref.watch(appPathsProvider),
    platform: ref.watch(platformProvider),
    documents: ref.watch(documentRepositoryProvider),
  ),
);

final recentDocumentsProvider = StreamProvider<List<DocumentInfo>>(
  (ref) => ref.watch(documentRepositoryProvider).watchRecent(),
);

/// Opens the database and services before the first frame.
Future<List<Override>> bootstrap() async {
  final paths = await AppPaths.resolve();
  final db = AppDatabase(
    NativeDatabase.createInBackground(File(paths.database)),
  );
  final platform = PlatformChannel();
  final memory = await platform.totalMemoryMb();
  // Housekeeping never delays the first frame.
  Future<void>(() async {
    await paths.sweep();
    await AppPaths.trim(paths.opened, 200 * 1024 * 1024);
  }).ignore();
  return [
    appPathsProvider.overrideWithValue(paths),
    databaseProvider.overrideWithValue(db),
    platformProvider.overrideWithValue(platform),
    jobRunnerProvider.overrideWithValue(
      JobRunner(workers: JobRunner.workersFor(memory)),
    ),
  ];
}
