import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/category_playlists_page.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:youtube_charts/youtube_charts.dart';

/// A YouTube Music mood or genre ("Chill", "Workout", "Pop"…): opens its
/// playlists.
class MoodCategory {
  const MoodCategory({required this.title, required this.params, this.color});

  final String title;
  final String params;

  /// YouTube's stripe color for it, used as a small accent only (text always
  /// uses the theme's colors, so it reads in light and dark).
  final Color? color;

  static MoodCategory? fromItem(dynamic item) {
    if (item is! Map) return null;
    final renderer = item['musicNavigationButtonRenderer'];
    if (renderer is! Map) return null;
    final runs = renderer['buttonText']?['runs'];
    final first = runs is List && runs.isNotEmpty ? runs.first : null;
    final title = first is Map ? first['text']?.toString() : null;
    final params = renderer['clickCommand']?['browseEndpoint']?['params']
        ?.toString();
    if (title == null || title.isEmpty || params == null) return null;
    final argb = int.tryParse(
      renderer['solid']?['leftStripeColor']?.toString() ?? '',
    );
    return MoodCategory(
      title: title,
      params: params,
      color: argb == null ? null : Color(argb).withAlpha(255),
    );
  }
}

class MoodSection {
  const MoodSection(this.title, this.moods);
  final String title;
  final List<MoodCategory> moods;
}

/// Moods & genres, fetched once per app session and shared by Home, Search
/// and the full list.
abstract final class Moods {
  static Future<List<MoodSection>>? _sections;
  static YouTubeChartsCountry? _country;

  /// For the user's country (Settings → Country); refetched when it changes.
  static Future<List<MoodSection>> load({bool refresh = false}) {
    final country = youtubeChartsCountryNotifier.value;
    if (refresh || country != _country) _sections = null;
    _country = country;
    return _sections ??= _fetch(country).catchError((Object e) {
      _sections = null; // let the next visit try again
      throw e;
    });
  }

  static Future<List<MoodSection>> _fetch(YouTubeChartsCountry country) async {
    final raw = await YouTubeChartsClient().getMoodsAndGenres(country: country);
    return [
      for (final section in raw)
        MoodSection(section['title']?.toString() ?? '', [
          for (final item in section['items'] as List? ?? const [])
            ?MoodCategory.fromItem(item),
        ]),
    ].where((s) => s.moods.isNotEmpty).toList();
  }

  @visibleForTesting
  static void reset() {
    _sections = null;
    _country = null;
  }

  static void open(BuildContext context, MoodCategory mood) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CategoryPlaylistsPage(title: mood.title, params: mood.params),
      ),
    );
  }
}

/// A rounded chip, for the row of moods on Home.
class MoodChip extends StatelessWidget {
  const MoodChip(this.mood, {super.key});
  final MoodCategory mood;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(mood.title),
      onPressed: () => Moods.open(context, mood),
      backgroundColor: context.neo.surfaceRaised,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: Theme.of(context).textTheme.labelLarge,
    );
  }
}

/// A tile with YouTube's color as a stripe on the left, for the "Browse all"
/// grid.
class MoodCard extends StatelessWidget {
  const MoodCard(this.mood, {super.key});
  final MoodCategory mood;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Material(
      color: neo.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Moods.open(context, mood),
        child: Row(
          children: [
            Container(width: 6, color: mood.color ?? neo.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mood.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Every mood & genre from YouTube Music as a sliver, grouped as YouTube
/// groups them (Search tab, under the charts). Shows an error with Retry
/// when the request fails, and nothing when there are none.
class BrowseAllMoods extends StatefulWidget {
  const BrowseAllMoods({super.key});

  @override
  State<BrowseAllMoods> createState() => _BrowseAllMoodsState();
}

class _BrowseAllMoodsState extends State<BrowseAllMoods> {
  late Future<List<MoodSection>> _future = Moods.load();

  Widget _title(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return FutureBuilder<List<MoodSection>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context, l10n.browseAll),
                LoadErrorView(
                  onRetry: () => setState(() {
                    _future = Moods.load(refresh: true);
                  }),
                ),
              ],
            ),
          );
        }
        final sections = snapshot.data ?? const <MoodSection>[];
        return SliverMainAxisGroup(
          slivers: [
            for (final (i, section) in sections.indexed) ...[
              SliverToBoxAdapter(
                child: _title(
                  context,
                  i == 0 || section.title.isEmpty
                      ? l10n.browseAll
                      : section.title,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 56,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: section.moods.length,
                  itemBuilder: (_, index) => MoodCard(section.moods[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
