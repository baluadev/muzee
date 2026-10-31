import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

///
class PlaylistPage extends YoutubePage<_InitialData> {
  ///
  final String playlistId;

  final String? _visitorData;

  late final List<_Video> videos = initialData.playlistVideos;

  late final String? title = initialData.title;

  late final String? description = initialData.description;

  late final String? author = initialData.author;

  late final int? viewCount = initialData.viewCount;

  late final int? videoCount = initialData.videoCount;

  /// InitialData
  PlaylistPage.id(this.playlistId, _InitialData initialData,
      [this._visitorData])
      : super.fromInitialData(initialData);

  ///
  Future<PlaylistPage?> nextPage(YoutubeHttpClient httpClient) async {
    if (initialData.continuationToken?.isEmpty ?? true) {
      return null;
    }

    final data = await httpClient.sendContinuation(
        'browse', initialData.continuationToken!, headers: {
      'x-youtube-client-name': '1',
      'x-goog-visitor-id': _visitorData ?? ''
    });
    final newInitialData = _InitialData(data);
    if (newInitialData.continuationToken != null &&
        newInitialData.continuationToken == initialData.continuationToken) {
      // Avoid sending always the same request.
      return null;
    }

    return PlaylistPage.id(playlistId, _InitialData(data), _visitorData);
  }

  ///
  static Future<PlaylistPage> get(
    YoutubeHttpClient httpClient,
    String id,
  ) async {
    final url = 'https://www.youtube.com/playlist?list=$id&hl=en&persist_hl=1';
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final page = PlaylistPage.parse(raw, id);
      if (page.initialData.exists && (page.videos.isNotEmpty || page.initialData.browseId == null)) {
        return page;
      }

      // Try to fetch using the browse API
      final data = await httpClient.sendPost('browse', {
        'browseId': page.initialData.browseId!,
      }, headers: {
        'x-youtube-client-name': '1',
        'x-goog-visitor-id': page.initialData.visitorData ?? '',
      });
      return PlaylistPage.id(
          id, _InitialData(data), page.initialData.visitorData);
    });
  }

  ///
  PlaylistPage.parse(String raw, this.playlistId)
      : _visitorData = null,
        super(parser.parse(raw), (root) => _InitialData(root));
}

class _InitialData extends InitialData {
  _InitialData(super.root);

  String? get visitorData => root
      .get('responseContext')
      ?.get('webResponseContextExtensionData')
      ?.get('ytConfigData')
      ?.getT<String>('visitorData');

  String? get browseId => root
      .get('responseContext')
      ?.getList('serviceTrackingParams')
      ?.firstWhereOrNull((e) => e['service'] == 'GFEEDBACK')
      ?.getList('params')
      ?.firstWhereOrNull((e) => e['key'] == 'browse_id')
      ?.getT<String>('value');

  bool get exists =>
      root
          .getList('alerts')
          ?.firstOrNull
          ?.get('alertRenderer')
          ?.getT<String>('type') !=
      'ERROR';

  late final String? title = root
      .get('metadata')
      ?.get('playlistMetadataRenderer')
      ?.getT<String>('title');

  late final String? author = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.elementAtSafe(1)
      ?.get('playlistSidebarSecondaryInfoRenderer')
      ?.get('videoOwner')
      ?.get('videoOwnerRenderer')
      ?.get('title')
      ?.getT<List<dynamic>>('runs')
      ?.cast<Map<dynamic, dynamic>>()
      .parseRuns();

  late final String? description = root
      .get('metadata')
      ?.get('playlistMetadataRenderer')
      ?.getT<String>('description');

  late final int? viewCount = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.firstOrNull
      ?.get('playlistSidebarPrimaryInfoRenderer')
      ?.getList('stats')
      ?.elementAtSafe(1)
      ?.getT<String>('simpleText')
      .parseInt();

