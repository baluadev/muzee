import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:muzee/design_system/gallery/neo_gallery_page.dart';
import 'package:muzee/screens/app_shell.dart';
import 'package:muzee/screens/artist_details_page.dart';
import 'package:muzee/screens/explore_page.dart';
import 'package:muzee/screens/home_page.dart';
import 'package:muzee/screens/intro_page.dart';
import 'package:muzee/screens/library_page.dart';
import 'package:muzee/screens/playlist_folder_page.dart';
import 'package:muzee/screens/playlist_page.dart';
import 'package:muzee/screens/premium_paywall_page.dart';
import 'package:muzee/screens/search_page.dart';
import 'package:muzee/screens/settings_page.dart';
import 'package:muzee/screens/user_songs_page.dart';

class NavigationManager {
  factory NavigationManager() {
    return _instance;
  }

  NavigationManager._internal() {
    _setupRouter();
  }

  void _setupRouter() {
    final routes = [
      GoRoute(
        path: introPath,
        parentNavigatorKey: parentNavigatorKey,
        builder: (context, state) => const IntroPage(),
      ),
      GoRoute(
        path: settingsPath,
        parentNavigatorKey: parentNavigatorKey,
        pageBuilder: (context, state) =>
            _pushPage(child: const SettingsPage(), state: state),
        routes: [
          GoRoute(
            path: 'premium',
            parentNavigatorKey: parentNavigatorKey,
            pageBuilder: (context, state) =>
                _pushPage(child: const PremiumPaywallPage(), state: state),
          ),
          if (kDebugMode)
            GoRoute(
              path: designSystemSubPath,
              parentNavigatorKey: parentNavigatorKey,
              pageBuilder: (context, state) =>
                  _pushPage(child: const NeoGalleryPage(), state: state),
            ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        branches: _getRouteBranches(),
        pageBuilder: (context, state, navigationShell) {
          return getPage(
            child: AppShell(child: navigationShell),
            state: state,
          );
        },
      ),
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation:
          Hive.box('settings').get(introShownKey, defaultValue: false) == true
          ? homePath
          : introPath,
      routes: routes,
      restorationScopeId: 'router',
      debugLogDiagnostics: kDebugMode,
      routerNeglect: true,
    );
  }

  static final NavigationManager _instance = NavigationManager._internal();

  static NavigationManager get instance => _instance;

  static late final GoRouter router;

  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> searchTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> libraryTabNavigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext get context {
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      throw StateError(
        'NavigationManager.context was accessed before the navigator context was available.',
      );
    }
    return ctx;
  }

  GoRouterDelegate get routerDelegate => router.routerDelegate;

  GoRouteInformationParser get routeInformationParser =>
      router.routeInformationParser;

  static const String introPath = '/intro';
  static const String homePath = '/home';
  static const String settingsPath = '/settings';
  static const String explorePath = '/explore';
  static const String searchPath = '/search';
  static const String libraryPath = '/library';

  /// Debug-only design-system gallery, under Settings.
  static const String designSystemSubPath = 'design-system';
  static const String designSystemPath = '$settingsPath/$designSystemSubPath';

  List<StatefulShellBranch> _getRouteBranches() {
    // Always return all branches, but handle visibility in the UI
    return [
      // Branch 0: Home
      StatefulShellBranch(
        navigatorKey: homeTabNavigatorKey,
        routes: [
          GoRoute(
            path: homePath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const HomePage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'library',
                pageBuilder: (context, state) =>
                    _pushPage(child: const LibraryPage(), state: state),
              ),
              GoRoute(
                path: 'playlist/:playlistId',
                pageBuilder: (context, state) => _pushPage(
                  child: PlaylistPage(
                    playlistId: state.pathParameters['playlistId'],
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'folder/:folderId/:folderName',
                pageBuilder: (context, state) => _pushPage(
                  child: PlaylistFolderPage(
                    folderId: state.pathParameters['folderId'] ?? '',
                    folderName: state.pathParameters['folderName'] ?? '',
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'artist/:artistId',
                pageBuilder: (context, state) {
                  final artistId = state.pathParameters['artistId']!;
                  return _pushPage(
                    child: ArtistDetailsPage(
                      artistId: Uri.decodeComponent(artistId),
                    ),
                    state: state,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      // Branch 1: Search (its landing page is Explore's content)
      StatefulShellBranch(
        navigatorKey: searchTabNavigatorKey,
        routes: [
          GoRoute(
            path: explorePath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const ExplorePage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'artist/:artistId',
                pageBuilder: (context, state) {
                  final artistId = state.pathParameters['artistId']!;
                  return _pushPage(
                    child: ArtistDetailsPage(
                      artistId: Uri.decodeComponent(artistId),
                    ),
                    state: state,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: searchPath,
            pageBuilder: (context, GoRouterState state) {
              return _pushPage(child: const SearchPage(), state: state);
            },
          ),
        ],
      ),
      // Branch 2: Library
      StatefulShellBranch(
        navigatorKey: libraryTabNavigatorKey,
        routes: [
          GoRoute(
            path: libraryPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const LibraryPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'userSongs/:page',
                pageBuilder: (context, state) => _pushPage(
                  child: UserSongsPage(
                    page: state.pathParameters['page'] ?? 'liked',
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'folder',
                pageBuilder: (context, state) {
                  final folder = state.extra as Map?;
                  return _pushPage(
                    child: PlaylistFolderPage(
                      folderId: folder?['id']?.toString() ?? '',
                      folderName: folder?['name']?.toString() ?? '',
                    ),
                    state: state,
                  );
                },
              ),
              GoRoute(
                path: 'playlist',
                pageBuilder: (context, state) {
                  return _pushPage(
                    child: PlaylistPage(playlistData: state.extra),
                    state: state,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static Page<void> getPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  static Page<void> _pushPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
