import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';

import 'artist_view.dart';

class Cell extends StatelessWidget {
  final ArtistModel artist;
  const Cell({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushScreenWithNavBar(
        context,
        ArtistView(
          artistModel: artist,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: CachedNetworkImage(
              width: 88.w,
              height: 88.w,
              imageUrl: artist.imgPath ?? '',
              errorWidget: (context, url, error) {
                return Container(
                  color: MyColors.primary,
                  child: Icon(
                    FlutterRemix.user_fill,
                    color: MyColors.black.withOpacity(0.75),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: 88.w,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                artist.name ?? '',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
