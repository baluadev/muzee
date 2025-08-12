import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/sudoku_pause_cover.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku/util/localization_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

final Logger log = Logger();
final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black54,
  shadowColor: Colors.blue,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

final ButtonStyle primaryFlatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.lightBlue,
  shadowColor: Colors.blue,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

const ideaAssetImage = AssetImage("packages/sudoku/assets/image/icon_idea.png");
const lifeAssetImage = AssetImage("packages/sudoku/assets/image/icon_life.png");
const logoAssetImage = AssetImage("packages/sudoku/assets/image/sudoku_logo.png");
const eraserAssetImage = AssetImage("packages/sudoku/assets/image/icon_eraser.png");

const Image ideaPng = Image(
  image: ideaAssetImage,
  width: 25,
  height: 25,
);
const Image lifePng = Image(
  image: lifeAssetImage,
  width: 25,
  height: 25,
);

final timerPauseAssetSvg = SvgPicture.asset(
  "packages/sudoku/assets/svg/pause-mini-fill.svg",
  width: 25,
  height: 25,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
);

final lightbulbAssetSvg = SvgPicture.asset(
  "packages/sudoku/assets/svg/brain-line.svg",
  width: 25,
  height: 25,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
);

final lightbulbDisableAssetSvg = SvgPicture.asset(
  "packages/sudoku/assets/svg/brain-line.svg",
  width: 25,
  height: 25,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.white12, BlendMode.srcIn),
);

final noteAltAssetSvg = SvgPicture.asset(
  "packages/sudoku/assets/svg/sticky-note-add-line.svg",
  width: 25,
  height: 25,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
);

final exitToAppAssetSvg = SvgPicture.asset(
  "packages/sudoku/assets/svg/logout-circle-r-line.svg",
  width: 25,
  height: 25,
  colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
);

