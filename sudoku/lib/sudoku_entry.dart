// sudoku_entry.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/bootstrap.dart';
import 'package:sudoku/page/sudoku_game.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/ml/detector.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final Logger log = Logger();

// Future<void> initSudoku() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await SystemChrome.setPreferredOrientations(
//     [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
//   );
// }

Future<SudokuState> loadSudokuState() async {
  if (!Constant.enableGoogleFirebase) {
    log.i("Google Firebase is disabled.");
  }
  await SoundEffect.init();
  await DetectorFactory.getSudokuDetector();
  await DetectorFactory.getDigitsDetector();
  return await SudokuState.resumeFromDB();
}

Widget buildSudokuApp({SudokuState? state, Widget? bannerAds, Widget? nativedAds, VoidCallback? showAds}) {
  SudokuState sudokuState = state ?? SudokuState();
  BootstrapPage bootstrapPage = BootstrapPage(title: "Loading", bannerAds: bannerAds,);
  SudokuGamePage sudokuGamePage = SudokuGamePage(title: "Sudoku", nativedAds: nativedAds, showAds: showAds);

  return ScopedModel<SudokuState>(
    model: sudokuState,
    child: MaterialApp(
      title: 'Sudoku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        SudokuLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SudokuLocalizations.supportedLocales,
      home: bootstrapPage,
      routes: <String, WidgetBuilder>{
        "/bootstrap": (context) => bootstrapPage,
        "/newGame": (context) => sudokuGamePage,
        "/gaming": (context) => sudokuGamePage,
      },
    ),
  );
}
