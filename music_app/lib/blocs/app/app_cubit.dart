import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/core/enums.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/admob/banner_admanager.dart';
import 'package:muzee/services/admob/native_admanager.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:quiver/async.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppInitial());
  Stream<Duration?> get sleepTimerStream => _sleepTimerSubject.stream;
  final _sleepTimerSubject = StreamController<Duration?>.broadcast();
  TimerAction _timerAction = TimerAction.origin;
  TimerAction get timerAction => _timerAction;
  CountdownTimer? _countDownTimer;
  Duration? _sleepTimerDuration;

  ///
  ///INIT ADS
  ///

  BannerAdmanager bannerWidget = const BannerAdmanager();
  BannerAdmanager bannerCollapWidget =
      const BannerAdmanager(collapsiblePos: 'bottom');

  NativeAdManager nativeAdManager = const NativeAdManager();
  SongNativeAdManager songNativeAdManager = const SongNativeAdManager();
  PlaylistNativeAdManager playlistNativeAdManager =
      const PlaylistNativeAdManager();

  ///
  ///METHODS
  ///
  Future<void> changeLanguage(String languageCode) async {
    emit(AppInitial());
    await LocalStore.inst.setLanguageCode(languageCode);
    emit(AppUpdateLanguage(languageCode: languageCode));
  }

  Future<void> changeCountry(String countryCode) async {
    emit(AppInitial());
    await LocalStore.inst.setCountryCode(countryCode);
    emit(AppUpdateCountry(countryCode: countryCode));
  }

  void _startTimer() {
    if (_sleepTimerDuration == null) return;
    _countDownTimer?.cancel();
    _countDownTimer = CountdownTimer(
      _sleepTimerDuration!,
      const Duration(seconds: 1),
    )..listen((data) {
        _sleepTimerDuration = data.remaining;
        _sleepTimerSubject.add(_sleepTimerDuration!);
      }, onDone: () {
        /// onDone called after duration = 0 or call CountdownTimer.cancel
        if (_sleepTimerDuration!.inSeconds <= 0) {
          // proPlayerCubit.stop();
          _countDownTimer?.cancel();
          _sleepTimerSubject.add(null);
          _timerAction = TimerAction.origin;
          myPlayerService.pause();
          // disables the wakelock again.
          WakelockPlus.disable();
        }
      });
  }

  Future<void> setSleepTime(Duration? duration) async {
    _timerAction = TimerAction.isPlaying;
    _sleepTimerDuration = duration;
    _startTimer();
    emit(SetSleepTimer(duration));
  }

  Future<void> pauseSleepTime() async {
    _timerAction = TimerAction.pause;
    _countDownTimer?.cancel();
    emit(PauseSleepTimer());
  }

  Future<void> resumeSleepTime() async {
    _timerAction = TimerAction.isPlaying;
    _startTimer();
    emit(ResumeSleepTimer());
  }

  Future<void> resetSleepTime() async {
    _countDownTimer?.cancel();
    _sleepTimerDuration = null;
    _sleepTimerSubject.add(null);
    _timerAction = TimerAction.origin;
    emit(ResetSleepTimer());
  }
}
