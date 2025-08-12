import 'dart:async';
import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationService {
  static ReceivedAction? initialAction;
  static ReceivePort? receivePort;
  static late MuzeePlayerCubit playerCubit;

  static final StreamController<SongModel> handleData =
      StreamController<SongModel>.broadcast();

  dispose() {
    receivePort?.close();
    handleData.close();
  }

  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alert_normal',
          channelName: 'Alerts',
          channelDescription: 'Notification tests as alerts',
          playSound: true,
          onlyAlertOnce: true,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultColor: Colors.deepPurple,
          ledColor: Colors.deepPurple,
        ),
        NotificationChannel(
          channelKey: 'daily_music',
          channelName: 'Daily Music Suggestions',
          channelDescription: 'Get music suggestions throughout your day',
          importance: NotificationImportance.Max,
          defaultColor: Colors.white,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      debug: true,
    );

    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static int get nextId =>
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  static Future<void> requestNotificationPermissionWithRetry() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();

      Timer(const Duration(hours: 2), () async {
        bool isStillNotAllowed =
            !(await AwesomeNotifications().isNotificationAllowed());

        if (isStillNotAllowed) {
          DialogHelper.showNotificationPermissionPopup();
        }
      });
    }
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  static Future<void> scheduleDailyNotifications(
    List<SongModel> songs,
    String languageCode,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;
    final content0 = generateNotificationContent(7, songs[0], languageCode);
    await scheduleNotification(
      id: 700,
      title: content0.title,
      body: content0.body,
      hour: 7,
      minute: 0,
      image: Utils.thumbM(songs[0].id),
      payload: songs[0].toJson2(),
    );

    final content1 = generateNotificationContent(12, songs[1], languageCode);
    await scheduleNotification(
      id: 1200,
      title: content1.title,
      body: content1.body,
      hour: 12,
      minute: 0,
      image: Utils.thumbM(songs[1].id),
      payload: songs[1].toJson2(),
    );

    final content2 = generateNotificationContent(21, songs[2], languageCode);
    await scheduleNotification(
      id: 2100,
      title: content2.title,
      body: content2.body,
      hour: 21,
      minute: 0,
      image: Utils.thumbM(songs[2].id),
      payload: songs[2].toJson2(),
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String image,
    required Map<String, String?> payload,
  }) async {
    final timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'daily_music',
        title: title,
        body: body,
        fullScreenIntent: true,
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        bigPicture: image,
        notificationLayout: NotificationLayout.BigPicture,
        payload: payload,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
        timeZone: timeZone,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(
            key: 'PLAY', label: 'Play', actionType: ActionType.SilentAction),
        NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.DismissAction,
            isDangerousOption: true)
      ],
    );
  }

  static Future<void> pushNewMusicNotification(
      String title, String body, Map<String, dynamic> payload) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    final song = SongModel.fromJson(payload);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: nextId,
        channelKey: 'daily_music',
        title: title,
        body: body,
        bigPicture: Utils.thumbD(payload['songId'] ?? ''),
        notificationLayout: payload['image'] != null
            ? NotificationLayout.MediaPlayer
            : NotificationLayout.Default,
        payload: song.toJson2(),
        fullScreenIntent: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'PLAY',
          label: 'Play',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.DismissAction,
            isDangerousOption: true)
      ],
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.payload != null) {
      final song = SongModel.fromJson2(receivedAction.payload ?? {});
      handleData.add(song);
    }
  }

  static Map<int, Map<String, List<Map<String, String>>>> suggestionMessages = {
    7: {
      'en': [
        {
          'title': "Good Morning 🎶",
          'body': "Start your day with {title} by {artist}"
        },
        {'title': "Wake-up Tunes ☀️", 'body': "{title} will get you going!"},
        {
          'title': "Your morning vibe 🎧",
          'body': "Feel energized with {title}"
        },
      ],
      'vi': [
        {
          'title': "Chào buổi sáng 🎶",
          'body': "Bắt đầu ngày mới cùng {title} - {artist}"
        },
        {
          'title': "Âm nhạc tỉnh táo ☀️",
          'body': "{title} sẽ giúp bạn tỉnh táo!"
        },
        {
          'title': "Giai điệu sáng nay 🎧",
          'body': "Nạp năng lượng cùng {title}"
        },
      ]
    },
    12: {
      'en': [
        {'title': "Midday Break 🎵", 'body': "Relax with {title} by {artist}"},
        {'title': "Lunchtime Tunes 🍱", 'body': "Enjoy {title} while you eat"},
        {'title': "Need a boost?", 'body': "{title} is perfect right now!"},
      ],
      'vi': [
        {
          'title': "Giải lao giữa trưa 🎵",
          'body': "Thư giãn cùng {title} - {artist}"
        },
        {
          'title': "Nhạc trưa 🍱",
          'body': "Thưởng thức {title} khi ăn trưa nhé"
        },
        {
          'title': "Cần nạp lại năng lượng?",
          'body': "{title} là lựa chọn tuyệt vời lúc này!"
        },
      ]
    },
    18: {
      'en': [
        {
          'title': "Evening Vibes 🌆",
          'body': "Unwind with {title} by {artist}"
        },
        {'title': "Chill Time 🎶", 'body': "{title} sets the mood tonight"},
        {
          'title': "Relax and enjoy",
          'body': "Let {title} flow with the evening"
        },
      ],
      'vi': [
        {
          'title': "Giai điệu hoàng hôn 🌆",
          'body': "Thư giãn với {title} - {artist}"
        },
        {
          'title': "Thư giãn buổi tối 🎶",
          'body': "{title} mang lại cảm xúc yên bình"
        },
        {
          'title': "Nghe nhạc và chill",
          'body': "Để {title} dẫn lối cảm xúc bạn"
        },
      ]
    },
    21: {
      'en': [
        {
          'title': "Late Night Tunes 🌙",
          'body': "Fall asleep with {title} by {artist}"
        },
        {'title': "Goodnight melodies 💫", 'body': "End the day with {title}"},
        {'title': "Midnight Vibes", 'body': "{title} is perfect before bed"},
      ],
      'vi': [
        {
          'title': "Nhạc đêm muộn 🌙",
          'body': "Ru bạn vào giấc ngủ với {title} - {artist}"
        },
        {
          'title': "Giai điệu chúc ngủ ngon 💫",
          'body': "Kết thúc ngày cùng {title}"
        },
        {
          'title': "Âm nhạc trước khi ngủ",
          'body': "{title} giúp bạn thư giãn trước khi ngủ"
        },
      ]
    }
  };

  static CustomNotificationContent generateNotificationContent(
    int hour,
    SongModel song,
    String lang,
  ) {
    final safeLang =
        suggestionMessages[hour]?.containsKey(lang) == true ? lang : 'en';
    final messages = suggestionMessages[hour]?[safeLang];
    if (messages == null || messages.isEmpty) {
      return CustomNotificationContent(
        title: song.title ?? 'Now Playing',
        body: song.artist ?? '',
      );
    }

    final randomMessage = (messages..shuffle()).first;

    final title = randomMessage['title']!
        .replaceAll('{title}', song.title ?? '')
        .replaceAll('{artist}', song.artist ?? '');

    final body = randomMessage['body']!
        .replaceAll('{title}', song.title ?? '')
        .replaceAll('{artist}', song.artist ?? '');

    return CustomNotificationContent(title: title, body: body);
  }
}

class CustomNotificationContent {
  final String title;
  final String body;

  CustomNotificationContent({required this.title, required this.body});
}
