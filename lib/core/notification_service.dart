import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // 타임존 초기화 (알림 스케줄링에 필수)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // 기본 앱 아이콘

    // iOS/macOS 초기화 설정 (Web은 지원 안함)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('알림 클릭: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 혜택 마감일(end_date) 기준으로 n일 전에 알림 예약
  Future<void> scheduleDeadlineAlert({
    required int id,
    required String title,
    required String body,
    required DateTime deadline,
    int daysBefore = 3,
  }) async {
    if (kIsWeb) return; // 웹은 미지원

    // 예약 시간 계산: 마감일에서 daysBefore 뺀 날짜의 오전 10시
    DateTime alertDate = deadline.subtract(Duration(days: daysBefore));
    alertDate = DateTime(alertDate.year, alertDate.month, alertDate.day, 10, 0); // 오전 10시

    // 예약 시간이 이미 과거라면 알림 예약 안 함
    if (alertDate.isBefore(DateTime.now())) {
      debugPrint('마감 임박 알림 예약 시간($alertDate)이 과거이므로 건너뜁니다.');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(alertDate, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'deadline_channel',
      '마감 임박 혜택 알림',
      channelDescription: '저장한 혜택의 마감일이 임박했을 때 알려줍니다.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'deadline_alert_$id',
    );
    
    debugPrint('알림 예약 완료: $title (예약일: $alertDate)');
  }

  /// 예약된 알림 취소 (캘린더에서 제거 시)
  Future<void> cancelAlert(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
