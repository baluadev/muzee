import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/ytb/ytb_service.dart';
import 'package:muzee/views/artist/artist_view.dart';

class TrendingArtists extends StatefulWidget {
  const TrendingArtists({super.key});

  @override
  State<TrendingArtists> createState() => _TrendingArtistsState();
}

class _TrendingArtistsState extends State<TrendingArtists> {
  List<ArtistModel> artists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchArtists();
      context.read<AppCubit>().stream.listen((state) {
        fetchArtists();
      });
    });

    context.read<AuthCubit>().stream.listen((state) {
      if (state.isLoggedIn) fetchArtists();
    });
  }

  Future<void> fetchArtists() async {
    try {
      artists = await YtbService.getTrendingArtistsFromYouTube();
    } catch (e) {
      artists = [];
    }
    reloadView();
  }

  reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 16.h),
            child: Row(
              children: [
                Assets.icons.trendingUp.svg(width: 20.w),
                SizedBox(width: 8.w),
                Text(
                  locale.trendingArtists,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 16.w),
              children: List.generate(
                artists.length,
                (index) => Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: GestureDetector(
                    onTap: () {
                      pushScreenWithNavBar(
                        context,
                        ArtistView(
                          artistModel: artists[index],
                        ),
                      );
                    },
                    child: ArtistCell(
                      artist: artists[index],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArtistCell extends StatelessWidget {
  final ArtistModel artist;
  const ArtistCell({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: CachedNetworkImage(
              width: 64.w,
              height: 64.w,
              imageUrl: artist.imgPath ?? '',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  Icon(FlutterRemix.user_line, size: 64.w),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            artist.name ?? 'Unknown Artist',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
