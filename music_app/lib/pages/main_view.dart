import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/games/game_center.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/pages/home/home_page.dart';
import 'package:muzee/pages/library/library_page.dart';
import 'package:muzee/pages/search/search_page.dart';
import 'package:muzee/services/admob/appopen_admanager.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/firebase/messaging_service.dart';
import 'package:muzee/services/firebase/remote_service.dart';
import 'package:muzee/services/notification/notification_service.dart';
import 'package:rate_my_app/rate_my_app.dart';

import 'player/full_player.dart';
import 'player/mini_player.dart';

RateMyApp rateMyApp = RateMyApp(
  preferencesPrefix: 'rateMuzee_',
  minDays: 7,
  minLaunches: 10,
  remindDays: 7,
  remindLaunches: 10,
  googlePlayIdentifier: 'up.nexstudio.muzee',
  appStoreIdentifier: '',
);

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with WidgetsBindingObserver {
  PersistentTabController controller = PersistentTabController();
  StreamSubscription? _messagingSub;
  StreamSubscription? _localSub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationService.requestNotificationPermissionWithRetry();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await rateMyApp.init();
        if (mounted && rateMyApp.shouldOpenDialog) {
          rateMyApp.showRateDialog(
            context,
            title: locale.rateTitle,
            message: locale.rateMessage,
            rateButton: locale.rateButton,
            noButton: locale.notNow,
            laterButton: locale.maybeLater,
          );
        }
      });
    });
    WidgetsBinding.instance.addObserver(this);
    controller.jumpToTab(0);
    controller.addListener(() {
      reloadView();
      switch (controller.index) {
        case 0:
          FirebaseAnalyticsService.inst.logScreenEvent('HOME');
          break;
        case 1:
          FirebaseAnalyticsService.inst.logScreenEvent('SEARCH');
          break;
        case 2:
          FirebaseAnalyticsService.inst.logScreenEvent('LIBRARY');
          break;
        default:
      }
    });

    FirebaseMessaging.instance.getToken().then((token) {
      // print('FCM Token: $token');
    });

    // Setup Firebase Messaging
    MessagingService.inst.setup();
    _messagingSub =
        MessagingService.inst.handleData.stream.listen(_handleNotificationData);
    _localSub =
        NotificationService.handleData.stream.listen(_handleNotificationData);
  }

  void _handleNotificationData(SongModel song) {
    Future.delayed(const Duration(seconds: 5), () {
      myPlayerService.setQueue([song]);
    });
  }

  void reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<MuzeePlayerCubit>().close();
    _messagingSub?.cancel();
    _localSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppOpenAdManager.inst.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AppOpenAdManager.inst.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: PersistentTabControllerProvider(
        controller: controller,
        child: BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
          builder: (context, state) {
            final isVisible = state.showFullPlayer;
            const activeColor = MyColors.white;
            final inactiveColor = MyColors.white.withOpacity(0.5);
            return Stack(
              children: [
                PersistentTabView(
                  controller: controller,
                  tabs: [
                    PersistentTabConfig(
                      screen: const HomePage(),
                      item: ItemConfig(
                        icon: const Icon(
                          FlutterRemix.home_2_line,
                          color: activeColor,
                        ),
                        inactiveIcon: Icon(
                          FlutterRemix.home_2_line,
                          color: inactiveColor,
                        ),
                        activeForegroundColor: activeColor,
                        inactiveForegroundColor: inactiveColor,
                        title: locale.home,
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: MyColors.white),
                      ),
                    ),
                    PersistentTabConfig(
                      screen: const SearchPage(),
                      item: ItemConfig(
                        icon: const Icon(
                          FlutterRemix.search_2_line,
                          color: activeColor,
                        ),
                        inactiveIcon: Icon(
                          FlutterRemix.search_2_line,
                          color: inactiveColor,
                        ),
                        activeForegroundColor: activeColor,
                        inactiveForegroundColor: inactiveColor,
                        title: locale.search,
                        textStyle: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                    PersistentTabConfig(
                      screen: const LibraryPage(),
                      item: ItemConfig(
                        icon: const Icon(
                          FlutterRemix.folder_music_line,
                          color: activeColor,
                        ),
                        inactiveIcon: Icon(
                          FlutterRemix.folder_music_line,
                          color: inactiveColor,
                        ),
                        activeForegroundColor: activeColor,
                        inactiveForegroundColor: inactiveColor,
                        title: locale.yourLibrary,
                        textStyle: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                    if (RMConfigService.inst.enableGame || kDebugMode)
                      PersistentTabConfig(
                        screen: const GameCenter(),
                        item: ItemConfig(
                          icon: const Icon(
                            FlutterRemix.gamepad_line,
                            color: activeColor,
                          ),
                          inactiveIcon: Icon(
                            FlutterRemix.gamepad_line,
                            color: inactiveColor,
                          ),
                          activeForegroundColor: activeColor,
                          inactiveForegroundColor: inactiveColor,
                          title: 'Games',
                          textStyle: Theme.of(context).textTheme.titleSmall!,
                        ),
                      ),
                  ],
                  navBarBuilder: (navBarConfig) => Style1BottomNavBar(
                    navBarConfig: navBarConfig,
                    navBarDecoration: NavBarDecoration(
                      // color: MyColors.black.withOpacity(0.9),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MyColors.black.withOpacity(.5),
                          MyColors.black.withOpacity(1),
                        ],
                      ),
                      padding: const EdgeInsets.only(top: 10),
                      // border: Border.all(
                      //   width: 0.1,
                      //   // color: MyColors.secondary,
                      // ),
                    ),
                  ),
                ),
                if (state.currentSong != null)
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child:
                        SafeArea(child: MiniPlayerWidget()), // sẽ tạo bên dưới
                  ),
                AnimatedSlide(
                  offset: isVisible ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: isVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta != null &&
                            details.primaryDelta! > 10) {
                          context
                              .read<MuzeePlayerCubit>()
                              .hideOrShowFullPlayer(false);
                        }
                      },
                      child: const FullPlayerWidget(), // bạn có thể thay thế
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).attachRMConfigWidget();
  }
}

class PersistentTabControllerProvider extends InheritedWidget {
  final PersistentTabController controller;

  const PersistentTabControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static PersistentTabController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<PersistentTabControllerProvider>();
    assert(provider != null,
        'No PersistentTabControllerProvider found in context');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(PersistentTabControllerProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}
