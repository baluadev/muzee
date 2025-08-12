import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/ytb/ytb_service.dart';

import 'flip_card_model.dart';

class FlipGameScence extends StatefulWidget {
  const FlipGameScence({super.key});

  @override
  State<FlipGameScence> createState() => _FlipGameScenceState();
}

class _FlipGameScenceState extends State<FlipGameScence> {
  List<FlipCardModel> cards = [];
  List<int> selectedIndices = [];
  Set<int> matched = {};
  bool allowFlip = true;
  int flips = 0;
  int matchedFlips = 0;
  int wrongFlips = 0;
  String difficulty = 'easy';

  @override
  void initState() {
    super.initState();
    loadLevel(difficulty);
  }

  void loadLevel(String level) async {
    difficulty = level;

    final data = await YtbService.getTrendingArtistsFromYouTube();
    final dummyData = List.generate(
        data.length,
        (i) => MusicCard(
              id: data[i].channelId!,
              title: data[i].name!,
              artist: data[i].name!,
              imageUrl: data[i].imgPath!,
            ));

    dummyData.shuffle();

    int pairCount;
    switch (level) {
      case 'easy':
        pairCount = 4;
        break;
      case 'medium':
        pairCount = 6;
        break;
      case 'hard':
        pairCount = 8;
        break;
      default:
        pairCount = 4;
    }

    final selected = dummyData.take(pairCount).toList();
    cards = [];
    for (final song in selected) {
      cards.add(FlipCardModel(
        id: song.id,
        type: 'image',
        value: song.imageUrl,
      ));
      cards.add(FlipCardModel(
        id: song.id,
        type: 'title',
        value: song.title,
      ));
    }
    cards.shuffle();
    matched.clear();
    selectedIndices.clear();
    flips = 0;
    matchedFlips = 0;
    wrongFlips = 0;
    allowFlip = true;
    setState(() {});
  }

  bool isMatch(FlipCardModel a, FlipCardModel b) {
    return a.id == b.id && a.type != b.type;
  }

  void onCardTap(int index) async {
    if (!allowFlip ||
        matched.contains(index) ||
        selectedIndices.contains(index)) return;

    setState(() {
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      allowFlip = false;
      flips++;
      final first = cards[selectedIndices[0]];
      final second = cards[selectedIndices[1]];

      if (isMatch(first, second)) {
        matched.addAll(selectedIndices);
        first.isMatched = true;
        second.isMatched = true;
        matchedFlips++;
      } else {
        wrongFlips++;
        await Future.delayed(const Duration(milliseconds: 800));
      }

      setState(() {
        selectedIndices.clear();
        allowFlip = true;
      });

      if (cards.every((c) => c.isMatched)) {
        _showGameOverDialog('You Win!');
      } else if (wrongFlips >= 3) {
        _showGameOverDialog('You Lose!');
      }
    }
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        backgroundColor: MyColors.background,
        title: Text(
          message,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Flips: $flips\nMatched: $matchedFlips\nWrong: $wrongFlips',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          Text(
            'Play Again',
            style: Theme.of(context).textTheme.titleMedium,
          ).attachGestureDetector(onTap: () {
            Navigator.pop(d);
            loadLevel(difficulty);
          }),
        ],
      ),
    );
  }

  Widget buildCard(int index) {
    final card = cards[index];
    final isFlipped =
        selectedIndices.contains(index) || matched.contains(index);

    return GestureDetector(
      onTap: () => onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isFlipped ? Colors.white : Colors.blueGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: isFlipped
            ? buildCardContent(card)
            : const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }

  Widget buildCardContent(FlipCardModel card) {
    if (card.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: card.value,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          card.value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MyColors.inputText),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Flip Cards'),
        trailing: PopupMenuButton<String>(
          onSelected: loadLevel,
          color: MyColors.background,
          padding: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          child: const Icon(
            FlutterRemix.more_2_line,
            size: 24,
            color: MyColors.primary,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'easy',
              child: Text(
                'Easy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuItem(
                value: 'medium',
                child: Text(
                  'Medium',
                  style: Theme.of(context).textTheme.titleMedium,
                )),
            PopupMenuItem(
                value: 'hard',
                child: Text(
                  'Hard',
                  style: Theme.of(context).textTheme.titleMedium,
                )),
          ],
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          context.read<AppCubit>().bannerWidget,
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text("Level: $difficulty",
                    style: const TextStyle(fontSize: 16)),
                Text(
                    "Flips: $flips  Matched: $matchedFlips  Wrong: $wrongFlips",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) => buildCard(index),
            ),
          ),
        ],
      ),
    );
  }
}
