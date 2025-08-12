import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/core/enums.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/gen/colors.gen.dart';

class SleepTimerView extends StatefulWidget {
  const SleepTimerView({super.key});

  @override
  State<SleepTimerView> createState() => _SleepTimerViewState();
}

class _SleepTimerViewState extends State<SleepTimerView> {
  late AppCubit appBloc;

  int _hours = 0;
  int _min = 0;

  Duration? _remainDuration;

  TimerAction? _timerAction;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    appBloc = BlocProvider.of<AppCubit>(context);
    _subscription = appBloc.sleepTimerStream.listen((duration) {
      setState(() => _remainDuration = duration);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _timerAction = appBloc.timerAction;
    return Scaffold(
      appBar: CustomAppBar(title: locale.sleepTimer),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            if (_timerAction == TimerAction.origin)
              Container(
                height: 250,
                margin: const EdgeInsets.only(top: 50, bottom: 10),
                child: Stack(
                  children: <Widget>[
                    _buildScrollTime(),
                    Center(
                        child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 17),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: MyColors.primary),
                          bottom: BorderSide(color: MyColors.primary),
                        ),
                      ),
                    )),
                  ],
                ),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 50, bottom: 10),
                child: Text(
                  Utils.formatDuration(_remainDuration ?? const Duration()),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_timerAction == TimerAction.origin)
              _buildButton(
                title: locale.sleepStart,
                onTap: _setTimer,
              ),
            if (_timerAction == TimerAction.isPlaying)
              _buildButton(
                title: locale.sleepPause,
                onTap: () => _pauseTimer(),
              ),
            if (_timerAction == TimerAction.pause)
              _buildButton(
                title: locale.sleepResume,
                onTap: () => _resumeTimer(),
              ),
            if (_timerAction != TimerAction.origin)
              _buildButton(
                title: locale.sleepReset,
                onTap: () => _resetTimer(),
                color: Colors.red,
              ),
            // const BottomPaddingPlaying(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({String? title, VoidCallback? onTap, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 16.w),
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(backgroundColor: MyColors.primary),
        onPressed: onTap,
        // color: Theme.of(context).buttonColor,
        // padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title ?? '',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: MyColors.black.withOpacity(0.75)),
        ),
      ),
    );
  }

  Widget _buildScrollTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildWheel(
            totalItem: 24,
            onSelectedItemChanged: (hour) => _hours = hour,
          ),
          _buildTitle(locale.sleepHours),
          const SizedBox(width: 20),
          _buildWheel(
            totalItem: 60,
            onSelectedItemChanged: (min) => _min = min,
          ),
          _buildTitle(
            locale.sleepMin,
          ),
        ],
      ),
    );
  }

  Container _buildTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      child: Text(
        title,
        // style: ,
      ),
    );
  }

  Widget _buildWheel({int? totalItem, Function(int)? onSelectedItemChanged}) {
    return Expanded(
      child: ListWheelScrollView(
          itemExtent: 40,
          useMagnifier: true,
          diameterRatio: 1.6,
          magnification: 1.5,
          onSelectedItemChanged: onSelectedItemChanged,
          physics: const FixedExtentScrollPhysics(),
          children: List.generate(totalItem ?? 0, (index) {
            return Text(
              '$index',
              // style: AppStyles.headline5(context),
            );
          })),
    );
  }

  void _pauseTimer() {
    setState(() => _timerAction = TimerAction.pause);
    appBloc.pauseSleepTime();
  }

  void _resumeTimer() {
    setState(() => _timerAction = TimerAction.isPlaying);
    appBloc.resumeSleepTime();
  }

  void _resetTimer() {
    setState(() => _timerAction = TimerAction.origin);
    appBloc.resetSleepTime();
  }

  void _setTimer() {
    if (_hours == 0 && _min == 0) {
      Utils.showToast(locale.sleepTimeInvalid);
      return;
    }
    _timerAction = TimerAction.origin;

    /// seconds = 2 because delay
    final duration = Duration(hours: _hours, minutes: _min, seconds: 1);
    appBloc.setSleepTime(duration);

    /// reset time
    _hours = 0;
    _min = 0;
  }
}
