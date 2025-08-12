import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/board_adapter.dart';

import 'game.dart';

Future<void> initGame2048() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(BoardAdapter().typeId)) {
    Hive.registerAdapter(BoardAdapter());
  }
}

Widget buildGame2048(Widget ads) {
  return ProviderScope(
    child: Game2048Screen(adsWidget: ads),
  );
}
