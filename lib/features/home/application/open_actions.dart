import 'package:docnook/app/providers.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Open file": the system picker, then the right viewer.
Future<void> pickAndOpen(BuildContext context, WidgetRef ref) async {
  final files = await ref.read(platformProvider).pickFiles();
  if (files.isEmpty || !context.mounted) return;
  await context.push(
    '/view',
    extra: OpenRequest.fromIncoming(files.first, source: DocSource.picked),
  );
}

/// Opens a document DocNook already knows (Recents, Files, search).
Future<void> openDocument(
  BuildContext context,
  DocumentInfo doc, {
  int? page,
  String? searchTerm,
}) => context.push(
  '/view',
  extra: OpenRequest.fromDocument(doc, page: page, searchTerm: searchTerm),
);
