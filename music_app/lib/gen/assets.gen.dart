/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/ic_add.png
  AssetGenImage get icAdd => const AssetGenImage('assets/icons/ic_add.png');

  /// File path: assets/icons/ic_artist.png
  AssetGenImage get icArtist =>
      const AssetGenImage('assets/icons/ic_artist.png');

  /// File path: assets/icons/ic_back.png
  AssetGenImage get icBack => const AssetGenImage('assets/icons/ic_back.png');

  /// File path: assets/icons/ic_close.svg
  SvgGenImage get icClose => const SvgGenImage('assets/icons/ic_close.svg');

  /// File path: assets/icons/ic_download.png
  AssetGenImage get icDownload =>
      const AssetGenImage('assets/icons/ic_download.png');

  /// File path: assets/icons/ic_edit.svg
  SvgGenImage get icEdit => const SvgGenImage('assets/icons/ic_edit.svg');

  /// File path: assets/icons/ic_favorite.png
  AssetGenImage get icFavorite =>
      const AssetGenImage('assets/icons/ic_favorite.png');

  /// File path: assets/icons/ic_home.png
  AssetGenImage get icHome => const AssetGenImage('assets/icons/ic_home.png');

  /// File path: assets/icons/ic_library.png
  AssetGenImage get icLibrary =>
      const AssetGenImage('assets/icons/ic_library.png');

  /// File path: assets/icons/ic_more.png
  AssetGenImage get icMore => const AssetGenImage('assets/icons/ic_more.png');

  /// File path: assets/icons/ic_playlist.png
  AssetGenImage get icPlaylist =>
      const AssetGenImage('assets/icons/ic_playlist.png');

  /// File path: assets/icons/ic_plus.svg
  SvgGenImage get icPlus => const SvgGenImage('assets/icons/ic_plus.svg');

  /// File path: assets/icons/ic_search.png
  AssetGenImage get icSearch =>
      const AssetGenImage('assets/icons/ic_search.png');

  /// File path: assets/icons/ic_search2.png
  AssetGenImage get icSearch2 =>
      const AssetGenImage('assets/icons/ic_search2.png');

  /// File path: assets/icons/ic_sort.png
  AssetGenImage get icSort => const AssetGenImage('assets/icons/ic_sort.png');

  /// File path: assets/icons/ic_trash.svg
  SvgGenImage get icTrash => const SvgGenImage('assets/icons/ic_trash.svg');

  /// File path: assets/icons/ic_user.svg
  SvgGenImage get icUser => const SvgGenImage('assets/icons/ic_user.svg');

  /// File path: assets/icons/trending_up.svg
  SvgGenImage get trendingUp =>
      const SvgGenImage('assets/icons/trending_up.svg');

  /// List of all assets
  List<dynamic> get values => [
        icAdd,
        icArtist,
        icBack,
        icClose,
        icDownload,
        icEdit,
        icFavorite,
        icHome,
        icLibrary,
        icMore,
        icPlaylist,
        icPlus,
        icSearch,
        icSearch2,
        icSort,
        icTrash,
        icUser,
        trendingUp
      ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/crown.png
  AssetGenImage get crown => const AssetGenImage('assets/images/crown.png');

  /// File path: assets/images/img_american.png
  AssetGenImage get imgAmerican =>
      const AssetGenImage('assets/images/img_american.png');

  /// File path: assets/images/img_asian.png
  AssetGenImage get imgAsian =>
      const AssetGenImage('assets/images/img_asian.png');

  /// File path: assets/images/img_classical.png
  AssetGenImage get imgClassical =>
      const AssetGenImage('assets/images/img_classical.png');

  /// File path: assets/images/img_country.png
  AssetGenImage get imgCountry =>
      const AssetGenImage('assets/images/img_country.png');

  /// File path: assets/images/img_hiphop.png
  AssetGenImage get imgHiphop =>
      const AssetGenImage('assets/images/img_hiphop.png');

  /// File path: assets/images/img_jazz.png
  AssetGenImage get imgJazz =>
      const AssetGenImage('assets/images/img_jazz.png');

  /// File path: assets/images/img_movie.png
  AssetGenImage get imgMovie =>
      const AssetGenImage('assets/images/img_movie.png');

  /// File path: assets/images/img_music_game.png
  AssetGenImage get imgMusicGame =>
      const AssetGenImage('assets/images/img_music_game.png');

  /// File path: assets/images/img_pop.png
  AssetGenImage get imgPop => const AssetGenImage('assets/images/img_pop.png');

  /// File path: assets/images/img_rock.png
  AssetGenImage get imgRock =>
      const AssetGenImage('assets/images/img_rock.png');

  /// File path: assets/images/verify.png
  AssetGenImage get verify => const AssetGenImage('assets/images/verify.png');

  /// List of all assets
  List<AssetGenImage> get values => [
        crown,
        imgAmerican,
        imgAsian,
        imgClassical,
        imgCountry,
        imgHiphop,
        imgJazz,
        imgMovie,
        imgMusicGame,
        imgPop,
        imgRock,
        verify
      ];
}

class Assets {
  Assets._();

  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class SvgGenImage {
  const SvgGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = false;

  const SvgGenImage.vec(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
