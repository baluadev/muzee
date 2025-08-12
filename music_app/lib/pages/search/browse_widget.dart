import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/liked_playlist/detail_browse.dart';

const dataTopic = [
  {"name": "Pop", "code": "/m/064t9", "thumb": "assets/images/img_pop.png"},
  {"name": "Rock", "code": "/m/06by7", "thumb": "assets/images/img_rock.png"},
  {
    "name": "Hip hop",
    "code": "/m/0glt670",
    "thumb": "assets/images/img_hiphop.png"
  },
  {"name": "Jazz", "code": "/m/03_d0", "thumb": "assets/images/img_jazz.png"},
  {
    "name": "Classical",
    "code": "/m/0ggq0m",
    "thumb": "assets/images/img_classical.png"
  },
  {
    "name": "Country",
    "code": "/m/01lyv",
    "thumb": "assets/images/img_country.png"
  },
  {
    "name": "Movies",
    "code": "/m/02vxn",
    "thumb": "assets/images/img_movie.png"
  },
  {
    "name": "Game",
    "code": "/m/02hygl",
    "thumb": "assets/images/img_music_game.png"
  },
  {"name": "Asia", "code": "/m/028sqc", "thumb": "assets/images/img_asian.png"},
  {
    "name": "America",
    "code": "/m/0g293",
    "thumb": "assets/images/img_american.png"
  }
];

class BrowseWidget extends StatefulWidget {
  const BrowseWidget({super.key});

  @override
  State<BrowseWidget> createState() => _BrowseWidgetState();
}

class _BrowseWidgetState extends State<BrowseWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              locale.browse,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Wrap(
            direction: Axis.horizontal,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              dataTopic.length,
              (index) {
                final item = dataTopic.elementAt(index);
                return BrowseCell(data: item).attachGestureDetector(
                  onTap: () => pushScreenWithNavBar(
                    context,
                    DetailBrowse(
                      title: item['name']!,
                      genreCode: item['code']!,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BrowseCell extends StatelessWidget {
  final Map data;
  const BrowseCell({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150.w,
      height: 80.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: Image.asset(data['thumb']).image,
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        data['name'],
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
