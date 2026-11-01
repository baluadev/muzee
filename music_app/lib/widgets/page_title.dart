import 'package:flutter/material.dart';

/// The big title at the top of a main tab (Search, Library), matching
/// Home's greeting: same size, weight and left edge. [trailing] sits at the
/// end of the row (e.g. Library's "+").
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, trailing == null ? 16 : 8, 4),
      child: SizedBox(
        // Home's header row height (its 48 dp settings button).
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
