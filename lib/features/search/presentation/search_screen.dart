import 'dart:async';
import 'dart:convert';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/repositories/search_repository.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/home/application/open_actions.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S06 Search: names and text inside documents, as you type (FR-ORG-02).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  String _term = '';
  int _generation = 0;
  bool _loading = false;
  List<DocumentInfo> _names = const [];
  List<ContentHit> _hits = const [];
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final raw = await ref
        .read(settingsRepositoryProvider)
        .get(SettingsRepository.keyRecentSearches);
    if (raw == null || !mounted) return;
    try {
      setState(
        () => _recent = (jsonDecode(raw) as List<Object?>).cast<String>(),
      );
    } on FormatException {
      // Ignore a damaged value.
    }
  }

  Future<void> _remember(String term) async {
    final list = [
      term,
      ..._recent.where((t) => t.toLowerCase() != term.toLowerCase()),
    ].take(8).toList();
    setState(() => _recent = list);
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingsRepository.keyRecentSearches, jsonEncode(list));
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = const []);
    await ref
        .read(settingsRepositoryProvider)
        .remove(SettingsRepository.keyRecentSearches);
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(_run(text)),
    );
  }

  Future<void> _run(String text) async {
    final term = text.trim();
    final generation = ++_generation;
    if (term.isEmpty) {
      setState(() {
        _term = '';
        _names = const [];
        _hits = const [];
      });
      return;
    }
    setState(() {
      _term = term;
      _loading = true;
    });
    final names = await ref.read(libraryRepositoryProvider).searchNames(term);
    final hits = await ref.read(searchRepositoryProvider).searchContent(term);
    if (!mounted || generation != _generation) return;
    setState(() {
      _names = names;
      _hits = hits;
      _loading = false;
    });
  }

  void _open(DocumentInfo doc, {int? page}) {
    unawaited(_remember(_term));
    unawaited(
      openDocument(
        context,
        doc,
        page: page,
        searchTerm: page == null ? null : _term,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconAction(
          icon: PhosphorIconsRegular.arrowLeft,
          label: l.actionBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: DocNookText.body.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: l.searchHint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (t) {
            _debounce?.cancel();
            unawaited(_run(t));
            if (t.trim().isNotEmpty) unawaited(_remember(t.trim()));
          },
        ),
        actions: [
          if (_field.text.isNotEmpty || _term.isNotEmpty)
            IconAction(
              icon: PhosphorIconsRegular.x,
              label: l.actionClose,
              onPressed: () {
                _field.clear();
                unawaited(_run(''));
              },
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Hairline(),
        ),
      ),
      body: _term.isEmpty ? _start(l, c) : _results(l, c),
    );
  }

  Widget _start(AppLocalizations l, DocNookColors c) {
    if (_recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Text(
          l.searchStartHint,
          style: DocNookText.body.copyWith(color: c.inkMuted),
        ),
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.x3,
            Space.x2,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.searchRecent,
                  style: DocNookText.label.copyWith(color: c.inkMuted),
                ),
              ),
              QuietButton(
                label: l.searchClearRecent,
                onPressed: () => unawaited(_clearRecent()),
              ),
            ],
          ),
        ),
        for (final term in _recent)
          ListTile(
            leading: Icon(
              PhosphorIconsRegular.clockCounterClockwise,
              size: Sizes.iconSmall,
              color: c.inkMuted,
            ),
            title: Text(term),
            onTap: () {
              _field.text = term;
              unawaited(_run(term));
            },
          ),
      ],
    );
  }

  Widget _results(AppLocalizations l, DocNookColors c) {
    if (_loading && _names.isEmpty && _hits.isEmpty) {
      return const LoadingState();
    }
    if (_names.isEmpty && _hits.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          art: EmptyArt.paperStack,
          title: l.searchEmptyTitle(_term),
          body: l.searchEmptyHint,
        ),
      );
    }
    final thumbs = ref.watch(thumbnailCacheProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x8),
      children: [
        if (_names.isNotEmpty) ...[
          SectionHeader(l.searchNames),
          for (final doc in _names) ...[
            FileRow(
              type: doc.type,
              name: doc.name,
              details: l.documentDetails(doc),
              thumbnail: thumbs.imageFor(doc.thumbKey),
              starred: doc.starred,
              onTap: () => _open(doc),
              onMore: () => unawaited(showFileActions(context, ref, doc)),
              moreLabel: l.actionMore,
            ),
            const Hairline(indent: 76),
          ],
        ],
        if (_hits.isNotEmpty) ...[
          SectionHeader(l.searchInside),
          for (final hit in _hits) ...[
            _HitRow(
              hit: hit,
              onTap: () => _open(
                hit.document,
                page: hit.document.type == DocType.pdf ? hit.page : null,
              ),
            ),
            const Hairline(indent: Space.screen + Sizes.spine + Space.x3),
          ],
        ],
      ],
    );
  }
}

/// A content hit: file name, page, and a two-line snippet with the match
/// in bold.
class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.onTap});

  final ContentHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final where = hit.document.type == DocType.pdf
        ? l.searchPageHit(hit.page)
        : l.searchPartHit(hit.page);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.x2,
          Space.x3,
          Space.screen,
          Space.x3,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TypeSpine(hit.document.type),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.document.name} · $where',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DocNookText.caption.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      _highlight(hit.snippet, c),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DocNookText.body.copyWith(color: c.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The index marks matches with [ and ]; render them bold.
  static TextSpan _highlight(String snippet, DocNookColors c) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\[([^\]]*)\]');
    var last = 0;
    for (final m in pattern.allMatches(snippet)) {
      if (m.start > last) {
        spans.add(TextSpan(text: snippet.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            backgroundColor: c.accent.withValues(alpha: 0.18),
          ),
        ),
      );
      last = m.end;
    }
    if (last < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(last)));
    }
    return TextSpan(children: spans);
  }
}
