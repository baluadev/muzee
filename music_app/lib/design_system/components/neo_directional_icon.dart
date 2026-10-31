import 'package:flutter/material.dart';

/// An icon that points "forward": mirrored in right-to-left locales (Hebrew),
/// because the Fluent glyphs are not marked `matchTextDirection`.
class NeoDirectionalIcon extends StatelessWidget {
  const NeoDirectionalIcon(this.icon, {this.size, this.color, super.key});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: Icon(icon, size: size, color: color),
    );
  }
}
