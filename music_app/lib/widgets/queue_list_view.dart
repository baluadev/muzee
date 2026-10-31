import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:muzee/widgets/no_artwork_cube.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget({
    super.key,
    this.isBottomSheet = false,
    this.sheetScrollController,
  });

  final bool isBottomSheet;

  /// The [DraggableScrollableSheet]'s controller when shown as a sheet, so
  /// dragging the list also resizes the sheet.
  final ScrollController? sheetScrollController;

  @override
  State<QueueWidget> createState() => _QueueWidgetState();
}

class _QueueWidgetState extends State<QueueWidget> {
  List<Map> _queue = [];
  late StreamSubscription<List<Map>> _subscription;
  bool _isDismissing = false;
  bool _hasScrolledToInitial = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _subscription = audioHandler.queueAsMapStream.listen((queue) {
      if (mounted && !_isDismissing) {
        setState(() {
          _queue = List<Map>.from(queue);
        });
        if (!_hasScrolledToInitial && queue.isNotEmpty) {
          _hasScrolledToInitial = true;
          _scrollToCurrentSong();
        }
      }
    });
  }

  void _scrollToCurrentSong() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final currentIndex = audioHandler.currentQueueIndex;
      if (currentIndex <= 0) return;
      const estimatedItemHeight = 68.0;
      const topPadding = 4.0;
      final targetOffset = currentIndex * estimatedItemHeight + topPadding;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentIndex = audioHandler.currentQueueIndex;

    if (widget.isBottomSheet) return _buildSheet(context, currentIndex);

    return Column(
      children: [
        _buildHeader(context, colorScheme, textTheme, compact: false),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          indent: 8,
          endIndent: 8,
        ),
        Expanded(
          child: _queue.isEmpty
              ? _buildEmptyState(context, colorScheme, textTheme)
              : _buildList(context, colorScheme, currentIndex),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context, int currentIndex) {
    final l10n = context.l10n!;
    final text = Theme.of(context).textTheme;
    final neo = context.neo;
    Widget label(String value) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        value,
        style: text.titleSmall?.copyWith(color: neo.onSurfaceMuted),
      ),
    );
    final hasCurrent = currentIndex >= 0 && currentIndex < _queue.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.queue, style: text.titleLarge),
                    if (_queue.isNotEmpty)
                      Text(
                        l10n.songCount(_queue.length),
                        style: text.bodySmall?.copyWith(
                          color: neo.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (_queue.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearQueue(context),
                  child: Text(l10n.clearAll),
                ),
            ],
          ),
        ),
        Expanded(
          child: _queue.isEmpty
              ? ListView(
                  controller: widget.sheetScrollController,
                  padding: const EdgeInsets.all(32),
                  children: [
                    Text(
                      l10n.noSongsInQueue,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: neo.onSurfaceMuted,
                      ),
                    ),
                  ],
                )
              : _buildNewUpNextList(
                  context,
                  currentIndex,
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasCurrent) ...[
                        label(l10n.nowPlaying),
                        _buildNewNowPlayingItem(context, _queue[currentIndex]),
                      ],
                      if (currentIndex < _queue.length - 1) label(l10n.upNext),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _confirmClearQueue(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmationDialog(
        confirmationMessage: context.l10n!.clearQueueQuestion,
        submitMessage: context.l10n!.clear,
        isDangerous: true,
        onCancel: () => Navigator.pop(context),
        onSubmit: () {
          Navigator.pop(context);
          audioHandler.clearQueue();
          if (widget.isBottomSheet) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool compact,
  }) {
    return Padding(
      padding: compact
          ? const EdgeInsets.only(left: 10, right: 8, bottom: 12)
          : const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FluentIcons.apps_list_24_regular,
              color: colorScheme.onPrimaryContainer,
              size: compact ? 20.0 : 22.0,
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n!.queue,
                  style: compact
                      ? TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        )
                      : textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                if (_queue.isNotEmpty)
                  Text(
                    '${_queue.length} ${context.l10n!.songs.toLowerCase()}',
                    style: compact
                        ? TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          )
                        : textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
              ],
            ),
          ),
          if (_queue.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () => _confirmClearQueue(context),
              icon: const Icon(FluentIcons.dismiss_24_regular, size: 18),
              label: Text(context.l10n!.clear),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.music_note_1_24_regular,
                color: colorScheme.onSurfaceVariant,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n!.noSongsInQueue,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _queueEntryKey(Map song, int index) {
    return song['queueEntryId']?.toString() ?? 'legacy_${song['ytid']}_$index';
  }

  Widget _buildList(
    BuildContext context,
    ColorScheme colorScheme,
    int currentIndex, {
    bool closeOnTap = false,
  }) {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(top: 4, bottom: 24, left: 8, right: 8),
      itemCount: _queue.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        setState(() {
          final item = _queue.removeAt(oldIndex);
          _queue.insert(newIndex, item);
        });
        audioHandler.reorderQueue(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => Material(
        elevation: 8,
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.35),
        child: child,
      ),
      itemBuilder: (context, index) {
        final song = _queue[index];
        final isCurrentSong = index == currentIndex;
        final queueEntryId = _queueEntryKey(song, index);
        return QueueTile(
          key: ValueKey(queueEntryId),
          song: song,
          index: index,
          queueEntryId: queueEntryId,
          isCurrentSong: isCurrentSong,
          colorScheme: colorScheme,
          onTap: () {
            audioHandler.skipToSong(index);
            if (closeOnTap) Navigator.pop(context);
          },
          confirmDismiss: (_) async {
            _isDismissing = true;
            return true;
          },
          onDismissed: () {
            final actualIndex = _queue.indexWhere(
              (item) => item['queueEntryId']?.toString() == queueEntryId,
            );
            if (actualIndex == -1) return;
            setState(() {
              _isDismissing = false;
              _queue.removeAt(actualIndex);
            });
            audioHandler.removeFromQueue(actualIndex);
          },
        );
      },
    );
  }

  Widget _buildNewNowPlayingItem(BuildContext context, Map song) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.neo.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.neo.surface,
            ),
            child: _ArtworkThumbnail(
              song: song,
              size: 56,
              radius: 8,
              colorScheme: Theme.of(context).colorScheme,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song['title']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: context.neo.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song['artist']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    color: context.neo.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            FluentIcons.cellular_data_3_24_filled,
            color: context.neo.accent,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNewUpNextList(
    BuildContext context,
    int currentIndex, {
    Widget? header,
  }) {
    final startIndex = (currentIndex + 1).clamp(0, _queue.length);
    final upNextQueue = _queue.sublist(startIndex);

    return ReorderableListView.builder(
      scrollController: widget.sheetScrollController ?? _scrollController,
      header: header,
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        8,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      buildDefaultDragHandles: false,
      itemCount: upNextQueue.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final actualOldIndex = oldIndex + startIndex;
        final actualNewIndex = newIndex + startIndex;
        setState(() {
          final item = _queue.removeAt(actualOldIndex);
          _queue.insert(actualNewIndex, item);
        });
        audioHandler.reorderQueue(actualOldIndex, actualNewIndex);
      },
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final song = upNextQueue[index];
        final actualIndex = index + startIndex;
        final queueEntryId = _queueEntryKey(song, actualIndex);
        return Dismissible(
          key: ValueKey(queueEntryId),
          confirmDismiss: (_) async {
            _isDismissing = true;
            return true;
          },
          onDismissed: (_) {
            final realIndex = _queue.indexWhere(
              (item) => item['queueEntryId']?.toString() == queueEntryId,
            );
            if (realIndex == -1) return;
            setState(() {
              _isDismissing = false;
              _queue.removeAt(realIndex);
            });
            audioHandler.removeFromQueue(realIndex);
          },
          background: _DismissBackground(
            alignment: Alignment.centerLeft,
            colorScheme: Theme.of(context).colorScheme,
          ),
          secondaryBackground: _DismissBackground(
            alignment: Alignment.centerRight,
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: _UpNextTile(
            song: song,
            index: index,
            onTap: () {
              audioHandler.skipToSong(actualIndex);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

class QueueTile extends StatelessWidget {
  const QueueTile({
    super.key,
    required this.song,
    required this.index,
    required this.queueEntryId,
    required this.isCurrentSong,
    required this.colorScheme,
    required this.onTap,
    required this.onDismissed,
    this.confirmDismiss,
  });

  final Map song;
  final int index;
  final String queueEntryId;
  final bool isCurrentSong;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;

  static const double _artSize = 46;
  static const double _artRadius = 10;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(queueEntryId),
      confirmDismiss: confirmDismiss,
      onDismissed: (_) => onDismissed(),
      background: _DismissBackground(
        alignment: Alignment.centerLeft,
        colorScheme: colorScheme,
      ),
      secondaryBackground: _DismissBackground(
        alignment: Alignment.centerRight,
        colorScheme: colorScheme,
      ),
      child: Material(
        color: isCurrentSong
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.transparent,
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _ArtworkThumbnail(
                  song: song,
                  size: _artSize,
                  radius: _artRadius,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title']?.toString() ?? '',
                        style: TextStyle(
                          color: isCurrentSong
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: isCurrentSong
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song['artist']?.toString() ?? '',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrentSong) ...[
                  Icon(
                    FluentIcons.music_note_2_24_regular,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Icon(
                      FluentIcons.re_order_24_regular,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({
    required this.song,
    required this.size,
    required this.radius,
    required this.colorScheme,
  });

  final Map song;
  final double size;
  final double radius;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final artworkPath = song['artworkPath'] as String?;
    if (artworkPath != null && artworkPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(artworkPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    final imageUrl = song['lowResImage']?.toString() ?? '';
    if (imageUrl.isEmpty) return _fallback();
    return CachedNetworkImage(
      width: size,
      height: size,
      imageUrl: imageUrl,
      imageBuilder: (_, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image(image: imageProvider, fit: BoxFit.cover),
      ),
      placeholder: (_, __) => _loading(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => NullArtworkWidget(
    size: size,
    borderRadius: radius,
    iconSize: size * 0.45,
  );

  Widget _loading() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({
    required this.alignment,
    required this.colorScheme,
  });

  final Alignment alignment;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        FluentIcons.delete_24_regular,
        color: colorScheme.onErrorContainer,
        size: 22,
      ),
    );
  }
}

class _UpNextTile extends StatelessWidget {
  const _UpNextTile({
    required this.song,
    required this.index,
    required this.onTap,
  });

  final Map song;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.neo.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _ArtworkThumbnail(
                song: song,
                size: 48,
                radius: 8,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song['title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.neo.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song['artist']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: context.neo.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  FluentIcons.line_horizontal_3_20_regular,
                  color: context.neo.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
