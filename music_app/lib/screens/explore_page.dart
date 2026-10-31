import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzee/screens/artists_page.dart';
import 'package:muzee/screens/explore/explore_controller.dart';
import 'package:muzee/screens/explore/explore_mobile_view.dart';
import 'package:muzee/utilities/adaptive_navigation.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final ExploreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExploreController();
  }

  void _onSearchTap() {
    context.push('/search');
  }

  void _onArtistsViewAll() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArtistsPage()),
    );
  }

  void _onArtistSelected(String artistId) {
    AdaptiveNavigation.pushArtist(
      context,
      artistId: artistId,
      baseRoute: '/explore',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExploreMobileView(
        controller: _controller,
        onSearchTap: _onSearchTap,
        onArtistsViewAll: _onArtistsViewAll,
        onArtistSelected: _onArtistSelected,
      ),
    );
  }
}
