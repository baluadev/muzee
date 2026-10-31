import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_bottom_sheet.dart'
    show closeCurrentBottomSheet;
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/tablet_detail_manager.dart';
import 'package:muzee/widgets/mini_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.child, super.key});

  final StatefulNavigationShell child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Track the previously selected tab index to detect double-taps on the same tab.
  int? _previousTabIndex;

  StreamSubscription<Map>? _playbackErrorSubscription;

  @override
  void initState() {
    super.initState();
    _playbackErrorSubscription = audioHandler.playbackErrors.listen(
      _showPlaybackError,
    );
  }

  @override
  void dispose() {
    _playbackErrorSubscription?.cancel();
    super.dispose();
  }

  void _showPlaybackError(Map song) {
    if (!mounted) return;
    // Several songs in a row can fail; show only the latest.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showToast(
      context,
      context.l10n!.songUnavailable(song['title']?.toString() ?? ''),
      icon: FluentIcons.warning_20_regular,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.child.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final currentIndex = widget.child.currentIndex;
        if (currentIndex != 0) {
          widget.child.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
          // Typing in a search field: the mini player would sit on the
          // keyboard and cover the suggestions.
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
          final items = _getNavigationItems();
          final selectedIndex = _getCurrentIndex(items);

          return Scaffold(
            body: SafeArea(
              bottom: isLargeScreen,
              child: Row(
                children: [
                  if (isLargeScreen)
                    NavigationRail(
                      labelType: NavigationRailLabelType.all,
                      destinations: items
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label),
                            ),
                          )
                          .toList(),
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) =>
                          _onTabTapped(index, items),
                    ),
                  Expanded(
                    child: ValueListenableBuilder<Widget?>(
                      valueListenable:
                          TabletDetailManager.instance.detailWidget,
                      builder: (context, detailWidget, _) {
                        final showDetail =
                            isLargeScreen && detailWidget != null;
                        return Row(
                          children: [
                            Expanded(
                              flex: showDetail ? 4 : 10,
                              child: Column(
                                children: [
                                  Expanded(child: widget.child),
                                  if (!keyboardOpen) const MiniPlayer(),
                                ],
                              ),
                            ),
                            if (showDetail) ...[
                              VerticalDivider(
                                width: 1,
                                color: context.neo.hairline,
                              ),
                              Expanded(flex: 6, child: detailWidget),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Theme (buildNeoTheme): app background, indicator pill, filled
            // icon and bold label for the selected tab. Labels always show,
            // in every language.
            bottomNavigationBar: isLargeScreen
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.neo.hairline),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: selectedIndex,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: (index) =>
                          _onTabTapped(index, items),
                      destinations: items
                          .map(
                            (item) => NavigationDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: item.label,
                              tooltip: '',
                            ),
                          )
                          .toList(),
                    ),
                  ),
          );
        },
      ),
    );
  }

  /// Home, Search and Library. Settings and Premium open from the avatar on
  /// Home.
  List<_NavigationItem> _getNavigationItems() {
    final l10n = context.l10n!;
    return [
      _NavigationItem(
        icon: FluentIcons.home_24_regular,
        selectedIcon: FluentIcons.home_24_filled,
        label: l10n.home,
        shellIndex: 0,
      ),
      _NavigationItem(
        icon: FluentIcons.search_24_regular,
        selectedIcon: FluentIcons.search_24_filled,
        label: l10n.search,
        shellIndex: 1,
      ),
      _NavigationItem(
        icon: FluentIcons.library_24_regular,
        selectedIcon: FluentIcons.library_24_filled,
        label: l10n.library,
        shellIndex: 2,
      ),
    ];
  }

  void _onTabTapped(int index, List<_NavigationItem> items) {
    if (index < items.length) {
      final item = items[index];
      final isReselect = _previousTabIndex == index;

      // Close any open bottom sheet before switching tabs
      closeCurrentBottomSheet();

      // Clear the detail pane on tablet when switching tabs
      TabletDetailManager.instance.clear();

      // If user taps the same tab again, reset it to initial state.
      // Otherwise, preserve the branch state.
      if (isReselect) {
        widget.child.goBranch(item.shellIndex, initialLocation: true);
      } else {
        widget.child.goBranch(item.shellIndex);
      }

      _previousTabIndex = index;
    }
  }

  int _getCurrentIndex(List<_NavigationItem> items) {
    final matchedIndex = items.indexWhere(
      (item) => item.shellIndex == widget.child.currentIndex,
    );
    return matchedIndex == -1 ? 0 : matchedIndex;
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.shellIndex,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int shellIndex;
}
