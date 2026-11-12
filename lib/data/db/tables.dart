import 'package:drift/drift.dart';

/// Every file DocNook knows about (BLUEPRINT 6.1). Metadata only, never the
/// files themselves.
@DataClassName('DocumentRow')
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uri => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get extension => text().nullable()();
  TextColumn get mime => text().nullable()();

  /// pdf, word, sheet, slides, text, markdown, epub, image, archive, other
  TextColumn get docType => text()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get modifiedAt => integer().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get lastOpenedAt => integer().nullable()();
  IntColumn get openCount => integer().withDefault(const Constant(0))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();

  /// discovered, picked, intent, created, scanned
  TextColumn get source => text()();
  IntColumn get pageCount => integer().nullable()();
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  TextColumn get thumbKey => text().nullable()();
  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  /// none, pending, done, failed, skipped
  TextColumn get indexState => text().withDefault(const Constant('none'))();
  IntColumn get indexedAt => integer().nullable()();
}

@DataClassName('CollectionRow')
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get colorToken => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

@DataClassName('CollectionItemRow')
class CollectionItems extends Table {
  IntColumn get collectionId =>
      integer().references(Collections, #id, onDelete: KeyAction.cascade)();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, documentId};
}

/// Resume position, one row per document (FR-READ-03).
@DataClassName('ReadingStateRow')
class ReadingStates extends Table {
  @override
  String get tableName => 'reading_state';

  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get positionJson => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get viewPrefsJson => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get anchorJson => text()();
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
}

@DataClassName('ScanSessionRow')
class ScanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// draft, exported
  TextColumn get status => text()();

  /// document, id_card, book
  TextColumn get mode => text()();
  TextColumn get pageSize => text()();
  TextColumn get quality => text()();
  BoolColumn get ocrEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get outputDocumentId => integer().nullable().references(
    Documents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('ScanPageRow')
class ScanPages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(ScanSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get originalPath => text()();
  TextColumn get processedPath => text().nullable()();
  TextColumn get cornersJson => text().nullable()();
  TextColumn get filter => text().withDefault(const Constant('original'))();
  IntColumn get rotation => integer().withDefault(const Constant(0))();
  TextColumn get ocrText => text().nullable()();
}

/// Long operations, for progress, recovery and Recent activity.
@DataClassName('JobRow')
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();

  /// queued, running, done, failed, cancelled, interrupted
  TextColumn get status => text()();
  TextColumn get inputJson => text()();
  TextColumn get optionsJson => text().withDefault(const Constant('{}'))();
  TextColumn get outputJson => text().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get finishedAt => integer().nullable()();
}

@DataClassName('FolderGrantRow')
class FolderGrants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get treeUri => text().unique()();
  TextColumn get displayName => text()();
  IntColumn get grantedAt => integer()();
}

@DataClassName('SignatureRow')
class Signatures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  IntColumn get createdAt => integer()();
}

@DataClassName('VaultItemRow')
class VaultItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get blobName => text().unique()();
  TextColumn get originalName => text()();
  TextColumn get mime => text().nullable()();
  IntColumn get sizeBytes => integer()();
  BlobColumn get wrappedKey => blob()();
  TextColumn get originalLocation => text().nullable()();
  IntColumn get addedAt => integer()();
}

/// Typed through SettingsRepository; no SharedPreferences.
@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
