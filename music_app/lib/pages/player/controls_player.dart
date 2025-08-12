// import 'dart:async';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:muzee/blocs/player/jojo_player_cubit.dart';
// import 'package:muzee/core/positioned_tap_detector.dart';
// import 'package:muzee/gen/colors.gen.dart';
// import 'package:muzee/main.dart';
// import 'package:flutter/material.dart';
// import 'package:muzee/models/song_model.dart';

// enum FastType { controlFullScreen, player }

// class FastView extends StatefulWidget {
//   const FastView({
//     super.key,
//     required this.fastType,
//     required this.child,
//     this.rippleRadius = 100,
//   });

//   final FastType fastType;
//   final Widget child;
//   final double rippleRadius;

//   @override
//   State<FastView> createState() => _FastViewState();
// }

// class _FastViewState extends State<FastView> with TickerProviderStateMixin {
//   Offset _offset = Offset.zero;
//   Timer? fastTimer;
//   Timer? actionTimer;
//   bool _showTempView = false;

//   AnimationController? fastRewindController;
//   AnimationController? fastForwardController;

//   AnimationController? rippleController;

//   Animation<double>? rippleAnimation;

//   AnimationController? actionController;

//   @override
//   void initState() {
//     fastRewindController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     fastForwardController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     rippleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     rippleAnimation = Tween<double>(
//       begin: 0,
//       end: 100,
//     ).animate(rippleController!);

//     actionController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..addStatusListener((status) {
//         setState(() {
//           _showTempView = status == AnimationStatus.dismissed;
//         });
//       });

//     super.initState();
//     _showTimer();
//   }

//   Future<void> handleShowFastRewind(TapPosition position) async {
//     if (myPlayerService.isInitialized) {
//       final width = MediaQuery.of(context).size.width;
//       if (position.global.dx < width / 2) {
//         myPlayerService.rewind();
//         fastRewindController?.forward();
//       } else {
//         myPlayerService.fastForward();
//         fastForwardController?.forward();
//       }
//       rippleController?.forward();
//       setState(() {
//         _offset = position.relative!;
//       });
//       handleCloseFastView();
//     }
//   }

//   void handleCloseFastView({int mills = 400}) {
//     fastTimer?.cancel();
//     fastTimer = Timer(Duration(milliseconds: mills), () {
//       _offset = Offset.zero;
//       fastTimer?.cancel();
//       fastTimer = null;
//       rippleController?.reset();
//       fastRewindController?.reverse();
//       fastForwardController?.reverse();
//     });
//   }

//   void toggleEnableTimer({bool immediately = false}) {
//     if (actionController?.isCompleted ?? false) {
//       _cancelTimer(immediately: immediately);
//     } else {
//       _showTimer();
//     }
//   }

//   void _showTimer({bool immediately = false}) {
//     if (actionController?.status != AnimationStatus.completed) {
//       actionController?.forward();
//     }
//     _cancelTimer(immediately: immediately);
//   }

//   void _cancelTimer({bool immediately = false}) {
//     actionTimer?.cancel();

//     if (immediately) {
//       actionController?.reverse();
//     } else {
//       actionTimer = Timer(const Duration(seconds: 3), () {
//         actionController?.reverse();

