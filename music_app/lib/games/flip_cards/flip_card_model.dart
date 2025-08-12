class MusicCard {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;

  MusicCard({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });
}

class FlipCardModel {
  final String id;
  final String type;
  final String value;
  bool isMatched;

  FlipCardModel({
    required this.id,
    required this.type,
    required this.value,
    this.isMatched = false,
  });
}
