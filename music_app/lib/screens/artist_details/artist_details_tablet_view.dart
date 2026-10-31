import 'package:flutter/material.dart';
import 'package:muzee/screens/artist_details/artist_details_controller.dart';
import 'package:muzee/screens/artist_details/artist_details_mobile_view.dart';

class ArtistDetailsTabletView extends StatelessWidget {
  const ArtistDetailsTabletView({super.key, required this.controller});
  final ArtistDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ArtistDetailsMobileView(controller: controller),
      ),
    );
  }
}
