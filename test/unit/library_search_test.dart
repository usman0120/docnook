import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/data/repositories/search_repository.dart';
import 'package:docnook/engines/library/discovery.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

FoundFile f(String path, {int size = 10, int modified = 1}) =>
    FoundFile(uri: path, name: path.split('/').last, size: size, modifiedMs: modified);

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late SearchRepository search;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    library = LibraryRepository(db);
    search = SearchRepository(db);
  });
  tearDown(() => db.close());

  test('discovery adds, updates and marks vanished files missing', () async {
    final first = await library.applyDiscovery([
      f('/s/Download/a.pdf'),
      f('/s/Download/b.docx'),
      f('/s/Documents/c.xlsx'),
    ], scopes: ['/s']);
    expect(first.added, 3);

    var all = await library.watchLibrary().first;
    expect(all.map((d) => d.name).toSet(), {'a.pdf', 'b.docx', 'c.xlsx'});
    expect(all.firstWhere((d) => d.name == 'b.docx').type.name, 'word');

    final second = await library.applyDiscovery([
      f('/s/Download/a.pdf', size: 99, modified: 2),
      f('/s/Documents/c.xlsx'),
    ], scopes: ['/s']);
    expect(second.added, 0);
    expect(second.missing, 1);

    all = await library.watchLibrary().first;
    expect(all.map((d) => d.name).toSet(), {'a.pdf', 'c.xlsx'});
    expect(all.firstWhere((d) => d.name == 'a.pdf').sizeBytes, 99);
  });

  test('files outside the scanned scope are never marked missing', () async {
    await library.applyDiscovery([f('/s/a.pdf')], scopes: ['/s']);
    await library.applyDiscovery([f('content://tree/x.pdf')], scopes: ['content://tree']);
    expect((await library.watchLibrary().first).length, 2);
  });

  test('filters and sort', () async {
    await library.applyDiscovery([
      f('/s/zeta.pdf', size: 5),
      f('/s/alpha.pdf', size: 50),
      f('/s/notes.md', size: 1),
    ], scopes: ['/s']);
    final pdfs = await library.watchLibrary(filter: LibraryFilter.pdf, sort: LibrarySort.name).first;
    expect(pdfs.map((d) => d.name), ['alpha.pdf', 'zeta.pdf']);
    final text = await library.watchLibrary(filter: LibraryFilter.text).first;
    expect(text.single.name, 'notes.md');
    final bySize = await library.watchLibrary(sort: LibrarySort.size).first;
    expect(bySize.first.name, 'alpha.pdf');
    expect((await library.searchNames('ALPH')).single.name, 'alpha.pdf');
    expect(await library.searchNames('100%'), isEmpty);
  });

  test('collections hold documents without copying them', () async {
    await library.applyDiscovery([f('/s/a.pdf'), f('/s/b.pdf')], scopes: ['/s']);
    final docs = await library.watchLibrary(sort: LibrarySort.name).first;
    final taxes = await library.createCollection('  Taxes ');
    final work = await library.createCollection('Work');
    await library.addToCollection(taxes, [docs[0].id, docs[1].id]);
    await library.addToCollection(work, [docs[0].id]);
    await library.addToCollection(work, [docs[0].id]); // duplicate ignored

    final collections = await library.watchCollections().first;
    expect(collections.map((c) => (c.name, c.count)), [('Taxes', 2), ('Work', 1)]);
    expect(await library.collectionsOf(docs[0].id), ['Taxes', 'Work']);

    final inWork = await library.watchLibrary(collectionId: work).first;
    expect(inWork.single.name, 'a.pdf');

    await library.removeFromCollection(taxes, [docs[1].id]);
    await library.deleteCollection(work);
    expect((await library.watchCollections().first).single.count, 1);
  });

  test('full-text search returns page hits with highlighted snippets', () async {
    await library.applyDiscovery([f('/s/invoice.pdf'), f('/s/notes.txt')], scopes: ['/s']);
    final docs = await library.watchLibrary(sort: LibrarySort.name).first;
    final invoice = docs.firstWhere((d) => d.name == 'invoice.pdf');
    final notes = docs.firstWhere((d) => d.name == 'notes.txt');

    expect((await search.pending(types: ['pdf', 'text'])).length, 2);
    await search.store(invoice, const [
      IndexChunk(1, 'Cover page'),
      IndexChunk(7, 'The total amount due for the café order is 4,200 rupees.'),
    ]);
    await search.store(notes, chunkText('shopping list\nmilk\ncafe beans'));
    expect(await search.pending(types: ['pdf', 'text']), isEmpty);
    expect(await search.isIndexed(invoice.id), isTrue);

    final hits = await search.searchContent('cafe');
    expect(hits.map((h) => h.document.name).toSet(), {'invoice.pdf', 'notes.txt'});
    final pdfHit = hits.firstWhere((h) => h.document.id == invoice.id);
    expect(pdfHit.page, 7);
    expect(pdfHit.snippet, contains('[café]'));

    // Prefix match, several words, punctuation that would break raw FTS.
    expect((await search.searchContent('amou du')).single.page, 7);
    expect(await search.searchContent('"; DROP TABLE x; --'), isEmpty);
    expect(await search.searchContent('   '), isEmpty);

    // Re-indexing replaces old rows.
    await search.store(invoice, const [IndexChunk(1, 'nothing here')]);
    expect((await search.searchContent('rupees')), isEmpty);
  });

  test('FTS query building', () {
    expect(SearchRepository.ftsQuery('Hello, World!'), '"hello"* "world"*');
    expect(SearchRepository.ftsQuery('***'), isNull);
    expect(SearchRepository.ftsQuery('Ürün fiyatı'), '"ürün"* "fiyatı"*');
  });

  test('text chunks split on lines near 4 KB', () {
    final text = List.generate(300, (i) => 'line number $i of the log').join('\n');
    final chunks = chunkText(text);
    expect(chunks.length, greaterThan(1));
    expect(chunks.map((c) => c.text).join(), text);
    expect(chunks.first.text.endsWith('\n'), isTrue);
    expect(chunks.map((c) => c.page), List.generate(chunks.length, (i) => i + 1));
  });
}
