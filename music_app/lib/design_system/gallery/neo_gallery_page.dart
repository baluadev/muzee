import 'package:flutter/material.dart';
import 'package:muzee/design_system/neo_design_system.dart';

/// Debug-only catalogue of every Neon Tube token and component.
///
/// It applies the Neo theme itself, so it renders correctly even while the
/// rest of the app still runs on the old theme. Copy is English on purpose:
/// this page never ships to users.
class NeoGalleryPage extends StatefulWidget {
  const NeoGalleryPage({this.initialVariant = NeoThemeVariant.dark, super.key});

  final NeoThemeVariant initialVariant;

  @override
  State<NeoGalleryPage> createState() => _NeoGalleryPageState();
}

class _NeoGalleryPageState extends State<NeoGalleryPage> {
  late NeoThemeVariant _variant = widget.initialVariant;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildNeoTheme(_variant),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Neon Tube')),
          body: _GalleryBody(
            variant: _variant,
            onVariantChanged: (v) => setState(() => _variant = v),
          ),
        ),
      ),
    );
  }
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody({required this.variant, required this.onVariantChanged});

  final NeoThemeVariant variant;
  final ValueChanged<NeoThemeVariant> onVariantChanged;

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  final _search = TextEditingController(text: 'Lofi');
  String _mood = 'Chill';
  bool _liked = true;
  bool _shuffle = false;
  bool _isPlaying = true;
  bool _notifications = true;
  double _seek = 0.35;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = NeoLayout.of(context);
    final gap = SizedBox(height: layout.sectionGap);
    final small = SizedBox(height: layout.space12);

    return ListView(
      padding: EdgeInsets.only(bottom: layout.space48),
      children: [
        _Row(
          children: [
            for (final v in NeoThemeVariant.values)
              NeoChip(
                label: v.name,
                selected: v == widget.variant,
                onSelected: (_) => widget.onVariantChanged(v),
              ),
          ],
        ),
        gap,
        const NeoSectionHeader(title: 'Colors', eyebrow: 'Tokens'),
        small,
        const _Swatches(),
        gap,
        const NeoSectionHeader(title: 'Typography', eyebrow: 'Tokens'),
        small,
        const _TypeScale(),
        gap,
        const NeoSectionHeader(title: 'Spacing and shapes', eyebrow: 'Tokens'),
        small,
        const _SpacingAndShapes(),
        gap,
        const NeoSectionHeader(title: 'Buttons', eyebrow: 'Components'),
        small,
        _Row(
          children: [
            NeoButton(label: 'Play all', icon: NeoIcons.play, onPressed: () {}),
            NeoButton(
              label: 'Shuffle',
              icon: NeoIcons.shuffle,
              variant: NeoButtonVariant.secondary,
              onPressed: () {},
            ),
            NeoButton(
              label: 'Follow',
              variant: NeoButtonVariant.outline,
              onPressed: () {},
            ),
            NeoButton(
              label: 'See all',
              variant: NeoButtonVariant.ghost,
              onPressed: () {},
            ),
            NeoButton(
              label: 'Delete',
              variant: NeoButtonVariant.danger,
              onPressed: () {},
            ),
            NeoButton(label: 'Saving', isLoading: true, onPressed: () {}),
            const NeoButton(label: 'Disabled', onPressed: null),
          ],
        ),
        small,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.gutter),
          child: NeoButton(
            label: 'Go Premium',
            icon: NeoIcons.premium,
            size: NeoButtonSize.large,
            expand: true,
            onPressed: () {},
          ),
        ),
        gap,
        const NeoSectionHeader(title: 'Icon and play buttons'),
        small,
        _Row(
          children: [
            NeoIconButton(
              icon: NeoIcons.more,
              tooltip: 'More',
              onPressed: () {},
            ),
            NeoIconButton(
              icon: NeoIcons.like,
              selectedIcon: NeoIcons.liked,
              tooltip: 'Like',
              isSelected: _liked,
              variant: NeoIconButtonVariant.tonal,
              onPressed: () => setState(() => _liked = !_liked),
            ),
            NeoIconButton(
              icon: NeoIcons.shuffle,
              tooltip: 'Shuffle',
              isSelected: _shuffle,
              variant: NeoIconButtonVariant.tonal,
              onPressed: () => setState(() => _shuffle = !_shuffle),
            ),
            NeoPlayButton(
              isPlaying: _isPlaying,
              onPressed: () => setState(() => _isPlaying = !_isPlaying),
              playLabel: 'Play',
              pauseLabel: 'Pause',
              size: NeoPlayButtonSize.small,
            ),
            NeoPlayButton(
              isPlaying: false,
              isBuffering: true,
              onPressed: () {},
              playLabel: 'Play',
              pauseLabel: 'Pause',
            ),
            NeoPlayButton(
              isPlaying: _isPlaying,
              onPressed: () => setState(() => _isPlaying = !_isPlaying),
              playLabel: 'Play',
              pauseLabel: 'Pause',
              size: NeoPlayButtonSize.large,
            ),
          ],
        ),
        gap,
        const NeoSectionHeader(title: 'Chips and search'),
        small,
        _Row(
          children: [
            for (final mood in ['Chill', 'Focus', 'Workout', 'Sleep'])
              NeoChip(
                label: mood,
                selected: _mood == mood,
                onSelected: (_) => setState(() => _mood = mood),
              ),
          ],
        ),
        small,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.gutter),
          child: NeoSearchField(
            controller: _search,
            hintText: 'Songs, artists, playlists',
            clearLabel: 'Clear',
          ),
        ),
        gap,
        NeoSectionHeader(
          title: 'Suggested playlists',
          actionLabel: 'See all',
          onAction: () {},
        ),
        small,
        SizedBox(
          height: layout.artworkCard + layout.space48 + layout.space16,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: layout.gutter),
            itemCount: 4,
            separatorBuilder: (_, _) => SizedBox(width: layout.space12),
            itemBuilder: (context, i) => i == 3
                ? NeoMediaCard(
                    title: 'Artist name',
                    subtitle: 'Artist',
                    placeholderIcon: NeoIcons.artist,
                    circular: true,
                    onTap: () {},
                  )
                : NeoMediaCard(
                    title: 'Late night drive vol. ${i + 1}',
                    subtitle: '24 songs',
                    onTap: () {},
                  ),
          ),
        ),
        gap,
        const NeoSectionHeader(title: 'Song rows'),
        small,
        for (final (i, state) in NeoPlaybackState.values.indexed)
          NeoSongTile(
            title: 'Song title in ${state.name} state',
            subtitle: 'Artist name',
            playbackState: state,
            currentLabel: 'Now playing',
            leadingIndex: i + 1,
            onTap: () {},
            trailing: NeoIconButton(
              icon: NeoIcons.more,
              tooltip: 'More',
              onPressed: () {},
            ),
          ),
        gap,
        NeoListGroup(
          title: 'Preferences',
          children: [
            NeoListRow.toggle(
              title: 'Notifications',
              subtitle: 'Playback controls on the lock screen',
              leadingIcon: NeoIcons.settings,
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            NeoListRow.value(
              title: 'Language',
              value: 'Tiếng Việt',
              leadingIcon: NeoIcons.song,
              onTap: () {},
            ),
            NeoListRow.navigation(
              title: 'Sleep timer',
              leadingIcon: NeoIcons.sleepTimer,
              onTap: () {},
            ),
            const NeoListRow(
              title: 'Clear history',
              leadingIcon: NeoIcons.close,
              tone: NeoListRowTone.danger,
            ),
          ],
        ),
        gap,
        const NeoSectionHeader(title: 'Badges and controls'),
        small,
        const _Row(
          children: [
            NeoBadge(label: 'Premium', icon: NeoIcons.premium),
            NeoBadge(label: 'New', tone: NeoBadgeTone.secondary),
            NeoBadge(label: 'Offline', tone: NeoBadgeTone.neutral),
            NeoBadge(label: 'Error', tone: NeoBadgeTone.danger),
          ],
        ),
        small,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.gutter),
          child: Column(
            children: [
              Slider(value: _seek, onChanged: (v) => setState(() => _seek = v)),
              const LinearProgressIndicator(value: 0.6),
              SizedBox(height: layout.space16),
              const TextField(
                decoration: InputDecoration(labelText: 'Playlist name'),
              ),
            ],
          ),
        ),
        gap,
        NeoEmptyState(
          icon: NeoIcons.folder,
          title: 'Start your first playlist',
          message: 'Save songs you love and find them here.',
          actionLabel: 'Create playlist',
          onAction: () {},
        ),
        gap,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.space8),
          child: NeoMiniPlayer(
            title: 'Song title that is a little too long to fit',
            subtitle: 'Artist name',
            isPlaying: _isPlaying,
            progress: _seek,
            onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
            onNext: () {},
            onTap: () {},
            playLabel: 'Play',
            pauseLabel: 'Pause',
            nextLabel: 'Next',
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final layout = NeoLayout.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.gutter),
      child: Wrap(
        spacing: layout.space8,
        runSpacing: layout.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final text = Theme.of(context).textTheme;

    final entries = <(String, Color)>[
      ('background', c.background),
      ('surface', c.surface),
      ('surfaceRaised', c.surfaceRaised),
      ('hairline', c.hairline),
      ('outline', c.outline),
      ('onSurface', c.onSurface),
      ('onSurfaceMuted', c.onSurfaceMuted),
      ('onSurfaceSubtle', c.onSurfaceSubtle),
      ('accent', c.accent),
      ('accentSoft', c.accentSoft),
      ('secondary', c.secondary),
      ('secondarySoft', c.secondarySoft),
      ('danger', c.danger),
      ('dangerSoft', c.dangerSoft),
    ];

    return _Row(
      children: [
        for (final (name, color) in entries)
          SizedBox(
            width: layout.artworkCard / 2 + layout.space16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: layout.artworkTile,
                  decoration: ShapeDecoration(
                    color: color,
                    shape: shapes.controlShape(
                      side: BorderSide(color: c.hairline),
                    ),
                  ),
                ),
                SizedBox(height: layout.space4),
                Text(
                  name,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(_hex(color), style: NeoTypeExtras.of(context).timecode),
              ],
            ),
          ),
      ],
    );
  }

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final layout = NeoLayout.of(context);
    final t = Theme.of(context).textTheme;
    final roles = <(String, TextStyle?)>[
      ('displayMedium', t.displayMedium),
      ('headlineMedium', t.headlineMedium),
      ('titleLarge', t.titleLarge),
      ('titleMedium', t.titleMedium),
      ('bodyLarge', t.bodyLarge),
      ('bodySmall', t.bodySmall),
      ('labelLarge', t.labelLarge),
      ('labelSmall', t.labelSmall),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, style) in roles)
            Padding(
              padding: EdgeInsets.only(bottom: layout.space8),
              child: Text(
                'Nghe nhạc mọi lúc · $name',
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text('03:27 / 04:10', style: NeoTypeExtras.of(context).timecode),
        ],
      ),
    );
  }
}

class _SpacingAndShapes extends StatelessWidget {
  const _SpacingAndShapes();

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final steps = [
      layout.space4,
      layout.space8,
      layout.space12,
      layout.space16,
      layout.space24,
      layout.space32,
      layout.space48,
    ];

    return Column(
      children: [
        _Row(
          children: [
            for (final s in steps)
              Container(width: s, height: layout.space24, color: c.accent),
          ],
        ),
        SizedBox(height: layout.space12),
        _Row(
          children: [
            for (final radius in [shapes.small, shapes.medium, shapes.large])
              Container(
                width: layout.artworkTile,
                height: layout.artworkTile,
                decoration: BoxDecoration(
                  color: c.secondarySoft,
                  borderRadius: radius,
                  border: Border.all(color: c.secondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
