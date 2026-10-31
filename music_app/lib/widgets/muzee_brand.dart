import 'package:flutter/material.dart';

/// The app icon (white headphones and "Muzee" on the icon's dark tile), with
/// the launcher's rounded corners. Same image in light and dark themes, like
/// the icon on the home screen.
class MuzeeIcon extends StatelessWidget {
  const MuzeeIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/brand/muzee_icon.png',
        width: size,
        height: size,
        semanticLabel: 'Muzee',
      ),
    );
  }
}