  // sidebar.playlistSidebarRenderer.items[0].playlistSidebarPrimaryInfoRenderer.stats
  late final int? videoCount = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.firstOrNull
      ?.get('playlistSidebarPrimaryInfoRenderer')
      ?.getList('stats')
      ?.elementAtSafe(0)
      ?.getList('runs')
      ?.firstOrNull
      ?.getT<String>('text')
      .parseInt();

  String? get continuationToken {
    final continuationEndpoint = (videosContent ?? playlistVideosContent)
        ?.firstWhereOrNull((e) => e['continuationItemRenderer'] != null)
        ?.get('continuationItemRenderer')
        ?.get('continuationEndpoint');

    return continuationEndpoint
            ?.get('continuationCommand')
            ?.getT<String>('token') ??
        continuationEndpoint
            ?.get('commandExecutorCommand')
            ?.getList('commands')
            ?.firstWhereOrNull((e) => e['continuationCommand'] != null)
            ?.get('continuationCommand')
            ?.getT<String>('token');
  }

  List<JsonMap>? get playlistVideosContent {
    final continuationItems = root
        .getList('onResponseReceivedActions')
        ?.firstOrNull
        ?.get('appendContinuationItemsAction')
        ?.getList('continuationItems');
    if (continuationItems != null) return continuationItems;

    final itemSectionContents = root
        .get('contents')
        ?.get('twoColumnBrowseResultsRenderer')
        ?.getList('tabs')
        ?.firstOrNull
        ?.get('tabRenderer')
        ?.get('content')
        ?.get('sectionListRenderer')
        ?.getList('contents')
        ?.firstOrNull
        ?.get('itemSectionRenderer')
        ?.getList('contents');

    if (itemSectionContents == null) return null;

    final playlistVideoListContents = itemSectionContents
        .firstOrNull
        ?.get('playlistVideoListRenderer')
        ?.getList('contents');

    return playlistVideoListContents ?? itemSectionContents;
  }

  late final List<JsonMap>? videosContent = root
          .get('contents')
          ?.get('twoColumnSearchResultsRenderer')
          ?.get('primaryContents')
          ?.get('sectionListRenderer')
          ?.getList('contents') ??
      root
          .getList('onResponseReceivedCommands')
          ?.firstOrNull
          ?.get('appendContinuationItemsAction')
          ?.getList('continuationItems');

  List<_Video> get playlistVideos {
    if (playlistVideosContent == null) return const [];
    final list = <_Video>[];
    for (final e in playlistVideosContent!) {
      if (e['playlistVideoRenderer'] != null) {
        list.add(_Video(e['playlistVideoRenderer']));
      } else if (e['lockupViewModel'] != null) {
        list.add(_Video(e['lockupViewModel']));
      }
    }
    return list;
  }
}

class _Video {
  // Json parsed map
  final JsonMap root;

  _Video(this.root);

  bool get _isLockup => root['contentId'] != null;

  String get id => _isLockup 
      ? root.getT<String>('contentId')!
      : root.getT<String>('videoId')!;

  String get author {
    if (_isLockup) {
      final rows = root.get('metadata')?.get('lockupMetadataViewModel')?.get('metadata')?.get('contentMetadataViewModel')?.getList('metadataRows');
      if (rows != null && rows.isNotEmpty) {
        final parts = rows.first.getList('metadataParts');
        if (parts != null && parts.isNotEmpty) {
          return parts.first.get('text')?.getT<String>('content') ?? '';
        }
      }
      return '';
    }
    return root
            .get('ownerText')
            ?.getT<List<dynamic>>('runs')
            ?.cast<Map<dynamic, dynamic>>()
            .parseRuns() ??
        root
            .get('shortBylineText')
            ?.getT<List<dynamic>>('runs')
            ?.cast<Map<dynamic, dynamic>>()
            .parseRuns() ??
        '';
  }

