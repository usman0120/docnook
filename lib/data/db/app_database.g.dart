// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionMeta = const VerificationMeta(
    'extension',
  );
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
    'extension',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<int> lastOpenedAt = GeneratedColumn<int>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openCountMeta = const VerificationMeta(
    'openCount',
  );
  @override
  late final GeneratedColumn<int> openCount = GeneratedColumn<int>(
    'open_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isStarredMeta = const VerificationMeta(
    'isStarred',
  );
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
    'is_starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEncryptedMeta = const VerificationMeta(
    'isEncrypted',
  );
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
    'is_encrypted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_encrypted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thumbKeyMeta = const VerificationMeta(
    'thumbKey',
  );
  @override
  late final GeneratedColumn<String> thumbKey = GeneratedColumn<String>(
    'thumb_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMissingMeta = const VerificationMeta(
    'isMissing',
  );
  @override
  late final GeneratedColumn<bool> isMissing = GeneratedColumn<bool>(
    'is_missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _indexStateMeta = const VerificationMeta(
    'indexState',
  );
  @override
  late final GeneratedColumn<String> indexState = GeneratedColumn<String>(
    'index_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<int> indexedAt = GeneratedColumn<int>(
    'indexed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uri,
    displayName,
    extension,
    mime,
    docType,
    sizeBytes,
    modifiedAt,
    addedAt,
    lastOpenedAt,
    openCount,
    isStarred,
    source,
    pageCount,
    isEncrypted,
    thumbKey,
    isMissing,
    indexState,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(
        _extensionMeta,
        extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('open_count')) {
      context.handle(
        _openCountMeta,
        openCount.isAcceptableOrUnknown(data['open_count']!, _openCountMeta),
      );
    }
    if (data.containsKey('is_starred')) {
      context.handle(
        _isStarredMeta,
        isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
        _isEncryptedMeta,
        isEncrypted.isAcceptableOrUnknown(
          data['is_encrypted']!,
          _isEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('thumb_key')) {
      context.handle(
        _thumbKeyMeta,
        thumbKey.isAcceptableOrUnknown(data['thumb_key']!, _thumbKeyMeta),
      );
    }
    if (data.containsKey('is_missing')) {
      context.handle(
        _isMissingMeta,
        isMissing.isAcceptableOrUnknown(data['is_missing']!, _isMissingMeta),
      );
    }
    if (data.containsKey('index_state')) {
      context.handle(
        _indexStateMeta,
        indexState.isAcceptableOrUnknown(data['index_state']!, _indexStateMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      extension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension'],
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_opened_at'],
      ),
      openCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_count'],
      )!,
      isStarred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starred'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      isEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_encrypted'],
      )!,
      thumbKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_key'],
      ),
      isMissing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_missing'],
      )!,
      indexState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}index_state'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at'],
      ),
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final int id;
  final String uri;
  final String displayName;
  final String? extension;
  final String? mime;

  /// pdf, word, sheet, slides, text, markdown, epub, image, archive, other
  final String docType;
  final int? sizeBytes;
  final int? modifiedAt;
  final int addedAt;
  final int? lastOpenedAt;
  final int openCount;
  final bool isStarred;

  /// discovered, picked, intent, created, scanned
  final String source;
  final int? pageCount;
  final bool isEncrypted;
  final String? thumbKey;
  final bool isMissing;

  /// none, pending, done, failed, skipped
  final String indexState;
  final int? indexedAt;
  const DocumentRow({
    required this.id,
    required this.uri,
    required this.displayName,
    this.extension,
    this.mime,
    required this.docType,
    this.sizeBytes,
    this.modifiedAt,
    required this.addedAt,
    this.lastOpenedAt,
    required this.openCount,
    required this.isStarred,
    required this.source,
    this.pageCount,
    required this.isEncrypted,
    this.thumbKey,
    required this.isMissing,
    required this.indexState,
    this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || extension != null) {
      map['extension'] = Variable<String>(extension);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    map['doc_type'] = Variable<String>(docType);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<int>(modifiedAt);
    }
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt);
    }
    map['open_count'] = Variable<int>(openCount);
    map['is_starred'] = Variable<bool>(isStarred);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    if (!nullToAbsent || thumbKey != null) {
      map['thumb_key'] = Variable<String>(thumbKey);
    }
    map['is_missing'] = Variable<bool>(isMissing);
    map['index_state'] = Variable<String>(indexState);
    if (!nullToAbsent || indexedAt != null) {
      map['indexed_at'] = Variable<int>(indexedAt);
    }
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      uri: Value(uri),
      displayName: Value(displayName),
      extension: extension == null && nullToAbsent
          ? const Value.absent()
          : Value(extension),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      docType: Value(docType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      openCount: Value(openCount),
      isStarred: Value(isStarred),
      source: Value(source),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      isEncrypted: Value(isEncrypted),
      thumbKey: thumbKey == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbKey),
      isMissing: Value(isMissing),
      indexState: Value(indexState),
      indexedAt: indexedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(indexedAt),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<int>(json['id']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      extension: serializer.fromJson<String?>(json['extension']),
      mime: serializer.fromJson<String?>(json['mime']),
      docType: serializer.fromJson<String>(json['docType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      modifiedAt: serializer.fromJson<int?>(json['modifiedAt']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<int?>(json['lastOpenedAt']),
      openCount: serializer.fromJson<int>(json['openCount']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      source: serializer.fromJson<String>(json['source']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      thumbKey: serializer.fromJson<String?>(json['thumbKey']),
      isMissing: serializer.fromJson<bool>(json['isMissing']),
      indexState: serializer.fromJson<String>(json['indexState']),
      indexedAt: serializer.fromJson<int?>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'extension': serializer.toJson<String?>(extension),
      'mime': serializer.toJson<String?>(mime),
      'docType': serializer.toJson<String>(docType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'modifiedAt': serializer.toJson<int?>(modifiedAt),
      'addedAt': serializer.toJson<int>(addedAt),
      'lastOpenedAt': serializer.toJson<int?>(lastOpenedAt),
      'openCount': serializer.toJson<int>(openCount),
      'isStarred': serializer.toJson<bool>(isStarred),
      'source': serializer.toJson<String>(source),
      'pageCount': serializer.toJson<int?>(pageCount),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'thumbKey': serializer.toJson<String?>(thumbKey),
      'isMissing': serializer.toJson<bool>(isMissing),
      'indexState': serializer.toJson<String>(indexState),
      'indexedAt': serializer.toJson<int?>(indexedAt),
    };
  }

  DocumentRow copyWith({
    int? id,
    String? uri,
    String? displayName,
    Value<String?> extension = const Value.absent(),
    Value<String?> mime = const Value.absent(),
    String? docType,
    Value<int?> sizeBytes = const Value.absent(),
    Value<int?> modifiedAt = const Value.absent(),
    int? addedAt,
    Value<int?> lastOpenedAt = const Value.absent(),
    int? openCount,
    bool? isStarred,
    String? source,
    Value<int?> pageCount = const Value.absent(),
    bool? isEncrypted,
    Value<String?> thumbKey = const Value.absent(),
    bool? isMissing,
    String? indexState,
    Value<int?> indexedAt = const Value.absent(),
  }) => DocumentRow(
    id: id ?? this.id,
    uri: uri ?? this.uri,
    displayName: displayName ?? this.displayName,
    extension: extension.present ? extension.value : this.extension,
    mime: mime.present ? mime.value : this.mime,
    docType: docType ?? this.docType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    openCount: openCount ?? this.openCount,
    isStarred: isStarred ?? this.isStarred,
    source: source ?? this.source,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    isEncrypted: isEncrypted ?? this.isEncrypted,
    thumbKey: thumbKey.present ? thumbKey.value : this.thumbKey,
    isMissing: isMissing ?? this.isMissing,
    indexState: indexState ?? this.indexState,
    indexedAt: indexedAt.present ? indexedAt.value : this.indexedAt,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      extension: data.extension.present ? data.extension.value : this.extension,
      mime: data.mime.present ? data.mime.value : this.mime,
      docType: data.docType.present ? data.docType.value : this.docType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      openCount: data.openCount.present ? data.openCount.value : this.openCount,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      source: data.source.present ? data.source.value : this.source,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      isEncrypted: data.isEncrypted.present
          ? data.isEncrypted.value
          : this.isEncrypted,
      thumbKey: data.thumbKey.present ? data.thumbKey.value : this.thumbKey,
      isMissing: data.isMissing.present ? data.isMissing.value : this.isMissing,
      indexState: data.indexState.present
          ? data.indexState.value
          : this.indexState,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('extension: $extension, ')
          ..write('mime: $mime, ')
          ..write('docType: $docType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('openCount: $openCount, ')
          ..write('isStarred: $isStarred, ')
          ..write('source: $source, ')
          ..write('pageCount: $pageCount, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('thumbKey: $thumbKey, ')
          ..write('isMissing: $isMissing, ')
          ..write('indexState: $indexState, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uri,
    displayName,
    extension,
    mime,
    docType,
    sizeBytes,
    modifiedAt,
    addedAt,
    lastOpenedAt,
    openCount,
    isStarred,
    source,
    pageCount,
    isEncrypted,
    thumbKey,
    isMissing,
    indexState,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.extension == this.extension &&
          other.mime == this.mime &&
          other.docType == this.docType &&
          other.sizeBytes == this.sizeBytes &&
          other.modifiedAt == this.modifiedAt &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.openCount == this.openCount &&
          other.isStarred == this.isStarred &&
          other.source == this.source &&
          other.pageCount == this.pageCount &&
          other.isEncrypted == this.isEncrypted &&
          other.thumbKey == this.thumbKey &&
          other.isMissing == this.isMissing &&
          other.indexState == this.indexState &&
          other.indexedAt == this.indexedAt);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<int> id;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<String?> extension;
  final Value<String?> mime;
  final Value<String> docType;
  final Value<int?> sizeBytes;
  final Value<int?> modifiedAt;
  final Value<int> addedAt;
  final Value<int?> lastOpenedAt;
  final Value<int> openCount;
  final Value<bool> isStarred;
  final Value<String> source;
  final Value<int?> pageCount;
  final Value<bool> isEncrypted;
  final Value<String?> thumbKey;
  final Value<bool> isMissing;
  final Value<String> indexState;
  final Value<int?> indexedAt;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.extension = const Value.absent(),
    this.mime = const Value.absent(),
    this.docType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.openCount = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.source = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.thumbKey = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.indexState = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  DocumentsCompanion.insert({
    this.id = const Value.absent(),
    required String uri,
    required String displayName,
    this.extension = const Value.absent(),
    this.mime = const Value.absent(),
    required String docType,
    this.sizeBytes = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    required int addedAt,
    this.lastOpenedAt = const Value.absent(),
    this.openCount = const Value.absent(),
    this.isStarred = const Value.absent(),
    required String source,
    this.pageCount = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.thumbKey = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.indexState = const Value.absent(),
    this.indexedAt = const Value.absent(),
  }) : uri = Value(uri),
       displayName = Value(displayName),
       docType = Value(docType),
       addedAt = Value(addedAt),
       source = Value(source);
  static Insertable<DocumentRow> custom({
    Expression<int>? id,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<String>? extension,
    Expression<String>? mime,
    Expression<String>? docType,
    Expression<int>? sizeBytes,
    Expression<int>? modifiedAt,
    Expression<int>? addedAt,
    Expression<int>? lastOpenedAt,
    Expression<int>? openCount,
    Expression<bool>? isStarred,
    Expression<String>? source,
    Expression<int>? pageCount,
    Expression<bool>? isEncrypted,
    Expression<String>? thumbKey,
    Expression<bool>? isMissing,
    Expression<String>? indexState,
    Expression<int>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (extension != null) 'extension': extension,
      if (mime != null) 'mime': mime,
      if (docType != null) 'doc_type': docType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (openCount != null) 'open_count': openCount,
      if (isStarred != null) 'is_starred': isStarred,
      if (source != null) 'source': source,
      if (pageCount != null) 'page_count': pageCount,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (thumbKey != null) 'thumb_key': thumbKey,
      if (isMissing != null) 'is_missing': isMissing,
      if (indexState != null) 'index_state': indexState,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  DocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? uri,
    Value<String>? displayName,
    Value<String?>? extension,
    Value<String?>? mime,
    Value<String>? docType,
    Value<int?>? sizeBytes,
    Value<int?>? modifiedAt,
    Value<int>? addedAt,
    Value<int?>? lastOpenedAt,
    Value<int>? openCount,
    Value<bool>? isStarred,
    Value<String>? source,
    Value<int?>? pageCount,
    Value<bool>? isEncrypted,
    Value<String?>? thumbKey,
    Value<bool>? isMissing,
    Value<String>? indexState,
    Value<int?>? indexedAt,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      extension: extension ?? this.extension,
      mime: mime ?? this.mime,
      docType: docType ?? this.docType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      openCount: openCount ?? this.openCount,
      isStarred: isStarred ?? this.isStarred,
      source: source ?? this.source,
      pageCount: pageCount ?? this.pageCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      thumbKey: thumbKey ?? this.thumbKey,
      isMissing: isMissing ?? this.isMissing,
      indexState: indexState ?? this.indexState,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt.value);
    }
    if (openCount.present) {
      map['open_count'] = Variable<int>(openCount.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (thumbKey.present) {
      map['thumb_key'] = Variable<String>(thumbKey.value);
    }
    if (isMissing.present) {
      map['is_missing'] = Variable<bool>(isMissing.value);
    }
    if (indexState.present) {
      map['index_state'] = Variable<String>(indexState.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<int>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('extension: $extension, ')
          ..write('mime: $mime, ')
          ..write('docType: $docType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('openCount: $openCount, ')
          ..write('isStarred: $isStarred, ')
          ..write('source: $source, ')
          ..write('pageCount: $pageCount, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('thumbKey: $thumbKey, ')
          ..write('isMissing: $isMissing, ')
          ..write('indexState: $indexState, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, CollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorTokenMeta = const VerificationMeta(
    'colorToken',
  );
  @override
  late final GeneratedColumn<String> colorToken = GeneratedColumn<String>(
    'color_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorToken,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_token')) {
      context.handle(
        _colorTokenMeta,
        colorToken.isAcceptableOrUnknown(data['color_token']!, _colorTokenMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_token'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class CollectionRow extends DataClass implements Insertable<CollectionRow> {
  final int id;
  final String name;
  final String? colorToken;
  final int sortOrder;
  final int createdAt;
  const CollectionRow({
    required this.id,
    required this.name,
    this.colorToken,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorToken != null) {
      map['color_token'] = Variable<String>(colorToken);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      colorToken: colorToken == null && nullToAbsent
          ? const Value.absent()
          : Value(colorToken),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorToken: serializer.fromJson<String?>(json['colorToken']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorToken': serializer.toJson<String?>(colorToken),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CollectionRow copyWith({
    int? id,
    String? name,
    Value<String?> colorToken = const Value.absent(),
    int? sortOrder,
    int? createdAt,
  }) => CollectionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorToken: colorToken.present ? colorToken.value : this.colorToken,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CollectionRow copyWithCompanion(CollectionsCompanion data) {
    return CollectionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorToken: data.colorToken.present
          ? data.colorToken.value
          : this.colorToken,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorToken: $colorToken, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorToken, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorToken == this.colorToken &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CollectionsCompanion extends UpdateCompanion<CollectionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> colorToken;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorToken = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorToken = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CollectionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorToken,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorToken != null) 'color_token': colorToken,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? colorToken,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorToken: colorToken ?? this.colorToken,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorToken.present) {
      map['color_token'] = Variable<String>(colorToken.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorToken: $colorToken, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<int> collectionId = GeneratedColumn<int>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [collectionId, documentId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, documentId};
  @override
  CollectionItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItemRow(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collection_id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItemRow extends DataClass
    implements Insertable<CollectionItemRow> {
  final int collectionId;
  final int documentId;
  final int addedAt;
  const CollectionItemRow({
    required this.collectionId,
    required this.documentId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<int>(collectionId);
    map['document_id'] = Variable<int>(documentId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      collectionId: Value(collectionId),
      documentId: Value(documentId),
      addedAt: Value(addedAt),
    );
  }

  factory CollectionItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItemRow(
      collectionId: serializer.fromJson<int>(json['collectionId']),
      documentId: serializer.fromJson<int>(json['documentId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<int>(collectionId),
      'documentId': serializer.toJson<int>(documentId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  CollectionItemRow copyWith({
    int? collectionId,
    int? documentId,
    int? addedAt,
  }) => CollectionItemRow(
    collectionId: collectionId ?? this.collectionId,
    documentId: documentId ?? this.documentId,
    addedAt: addedAt ?? this.addedAt,
  );
  CollectionItemRow copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItemRow(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemRow(')
          ..write('collectionId: $collectionId, ')
          ..write('documentId: $documentId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, documentId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItemRow &&
          other.collectionId == this.collectionId &&
          other.documentId == this.documentId &&
          other.addedAt == this.addedAt);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItemRow> {
  final Value<int> collectionId;
  final Value<int> documentId;
  final Value<int> addedAt;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.collectionId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required int collectionId,
    required int documentId,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       documentId = Value(documentId),
       addedAt = Value(addedAt);
  static Insertable<CollectionItemRow> custom({
    Expression<int>? collectionId,
    Expression<int>? documentId,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (documentId != null) 'document_id': documentId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<int>? collectionId,
    Value<int>? documentId,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      collectionId: collectionId ?? this.collectionId,
      documentId: documentId ?? this.documentId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<int>(collectionId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('documentId: $documentId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingStatesTable extends ReadingStates
    with TableInfo<$ReadingStatesTable, ReadingStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionJsonMeta = const VerificationMeta(
    'positionJson',
  );
  @override
  late final GeneratedColumn<String> positionJson = GeneratedColumn<String>(
    'position_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _viewPrefsJsonMeta = const VerificationMeta(
    'viewPrefsJson',
  );
  @override
  late final GeneratedColumn<String> viewPrefsJson = GeneratedColumn<String>(
    'view_prefs_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    positionJson,
    progress,
    viewPrefsJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    if (data.containsKey('position_json')) {
      context.handle(
        _positionJsonMeta,
        positionJson.isAcceptableOrUnknown(
          data['position_json']!,
          _positionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionJsonMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('view_prefs_json')) {
      context.handle(
        _viewPrefsJsonMeta,
        viewPrefsJson.isAcceptableOrUnknown(
          data['view_prefs_json']!,
          _viewPrefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ReadingStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingStateRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      positionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_json'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      viewPrefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_prefs_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingStatesTable createAlias(String alias) {
    return $ReadingStatesTable(attachedDatabase, alias);
  }
}

class ReadingStateRow extends DataClass implements Insertable<ReadingStateRow> {
  final int documentId;
  final String positionJson;
  final double progress;
  final String? viewPrefsJson;
  final int updatedAt;
  const ReadingStateRow({
    required this.documentId,
    required this.positionJson,
    required this.progress,
    this.viewPrefsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<int>(documentId);
    map['position_json'] = Variable<String>(positionJson);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || viewPrefsJson != null) {
      map['view_prefs_json'] = Variable<String>(viewPrefsJson);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ReadingStatesCompanion toCompanion(bool nullToAbsent) {
    return ReadingStatesCompanion(
      documentId: Value(documentId),
      positionJson: Value(positionJson),
      progress: Value(progress),
      viewPrefsJson: viewPrefsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(viewPrefsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingStateRow(
      documentId: serializer.fromJson<int>(json['documentId']),
      positionJson: serializer.fromJson<String>(json['positionJson']),
      progress: serializer.fromJson<double>(json['progress']),
      viewPrefsJson: serializer.fromJson<String?>(json['viewPrefsJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<int>(documentId),
      'positionJson': serializer.toJson<String>(positionJson),
      'progress': serializer.toJson<double>(progress),
      'viewPrefsJson': serializer.toJson<String?>(viewPrefsJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ReadingStateRow copyWith({
    int? documentId,
    String? positionJson,
    double? progress,
    Value<String?> viewPrefsJson = const Value.absent(),
    int? updatedAt,
  }) => ReadingStateRow(
    documentId: documentId ?? this.documentId,
    positionJson: positionJson ?? this.positionJson,
    progress: progress ?? this.progress,
    viewPrefsJson: viewPrefsJson.present
        ? viewPrefsJson.value
        : this.viewPrefsJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingStateRow copyWithCompanion(ReadingStatesCompanion data) {
    return ReadingStateRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      positionJson: data.positionJson.present
          ? data.positionJson.value
          : this.positionJson,
      progress: data.progress.present ? data.progress.value : this.progress,
      viewPrefsJson: data.viewPrefsJson.present
          ? data.viewPrefsJson.value
          : this.viewPrefsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStateRow(')
          ..write('documentId: $documentId, ')
          ..write('positionJson: $positionJson, ')
          ..write('progress: $progress, ')
          ..write('viewPrefsJson: $viewPrefsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, positionJson, progress, viewPrefsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingStateRow &&
          other.documentId == this.documentId &&
          other.positionJson == this.positionJson &&
          other.progress == this.progress &&
          other.viewPrefsJson == this.viewPrefsJson &&
          other.updatedAt == this.updatedAt);
}

class ReadingStatesCompanion extends UpdateCompanion<ReadingStateRow> {
  final Value<int> documentId;
  final Value<String> positionJson;
  final Value<double> progress;
  final Value<String?> viewPrefsJson;
  final Value<int> updatedAt;
  const ReadingStatesCompanion({
    this.documentId = const Value.absent(),
    this.positionJson = const Value.absent(),
    this.progress = const Value.absent(),
    this.viewPrefsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReadingStatesCompanion.insert({
    this.documentId = const Value.absent(),
    required String positionJson,
    this.progress = const Value.absent(),
    this.viewPrefsJson = const Value.absent(),
    required int updatedAt,
  }) : positionJson = Value(positionJson),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingStateRow> custom({
    Expression<int>? documentId,
    Expression<String>? positionJson,
    Expression<double>? progress,
    Expression<String>? viewPrefsJson,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (positionJson != null) 'position_json': positionJson,
      if (progress != null) 'progress': progress,
      if (viewPrefsJson != null) 'view_prefs_json': viewPrefsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReadingStatesCompanion copyWith({
    Value<int>? documentId,
    Value<String>? positionJson,
    Value<double>? progress,
    Value<String?>? viewPrefsJson,
    Value<int>? updatedAt,
  }) {
    return ReadingStatesCompanion(
      documentId: documentId ?? this.documentId,
      positionJson: positionJson ?? this.positionJson,
      progress: progress ?? this.progress,
      viewPrefsJson: viewPrefsJson ?? this.viewPrefsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (positionJson.present) {
      map['position_json'] = Variable<String>(positionJson.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (viewPrefsJson.present) {
      map['view_prefs_json'] = Variable<String>(viewPrefsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStatesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('positionJson: $positionJson, ')
          ..write('progress: $progress, ')
          ..write('viewPrefsJson: $viewPrefsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _anchorJsonMeta = const VerificationMeta(
    'anchorJson',
  );
  @override
  late final GeneratedColumn<String> anchorJson = GeneratedColumn<String>(
    'anchor_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    anchorJson,
    label,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('anchor_json')) {
      context.handle(
        _anchorJsonMeta,
        anchorJson.isAcceptableOrUnknown(data['anchor_json']!, _anchorJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorJsonMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      anchorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_json'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final int id;
  final int documentId;
  final String anchorJson;
  final String label;
  final int createdAt;
  const BookmarkRow({
    required this.id,
    required this.documentId,
    required this.anchorJson,
    required this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['anchor_json'] = Variable<String>(anchorJson);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      anchorJson: Value(anchorJson),
      label: Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      anchorJson: serializer.fromJson<String>(json['anchorJson']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'anchorJson': serializer.toJson<String>(anchorJson),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookmarkRow copyWith({
    int? id,
    int? documentId,
    String? anchorJson,
    String? label,
    int? createdAt,
  }) => BookmarkRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    anchorJson: anchorJson ?? this.anchorJson,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      anchorJson: data.anchorJson.present
          ? data.anchorJson.value
          : this.anchorJson,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, documentId, anchorJson, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.anchorJson == this.anchorJson &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<String> anchorJson;
  final Value<String> label;
  final Value<int> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.anchorJson = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required String anchorJson,
    required String label,
    required int createdAt,
  }) : documentId = Value(documentId),
       anchorJson = Value(anchorJson),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<BookmarkRow> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<String>? anchorJson,
    Expression<String>? label,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (anchorJson != null) 'anchor_json': anchorJson,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? documentId,
    Value<String>? anchorJson,
    Value<String>? label,
    Value<int>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      anchorJson: anchorJson ?? this.anchorJson,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (anchorJson.present) {
      map['anchor_json'] = Variable<String>(anchorJson.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScanSessionsTable extends ScanSessions
    with TableInfo<$ScanSessionsTable, ScanSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageSizeMeta = const VerificationMeta(
    'pageSize',
  );
  @override
  late final GeneratedColumn<String> pageSize = GeneratedColumn<String>(
    'page_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ocrEnabledMeta = const VerificationMeta(
    'ocrEnabled',
  );
  @override
  late final GeneratedColumn<bool> ocrEnabled = GeneratedColumn<bool>(
    'ocr_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ocr_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _outputDocumentIdMeta = const VerificationMeta(
    'outputDocumentId',
  );
  @override
  late final GeneratedColumn<int> outputDocumentId = GeneratedColumn<int>(
    'output_document_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    status,
    mode,
    pageSize,
    quality,
    ocrEnabled,
    outputDocumentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('page_size')) {
      context.handle(
        _pageSizeMeta,
        pageSize.isAcceptableOrUnknown(data['page_size']!, _pageSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_pageSizeMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('ocr_enabled')) {
      context.handle(
        _ocrEnabledMeta,
        ocrEnabled.isAcceptableOrUnknown(data['ocr_enabled']!, _ocrEnabledMeta),
      );
    }
    if (data.containsKey('output_document_id')) {
      context.handle(
        _outputDocumentIdMeta,
        outputDocumentId.isAcceptableOrUnknown(
          data['output_document_id']!,
          _outputDocumentIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      pageSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_size'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      ocrEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ocr_enabled'],
      )!,
      outputDocumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_document_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScanSessionsTable createAlias(String alias) {
    return $ScanSessionsTable(attachedDatabase, alias);
  }
}

class ScanSessionRow extends DataClass implements Insertable<ScanSessionRow> {
  final int id;
  final String title;

  /// draft, exported
  final String status;

  /// document, id_card, book
  final String mode;
  final String pageSize;
  final String quality;
  final bool ocrEnabled;
  final int? outputDocumentId;
  final int createdAt;
  final int updatedAt;
  const ScanSessionRow({
    required this.id,
    required this.title,
    required this.status,
    required this.mode,
    required this.pageSize,
    required this.quality,
    required this.ocrEnabled,
    this.outputDocumentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['mode'] = Variable<String>(mode);
    map['page_size'] = Variable<String>(pageSize);
    map['quality'] = Variable<String>(quality);
    map['ocr_enabled'] = Variable<bool>(ocrEnabled);
    if (!nullToAbsent || outputDocumentId != null) {
      map['output_document_id'] = Variable<int>(outputDocumentId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ScanSessionsCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsCompanion(
      id: Value(id),
      title: Value(title),
      status: Value(status),
      mode: Value(mode),
      pageSize: Value(pageSize),
      quality: Value(quality),
      ocrEnabled: Value(ocrEnabled),
      outputDocumentId: outputDocumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(outputDocumentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScanSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSessionRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      mode: serializer.fromJson<String>(json['mode']),
      pageSize: serializer.fromJson<String>(json['pageSize']),
      quality: serializer.fromJson<String>(json['quality']),
      ocrEnabled: serializer.fromJson<bool>(json['ocrEnabled']),
      outputDocumentId: serializer.fromJson<int?>(json['outputDocumentId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'mode': serializer.toJson<String>(mode),
      'pageSize': serializer.toJson<String>(pageSize),
      'quality': serializer.toJson<String>(quality),
      'ocrEnabled': serializer.toJson<bool>(ocrEnabled),
      'outputDocumentId': serializer.toJson<int?>(outputDocumentId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ScanSessionRow copyWith({
    int? id,
    String? title,
    String? status,
    String? mode,
    String? pageSize,
    String? quality,
    bool? ocrEnabled,
    Value<int?> outputDocumentId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ScanSessionRow(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    mode: mode ?? this.mode,
    pageSize: pageSize ?? this.pageSize,
    quality: quality ?? this.quality,
    ocrEnabled: ocrEnabled ?? this.ocrEnabled,
    outputDocumentId: outputDocumentId.present
        ? outputDocumentId.value
        : this.outputDocumentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScanSessionRow copyWithCompanion(ScanSessionsCompanion data) {
    return ScanSessionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      mode: data.mode.present ? data.mode.value : this.mode,
      pageSize: data.pageSize.present ? data.pageSize.value : this.pageSize,
      quality: data.quality.present ? data.quality.value : this.quality,
      ocrEnabled: data.ocrEnabled.present
          ? data.ocrEnabled.value
          : this.ocrEnabled,
      outputDocumentId: data.outputDocumentId.present
          ? data.outputDocumentId.value
          : this.outputDocumentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('pageSize: $pageSize, ')
          ..write('quality: $quality, ')
          ..write('ocrEnabled: $ocrEnabled, ')
          ..write('outputDocumentId: $outputDocumentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    mode,
    pageSize,
    quality,
    ocrEnabled,
    outputDocumentId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSessionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.status == this.status &&
          other.mode == this.mode &&
          other.pageSize == this.pageSize &&
          other.quality == this.quality &&
          other.ocrEnabled == this.ocrEnabled &&
          other.outputDocumentId == this.outputDocumentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScanSessionsCompanion extends UpdateCompanion<ScanSessionRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> status;
  final Value<String> mode;
  final Value<String> pageSize;
  final Value<String> quality;
  final Value<bool> ocrEnabled;
  final Value<int?> outputDocumentId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ScanSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.mode = const Value.absent(),
    this.pageSize = const Value.absent(),
    this.quality = const Value.absent(),
    this.ocrEnabled = const Value.absent(),
    this.outputDocumentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String status,
    required String mode,
    required String pageSize,
    required String quality,
    this.ocrEnabled = const Value.absent(),
    this.outputDocumentId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       status = Value(status),
       mode = Value(mode),
       pageSize = Value(pageSize),
       quality = Value(quality),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScanSessionRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? mode,
    Expression<String>? pageSize,
    Expression<String>? quality,
    Expression<bool>? ocrEnabled,
    Expression<int>? outputDocumentId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (mode != null) 'mode': mode,
      if (pageSize != null) 'page_size': pageSize,
      if (quality != null) 'quality': quality,
      if (ocrEnabled != null) 'ocr_enabled': ocrEnabled,
      if (outputDocumentId != null) 'output_document_id': outputDocumentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScanSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? status,
    Value<String>? mode,
    Value<String>? pageSize,
    Value<String>? quality,
    Value<bool>? ocrEnabled,
    Value<int?>? outputDocumentId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ScanSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      pageSize: pageSize ?? this.pageSize,
      quality: quality ?? this.quality,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
      outputDocumentId: outputDocumentId ?? this.outputDocumentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (pageSize.present) {
      map['page_size'] = Variable<String>(pageSize.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (ocrEnabled.present) {
      map['ocr_enabled'] = Variable<bool>(ocrEnabled.value);
    }
    if (outputDocumentId.present) {
      map['output_document_id'] = Variable<int>(outputDocumentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('pageSize: $pageSize, ')
          ..write('quality: $quality, ')
          ..write('ocrEnabled: $ocrEnabled, ')
          ..write('outputDocumentId: $outputDocumentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScanPagesTable extends ScanPages
    with TableInfo<$ScanPagesTable, ScanPageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedPathMeta = const VerificationMeta(
    'processedPath',
  );
  @override
  late final GeneratedColumn<String> processedPath = GeneratedColumn<String>(
    'processed_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cornersJsonMeta = const VerificationMeta(
    'cornersJson',
  );
  @override
  late final GeneratedColumn<String> cornersJson = GeneratedColumn<String>(
    'corners_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('original'),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<int> rotation = GeneratedColumn<int>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    position,
    originalPath,
    processedPath,
    cornersJson,
    filter,
    rotation,
    ocrText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanPageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('processed_path')) {
      context.handle(
        _processedPathMeta,
        processedPath.isAcceptableOrUnknown(
          data['processed_path']!,
          _processedPathMeta,
        ),
      );
    }
    if (data.containsKey('corners_json')) {
      context.handle(
        _cornersJsonMeta,
        cornersJson.isAcceptableOrUnknown(
          data['corners_json']!,
          _cornersJsonMeta,
        ),
      );
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanPageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanPageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      processedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processed_path'],
      ),
      cornersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corners_json'],
      ),
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
    );
  }

  @override
  $ScanPagesTable createAlias(String alias) {
    return $ScanPagesTable(attachedDatabase, alias);
  }
}

class ScanPageRow extends DataClass implements Insertable<ScanPageRow> {
  final int id;
  final int sessionId;
  final int position;
  final String originalPath;
  final String? processedPath;
  final String? cornersJson;
  final String filter;
  final int rotation;
  final String? ocrText;
  const ScanPageRow({
    required this.id,
    required this.sessionId,
    required this.position,
    required this.originalPath,
    this.processedPath,
    this.cornersJson,
    required this.filter,
    required this.rotation,
    this.ocrText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['position'] = Variable<int>(position);
    map['original_path'] = Variable<String>(originalPath);
    if (!nullToAbsent || processedPath != null) {
      map['processed_path'] = Variable<String>(processedPath);
    }
    if (!nullToAbsent || cornersJson != null) {
      map['corners_json'] = Variable<String>(cornersJson);
    }
    map['filter'] = Variable<String>(filter);
    map['rotation'] = Variable<int>(rotation);
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    return map;
  }

  ScanPagesCompanion toCompanion(bool nullToAbsent) {
    return ScanPagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      position: Value(position),
      originalPath: Value(originalPath),
      processedPath: processedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(processedPath),
      cornersJson: cornersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(cornersJson),
      filter: Value(filter),
      rotation: Value(rotation),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
    );
  }

  factory ScanPageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanPageRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      processedPath: serializer.fromJson<String?>(json['processedPath']),
      cornersJson: serializer.fromJson<String?>(json['cornersJson']),
      filter: serializer.fromJson<String>(json['filter']),
      rotation: serializer.fromJson<int>(json['rotation']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'position': serializer.toJson<int>(position),
      'originalPath': serializer.toJson<String>(originalPath),
      'processedPath': serializer.toJson<String?>(processedPath),
      'cornersJson': serializer.toJson<String?>(cornersJson),
      'filter': serializer.toJson<String>(filter),
      'rotation': serializer.toJson<int>(rotation),
      'ocrText': serializer.toJson<String?>(ocrText),
    };
  }

  ScanPageRow copyWith({
    int? id,
    int? sessionId,
    int? position,
    String? originalPath,
    Value<String?> processedPath = const Value.absent(),
    Value<String?> cornersJson = const Value.absent(),
    String? filter,
    int? rotation,
    Value<String?> ocrText = const Value.absent(),
  }) => ScanPageRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    originalPath: originalPath ?? this.originalPath,
    processedPath: processedPath.present
        ? processedPath.value
        : this.processedPath,
    cornersJson: cornersJson.present ? cornersJson.value : this.cornersJson,
    filter: filter ?? this.filter,
    rotation: rotation ?? this.rotation,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
  );
  ScanPageRow copyWithCompanion(ScanPagesCompanion data) {
    return ScanPageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      processedPath: data.processedPath.present
          ? data.processedPath.value
          : this.processedPath,
      cornersJson: data.cornersJson.present
          ? data.cornersJson.value
          : this.cornersJson,
      filter: data.filter.present ? data.filter.value : this.filter,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanPageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('originalPath: $originalPath, ')
          ..write('processedPath: $processedPath, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('filter: $filter, ')
          ..write('rotation: $rotation, ')
          ..write('ocrText: $ocrText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    position,
    originalPath,
    processedPath,
    cornersJson,
    filter,
    rotation,
    ocrText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanPageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.originalPath == this.originalPath &&
          other.processedPath == this.processedPath &&
          other.cornersJson == this.cornersJson &&
          other.filter == this.filter &&
          other.rotation == this.rotation &&
          other.ocrText == this.ocrText);
}

class ScanPagesCompanion extends UpdateCompanion<ScanPageRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> position;
  final Value<String> originalPath;
  final Value<String?> processedPath;
  final Value<String?> cornersJson;
  final Value<String> filter;
  final Value<int> rotation;
  final Value<String?> ocrText;
  const ScanPagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.processedPath = const Value.absent(),
    this.cornersJson = const Value.absent(),
    this.filter = const Value.absent(),
    this.rotation = const Value.absent(),
    this.ocrText = const Value.absent(),
  });
  ScanPagesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int position,
    required String originalPath,
    this.processedPath = const Value.absent(),
    this.cornersJson = const Value.absent(),
    this.filter = const Value.absent(),
    this.rotation = const Value.absent(),
    this.ocrText = const Value.absent(),
  }) : sessionId = Value(sessionId),
       position = Value(position),
       originalPath = Value(originalPath);
  static Insertable<ScanPageRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? position,
    Expression<String>? originalPath,
    Expression<String>? processedPath,
    Expression<String>? cornersJson,
    Expression<String>? filter,
    Expression<int>? rotation,
    Expression<String>? ocrText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (originalPath != null) 'original_path': originalPath,
      if (processedPath != null) 'processed_path': processedPath,
      if (cornersJson != null) 'corners_json': cornersJson,
      if (filter != null) 'filter': filter,
      if (rotation != null) 'rotation': rotation,
      if (ocrText != null) 'ocr_text': ocrText,
    });
  }

  ScanPagesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? position,
    Value<String>? originalPath,
    Value<String?>? processedPath,
    Value<String?>? cornersJson,
    Value<String>? filter,
    Value<int>? rotation,
    Value<String?>? ocrText,
  }) {
    return ScanPagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      cornersJson: cornersJson ?? this.cornersJson,
      filter: filter ?? this.filter,
      rotation: rotation ?? this.rotation,
      ocrText: ocrText ?? this.ocrText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (processedPath.present) {
      map['processed_path'] = Variable<String>(processedPath.value);
    }
    if (cornersJson.present) {
      map['corners_json'] = Variable<String>(cornersJson.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<int>(rotation.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanPagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('originalPath: $originalPath, ')
          ..write('processedPath: $processedPath, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('filter: $filter, ')
          ..write('rotation: $rotation, ')
          ..write('ocrText: $ocrText')
          ..write(')'))
        .toString();
  }
}

class $JobsTable extends Jobs with TableInfo<$JobsTable, JobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputJsonMeta = const VerificationMeta(
    'inputJson',
  );
  @override
  late final GeneratedColumn<String> inputJson = GeneratedColumn<String>(
    'input_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _outputJsonMeta = const VerificationMeta(
    'outputJson',
  );
  @override
  late final GeneratedColumn<String> outputJson = GeneratedColumn<String>(
    'output_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    status,
    inputJson,
    optionsJson,
    outputJson,
    progress,
    errorCode,
    createdAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('input_json')) {
      context.handle(
        _inputJsonMeta,
        inputJson.isAcceptableOrUnknown(data['input_json']!, _inputJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_inputJsonMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('output_json')) {
      context.handle(
        _outputJsonMeta,
        outputJson.isAcceptableOrUnknown(data['output_json']!, _outputJsonMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      inputJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_json'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      outputJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_json'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class JobRow extends DataClass implements Insertable<JobRow> {
  final int id;
  final String type;

  /// queued, running, done, failed, cancelled, interrupted
  final String status;
  final String inputJson;
  final String optionsJson;
  final String? outputJson;
  final double progress;
  final String? errorCode;
  final int createdAt;
  final int? finishedAt;
  const JobRow({
    required this.id,
    required this.type,
    required this.status,
    required this.inputJson,
    required this.optionsJson,
    this.outputJson,
    required this.progress,
    this.errorCode,
    required this.createdAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['input_json'] = Variable<String>(inputJson);
    map['options_json'] = Variable<String>(optionsJson);
    if (!nullToAbsent || outputJson != null) {
      map['output_json'] = Variable<String>(outputJson);
    }
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      type: Value(type),
      status: Value(status),
      inputJson: Value(inputJson),
      optionsJson: Value(optionsJson),
      outputJson: outputJson == null && nullToAbsent
          ? const Value.absent()
          : Value(outputJson),
      progress: Value(progress),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      createdAt: Value(createdAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory JobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      inputJson: serializer.fromJson<String>(json['inputJson']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      outputJson: serializer.fromJson<String?>(json['outputJson']),
      progress: serializer.fromJson<double>(json['progress']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'inputJson': serializer.toJson<String>(inputJson),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'outputJson': serializer.toJson<String?>(outputJson),
      'progress': serializer.toJson<double>(progress),
      'errorCode': serializer.toJson<String?>(errorCode),
      'createdAt': serializer.toJson<int>(createdAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
    };
  }

  JobRow copyWith({
    int? id,
    String? type,
    String? status,
    String? inputJson,
    String? optionsJson,
    Value<String?> outputJson = const Value.absent(),
    double? progress,
    Value<String?> errorCode = const Value.absent(),
    int? createdAt,
    Value<int?> finishedAt = const Value.absent(),
  }) => JobRow(
    id: id ?? this.id,
    type: type ?? this.type,
    status: status ?? this.status,
    inputJson: inputJson ?? this.inputJson,
    optionsJson: optionsJson ?? this.optionsJson,
    outputJson: outputJson.present ? outputJson.value : this.outputJson,
    progress: progress ?? this.progress,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    createdAt: createdAt ?? this.createdAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  JobRow copyWithCompanion(JobsCompanion data) {
    return JobRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      inputJson: data.inputJson.present ? data.inputJson.value : this.inputJson,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      outputJson: data.outputJson.present
          ? data.outputJson.value
          : this.outputJson,
      progress: data.progress.present ? data.progress.value : this.progress,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('inputJson: $inputJson, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('outputJson: $outputJson, ')
          ..write('progress: $progress, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    status,
    inputJson,
    optionsJson,
    outputJson,
    progress,
    errorCode,
    createdAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.status == this.status &&
          other.inputJson == this.inputJson &&
          other.optionsJson == this.optionsJson &&
          other.outputJson == this.outputJson &&
          other.progress == this.progress &&
          other.errorCode == this.errorCode &&
          other.createdAt == this.createdAt &&
          other.finishedAt == this.finishedAt);
}

class JobsCompanion extends UpdateCompanion<JobRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> status;
  final Value<String> inputJson;
  final Value<String> optionsJson;
  final Value<String?> outputJson;
  final Value<double> progress;
  final Value<String?> errorCode;
  final Value<int> createdAt;
  final Value<int?> finishedAt;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.inputJson = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.outputJson = const Value.absent(),
    this.progress = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  JobsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String status,
    required String inputJson,
    this.optionsJson = const Value.absent(),
    this.outputJson = const Value.absent(),
    this.progress = const Value.absent(),
    this.errorCode = const Value.absent(),
    required int createdAt,
    this.finishedAt = const Value.absent(),
  }) : type = Value(type),
       status = Value(status),
       inputJson = Value(inputJson),
       createdAt = Value(createdAt);
  static Insertable<JobRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? inputJson,
    Expression<String>? optionsJson,
    Expression<String>? outputJson,
    Expression<double>? progress,
    Expression<String>? errorCode,
    Expression<int>? createdAt,
    Expression<int>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (inputJson != null) 'input_json': inputJson,
      if (optionsJson != null) 'options_json': optionsJson,
      if (outputJson != null) 'output_json': outputJson,
      if (progress != null) 'progress': progress,
      if (errorCode != null) 'error_code': errorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  JobsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? status,
    Value<String>? inputJson,
    Value<String>? optionsJson,
    Value<String?>? outputJson,
    Value<double>? progress,
    Value<String?>? errorCode,
    Value<int>? createdAt,
    Value<int?>? finishedAt,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      inputJson: inputJson ?? this.inputJson,
      optionsJson: optionsJson ?? this.optionsJson,
      outputJson: outputJson ?? this.outputJson,
      progress: progress ?? this.progress,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (inputJson.present) {
      map['input_json'] = Variable<String>(inputJson.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (outputJson.present) {
      map['output_json'] = Variable<String>(outputJson.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('inputJson: $inputJson, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('outputJson: $outputJson, ')
          ..write('progress: $progress, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $FolderGrantsTable extends FolderGrants
    with TableInfo<$FolderGrantsTable, FolderGrantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderGrantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _treeUriMeta = const VerificationMeta(
    'treeUri',
  );
  @override
  late final GeneratedColumn<String> treeUri = GeneratedColumn<String>(
    'tree_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grantedAtMeta = const VerificationMeta(
    'grantedAt',
  );
  @override
  late final GeneratedColumn<int> grantedAt = GeneratedColumn<int>(
    'granted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, treeUri, displayName, grantedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_grants';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderGrantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tree_uri')) {
      context.handle(
        _treeUriMeta,
        treeUri.isAcceptableOrUnknown(data['tree_uri']!, _treeUriMeta),
      );
    } else if (isInserting) {
      context.missing(_treeUriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(
        _grantedAtMeta,
        grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_grantedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderGrantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderGrantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      treeUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tree_uri'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      grantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}granted_at'],
      )!,
    );
  }

  @override
  $FolderGrantsTable createAlias(String alias) {
    return $FolderGrantsTable(attachedDatabase, alias);
  }
}

class FolderGrantRow extends DataClass implements Insertable<FolderGrantRow> {
  final int id;
  final String treeUri;
  final String displayName;
  final int grantedAt;
  const FolderGrantRow({
    required this.id,
    required this.treeUri,
    required this.displayName,
    required this.grantedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tree_uri'] = Variable<String>(treeUri);
    map['display_name'] = Variable<String>(displayName);
    map['granted_at'] = Variable<int>(grantedAt);
    return map;
  }

  FolderGrantsCompanion toCompanion(bool nullToAbsent) {
    return FolderGrantsCompanion(
      id: Value(id),
      treeUri: Value(treeUri),
      displayName: Value(displayName),
      grantedAt: Value(grantedAt),
    );
  }

  factory FolderGrantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderGrantRow(
      id: serializer.fromJson<int>(json['id']),
      treeUri: serializer.fromJson<String>(json['treeUri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      grantedAt: serializer.fromJson<int>(json['grantedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'treeUri': serializer.toJson<String>(treeUri),
      'displayName': serializer.toJson<String>(displayName),
      'grantedAt': serializer.toJson<int>(grantedAt),
    };
  }

  FolderGrantRow copyWith({
    int? id,
    String? treeUri,
    String? displayName,
    int? grantedAt,
  }) => FolderGrantRow(
    id: id ?? this.id,
    treeUri: treeUri ?? this.treeUri,
    displayName: displayName ?? this.displayName,
    grantedAt: grantedAt ?? this.grantedAt,
  );
  FolderGrantRow copyWithCompanion(FolderGrantsCompanion data) {
    return FolderGrantRow(
      id: data.id.present ? data.id.value : this.id,
      treeUri: data.treeUri.present ? data.treeUri.value : this.treeUri,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderGrantRow(')
          ..write('id: $id, ')
          ..write('treeUri: $treeUri, ')
          ..write('displayName: $displayName, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, treeUri, displayName, grantedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderGrantRow &&
          other.id == this.id &&
          other.treeUri == this.treeUri &&
          other.displayName == this.displayName &&
          other.grantedAt == this.grantedAt);
}

class FolderGrantsCompanion extends UpdateCompanion<FolderGrantRow> {
  final Value<int> id;
  final Value<String> treeUri;
  final Value<String> displayName;
  final Value<int> grantedAt;
  const FolderGrantsCompanion({
    this.id = const Value.absent(),
    this.treeUri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.grantedAt = const Value.absent(),
  });
  FolderGrantsCompanion.insert({
    this.id = const Value.absent(),
    required String treeUri,
    required String displayName,
    required int grantedAt,
  }) : treeUri = Value(treeUri),
       displayName = Value(displayName),
       grantedAt = Value(grantedAt);
  static Insertable<FolderGrantRow> custom({
    Expression<int>? id,
    Expression<String>? treeUri,
    Expression<String>? displayName,
    Expression<int>? grantedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeUri != null) 'tree_uri': treeUri,
      if (displayName != null) 'display_name': displayName,
      if (grantedAt != null) 'granted_at': grantedAt,
    });
  }

  FolderGrantsCompanion copyWith({
    Value<int>? id,
    Value<String>? treeUri,
    Value<String>? displayName,
    Value<int>? grantedAt,
  }) {
    return FolderGrantsCompanion(
      id: id ?? this.id,
      treeUri: treeUri ?? this.treeUri,
      displayName: displayName ?? this.displayName,
      grantedAt: grantedAt ?? this.grantedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (treeUri.present) {
      map['tree_uri'] = Variable<String>(treeUri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<int>(grantedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderGrantsCompanion(')
          ..write('id: $id, ')
          ..write('treeUri: $treeUri, ')
          ..write('displayName: $displayName, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }
}

class $SignaturesTable extends Signatures
    with TableInfo<$SignaturesTable, SignatureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fileName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signatures';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignatureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignatureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignatureRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SignaturesTable createAlias(String alias) {
    return $SignaturesTable(attachedDatabase, alias);
  }
}

class SignatureRow extends DataClass implements Insertable<SignatureRow> {
  final int id;
  final String fileName;
  final int createdAt;
  const SignatureRow({
    required this.id,
    required this.fileName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_name'] = Variable<String>(fileName);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SignaturesCompanion toCompanion(bool nullToAbsent) {
    return SignaturesCompanion(
      id: Value(id),
      fileName: Value(fileName),
      createdAt: Value(createdAt),
    );
  }

  factory SignatureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignatureRow(
      id: serializer.fromJson<int>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileName': serializer.toJson<String>(fileName),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SignatureRow copyWith({int? id, String? fileName, int? createdAt}) =>
      SignatureRow(
        id: id ?? this.id,
        fileName: fileName ?? this.fileName,
        createdAt: createdAt ?? this.createdAt,
      );
  SignatureRow copyWithCompanion(SignaturesCompanion data) {
    return SignatureRow(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignatureRow(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fileName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignatureRow &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt);
}

class SignaturesCompanion extends UpdateCompanion<SignatureRow> {
  final Value<int> id;
  final Value<String> fileName;
  final Value<int> createdAt;
  const SignaturesCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignaturesCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    required int createdAt,
  }) : fileName = Value(fileName),
       createdAt = Value(createdAt);
  static Insertable<SignatureRow> custom({
    Expression<int>? id,
    Expression<String>? fileName,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SignaturesCompanion copyWith({
    Value<int>? id,
    Value<String>? fileName,
    Value<int>? createdAt,
  }) {
    return SignaturesCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignaturesCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VaultItemsTable extends VaultItems
    with TableInfo<$VaultItemsTable, VaultItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _blobNameMeta = const VerificationMeta(
    'blobName',
  );
  @override
  late final GeneratedColumn<String> blobName = GeneratedColumn<String>(
    'blob_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrappedKeyMeta = const VerificationMeta(
    'wrappedKey',
  );
  @override
  late final GeneratedColumn<Uint8List> wrappedKey = GeneratedColumn<Uint8List>(
    'wrapped_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalLocationMeta = const VerificationMeta(
    'originalLocation',
  );
  @override
  late final GeneratedColumn<String> originalLocation = GeneratedColumn<String>(
    'original_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    blobName,
    originalName,
    mime,
    sizeBytes,
    wrappedKey,
    originalLocation,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('blob_name')) {
      context.handle(
        _blobNameMeta,
        blobName.isAcceptableOrUnknown(data['blob_name']!, _blobNameMeta),
      );
    } else if (isInserting) {
      context.missing(_blobNameMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('wrapped_key')) {
      context.handle(
        _wrappedKeyMeta,
        wrappedKey.isAcceptableOrUnknown(data['wrapped_key']!, _wrappedKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_wrappedKeyMeta);
    }
    if (data.containsKey('original_location')) {
      context.handle(
        _originalLocationMeta,
        originalLocation.isAcceptableOrUnknown(
          data['original_location']!,
          _originalLocationMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      blobName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_name'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      wrappedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_key'],
      )!,
      originalLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_location'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $VaultItemsTable createAlias(String alias) {
    return $VaultItemsTable(attachedDatabase, alias);
  }
}

class VaultItemRow extends DataClass implements Insertable<VaultItemRow> {
  final int id;
  final String blobName;
  final String originalName;
  final String? mime;
  final int sizeBytes;
  final Uint8List wrappedKey;
  final String? originalLocation;
  final int addedAt;
  const VaultItemRow({
    required this.id,
    required this.blobName,
    required this.originalName,
    this.mime,
    required this.sizeBytes,
    required this.wrappedKey,
    this.originalLocation,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['blob_name'] = Variable<String>(blobName);
    map['original_name'] = Variable<String>(originalName);
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['wrapped_key'] = Variable<Uint8List>(wrappedKey);
    if (!nullToAbsent || originalLocation != null) {
      map['original_location'] = Variable<String>(originalLocation);
    }
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  VaultItemsCompanion toCompanion(bool nullToAbsent) {
    return VaultItemsCompanion(
      id: Value(id),
      blobName: Value(blobName),
      originalName: Value(originalName),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      sizeBytes: Value(sizeBytes),
      wrappedKey: Value(wrappedKey),
      originalLocation: originalLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(originalLocation),
      addedAt: Value(addedAt),
    );
  }

  factory VaultItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultItemRow(
      id: serializer.fromJson<int>(json['id']),
      blobName: serializer.fromJson<String>(json['blobName']),
      originalName: serializer.fromJson<String>(json['originalName']),
      mime: serializer.fromJson<String?>(json['mime']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      wrappedKey: serializer.fromJson<Uint8List>(json['wrappedKey']),
      originalLocation: serializer.fromJson<String?>(json['originalLocation']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blobName': serializer.toJson<String>(blobName),
      'originalName': serializer.toJson<String>(originalName),
      'mime': serializer.toJson<String?>(mime),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'wrappedKey': serializer.toJson<Uint8List>(wrappedKey),
      'originalLocation': serializer.toJson<String?>(originalLocation),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  VaultItemRow copyWith({
    int? id,
    String? blobName,
    String? originalName,
    Value<String?> mime = const Value.absent(),
    int? sizeBytes,
    Uint8List? wrappedKey,
    Value<String?> originalLocation = const Value.absent(),
    int? addedAt,
  }) => VaultItemRow(
    id: id ?? this.id,
    blobName: blobName ?? this.blobName,
    originalName: originalName ?? this.originalName,
    mime: mime.present ? mime.value : this.mime,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    wrappedKey: wrappedKey ?? this.wrappedKey,
    originalLocation: originalLocation.present
        ? originalLocation.value
        : this.originalLocation,
    addedAt: addedAt ?? this.addedAt,
  );
  VaultItemRow copyWithCompanion(VaultItemsCompanion data) {
    return VaultItemRow(
      id: data.id.present ? data.id.value : this.id,
      blobName: data.blobName.present ? data.blobName.value : this.blobName,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      mime: data.mime.present ? data.mime.value : this.mime,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      wrappedKey: data.wrappedKey.present
          ? data.wrappedKey.value
          : this.wrappedKey,
      originalLocation: data.originalLocation.present
          ? data.originalLocation.value
          : this.originalLocation,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultItemRow(')
          ..write('id: $id, ')
          ..write('blobName: $blobName, ')
          ..write('originalName: $originalName, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('wrappedKey: $wrappedKey, ')
          ..write('originalLocation: $originalLocation, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    blobName,
    originalName,
    mime,
    sizeBytes,
    $driftBlobEquality.hash(wrappedKey),
    originalLocation,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultItemRow &&
          other.id == this.id &&
          other.blobName == this.blobName &&
          other.originalName == this.originalName &&
          other.mime == this.mime &&
          other.sizeBytes == this.sizeBytes &&
          $driftBlobEquality.equals(other.wrappedKey, this.wrappedKey) &&
          other.originalLocation == this.originalLocation &&
          other.addedAt == this.addedAt);
}

class VaultItemsCompanion extends UpdateCompanion<VaultItemRow> {
  final Value<int> id;
  final Value<String> blobName;
  final Value<String> originalName;
  final Value<String?> mime;
  final Value<int> sizeBytes;
  final Value<Uint8List> wrappedKey;
  final Value<String?> originalLocation;
  final Value<int> addedAt;
  const VaultItemsCompanion({
    this.id = const Value.absent(),
    this.blobName = const Value.absent(),
    this.originalName = const Value.absent(),
    this.mime = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.wrappedKey = const Value.absent(),
    this.originalLocation = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  VaultItemsCompanion.insert({
    this.id = const Value.absent(),
    required String blobName,
    required String originalName,
    this.mime = const Value.absent(),
    required int sizeBytes,
    required Uint8List wrappedKey,
    this.originalLocation = const Value.absent(),
    required int addedAt,
  }) : blobName = Value(blobName),
       originalName = Value(originalName),
       sizeBytes = Value(sizeBytes),
       wrappedKey = Value(wrappedKey),
       addedAt = Value(addedAt);
  static Insertable<VaultItemRow> custom({
    Expression<int>? id,
    Expression<String>? blobName,
    Expression<String>? originalName,
    Expression<String>? mime,
    Expression<int>? sizeBytes,
    Expression<Uint8List>? wrappedKey,
    Expression<String>? originalLocation,
    Expression<int>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blobName != null) 'blob_name': blobName,
      if (originalName != null) 'original_name': originalName,
      if (mime != null) 'mime': mime,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (wrappedKey != null) 'wrapped_key': wrappedKey,
      if (originalLocation != null) 'original_location': originalLocation,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  VaultItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? blobName,
    Value<String>? originalName,
    Value<String?>? mime,
    Value<int>? sizeBytes,
    Value<Uint8List>? wrappedKey,
    Value<String?>? originalLocation,
    Value<int>? addedAt,
  }) {
    return VaultItemsCompanion(
      id: id ?? this.id,
      blobName: blobName ?? this.blobName,
      originalName: originalName ?? this.originalName,
      mime: mime ?? this.mime,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      wrappedKey: wrappedKey ?? this.wrappedKey,
      originalLocation: originalLocation ?? this.originalLocation,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blobName.present) {
      map['blob_name'] = Variable<String>(blobName.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (wrappedKey.present) {
      map['wrapped_key'] = Variable<Uint8List>(wrappedKey.value);
    }
    if (originalLocation.present) {
      map['original_location'] = Variable<String>(originalLocation.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultItemsCompanion(')
          ..write('id: $id, ')
          ..write('blobName: $blobName, ')
          ..write('originalName: $originalName, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('wrappedKey: $wrappedKey, ')
          ..write('originalLocation: $originalLocation, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $ReadingStatesTable readingStates = $ReadingStatesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ScanSessionsTable scanSessions = $ScanSessionsTable(this);
  late final $ScanPagesTable scanPages = $ScanPagesTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $FolderGrantsTable folderGrants = $FolderGrantsTable(this);
  late final $SignaturesTable signatures = $SignaturesTable(this);
  late final $VaultItemsTable vaultItems = $VaultItemsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    collections,
    collectionItems,
    readingStates,
    bookmarks,
    scanSessions,
    scanPages,
    jobs,
    folderGrants,
    signatures,
    vaultItems,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_state', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scan_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scan_pages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      required String uri,
      required String displayName,
      Value<String?> extension,
      Value<String?> mime,
      required String docType,
      Value<int?> sizeBytes,
      Value<int?> modifiedAt,
      required int addedAt,
      Value<int?> lastOpenedAt,
      Value<int> openCount,
      Value<bool> isStarred,
      required String source,
      Value<int?> pageCount,
      Value<bool> isEncrypted,
      Value<String?> thumbKey,
      Value<bool> isMissing,
      Value<String> indexState,
      Value<int?> indexedAt,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      Value<String> uri,
      Value<String> displayName,
      Value<String?> extension,
      Value<String?> mime,
      Value<String> docType,
      Value<int?> sizeBytes,
      Value<int?> modifiedAt,
      Value<int> addedAt,
      Value<int?> lastOpenedAt,
      Value<int> openCount,
      Value<bool> isStarred,
      Value<String> source,
      Value<int?> pageCount,
      Value<bool> isEncrypted,
      Value<String?> thumbKey,
      Value<bool> isMissing,
      Value<String> indexState,
      Value<int?> indexedAt,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItemRow>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'documents__id__collection_items__document_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingStatesTable, List<ReadingStateRow>>
  _readingStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingStates,
    aliasName: 'documents__id__reading_state__document_id',
  );

  $$ReadingStatesTableProcessedTableManager get readingStatesRefs {
    final manager = $$ReadingStatesTableTableManager(
      $_db,
      $_db.readingStates,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<BookmarkRow>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'documents__id__bookmarks__document_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScanSessionsTable, List<ScanSessionRow>>
  _scanSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanSessions,
    aliasName: 'documents__id__scan_sessions__output_document_id',
  );

  $$ScanSessionsTableProcessedTableManager get scanSessionsRefs {
    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.outputDocumentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEncrypted => $composableBuilder(
    column: $table.isEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbKey => $composableBuilder(
    column: $table.thumbKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingStatesRefs(
    Expression<bool> Function($$ReadingStatesTableFilterComposer f) f,
  ) {
    final $$ReadingStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableFilterComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scanSessionsRefs(
    Expression<bool> Function($$ScanSessionsTableFilterComposer f) f,
  ) {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.outputDocumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEncrypted => $composableBuilder(
    column: $table.isEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbKey => $composableBuilder(
    column: $table.thumbKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openCount =>
      $composableBuilder(column: $table.openCount, builder: (column) => column);

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<bool> get isEncrypted => $composableBuilder(
    column: $table.isEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbKey =>
      $composableBuilder(column: $table.thumbKey, builder: (column) => column);

  GeneratedColumn<bool> get isMissing =>
      $composableBuilder(column: $table.isMissing, builder: (column) => column);

  GeneratedColumn<String> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingStatesRefs<T extends Object>(
    Expression<T> Function($$ReadingStatesTableAnnotationComposer a) f,
  ) {
    final $$ReadingStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scanSessionsRefs<T extends Object>(
    Expression<T> Function($$ScanSessionsTableAnnotationComposer a) f,
  ) {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.outputDocumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({
            bool collectionItemsRefs,
            bool readingStatesRefs,
            bool bookmarksRefs,
            bool scanSessionsRefs,
          })
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> extension = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<String> docType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> modifiedAt = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<bool> isEncrypted = const Value.absent(),
                Value<String?> thumbKey = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                Value<String> indexState = const Value.absent(),
                Value<int?> indexedAt = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                uri: uri,
                displayName: displayName,
                extension: extension,
                mime: mime,
                docType: docType,
                sizeBytes: sizeBytes,
                modifiedAt: modifiedAt,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                openCount: openCount,
                isStarred: isStarred,
                source: source,
                pageCount: pageCount,
                isEncrypted: isEncrypted,
                thumbKey: thumbKey,
                isMissing: isMissing,
                indexState: indexState,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uri,
                required String displayName,
                Value<String?> extension = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                required String docType,
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> modifiedAt = const Value.absent(),
                required int addedAt,
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                required String source,
                Value<int?> pageCount = const Value.absent(),
                Value<bool> isEncrypted = const Value.absent(),
                Value<String?> thumbKey = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                Value<String> indexState = const Value.absent(),
                Value<int?> indexedAt = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                uri: uri,
                displayName: displayName,
                extension: extension,
                mime: mime,
                docType: docType,
                sizeBytes: sizeBytes,
                modifiedAt: modifiedAt,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                openCount: openCount,
                isStarred: isStarred,
                source: source,
                pageCount: pageCount,
                isEncrypted: isEncrypted,
                thumbKey: thumbKey,
                isMissing: isMissing,
                indexState: indexState,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentRow>(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                collectionItemsRefs = false,
                readingStatesRefs = false,
                bookmarksRefs = false,
                scanSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (collectionItemsRefs) db.collectionItems,
                    if (readingStatesRefs) db.readingStates,
                    if (bookmarksRefs) db.bookmarks,
                    if (scanSessionsRefs) db.scanSessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (collectionItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          CollectionItemRow,
                          $CollectionItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._collectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (readingStatesRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          ReadingStateRow,
                          $ReadingStatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._readingStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).readingStatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          BookmarkRow,
                          $BookmarksTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (scanSessionsRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          ScanSessionRow,
                          $ScanSessionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._scanSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).scanSessionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'output_document_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({
        bool collectionItemsRefs,
        bool readingStatesRefs,
        bool bookmarksRefs,
        bool scanSessionsRefs,
      })
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> colorToken,
      Value<int> sortOrder,
      required int createdAt,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> colorToken,
      Value<int> sortOrder,
      Value<int> createdAt,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectionsTable, CollectionRow> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItemRow>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'collections__id__collection_items__collection_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          CollectionRow,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (CollectionRow, $$CollectionsTableReferences),
          CollectionRow,
          PrefetchHooks Function({bool collectionItemsRefs})
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorToken = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                colorToken: colorToken,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> colorToken = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                colorToken: colorToken,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionsTable, CollectionRow>(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectionItemsRefs) db.collectionItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectionItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      CollectionRow,
                      $CollectionsTable,
                      CollectionItemRow,
                      $CollectionItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._collectionItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectionItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'collection_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      CollectionRow,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (CollectionRow, $$CollectionsTableReferences),
      CollectionRow,
      PrefetchHooks Function({bool collectionItemsRefs})
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required int collectionId,
      required int documentId,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<int> collectionId,
      Value<int> documentId,
      Value<int> addedAt,
      Value<int> rowid,
    });

final class $$CollectionItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItemRow
        > {
  $$CollectionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectionsTable _collectionIdTable(_$AppDatabase db) => db
      .collections
      .createAlias('collection_items__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<int>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('collection_items__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<int>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItemRow,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (CollectionItemRow, $$CollectionItemsTableReferences),
          CollectionItemRow,
          PrefetchHooks Function({bool collectionId, bool documentId})
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> collectionId = const Value.absent(),
                Value<int> documentId = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                collectionId: collectionId,
                documentId: documentId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int collectionId,
                required int documentId,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                collectionId: collectionId,
                documentId: documentId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionItemsTable, CollectionItemRow>(table),
                  $$CollectionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false, documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$CollectionItemsTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$CollectionItemsTableReferences
                                        ._collectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable:
                                    $$CollectionItemsTableReferences
                                        ._documentIdTable(db),
                                referencedColumn:
                                    $$CollectionItemsTableReferences
                                        ._documentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionItemRow,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (CollectionItemRow, $$CollectionItemsTableReferences),
      CollectionItemRow,
      PrefetchHooks Function({bool collectionId, bool documentId})
    >;
typedef $$ReadingStatesTableCreateCompanionBuilder =
    ReadingStatesCompanion Function({
      Value<int> documentId,
      required String positionJson,
      Value<double> progress,
      Value<String?> viewPrefsJson,
      required int updatedAt,
    });
typedef $$ReadingStatesTableUpdateCompanionBuilder =
    ReadingStatesCompanion Function({
      Value<int> documentId,
      Value<String> positionJson,
      Value<double> progress,
      Value<String?> viewPrefsJson,
      Value<int> updatedAt,
    });

final class $$ReadingStatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReadingStatesTable, ReadingStateRow> {
  $$ReadingStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('reading_state__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<int>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get positionJson => $composableBuilder(
    column: $table.positionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewPrefsJson => $composableBuilder(
    column: $table.viewPrefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get positionJson => $composableBuilder(
    column: $table.positionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewPrefsJson => $composableBuilder(
    column: $table.viewPrefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get positionJson => $composableBuilder(
    column: $table.positionJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get viewPrefsJson => $composableBuilder(
    column: $table.viewPrefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingStatesTable,
          ReadingStateRow,
          $$ReadingStatesTableFilterComposer,
          $$ReadingStatesTableOrderingComposer,
          $$ReadingStatesTableAnnotationComposer,
          $$ReadingStatesTableCreateCompanionBuilder,
          $$ReadingStatesTableUpdateCompanionBuilder,
          (ReadingStateRow, $$ReadingStatesTableReferences),
          ReadingStateRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$ReadingStatesTableTableManager(_$AppDatabase db, $ReadingStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> documentId = const Value.absent(),
                Value<String> positionJson = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> viewPrefsJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ReadingStatesCompanion(
                documentId: documentId,
                positionJson: positionJson,
                progress: progress,
                viewPrefsJson: viewPrefsJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> documentId = const Value.absent(),
                required String positionJson,
                Value<double> progress = const Value.absent(),
                Value<String?> viewPrefsJson = const Value.absent(),
                required int updatedAt,
              }) => ReadingStatesCompanion.insert(
                documentId: documentId,
                positionJson: positionJson,
                progress: progress,
                viewPrefsJson: viewPrefsJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingStatesTable, ReadingStateRow>(table),
                  $$ReadingStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$ReadingStatesTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$ReadingStatesTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingStatesTable,
      ReadingStateRow,
      $$ReadingStatesTableFilterComposer,
      $$ReadingStatesTableOrderingComposer,
      $$ReadingStatesTableAnnotationComposer,
      $$ReadingStatesTableCreateCompanionBuilder,
      $$ReadingStatesTableUpdateCompanionBuilder,
      (ReadingStateRow, $$ReadingStatesTableReferences),
      ReadingStateRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required int documentId,
      required String anchorJson,
      required String label,
      required int createdAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<int> documentId,
      Value<String> anchorJson,
      Value<String> label,
      Value<int> createdAt,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('bookmarks__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<int>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (BookmarkRow, $$BookmarksTableReferences),
          BookmarkRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> documentId = const Value.absent(),
                Value<String> anchorJson = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                documentId: documentId,
                anchorJson: anchorJson,
                label: label,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int documentId,
                required String anchorJson,
                required String label,
                required int createdAt,
              }) => BookmarksCompanion.insert(
                id: id,
                documentId: documentId,
                anchorJson: anchorJson,
                label: label,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, BookmarkRow>(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$BookmarksTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (BookmarkRow, $$BookmarksTableReferences),
      BookmarkRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$ScanSessionsTableCreateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      required String title,
      required String status,
      required String mode,
      required String pageSize,
      required String quality,
      Value<bool> ocrEnabled,
      Value<int?> outputDocumentId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ScanSessionsTableUpdateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> status,
      Value<String> mode,
      Value<String> pageSize,
      Value<String> quality,
      Value<bool> ocrEnabled,
      Value<int?> outputDocumentId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ScanSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanSessionsTable, ScanSessionRow> {
  $$ScanSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _outputDocumentIdTable(_$AppDatabase db) => db
      .documents
      .createAlias('scan_sessions__output_document_id__documents__id');

  $$DocumentsTableProcessedTableManager? get outputDocumentId {
    final $_column = $_itemColumn<int>('output_document_id');
    if ($_column == null) return null;
    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_outputDocumentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScanPagesTable, List<ScanPageRow>>
  _scanPagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanPages,
    aliasName: 'scan_sessions__id__scan_pages__session_id',
  );

  $$ScanPagesTableProcessedTableManager get scanPagesRefs {
    final manager = $$ScanPagesTableTableManager(
      $_db,
      $_db.scanPages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ocrEnabled => $composableBuilder(
    column: $table.ocrEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get outputDocumentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outputDocumentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scanPagesRefs(
    Expression<bool> Function($$ScanPagesTableFilterComposer f) f,
  ) {
    final $$ScanPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanPages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanPagesTableFilterComposer(
            $db: $db,
            $table: $db.scanPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ocrEnabled => $composableBuilder(
    column: $table.ocrEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get outputDocumentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outputDocumentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get pageSize =>
      $composableBuilder(column: $table.pageSize, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<bool> get ocrEnabled => $composableBuilder(
    column: $table.ocrEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get outputDocumentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outputDocumentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scanPagesRefs<T extends Object>(
    Expression<T> Function($$ScanPagesTableAnnotationComposer a) f,
  ) {
    final $$ScanPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanPages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.scanPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanSessionsTable,
          ScanSessionRow,
          $$ScanSessionsTableFilterComposer,
          $$ScanSessionsTableOrderingComposer,
          $$ScanSessionsTableAnnotationComposer,
          $$ScanSessionsTableCreateCompanionBuilder,
          $$ScanSessionsTableUpdateCompanionBuilder,
          (ScanSessionRow, $$ScanSessionsTableReferences),
          ScanSessionRow,
          PrefetchHooks Function({bool outputDocumentId, bool scanPagesRefs})
        > {
  $$ScanSessionsTableTableManager(_$AppDatabase db, $ScanSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> pageSize = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<bool> ocrEnabled = const Value.absent(),
                Value<int?> outputDocumentId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ScanSessionsCompanion(
                id: id,
                title: title,
                status: status,
                mode: mode,
                pageSize: pageSize,
                quality: quality,
                ocrEnabled: ocrEnabled,
                outputDocumentId: outputDocumentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String status,
                required String mode,
                required String pageSize,
                required String quality,
                Value<bool> ocrEnabled = const Value.absent(),
                Value<int?> outputDocumentId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ScanSessionsCompanion.insert(
                id: id,
                title: title,
                status: status,
                mode: mode,
                pageSize: pageSize,
                quality: quality,
                ocrEnabled: ocrEnabled,
                outputDocumentId: outputDocumentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanSessionsTable, ScanSessionRow>(table),
                  $$ScanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({outputDocumentId = false, scanPagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (scanPagesRefs) db.scanPages],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (outputDocumentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.outputDocumentId,
                                    referencedTable:
                                        $$ScanSessionsTableReferences
                                            ._outputDocumentIdTable(db),
                                    referencedColumn:
                                        $$ScanSessionsTableReferences
                                            ._outputDocumentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scanPagesRefs)
                        await $_getPrefetchedDataByColumns<
                          ScanSessionRow,
                          $ScanSessionsTable,
                          ScanPageRow,
                          $ScanPagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ScanSessionsTableReferences
                              ._scanPagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScanSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).scanPagesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScanSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanSessionsTable,
      ScanSessionRow,
      $$ScanSessionsTableFilterComposer,
      $$ScanSessionsTableOrderingComposer,
      $$ScanSessionsTableAnnotationComposer,
      $$ScanSessionsTableCreateCompanionBuilder,
      $$ScanSessionsTableUpdateCompanionBuilder,
      (ScanSessionRow, $$ScanSessionsTableReferences),
      ScanSessionRow,
      PrefetchHooks Function({bool outputDocumentId, bool scanPagesRefs})
    >;
typedef $$ScanPagesTableCreateCompanionBuilder =
    ScanPagesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int position,
      required String originalPath,
      Value<String?> processedPath,
      Value<String?> cornersJson,
      Value<String> filter,
      Value<int> rotation,
      Value<String?> ocrText,
    });
typedef $$ScanPagesTableUpdateCompanionBuilder =
    ScanPagesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> position,
      Value<String> originalPath,
      Value<String?> processedPath,
      Value<String?> cornersJson,
      Value<String> filter,
      Value<int> rotation,
      Value<String?> ocrText,
    });

final class $$ScanPagesTableReferences
    extends BaseReferences<_$AppDatabase, $ScanPagesTable, ScanPageRow> {
  $$ScanPagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScanSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.scanSessions.createAlias('scan_pages__session_id__scan_sessions__id');

  $$ScanSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScanPagesTableFilterComposer
    extends Composer<_$AppDatabase, $ScanPagesTable> {
  $$ScanPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  $$ScanSessionsTableFilterComposer get sessionId {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanPagesTable> {
  $$ScanPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScanSessionsTableOrderingComposer get sessionId {
    final $$ScanSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanPagesTable> {
  $$ScanPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumn<int> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  $$ScanSessionsTableAnnotationComposer get sessionId {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanPagesTable,
          ScanPageRow,
          $$ScanPagesTableFilterComposer,
          $$ScanPagesTableOrderingComposer,
          $$ScanPagesTableAnnotationComposer,
          $$ScanPagesTableCreateCompanionBuilder,
          $$ScanPagesTableUpdateCompanionBuilder,
          (ScanPageRow, $$ScanPagesTableReferences),
          ScanPageRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ScanPagesTableTableManager(_$AppDatabase db, $ScanPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String?> processedPath = const Value.absent(),
                Value<String?> cornersJson = const Value.absent(),
                Value<String> filter = const Value.absent(),
                Value<int> rotation = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
              }) => ScanPagesCompanion(
                id: id,
                sessionId: sessionId,
                position: position,
                originalPath: originalPath,
                processedPath: processedPath,
                cornersJson: cornersJson,
                filter: filter,
                rotation: rotation,
                ocrText: ocrText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int position,
                required String originalPath,
                Value<String?> processedPath = const Value.absent(),
                Value<String?> cornersJson = const Value.absent(),
                Value<String> filter = const Value.absent(),
                Value<int> rotation = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
              }) => ScanPagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                position: position,
                originalPath: originalPath,
                processedPath: processedPath,
                cornersJson: cornersJson,
                filter: filter,
                rotation: rotation,
                ocrText: ocrText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanPagesTable, ScanPageRow>(table),
                  $$ScanPagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$ScanPagesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$ScanPagesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScanPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanPagesTable,
      ScanPageRow,
      $$ScanPagesTableFilterComposer,
      $$ScanPagesTableOrderingComposer,
      $$ScanPagesTableAnnotationComposer,
      $$ScanPagesTableCreateCompanionBuilder,
      $$ScanPagesTableUpdateCompanionBuilder,
      (ScanPageRow, $$ScanPagesTableReferences),
      ScanPageRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$JobsTableCreateCompanionBuilder =
    JobsCompanion Function({
      Value<int> id,
      required String type,
      required String status,
      required String inputJson,
      Value<String> optionsJson,
      Value<String?> outputJson,
      Value<double> progress,
      Value<String?> errorCode,
      required int createdAt,
      Value<int?> finishedAt,
    });
typedef $$JobsTableUpdateCompanionBuilder =
    JobsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> status,
      Value<String> inputJson,
      Value<String> optionsJson,
      Value<String?> outputJson,
      Value<double> progress,
      Value<String?> errorCode,
      Value<int> createdAt,
      Value<int?> finishedAt,
    });

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputJson => $composableBuilder(
    column: $table.inputJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputJson => $composableBuilder(
    column: $table.outputJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputJson => $composableBuilder(
    column: $table.inputJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputJson => $composableBuilder(
    column: $table.outputJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get inputJson =>
      $composableBuilder(column: $table.inputJson, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputJson => $composableBuilder(
    column: $table.outputJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobsTable,
          JobRow,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (JobRow, BaseReferences<_$AppDatabase, $JobsTable, JobRow>),
          JobRow,
          PrefetchHooks Function()
        > {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> inputJson = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String?> outputJson = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                type: type,
                status: status,
                inputJson: inputJson,
                optionsJson: optionsJson,
                outputJson: outputJson,
                progress: progress,
                errorCode: errorCode,
                createdAt: createdAt,
                finishedAt: finishedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String status,
                required String inputJson,
                Value<String> optionsJson = const Value.absent(),
                Value<String?> outputJson = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required int createdAt,
                Value<int?> finishedAt = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                type: type,
                status: status,
                inputJson: inputJson,
                optionsJson: optionsJson,
                outputJson: outputJson,
                progress: progress,
                errorCode: errorCode,
                createdAt: createdAt,
                finishedAt: finishedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTable, JobRow>(table),
                  BaseReferences<_$AppDatabase, $JobsTable, JobRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobsTable,
      JobRow,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (JobRow, BaseReferences<_$AppDatabase, $JobsTable, JobRow>),
      JobRow,
      PrefetchHooks Function()
    >;
typedef $$FolderGrantsTableCreateCompanionBuilder =
    FolderGrantsCompanion Function({
      Value<int> id,
      required String treeUri,
      required String displayName,
      required int grantedAt,
    });
typedef $$FolderGrantsTableUpdateCompanionBuilder =
    FolderGrantsCompanion Function({
      Value<int> id,
      Value<String> treeUri,
      Value<String> displayName,
      Value<int> grantedAt,
    });

class $$FolderGrantsTableFilterComposer
    extends Composer<_$AppDatabase, $FolderGrantsTable> {
  $$FolderGrantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treeUri => $composableBuilder(
    column: $table.treeUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderGrantsTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderGrantsTable> {
  $$FolderGrantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treeUri => $composableBuilder(
    column: $table.treeUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderGrantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderGrantsTable> {
  $$FolderGrantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get treeUri =>
      $composableBuilder(column: $table.treeUri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);
}

class $$FolderGrantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderGrantsTable,
          FolderGrantRow,
          $$FolderGrantsTableFilterComposer,
          $$FolderGrantsTableOrderingComposer,
          $$FolderGrantsTableAnnotationComposer,
          $$FolderGrantsTableCreateCompanionBuilder,
          $$FolderGrantsTableUpdateCompanionBuilder,
          (
            FolderGrantRow,
            BaseReferences<_$AppDatabase, $FolderGrantsTable, FolderGrantRow>,
          ),
          FolderGrantRow,
          PrefetchHooks Function()
        > {
  $$FolderGrantsTableTableManager(_$AppDatabase db, $FolderGrantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderGrantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderGrantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderGrantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> treeUri = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> grantedAt = const Value.absent(),
              }) => FolderGrantsCompanion(
                id: id,
                treeUri: treeUri,
                displayName: displayName,
                grantedAt: grantedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String treeUri,
                required String displayName,
                required int grantedAt,
              }) => FolderGrantsCompanion.insert(
                id: id,
                treeUri: treeUri,
                displayName: displayName,
                grantedAt: grantedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FolderGrantsTable, FolderGrantRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FolderGrantsTable,
                    FolderGrantRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderGrantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderGrantsTable,
      FolderGrantRow,
      $$FolderGrantsTableFilterComposer,
      $$FolderGrantsTableOrderingComposer,
      $$FolderGrantsTableAnnotationComposer,
      $$FolderGrantsTableCreateCompanionBuilder,
      $$FolderGrantsTableUpdateCompanionBuilder,
      (
        FolderGrantRow,
        BaseReferences<_$AppDatabase, $FolderGrantsTable, FolderGrantRow>,
      ),
      FolderGrantRow,
      PrefetchHooks Function()
    >;
typedef $$SignaturesTableCreateCompanionBuilder =
    SignaturesCompanion Function({
      Value<int> id,
      required String fileName,
      required int createdAt,
    });
typedef $$SignaturesTableUpdateCompanionBuilder =
    SignaturesCompanion Function({
      Value<int> id,
      Value<String> fileName,
      Value<int> createdAt,
    });

class $$SignaturesTableFilterComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignaturesTableOrderingComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignaturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignaturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignaturesTable,
          SignatureRow,
          $$SignaturesTableFilterComposer,
          $$SignaturesTableOrderingComposer,
          $$SignaturesTableAnnotationComposer,
          $$SignaturesTableCreateCompanionBuilder,
          $$SignaturesTableUpdateCompanionBuilder,
          (
            SignatureRow,
            BaseReferences<_$AppDatabase, $SignaturesTable, SignatureRow>,
          ),
          SignatureRow,
          PrefetchHooks Function()
        > {
  $$SignaturesTableTableManager(_$AppDatabase db, $SignaturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignaturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => SignaturesCompanion(
                id: id,
                fileName: fileName,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileName,
                required int createdAt,
              }) => SignaturesCompanion.insert(
                id: id,
                fileName: fileName,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SignaturesTable, SignatureRow>(table),
                  BaseReferences<_$AppDatabase, $SignaturesTable, SignatureRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignaturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignaturesTable,
      SignatureRow,
      $$SignaturesTableFilterComposer,
      $$SignaturesTableOrderingComposer,
      $$SignaturesTableAnnotationComposer,
      $$SignaturesTableCreateCompanionBuilder,
      $$SignaturesTableUpdateCompanionBuilder,
      (
        SignatureRow,
        BaseReferences<_$AppDatabase, $SignaturesTable, SignatureRow>,
      ),
      SignatureRow,
      PrefetchHooks Function()
    >;
typedef $$VaultItemsTableCreateCompanionBuilder =
    VaultItemsCompanion Function({
      Value<int> id,
      required String blobName,
      required String originalName,
      Value<String?> mime,
      required int sizeBytes,
      required Uint8List wrappedKey,
      Value<String?> originalLocation,
      required int addedAt,
    });
typedef $$VaultItemsTableUpdateCompanionBuilder =
    VaultItemsCompanion Function({
      Value<int> id,
      Value<String> blobName,
      Value<String> originalName,
      Value<String?> mime,
      Value<int> sizeBytes,
      Value<Uint8List> wrappedKey,
      Value<String?> originalLocation,
      Value<int> addedAt,
    });

class $$VaultItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blobName => $composableBuilder(
    column: $table.blobName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLocation => $composableBuilder(
    column: $table.originalLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blobName => $composableBuilder(
    column: $table.blobName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLocation => $composableBuilder(
    column: $table.originalLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get blobName =>
      $composableBuilder(column: $table.blobName, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<Uint8List> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalLocation => $composableBuilder(
    column: $table.originalLocation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$VaultItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultItemsTable,
          VaultItemRow,
          $$VaultItemsTableFilterComposer,
          $$VaultItemsTableOrderingComposer,
          $$VaultItemsTableAnnotationComposer,
          $$VaultItemsTableCreateCompanionBuilder,
          $$VaultItemsTableUpdateCompanionBuilder,
          (
            VaultItemRow,
            BaseReferences<_$AppDatabase, $VaultItemsTable, VaultItemRow>,
          ),
          VaultItemRow,
          PrefetchHooks Function()
        > {
  $$VaultItemsTableTableManager(_$AppDatabase db, $VaultItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> blobName = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<Uint8List> wrappedKey = const Value.absent(),
                Value<String?> originalLocation = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
              }) => VaultItemsCompanion(
                id: id,
                blobName: blobName,
                originalName: originalName,
                mime: mime,
                sizeBytes: sizeBytes,
                wrappedKey: wrappedKey,
                originalLocation: originalLocation,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String blobName,
                required String originalName,
                Value<String?> mime = const Value.absent(),
                required int sizeBytes,
                required Uint8List wrappedKey,
                Value<String?> originalLocation = const Value.absent(),
                required int addedAt,
              }) => VaultItemsCompanion.insert(
                id: id,
                blobName: blobName,
                originalName: originalName,
                mime: mime,
                sizeBytes: sizeBytes,
                wrappedKey: wrappedKey,
                originalLocation: originalLocation,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultItemsTable, VaultItemRow>(table),
                  BaseReferences<_$AppDatabase, $VaultItemsTable, VaultItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultItemsTable,
      VaultItemRow,
      $$VaultItemsTableFilterComposer,
      $$VaultItemsTableOrderingComposer,
      $$VaultItemsTableAnnotationComposer,
      $$VaultItemsTableCreateCompanionBuilder,
      $$VaultItemsTableUpdateCompanionBuilder,
      (
        VaultItemRow,
        BaseReferences<_$AppDatabase, $VaultItemsTable, VaultItemRow>,
      ),
      VaultItemRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          SettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      SettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$ReadingStatesTableTableManager get readingStates =>
      $$ReadingStatesTableTableManager(_db, _db.readingStates);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db, _db.scanSessions);
  $$ScanPagesTableTableManager get scanPages =>
      $$ScanPagesTableTableManager(_db, _db.scanPages);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$FolderGrantsTableTableManager get folderGrants =>
      $$FolderGrantsTableTableManager(_db, _db.folderGrants);
  $$SignaturesTableTableManager get signatures =>
      $$SignaturesTableTableManager(_db, _db.signatures);
  $$VaultItemsTableTableManager get vaultItems =>
      $$VaultItemsTableTableManager(_db, _db.vaultItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
