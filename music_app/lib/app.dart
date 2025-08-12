import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/blocs/search/search_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:muzee/services/notification/notification_service.dart';
import 'blocs/app/app_cubit.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/library/library_cubit.dart';
import 'configs/app_themes.dart';
import 'configs/const.dart';
import 'core/app_routes.dart';
import 'core/navigation_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryCubit = LibraryCubit();
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AppCubit()),
            BlocProvider(create: (_) => AuthCubit()),
            BlocProvider(
              create: (_) {
                final muzeePlayerCubit = MuzeePlayerCubit(
                  myPlayerService,
                  libraryCubit,
                );
                NotificationService.playerCubit = muzeePlayerCubit;
                return muzeePlayerCubit;
              },
            ),
            BlocProvider(create: (_) => libraryCubit),
            BlocProvider(create: (_) => SearchCubit()),
          ],
          child: BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
              final languageCode = LocalStore.inst.getLanguageCode;
              return MaterialApp(
                navigatorKey: NavigationService.inst.rootNavigatorKey,
                title: 'Muzee',
                debugShowCheckedModeBanner: false,
                // themeMode: state.themeMode,
                // darkTheme: AppThemes.darkTheme,
                theme: AppThemes.lightTheme,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: Const.supportedLocales,
                locale: Locale(languageCode),

                initialRoute: AppRoutes.root,
                onGenerateRoute: AppRoutes().onGenerateRoute,
              );
            },
          ),
        );
      },
    );
  }
}
