import 'dart:collection';

import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

final Logger log = Logger();

/// this class define sound effect
class SoundEffect {
  static bool _init = false;

  static final AudioPlayer _wrongAudio = AudioPlayer();
  static final AudioPlayer _victoryAudio = AudioPlayer();
  static final AudioPlayer _gameOverAudio = AudioPlayer();

  // show user tips sound effect
  static final AudioPlayer _answerTipAudio = AudioPlayer();

  static init() async {
    if (!_init) {
      await _wrongAudio.setAsset("packages/sudoku/assets/audio/wrong_tip.mp3");
      await _victoryAudio.setAsset("packages/sudoku/assets/audio/victory_tip.mp3");
      await _gameOverAudio.setAsset("packages/sudoku/assets/audio/gameover_tip.mp3");
      await _answerTipAudio.setAsset("packages/sudoku/assets/audio/answer_tip.mp3");
    }
    _init = true;
  }

  static stuffError() async {
    if (!_init) {
      await init();
    }
    await _wrongAudio.seek(Duration.zero);
    await _wrongAudio.play();
  }

  static solveVictory() async {
    if (!_init) {
      await init();
    }
    await _victoryAudio.seek(Duration.zero);
    await _victoryAudio.play();
  }

  static gameOver() async {
    if (!_init) {
      await init();
    }
    await _gameOverAudio.seek(Duration.zero);
    await _gameOverAudio.play();
  }

  static answerTips() async {
    if (!_init) {
      await init();
    }
    await _answerTipAudio.seek(Duration.zero);
    await _answerTipAudio.play();
  }

  static final AudioPlayer _sudokuVoice = AudioPlayer();
  static final HashSet<String> _sudokuLanguageVoiceEmptySet = HashSet();

  static sudokuSpeak(String languageCode) async {
    print("play voice use language : $languageCode");

    bool isEmpty = _sudokuLanguageVoiceEmptySet.contains(languageCode);
    if (isEmpty) {
      languageCode = "en";
    }

    String sudokuSpeakAssetFile =
        "packages/sudoku/assets/audio/speak/sudoku_${languageCode}.mp3";
    try {
      AudioSource as = AudioSource.asset(sudokuSpeakAssetFile);
      await _sudokuVoice.setAudioSource(as);
      await _sudokuVoice.play();
    } catch (e, stacktrace) {
      log.e(e, stackTrace: stacktrace);
      _sudokuLanguageVoiceEmptySet.add(languageCode);
      AudioSource as = AudioSource.asset("packages/sudoku/assets/audio/speak/sudoku_en.mp3");
      await _sudokuVoice.setAudioSource(as);
      await _sudokuVoice.play();
    }
  }
}
