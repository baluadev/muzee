import 'package:flutter/material.dart';
import 'package:muzee/screens/artist_details/artist_details_controller.dart';
import 'package:muzee/screens/artist_details/artist_details_mobile_view.dart';
import 'package:muzee/screens/artist_details/artist_details_tablet_view.dart';
import 'package:muzee/utilities/responsive_layout.dart';

class ArtistDetailsPage extends StatefulWidget {
  const ArtistDetailsPage({super.key, required this.artistId});

  final String artistId;

  @override
  State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends State<ArtistDetailsPage> {
  late final ArtistDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArtistDetailsController(artistId: widget.artistId);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ArtistDetailsMobileView(controller: _controller),
      tablet: ArtistDetailsTabletView(controller: _controller),
    );
  }
}