//         actionTimer?.cancel();
//         actionTimer = null;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PositionedTapDetector(
//       onTap: (_) {
//         toggleEnableTimer();
//       },
//       onDoubleTap: handleShowFastRewind,
//       child: Stack(
//         children: <Widget>[
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: <Widget>[
//               Expanded(
//                 child: FadeTransition(
//                   opacity: fastRewindController!,
//                   child: _buildItemSkip(
//                     Icons.fast_rewind,
//                     direction: ClipDirection.ltr,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: FadeTransition(
//                   opacity: fastForwardController!,
//                   child: _buildItemSkip(
//                     Icons.fast_forward,
//                     direction: ClipDirection.rtl,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // Center(
//           //   child: FadeTransition(
//           //     opacity: actionController!,
//           //     child: widget.fastType == FastType.controlFullScreen
//           //         ? VideoTimingView(
//           //             resetTimer: () => _showTimer,
//           //           )
//           //         : widget.child,
//           //   ),
//           // ),
//           if (_showTempView)
//             Positioned.fill(child: Container(color: Colors.transparent))
//         ],
//       ),
//     );
//   }

//   Widget _buildItemSkip(IconData icon, {ClipDirection? direction}) {
//     final width = MediaQuery.of(context).size.width;

//     if (_offset.dx > width / 2) {
//       _offset = _offset.translate(-width / 2, 0);
//     }
//     return ClipPath(
//       clipper: ZigZagClipper(direction: direction!),
//       child: Stack(
//         children: <Widget>[
//           Positioned.fill(
//             child: Material(
//               color: Colors.white70.withOpacity(0.3),
//               child: InkWell(
//                 onTap: () {},
//                 autofocus: true,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     Icon(
//                       icon,
//                       color: Colors.white,
//                     ),
//                     Text(
//                       '10 Seconds',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           RippleAnimated(
//             offset: _offset,
//             controller: rippleAnimation!,
//           )
//         ],
//       ),
//     );
//   }

//   /// dispose in bloc => leak
//   @override
//   void dispose() {
//     actionTimer?.cancel();
//     actionController?.dispose();
//     fastForwardController?.dispose();
//     fastRewindController?.dispose();
//     rippleController?.dispose();
//     super.dispose();
//   }
// }

// class RippleAnimated extends AnimatedWidget {
//   const RippleAnimated({
//     super.key,
//     required this.offset,
//     required Animation<double> controller,
//   }) : super(listenable: controller);

//   final Offset offset;

//   Animation<double> get _progress => listenable as Animation<double>;

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fromRect(
//       rect: Rect.fromCircle(
//         center: offset,
//         radius: _progress.value,
//       ),
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white12,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }

// enum ClipDirection {
//   rtl,
//   ltr,
// }

// class ZigZagClipper extends CustomClipper<Path> {
//   const ZigZagClipper({this.direction = ClipDirection.ltr});

//   final ClipDirection direction;

//   @override
//   Path getClip(Size size) {
//     if (direction == ClipDirection.rtl) {
//       final path = Path()
//         ..lineTo(0.2 * size.width, 0)
//         ..quadraticBezierTo(
//           0,
//           0.5 * size.height,
//           0.2 * size.width,
//           size.height,
//         )
//         ..lineTo(size.width, size.height)
//         ..lineTo(size.width, 0);
//       return path;
//     } else {
//       final path = Path()
//         ..lineTo(0.8 * size.width, 0)
//         ..quadraticBezierTo(
//           size.width,
//           0.5 * size.height,
//           0.8 * size.width,
//           size.height,
//         )
//         ..lineTo(0, size.height)
//         ..lineTo(0, 0);
//       return path;
//     }
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) {
//     return false;
//   }
// }

// class VideoFullControlView extends StatefulWidget {
//   const VideoFullControlView({
//     super.key,
//     this.resetTimer,
//   });

//   final VoidCallback? resetTimer;

//   @override
//   State<VideoFullControlView> createState() => _VideoFullControlViewState();
// }

// class _VideoFullControlViewState extends State<VideoFullControlView>
//     with WidgetsBindingObserver {
//   SongModel? _music;

//   StreamSubscription? _currentPositionSub;
//   StreamSubscription? _currentSongSub;

//   // final _textStyle = AppStyles.copyStyle(fontSize: 13, color: AppStyles.white);

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final isPaused = _currentPositionSub?.isPaused ?? false;

//     if (_currentPositionSub != null) {
//       if (state == AppLifecycleState.resumed && isPaused) {
//         _currentSongSub = myPlayerService.mediaItem.listen(listenStartSong);
//         _currentPositionSub?.resume();
//       }

//       if (state == AppLifecycleState.inactive && !isPaused) {
//         _currentSongSub?.cancel();
//         _currentPositionSub?.pause();
//       }
//     }

//     super.didChangeAppLifecycleState(state);
//   }

//   @override
//   void initState() {
//     WidgetsBinding.instance.addObserver(this);
//     _currentSongSub = myPlayerService.mediaItem.listen(listenStartSong);
//     super.initState();
//   }

//   void listenStartSong(value) {
//     if (mounted) {
//       setState(
//         () => _music = myPlayerService.currentSong,
//       );
//     }
//   }

//   void onSkipToPrevious() {
//     myPlayerService.skipToPrevious();
//   }

//   void onSkipToNext() {
//     myPlayerService.skipToNext();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Container(
//       color: MyColors.black.withOpacity(0.4),
//       child: Stack(
//         children: <Widget>[
//           Positioned(
//             top: 0,
//             left: 0,
//             child: IconButton(
//               color: Colors.white,
//               iconSize: 32,
//               icon: const Icon(Icons.keyboard_arrow_down),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ),
//           Positioned(
//             top: 10,
//             left: 50,
//             child: SizedBox(
//               width: width * 0.7,
//               child: Text(
//                 _music?.title ?? '',
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//             ),
//           ),
//           _buildButtonBar(),
//           _buildSliderTiming(width)
//         ],
//       ),
//     );
//   }

//   Widget _buildSliderTiming(double width) {
//     return StreamBuilder(
//       stream: myPlayerService.progressStream,
//       builder: (cxt, snapshot) {
//         double progress = 0.0;
//         int durationMs = 0;
//         if (snapshot.hasData) {
//           final data = snapshot.data;
//           final position = data?.position ?? Duration.zero;
//           final duration = data?.duration ?? Duration.zero;
//           durationMs = duration.inMilliseconds;
//           final positionMs = position.inMilliseconds.clamp(0, durationMs);
//           progress = (durationMs > 0) ? positionMs / durationMs : 0.0;

//           return Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               height: 60,
//               width: width,
//               padding: const EdgeInsets.only(left: 20),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.max,
//                 children: <Widget>[
//                   Text(
//                     _currentTime(
//                         (durationMs != 0 ? (progress * durationMs) : 0.0)
//                             .toInt()),
//                     style: Theme.of(context).textTheme.labelMedium,
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         activeTrackColor: Colors.red,
//                         inactiveTrackColor: Colors.white.withOpacity(0.7),
//                         thumbColor: Colors.red,
//                         thumbShape:
//                             const RoundSliderThumbShape(enabledThumbRadius: 7),
//                         // trackShape: const CustomTrackShape(),
//                       ),
//                       child: Slider(
//                         value: progress,
//                         onChanged: (progress) {
//                           widget.resetTimer!();
//                           myPlayerService.seek(
//                             Duration(
//                               milliseconds: (progress * durationMs).round(),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     _duration(durationMs),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: Theme.of(context).textTheme.labelMedium,
//                   ),
//                   IconButton(
//                     icon: const Icon(
//                       Icons.fullscreen_exit,
//                       color: Colors.white,
//                     ),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//         return Container();
//       },
//     );
//   }

//   Center _buildButtonBar() {
//     return Center(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           IconButton(
//             onPressed: () {
//               widget.resetTimer!();
//               onSkipToPrevious();
//             },
//             iconSize: 50,
//             color: Colors.white,
//             icon: const Icon(Icons.skip_previous),
//           ),
//           const SizedBox(width: 30),
//           // const PlayPauseControl(),
//           const SizedBox(width: 30),
//           IconButton(
//             onPressed: () {
//               widget.resetTimer!();
//               onSkipToNext();
//             },
//             iconSize: 50,
//             color: Colors.white,
//             icon: const Icon(Icons.skip_next),
//           ),
//         ],
//       ),
//     );
//   }

//   String _currentTime(int miliseconds) {
//     return parseMsToString(miliseconds);
//   }

//   String _duration(int miliseconds) {
//     return parseMsToString(miliseconds);
//   }

//   String parseMsToString(int? duration) {
//     var duration0 = duration;
//     try {
//       if (duration0 == null || duration0 == 0) {
//         return '00:00';
//       } else {
//         var format = '';
//         final hour = (duration0 / 3600000).floor();

//         if (hour > 0) {
//           format = '${_addZeroIfNeed(hour)}:';
//           duration0 -= hour * 3600000;
//         }

//         final minute = (duration0 / 60000).floor();
//         duration0 -= minute * 60000;

//         format += '${_addZeroIfNeed(minute)}:';

//         final second = (duration0 / 1000).floor();

//         return format += _addZeroIfNeed(second);
//       }
//     } catch (e, stackTrace) {
//       debugPrint('$e - $stackTrace');
//       return '00:00';
//     }
//   }

//   String _addZeroIfNeed(int? data) {
//     if (data == null) {
//       return '00';
//     } else if (data < 10) {
//       return '0$data';
//     }
//     return '$data';
//   }

//   @override
//   void dispose() {
//     _currentSongSub?.cancel();
//     _currentPositionSub?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
// }