class SudokuGamePage extends StatefulWidget {
  SudokuGamePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _SudokuGamePageState createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with WidgetsBindingObserver {
  /// 选中的格子
  int _chooseSudokuBox = 0;

  // 与选中格子形成关联的格子集合 : 行 / 列 / 宫
  Set<int> _correlationChooseBoxes = {};

  /// 感知选中数字
  int _perceptionNum = 0;
  bool _markOpen = false;
  bool _manualPause = false;

  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  _aboutDialogAction(BuildContext context) {
    Widget appIcon = GestureDetector(
        child: Image(image: logoAssetImage, width: 45, height: 45),
        onDoubleTap: () {
          WidgetBuilder columnWidget = (BuildContext context) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(image: logoAssetImage),
                  CupertinoButton(
                    child: Text(
                      SudokuLocalizations.of(context).appName,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  )
                ]);
          };
          showDialog(context: context, builder: columnWidget);
        });
    return showAboutDialog(
        applicationIcon: appIcon,
        applicationName: SudokuLocalizations.of(context).appName,
        context: context,
        children: <Widget>[
          GestureDetector(
            child: Text(
              "Github Repository",
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () async {
              if (await canLaunchUrlString(Constant.githubRepository)) {
                if (Platform.isAndroid) {
                  await launchUrlString(
                    Constant.githubRepository,
                    mode: LaunchMode.externalApplication,
                    browserConfiguration: BrowserConfiguration(showTitle: true),
                    webOnlyWindowName: "Sudoku-Flutter Github Repository",
                  );
                } else {
                  await launchUrlString(Constant.githubRepository,
                      mode: LaunchMode.externalApplication);
                }
              } else {
                log.e(
                    "can't open browser to url : ${Constant.githubRepository}");
              }
            },
          ),
          Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
              padding: EdgeInsets.all(0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sudoku powered by Flutter",
                        style: TextStyle(fontSize: 12)),
                    Text(Constant.githubRepository,
                        style: TextStyle(fontSize: 12))
                  ]))
        ]);
  }

  bool _isOnlyReadGrid(int index) => (_state.sudoku?.puzzle[index] ?? 0) != -1;

  // 游戏盘点，检查是否游戏结束
  // check the game is done
  void _gameStackCount() {
    if (_state.isComplete) {
      _pauseTimer();
      _state.updateStatus(SudokuGameStatus.success);
      return _gameOver();
    }
  }

  /// game over trigger function
  void _gameOver() async {
    bool isWinner = _state.status == SudokuGameStatus.success;

    // i18n
    final String elapsedTimeText =
        SudokuLocalizations.of(context).elapsedTimeText;
    final String winnerConclusionText =
        SudokuLocalizations.of(context).winnerConclusionText;
    final String failureConclusionText =
        SudokuLocalizations.of(context).failureConclusionText;
    final String levelLabel =
        LocalizationUtils.localizationLevelName(context, _state.level!);

    // nội dung & âm thanh
    String title = isWinner ? "🎉 Well Done!" : "💀 Game Over";
    String conclusion =
        (isWinner ? winnerConclusionText : failureConclusionText)
            .replaceFirst("%level%", levelLabel);
    Function playSoundEffect =
        isWinner ? SoundEffect.solveVictory : SoundEffect.gameOver;

    // Giao diện trang kết quả
    PageRouteBuilder gameOverPageRouteBuilder = PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, animation, _) {
        playSoundEffect();

        Widget gameOverWidget = Scaffold(
          backgroundColor: Colors.black.withOpacity(0.8),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isWinner
                            ? Colors.lightGreenAccent
                            : Colors.redAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      conclusion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$elapsedTimeText : ${_state.timer}'s",
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!isWinner)
                          IconButton(
                            icon: const Icon(Icons.tv, color: Colors.grey),
                            tooltip: "Watch Ad (Get Extra Life)",
                            onPressed: () => Navigator.pop(context, "ad"),
                          ),
                        IconButton(
                          icon: const Icon(Icons.thumb_up, color: Colors.white),
                          tooltip: "Like Game",
                          onPressed: () {
                            // future: show rating, share, etc.
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.exit_to_app,
                              color: Colors.white),
                          tooltip: "Exit",
                          onPressed: () => Navigator.pop(context, "exit"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );

        return ScaleTransition(
          scale: Tween(begin: 3.0, end: 1.0).animate(animation),
          child: gameOverWidget,
        );
      },
    );

    String signal = await Navigator.of(context).push(gameOverPageRouteBuilder);
    switch (signal) {
      case "ad":
        // TODO: logic xem quảng cáo để hồi sinh
        break;
      case "exit":
      default:
        Navigator.pop(context);
        break;
    }
  }

  // fill zone [ 1 - 9 ]
  Widget _fillZone(BuildContext context) {
    List<Widget> fillTools = List.generate(
      9,
      (index) {
        int num = index + 1;
        bool hasNumStock = _state.hasNumStock(num);
        var fillOnPressed;
        if (!hasNumStock) {
          fillOnPressed = null;
        } else {
          fillOnPressed = () async {
            log.d("input : $num");
            if (_isOnlyReadGrid(_chooseSudokuBox)) {
              // 非填空项
              return;
            }
            if (_state.status != SudokuGameStatus.gaming) {
              // 未在游戏进行时
              return;
            }
            if (_markOpen) {
              /// markOpen , mean use mark notes
              log.d("填写笔记");
              _state.switchMark(_chooseSudokuBox, num);
            } else {
              // 填写数字
              _state.switchRecord(_chooseSudokuBox, num);
              // 判断真伪
              if (_state.record[_chooseSudokuBox] != -1 &&
                  _state.sudoku!.solution[_chooseSudokuBox] != num) {
                // 填入错误数字 wrong answer on _chooseSudokuBox with num
                _state.lifeLoss();

                if (_state.life <= 0) {
                  // 游戏结束
                  return _gameOver();
                }

                // "\nWrong Input\nYou can't afford ${_state.life} more turnovers"
                String wrongInputAlertText =
                    SudokuLocalizations.of(context).wrongInputAlertText;
                wrongInputAlertText = wrongInputAlertText.replaceFirst(
                    "%attempts%", "${_state.life}");
                String gotItText = SudokuLocalizations.of(context).gotItText;

                showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      // sound stuff error
                      SoundEffect.stuffError();
                      return CupertinoAlertDialog(
                        title: Text("Oops..."),
                        content: Text(wrongInputAlertText),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(gotItText),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    });

                return;
              }
              _gameStackCount();
            }
          };
        }

        Color recordFontColor = hasNumStock ? Colors.white : Colors.orange;
        Color recordBgColor = hasNumStock ? Colors.white10 : Colors.black26;

        Color markFontColor = hasNumStock ? Colors.orange : Colors.orange;
        Color markBgColor = hasNumStock ? Colors.white : Colors.black26;

        return Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(border: BorderDirectional()),
            child: CupertinoButton(
              color: _markOpen ? markBgColor : recordBgColor,
              borderRadius: BorderRadius.circular(99),
              padding: EdgeInsets.all(1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: _markOpen ? markFontColor : recordFontColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: fillOnPressed,
            ),
          ),
        );
      },
    );

    fillTools.add(Expanded(
        flex: 1,
        child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(border: BorderDirectional()),
            child: CupertinoButton(
                padding: EdgeInsets.all(8),
                color: Colors.white10,
                borderRadius: BorderRadius.circular(99),
                child: Image(
                  image: eraserAssetImage,
                  width: 40,
                  height: 40,
                  color: Colors.white,
                ),
                onPressed: () {
                  log.d("""
                  when ${_chooseSudokuBox + 1} is not a puzzle , then clean the choose \n
                  清除 ${_chooseSudokuBox + 1} 选型 , 如果他不是固定值的话
                  """);
                  if (_isOnlyReadGrid(_chooseSudokuBox)) {
                    // read only item , skip it - 只读格
                    return;
                  }
                  if (_state.status != SudokuGameStatus.gaming) {
                    // not playing , skip it - 未在游戏进行时
                    return;
                  }
                  _state.cleanMark(_chooseSudokuBox);
                  _state.cleanRecord(_chooseSudokuBox);
                }))));

    return Container(
      height: 40,
      // color: Colors.red,
      width: MediaQuery.of(context).size.width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(children: fillTools),
      ),
    );
  }

  Widget _toolZone(BuildContext context, int tips) {
    // pause button tap function
    var pauseOnPressed = () {
      if (_state.status != SudokuGameStatus.gaming) {
        return;
      }

      // 标记手动暂停
      setState(() {
        _manualPause = true;
      });

      _pause();
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (BuildContext context, _, __) {
                return SudokuPauseCoverPage();
              })).then((_) {
        _gaming();

        // 解除手动暂停
        setState(() {
          _manualPause = false;
        });
      });
    };

    // tips button tap function
    var tipsOnPressed;
    if (_state.hint > 0) {
      tipsOnPressed = () {
        // tips next cell answer
        log.d("top tips button");
        int hint = _state.hint;
        if (hint <= 0) {
          return;
        }
        List<int> puzzle = _state.sudoku!.puzzle;
        List<int> solution = _state.sudoku!.solution;
        List<int> record = _state.record;
        // random point tips
        int randomBeginPoint = new Random().nextInt(puzzle.length);
        for (int i = 0; i < puzzle.length; i++) {
          int index = (i + randomBeginPoint) % puzzle.length;
          if (puzzle[index] == -1 && record[index] == -1) {
            SoundEffect.answerTips();
            _state.setRecord(index, solution[index]);
            _state.hintLoss();
            _updateChooseState(index);
            _gameStackCount();

            // update choose state
            _updateChooseState(index);
            return;
          }
        }
      };
    }

    // mark button tap function
    var markOnPressed = () {
      log.d("enable mark function - 启用笔记功能");
      setState(() {
        _markOpen = !_markOpen;
      });
    };
    // define i18n text begin
    var exitGameText = SudokuLocalizations.of(context).exitGameText;
    var cancelText = SudokuLocalizations.of(context).cancelText;
    var pauseText = SudokuLocalizations.of(context).pauseText;
    var tipsText = '${SudokuLocalizations.of(context).tipsText}(${tips})';
    var enableMarkText = SudokuLocalizations.of(context).enableMarkText;
    var closeMarkText = SudokuLocalizations.of(context).closeMarkText;
    var exitGameContentText = SudokuLocalizations.of(context).exitGameContentText;
    // define i18n text end
    var exitGameOnPressed = () async {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: Text(exitGameText,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(exitGameContentText),
                actions: [
                  TextButton(
                    child: Text(exitGameText),
                    style: flatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: Text(cancelText),
                    style: primaryFlatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ]);
          }).then((val) {
        bool confirm = val;
        if (confirm == true) {
          // exit the game 退出游戏
          ScopedModel.of<SudokuState>(context).initialize();
          Navigator.pop(context);
        }
      });
    };

    var _toolContentWrapper = (svgPicture, label,
        {Color labelColor = Colors.white54, bool end = false}) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          Container(
            // color: Colors.black,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            child: SimpleShadow(child: svgPicture),
          ),
          Container(
            alignment: Alignment.center,
            width: 80,
            height: 25,
            child: Text(
              label,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    };

    return Container(
        // color: Colors.red,
        padding: EdgeInsets.all(5),
        child: Row(children: <Widget>[
          // 暂停游戏 pause game button
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: CupertinoButton(
                  padding: EdgeInsets.all(3),
                  onPressed: pauseOnPressed,
                  child: _toolContentWrapper(timerPauseAssetSvg, pauseText,
                      end: true),
                ),
                // child: Text(pauseText, style: TextStyle(fontSize: 15)),
              )),
          // 提示 tips
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: tipsOnPressed,
                    child: _state.hint > 0
                        ? _toolContentWrapper(lightbulbAssetSvg, tipsText)
                        : _toolContentWrapper(
                            lightbulbDisableAssetSvg, tipsText,
                            labelColor: Colors.black12),
                    // child: Text(tipsText, style: TextStyle(fontSize: 15)),
                  ))),
          // 笔记 mark record
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: markOnPressed,
                    child: _toolContentWrapper(noteAltAssetSvg,
                        _markOpen ? closeMarkText : enableMarkText),
                    // child: Text("${_markOpen ? closeMarkText : enableMarkText}",
                    //     style: TextStyle(fontSize: 15)),
                  ))),
          // 退出 exit
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: exitGameOnPressed,
                    child: _toolContentWrapper(exitToAppAssetSvg, exitGameText,
                        end: true),
                    // child: Text(exitGameText, style: TextStyle(fontSize: 15)),
                  ))),
          // 占位符，测试用
          // Expanded(flex: 5, child: Text("")),
        ]));
  }

  Widget _willPopWidget(
      BuildContext context, Widget child, void Function(bool didPop) onPop) {
    return PopScope(
      child: child,
      canPop: true,
      onPopInvoked: onPop,
    );
  }

  /// 计算网格背景色
  Color _gridCellBgColor(int index) {
    if (index == _chooseSudokuBox) {
      // Ô đang chọn
      return const Color(0xFF22313F); // Màu xanh đậm
    } else if (_correlationChooseBoxes.contains(index)) {
      // Ô liên quan
      return const Color(0xFF1A1F24); // Xám xanh
    } else {
      // Các ô còn lại: xen kẽ khối 3x3 với 2 màu nền đen nhạt và rất tối
      return Matrix.getZone(index: index).isOdd
          ? const Color(0xFF101214) // Tối trung bình
          : const Color(0xFF0E0E0E); // Rất tối
    }
  }

  ///
  /// 正常网格控件
  ///
  Widget _gridCellWidget(
      BuildContext context, int index, int num, GestureTapCallback onTap) {
    final Sudoku sudoku = _state.sudoku!;
    final List<int> puzzle = sudoku.puzzle;
    final List<int> solution = sudoku.solution;
    final List<int> record = _state.record;

    int currentNum = puzzle[index];
    double fontSize = 22;
    Color textColor = Colors.grey.shade300;
    FontWeight textWeight = FontWeight.bold;
    String? fontFamily;
    bool isWrong = false;

    if (currentNum == -1) {
      currentNum = record[index];
      textWeight = FontWeight.normal;

      if (currentNum != -1 && currentNum != solution[index]) {
        textColor = Colors.redAccent; // sai
        isWrong = true;
      } else if (currentNum != -1) {
        textColor = Colors.white; // người dùng nhập đúng
        fontSize = 24;
        fontFamily = "handwriting_digits";
      } else {
        textColor = Colors.grey.shade700; // trống
      }
    }

    final bool isPerceived = (currentNum != -1 && currentNum == _perceptionNum);

    final textWidget = Text(
      currentNum == -1 ? '' : '$currentNum',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: textWeight,
        fontFamily: fontFamily,
        color: textColor,
        decoration: isPerceived ? TextDecoration.underline : null,
        decorationStyle: isPerceived ? TextDecorationStyle.wavy : null,
        decorationColor: isPerceived ? Colors.deepOrangeAccent : null,
        decorationThickness: isPerceived ? 2.0 : null,
      ),
    );

    final cell = Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _gridCellBgColor(index),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWrong
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.grey.shade800,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: textWidget,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: Colors.blue.withOpacity(0.2),
      child: cell,
    );
  }

  ///
  /// 笔记网格控件
  ///
  Widget _markGridCellWidget(
    BuildContext context,
    int index,
    GestureTapCallback onTap,
  ) {
    Widget markGrid = InkWell(
      highlightColor: Colors.blue,
      customBorder: Border.all(color: Colors.blue),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _gridCellBgColor(index),
          border: Border.all(color: Colors.black12),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (BuildContext context, int _index) {
            double fontSize = 13;
            int markNum = _state.mark[index][_index + 1] ? _index + 1 : -1;
            String markNumText = '${markNum == -1 ? "" : markNum}';
            var _textContainer = Text(
              markNumText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontStyle: FontStyle.italic,
                color: _chooseSudokuBox == index
                    ? Colors.white
                    : Color.fromARGB(255, 0x26, 0x7A, 0xBC),
              ),
            );

            // 感知提示
            if (markNum != -1 && markNum == _perceptionNum) {
              _textContainer = Text(
                markNumText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontStyle: FontStyle.italic,
                  color: _chooseSudokuBox == index
                      ? Colors.white
                      : Color.fromARGB(255, 0x26, 0x7A, 0xBC),
                  // 提示线
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,
                  decorationColor: Colors.deepOrangeAccent,
                  decorationThickness: 1.2,
                ),
              );
            }

            return _textContainer;
          },
        ),
      ),
    );

    return markGrid;
  }

  /// 更新关联
  /// 用户每次选择框(cell)时,需要更新其关联的 行 列 宫 方便背景色和效果变更
  _updateCorrelationChooseBox() {
    // same zones
    List<int> zoneIndexes =
        Matrix.getZoneIndexes(zone: Matrix.getZone(index: _chooseSudokuBox));
    // same rows
    List<int> rowIndexes =
        Matrix.getRowIndexes(Matrix.getRow(_chooseSudokuBox));
    // same columns
    List<int> colIndexes =
        Matrix.getColIndexes(Matrix.getCol(_chooseSudokuBox));

    // 关联的格子
    Set<int> indexSet = Set();
    indexSet.addAll(zoneIndexes);
    indexSet.addAll(rowIndexes);
    indexSet.addAll(colIndexes);
    _correlationChooseBoxes = indexSet;
  }

  /// 选择感知
  /// 用户触摸每一个框(cell),尝试获得其触摸的数字,然后赋予提醒效果
  _choosePerception(int index) {
    Sudoku sudoku = _state.sudoku!;
    List<int> puzzle = sudoku.puzzle;
    List<int> record = _state.record;

    int perceptionNum = -1;
    if (record[index] > 0) {
      perceptionNum = record[index];
    } else if (puzzle[index] > 0) {
      perceptionNum = puzzle[index];
    }

    _perceptionNum = perceptionNum;
  }

  _updateChooseState(index) {
    setState(() {
      _chooseSudokuBox = index;
      _updateCorrelationChooseBox();
      _choosePerception(index);
    });
  }

  // cell onTop function
  _cellOnTapBuilder(index) {
    return () {
      _updateChooseState(index);
    };
  }

  Widget _bodyWidget(BuildContext context) {
    if (_state.sudoku == null) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Center(
          child: Text(
            'Sudoku Exiting...',
            style: TextStyle(color: Colors.black),
            textDirection: TextDirection.ltr,
          ),
        ),
      );
    }
    // var textValueStyle = TextStyle(
    //   fontSize: 18,
    //   fontWeight: FontWeight.w700,
    //   color: Colors.white,
    // );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          /// status zone
          /// life / tips / timer on here
          Container(
            height: 50,
            padding: EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Expanded(
                //   flex: 1,
                //   child: Row(
                //     children: <Widget>[
                //       lifePng,
                //       Text(" x ${_state.life}", style: textValueStyle)
                //     ],
                //   ),
                // ),
                BackButton(),
                // indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FlutterRemix.time_line,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        // "${LocalizationUtils.localizationLevelName(context, _state.level!)} - ${_state.timer} - ${LocalizationUtils.localizationGameStatus(context, _state.status)}",
                        _state.timer,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                //lifes
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _state.life,
                    (index) => Icon(
                      FlutterRemix.heart_fill,
                      color: Colors.red,
                    ),
                  ),
                )

                // tips
                // Expanded(
                //   flex: 1,
                //   child: Container(
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.end,
                //       children: <Widget>[
                //         ideaPng,
                //         Text(" x ${_state.hint}", style: textValueStyle)
                //       ],
                //     ),
                //   ),
                // )
              ],
            ),
          ),

          /// 9 x 9 cells sudoku puzzle board
          /// the whole sudoku game draw it here
          Container(
            // color: Colors.yellow,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 81,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemBuilder: (BuildContext context, int index) {
                int num = -1;
                if (_state.sudoku?.puzzle.length == 81) {
                  num = _state.sudoku!.puzzle[index];
                }

                // 用户做标记
                bool isUserMark = _state.sudoku!.puzzle[index] == -1 &&
                    _state.mark[index].any((element) => element);

                if (isUserMark) {
                  return _markGridCellWidget(
                      context, index, _cellOnTapBuilder(index));
                }

                return _gridCellWidget(
                    context, index, num, _cellOnTapBuilder(index));
              },
            ),
          ),

          /// user input zone
          /// use fillZone choose number fill cells or mark notes
          /// use toolZone to pause / exit game
          Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 5)),
          _fillZone(context),
          Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 5)),
          _toolZone(context, _state.hint)
        ],
      ),
    );
  }

  @override
  void deactivate() {
    log.d("on deactivate");
    WidgetsBinding.instance.removeObserver(this);
    super.deactivate();
  }

  @override
  void dispose() {
    log.d("on dispose");
    _pauseTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateChooseState(0);
    _gaming();
    // Future.delayed(Duration(seconds: 3), () {
    //   _gameOver();
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        log.d("is paused app lifecycle state");
        _pause();
        break;
      case AppLifecycleState.resumed:
        log.d("is resumed app lifecycle state");
        if (!_manualPause) {
          _gaming();
        }
        break;
      default:
        break;
    }
  }

  // 定时器
  Timer? _timer;

  void _gaming() {
    if (_state.status == SudokuGameStatus.pause) {
      log.d("on _gaming");
      _state.updateStatus(SudokuGameStatus.gaming);
      _state.persistent();
      _beginTimer();
    }
  }

  void _pause() {
    if (_state.status == SudokuGameStatus.gaming) {
      log.d("on _pause");
      _state.updateStatus(SudokuGameStatus.pause);
      _state.persistent();
      _pauseTimer();
    }
  }

  // 开始计时
  void _beginTimer() {
    log.d("timer begin");
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_state.status == SudokuGameStatus.gaming) {
          _state.tick();
          return;
        }
        timer.cancel();
      });
    }
  }

  // 暂停计时
  void _pauseTimer() {
    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
    }
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    Scaffold scaffold = Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.info_outline),
      //       onPressed: () {
      //         return _aboutDialogAction(context);
      //       },
      //     )
      //   ],
      // ),
      body: SafeArea(
        child: _willPopWidget(
          context,
          ScopedModelDescendant<SudokuState>(
            builder: (context, child, model) => _bodyWidget(context),
          ),
          (bool didPop) {
            if (didPop) {
              _pause();
            }
          },
        ),
      ),
    );

    return scaffold;
  }
}
