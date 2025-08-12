import 'package:flutter/widgets.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

/// LocalizationUtils
class LocalizationUtils {
  static String localizationLevelName(BuildContext context, Level level) {
    switch (level) {
      case Level.easy:
        return SudokuLocalizations.of(context).levelEasy;
      case Level.medium:
        return SudokuLocalizations.of(context).levelMedium;
      case Level.hard:
        return SudokuLocalizations.of(context).levelHard;
      case Level.expert:
        return SudokuLocalizations.of(context).levelExpert;
    }
  }

  static String localizationGameStatus(
      BuildContext context, SudokuGameStatus status) {
    switch (status) {
      case SudokuGameStatus.initialize:
        return SudokuLocalizations.of(context).gameStatusInitialize;
      case SudokuGameStatus.gaming:
        return SudokuLocalizations.of(context).gameStatusGaming;
      case SudokuGameStatus.pause:
        return SudokuLocalizations.of(context).gameStatusPause;
      case SudokuGameStatus.fail:
        return SudokuLocalizations.of(context).gameStatusFailure;
      case SudokuGameStatus.success:
        return SudokuLocalizations.of(context).gameStatusVictory;
    }
  }
}
