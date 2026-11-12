import 'package:docnook/data/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> addDoc(String name) => db
      .into(db.documents)
      .insert(
        DocumentsCompanion.insert(
          uri: '/storage/emulated/0/Documents/$name',
          displayName: name,
          docType: 'pdf',
          addedAt: 1,
          source: 'picked',
        ),
      );

  test('creates every table and applies defaults', () async {
    final id = await addDoc('report.pdf');
    final row = await (db.select(db.documents)..where((d) => d.id.equals(id))).getSingle();
    expect(row.openCount, 0);
    expect(row.isStarred, isFalse);
    expect(row.indexState, 'none');
    expect(row.isMissing, isFalse);
  });

  test('uri is unique', () async {
    await addDoc('a.pdf');
    expect(() => addDoc('a.pdf'), throwsA(isA<SqliteException>()));
  });

  test('deleting a document cascades to its dependent rows', () async {
    final doc = await addDoc('a.pdf');
    final collection = await db
        .into(db.collections)
        .insert(CollectionsCompanion.insert(name: 'Taxes', createdAt: 1));
    await db
        .into(db.collectionItems)
        .insert(
          CollectionItemsCompanion.insert(collectionId: collection, documentId: doc, addedAt: 1),
        );
    await db
        .into(db.readingStates)
        .insert(
          ReadingStatesCompanion.insert(documentId: Value(doc), positionJson: '{"page":3}', updatedAt: 1),
        );
    await db
        .into(db.bookmarks)
        .insert(BookmarksCompanion.insert(documentId: doc, anchorJson: '{}', label: 'p3', createdAt: 1));

    await (db.delete(db.documents)..where((d) => d.id.equals(doc))).go();

    expect(await db.select(db.collectionItems).get(), isEmpty);
    expect(await db.select(db.readingStates).get(), isEmpty);
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await db.select(db.collections).get(), hasLength(1));
  });

  test('full-text search finds words inside documents, ignoring accents', () async {
    final doc = await addDoc('invoice.pdf');
    await db.customStatement(
      'INSERT INTO doc_search (title, body, document_id, page) VALUES (?, ?, ?, ?)',
      ['invoice.pdf', 'Total due for the café order is 4,200 rupees', doc, 2],
    );
    final hits = await db
        .customSelect(
          "SELECT document_id, page, snippet(doc_search, 1, '[', ']', '…', 6) AS s "
          'FROM doc_search WHERE doc_search MATCH ?',
          variables: [Variable.withString('cafe')],
        )
        .get();
    expect(hits, hasLength(1));
    expect(hits.single.read<int>('document_id'), doc);
    expect(hits.single.read<int>('page'), 2);
    expect(hits.single.read<String>('s'), contains('[café]'));
  });

  test('settings are a key-value table', () async {
    await db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: 'theme', value: 'dark'));
    await db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: 'theme', value: 'light'));
    final rows = await db.select(db.appSettings).get();
    expect(rows.single.value, 'light');
  });
}