  String get channelId {
    if (_isLockup) {
      final browseId = root
          .get('metadata')
          ?.get('lockupMetadataViewModel')
          ?.get('image')
          ?.get('decoratedAvatarViewModel')
          ?.get('rendererContext')
          ?.get('commandContext')
          ?.get('onTap')
          ?.get('innertubeCommand')
          ?.get('browseEndpoint')
          ?.getT<String>('browseId');
      if (browseId != null) return browseId;
      
      final rows = root.get('metadata')?.get('lockupMetadataViewModel')?.get('metadata')?.get('contentMetadataViewModel')?.getList('metadataRows');
      if (rows != null && rows.isNotEmpty) {
        final parts = rows.first.getList('metadataParts');
        if (parts != null && parts.isNotEmpty) {
          final runs = parts.first.get('text')?.getList('commandRuns');
          if (runs != null && runs.isNotEmpty) {
            return runs.first.get('onTap')?.get('innertubeCommand')?.get('browseEndpoint')?.getT<String>('browseId') ?? '';
          }
        }
      }
      return '';
    }
    return root
            .get('ownerText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        root
            .get('shortBylineText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        root
            .get('shortBylineText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('showDialogCommand')
            ?.get('panelLoadingStrategy')
            ?.get('inlineContent')
            ?.get('dialogViewModel')
            ?.get('customContent')
            ?.get('listViewModel')
            ?.getList('listItems')
            ?.firstOrNull
            ?.get('listItemViewModel')
            ?.get('rendererContext')
            ?.get('commandContext')
            ?.get('onTap')
            ?.get('innertubeCommand')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        '';
  }

  String get title => _isLockup
      ? (root.get('metadata')?.get('lockupMetadataViewModel')?.get('title')?.getT<String>('content') ?? '')
      : (root.get('title')?.getList('runs')?.parseRuns() ?? '');

  String get description => _isLockup
      ? ''
      : (root.getList('descriptionSnippet')?.parseRuns() ?? '');

  Duration? get duration {
    if (_isLockup) {
      final overlays = root.get('contentImage')?.get('thumbnailViewModel')?.getList('overlays');
      if (overlays != null) {
        for (final overlay in overlays) {
          final badgeText = overlay
              .get('thumbnailBottomOverlayViewModel')
              ?.getList('badges')
              ?.firstOrNull
              ?.get('thumbnailBadgeViewModel')
              ?.getT<String>('text');
          if (badgeText != null) {
            return badgeText.toDuration();
          }
        }
      }
      return null;
    }
    return root.get('lengthText')?.getT<String>('simpleText')?.toDuration();
  }

  int get viewCount {
    if (_isLockup) {
      final rows = root.get('metadata')?.get('lockupMetadataViewModel')?.get('metadata')?.get('contentMetadataViewModel')?.getList('metadataRows');
      if (rows != null && rows.length > 1) {
        final parts = rows[1].getList('metadataParts');
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0].get('text')?.getT<String>('content');
          if (text != null) {
            return text.parseInt() ?? 0;
          }
        }
      }
      return 0;
    }
    return root.get('viewCountText')?.getT<String>('simpleText').parseInt() ??
        _videoInfo?.split('•').elementAtSafe(0)?.stripNonDigits().parseInt() ??
        0;
  }

  String? get uploadDateRaw {
    if (_isLockup) {
      final rows = root.get('metadata')?.get('lockupMetadataViewModel')?.get('metadata')?.get('contentMetadataViewModel')?.getList('metadataRows');
      if (rows != null && rows.length > 1) {
        final parts = rows[1].getList('metadataParts');
        if (parts != null && parts.length > 1) {
          return parts[1].get('text')?.getT<String>('content');
        }
      }
      return null;
    }
    return _videoInfo?.split('•').elementAtSafe(1);
  }

  String? get _videoInfo => _isLockup
      ? null
      : root
          .get('videoInfo')
          ?.getT<List<dynamic>>('runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns();
}
