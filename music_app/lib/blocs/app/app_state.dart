part of 'app_cubit.dart';

sealed class AppState extends Equatable {
  const AppState();

  @override
  List<Object> get props => [];
}

final class AppInitial extends AppState {}

final class AppUpdateLanguage extends AppState {
  final String languageCode;

  const AppUpdateLanguage({required this.languageCode});
}

final class AppUpdateCountry extends AppState {
  final String countryCode;

  const AppUpdateCountry({required this.countryCode});
}

final class AppUpdatePremium extends AppState {
  const AppUpdatePremium();
}

class SleepTimerState extends AppState {
  final Duration? remaining;
  final bool isActive;

  const SleepTimerState({this.remaining, this.isActive = false});
}

class SetSleepTimer extends AppState {
  /// ms
  final Duration? duration;

  const SetSleepTimer(this.duration);

  @override
  List<Object> get props => [duration ?? Duration.zero];
}

class PauseSleepTimer extends AppState {
  @override
  List<Object> get props => [];
}

class ResumeSleepTimer extends AppState {
  @override
  List<Object> get props => [];
}

class ResetSleepTimer extends AppState {
  @override
  List<Object> get props => [];
}
