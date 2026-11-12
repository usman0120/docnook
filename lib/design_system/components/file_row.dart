import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter/material.dart';

/// Short format marks shown on badges. These are format names, not prose.
String docTypeMark(DocType type) => switch (type) {
  DocType.pdf => 'PDF',
  DocType.word => 'DOC',
  DocType.sheet => 'XLS',
  DocType.slides => 'PPT',
  DocType.text => 'TXT',
  DocType.markdown => 'MD',
  DocType.epub => 'EPUB',
  DocType.image => 'IMG',
  DocType.archive => 'ZIP',
  DocType.other => 'FILE',
};

/// The 3 dp coloured stripe on a file row's leading edge, like the tab on a
/// binder divider (BLUEPRINT 9.4).
class TypeSpine extends StatelessWidget {
  const TypeSpine(this.type, {super.key});
  final DocType type;

  @override
  Widget build(BuildContext context) => Container(
    width: Sizes.spine,
    decoration: BoxDecoration(
      color: context.colors.fileType(type),
      borderRadius: const BorderRadius.all(Radius.circular(Sizes.spine / 2)),
    ),
  );
}

/// Small format label tinted with the file-type colour.
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {this.label, super.key});
  final DocType type;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.fileType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.colors.isDark ? 0.20 : 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Text(
        label ?? docTypeMark(type),
        // The badge is a mark, not reading text: it keeps its size so rows
        // stay aligned at large font scales.
        textScaler: TextScaler.noScaling,
        style: DocNookText.caption.copyWith(
          fontSize: 10,
          height: 12 / 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

/// A sheet of paper showing the document's real first page, or a neutral
/// tile with the type badge until a thumbnail exists.
class PaperThumb extends StatelessWidget {
  const PaperThumb({
    required this.type,
    this.image,
    this.width = Sizes.rowThumb,
    this.aspectRatio = 3 / 4,
    this.stacked = false,
    super.key,
  });

  final DocType type;
  final ImageProvider? image;
  final double width;
  final double aspectRatio;

  /// Draws offset paper edges behind the sheet for multi-file items.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = width / aspectRatio;
    final radius = BorderRadius.circular(width > 80 ? 6 : 4);

    final sheet = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceSunken : c.surface,
        borderRadius: radius,
        border: Border.all(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(child: TypeBadge(type))
          : Image(
              image: image!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Center(child: TypeBadge(type)),
            ),
    );
    if (!stacked) return sheet;

    Widget edge(double offset) => Positioned(
      left: offset,
      top: -offset,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: Border.all(color: c.hairline),
        ),
      ),
    );

    return SizedBox(
      width: width + 6,
      height: height + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 6,
            child: Stack(
              clipBehavior: Clip.none,
              children: [edge(6), edge(3), sheet],
            ),
          ),
        ],
      ),
    );
  }
}

/// One document in a list: spine, thumbnail, name, one line of facts.
class FileRow extends StatelessWidget {
  const FileRow({
    required this.type,
    required this.name,
    required this.details,
    this.thumbnail,
    this.onTap,
    this.onLongPress,
    this.onMore,
    this.moreLabel,
    this.progress,
    this.starred = false,
    this.selected = false,
    this.selecting = false,
    this.missing = false,
    this.heroTag,
    super.key,
  });

  final DocType type;
  final String name;

  /// e.g. "PDF · 24 pages · Yesterday".
  final String details;
  final ImageProvider? thumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;
  final String? moreLabel;

  /// Reading progress 0–1, drawn as a thin accent bar under the details.
  final double? progress;
  final bool starred;
  final bool selected;

  /// True while the list is in multi-select mode.
  final bool selecting;
  final bool missing;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget thumb = PaperThumb(type: type, image: thumbnail);
    if (heroTag != null) thumb = Hero(tag: heroTag!, child: thumb);

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$name, $details',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.selection : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: Space.x2),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.x2),
                    child: TypeSpine(type),
                  ),
                  const SizedBox(width: Space.x3),
                  Center(child: thumb),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.x2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DocNookText.bodyStrong.copyWith(
                              color: missing ? c.inkMuted : c.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (starred) ...[
                                Icon(
                                  PhosphorIconsFill.star,
                                  size: 12,
                                  color: c.accent,
                                ),
                                const SizedBox(width: Space.x1),
                              ],
                              Expanded(
                                child: Text(
                                  details,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DocNookText.caption.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (progress != null && progress! > 0) ...[
                            const SizedBox(height: Space.x1 + 2),
                            ThinProgress(progress!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (selecting)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x4),
                      child: Icon(
                        selected
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsRegular.circle,
                        size: Sizes.icon,
                        color: selected ? c.primary : c.inkMuted,
                      ),
                    )
                  else if (onMore != null)
                    Center(
                      child: Semantics(
                        button: true,
                        label: moreLabel,
                        child: InkResponse(
                          onTap: onMore,
                          radius: Sizes.touch / 2,
                          child: SizedBox(
                            width: Sizes.touch,
                            height: Sizes.touch,
                            child: Icon(
                              PhosphorIconsRegular.dotsThreeVertical,
                              size: Sizes.icon,
                              color: c.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: Space.x4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One document in a grid: large real thumbnail above the name.
class FileTile extends StatelessWidget {
  const FileTile({
    required this.type,
    required this.name,
    required this.details,
    this.thumbnail,
    this.onTap,
    this.onLongPress,
    this.progress,
    this.selected = false,
    this.heroTag,
    super.key,
  });

  final DocType type;
  final String name;
  final String details;
  final ImageProvider? thumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? progress;
  final bool selected;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$name, $details',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: Radii.chipAll,
        child: Padding(
          padding: const EdgeInsets.all(Space.x1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  Widget thumb = PaperThumb(
                    type: type,
                    image: thumbnail,
                    width: constraints.maxWidth,
                  );
                  if (heroTag != null)
                    thumb = Hero(tag: heroTag!, child: thumb);
                  return Stack(
                    children: [
                      thumb,
                      if (selected)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.selection,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: c.primary, width: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (progress != null && progress! > 0) ...[
                const SizedBox(height: Space.x1 + 2),
                ThinProgress(progress!),
              ],
              const SizedBox(height: Space.x2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SizedBox(height: 14, child: TypeSpine(type)),
                  ),
                  const SizedBox(width: Space.x2 - 2),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DocNookText.label.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2 dp reading-progress bar in the accent colour.
class ThinProgress extends StatelessWidget {
  const ThinProgress(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(1)),
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: 2,
          color: c.accent,
          backgroundColor: c.hairline,
        ),
      ),
    );
  }
}
