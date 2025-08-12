import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/gen/colors.gen.dart';

class ImageSongWidget extends StatelessWidget {
  final String? id;
  final String? url;
  final double? width;
  final double? height;
  final double? radius;
  final BoxFit? boxFit;
  const ImageSongWidget({
    super.key,
    this.id,
    this.url,
    this.radius,
    this.width,
    this.height,
    this.boxFit,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 5.0),
      child: Container(
        color: MyColors.primary,
        width: width ?? 32.w,
        height: height ?? 32.w,
        child: CachedNetworkImage(
          imageUrl: id != null ? Utils.thumbM(id) : url ?? '',
          fit: boxFit ?? BoxFit.cover,
          errorWidget: (context, url, error) => CachedNetworkImage(
            imageUrl: id != null ? Utils.thumbD(id) : url,
            fit: boxFit ?? BoxFit.cover,
            errorWidget: (context, url, error) =>
                const Icon(FlutterRemix.error_warning_line),
          ),
        ),
      ),
    );
  }
}
