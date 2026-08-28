import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/benefit.dart';
import '../core/notification_service.dart';

/// 앱 전역에서 사용하는 로컬 저장소(SharedPreferences) 관리 서비스
/// - 찜한 혜택 목록 (wishlist)
/// - 달력에 등록된 혜택 일정 (calendar events)
///
/// ValueNotifier를 사용해 별도의 상태관리 패키지 없이도
/// 홈 화면 <-> 달력 화면 간 실시간 동기화가 가능하도록 구성함.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const String _wishlistKey = 'wishlist_ids';
  static const String _calendarKey = 'calendar_events';
  static const String _viewCountKey = 'benefit_view_counts';

  /// 찜한 혜택 id 집합. UI는 이 값을 구독(watch)하여 하트 아이콘 상태를 갱신함.
  final ValueNotifier<Set<String>> wishlistNotifier =
      ValueNotifier<Set<String>>(<String>{});

  /// key: 'yyyy-MM-dd' 형태의 날짜 문자열, value: 해당 날짜에 등록된 이벤트 목록
  final ValueNotifier<Map<String, List<CalendarEvent>>> calendarNotifier =
      ValueNotifier<Map<String, List<CalendarEvent>>>(
          <String, List<CalendarEvent>>{});

  /// key: 혜택 id, value: 상세화면 조회 횟수 (조회수순 정렬에 사용)
  final ValueNotifier<Map<String, int>> viewCountNotifier =
      ValueNotifier<Map<String, int>>(<String, int>{});

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// main() 에서 runApp 이전에 반드시 호출되어야 함
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    try {
      final wishlistRaw = _prefs.getStringList(_wishlistKey) ?? <String>[];
      wishlistNotifier.value = wishlistRaw.toSet();

      final calendarRaw = _prefs.getString(_calendarKey);
      if (calendarRaw != null && calendarRaw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(calendarRaw);
        calendarNotifier.value = decoded.map((key, value) {
          final list = (value as List)
              .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList();
          return MapEntry(key, list);
        });
      }

      final viewCountRaw = _prefs.getString(_viewCountKey);
      if (viewCountRaw != null && viewCountRaw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(viewCountRaw);
        viewCountNotifier.value = decoded.map(
          (key, value) => MapEntry(key, value as int),
        );
      }
    } catch (e) {
      debugPrint('StorageService init error: $e');
      // If data is corrupted, clear it to prevent further crashes
      await _prefs.remove(_wishlistKey);
      await _prefs.remove(_calendarKey);
      await _prefs.remove(_viewCountKey);
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------
  // 찜하기 (Wishlist)
  // ---------------------------------------------------------------------

  bool isWishlisted(String benefitId) =>
      wishlistNotifier.value.contains(benefitId);

  /// 하트 아이콘 클릭 시 호출. 이미 찜한 상태면 해제, 아니면 추가.
  Future<void> toggleWishlist(String benefitId) async {
    final current = Set<String>.from(wishlistNotifier.value);
    if (current.contains(benefitId)) {
      current.remove(benefitId);
    } else {
      current.add(benefitId);
    }
    wishlistNotifier.value = current;
    await _prefs.setStringList(_wishlistKey, current.toList());

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'wishlist': current.toList(),
        });
      } catch (e) {
        // Ignore
      }
    }
  }

  List<Benefit> getWishlistedBenefits(List<Benefit> allBenefits) {
    final ids = wishlistNotifier.value;
    return allBenefits.where((b) => ids.contains(b.id)).toList();
  }

  // ---------------------------------------------------------------------
  // 달력 이벤트 (Calendar Events)
  // ---------------------------------------------------------------------

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 시작일~종료일 범위에 해당하는 모든 날짜에 이벤트를 등록 (기간형 다중 날짜 선택)
  Future<void> addDateRangeEvent({
    required Benefit benefit,
    required DateTime start,
    required DateTime end,
  }) async {
    final updated =
        Map<String, List<CalendarEvent>>.from(calendarNotifier.value);

    DateTime cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!cursor.isAfter(last)) {
      final key = _dateKey(cursor);
      final list = List<CalendarEvent>.from(updated[key] ?? <CalendarEvent>[]);

      // 동일 혜택이 같은 날짜에 중복 등록되지 않도록 방지
      final alreadyExists = list.any((e) => e.benefitId == benefit.id);
      if (!alreadyExists) {
        list.add(CalendarEvent(
          benefitId: benefit.id,
          title: benefit.title,
          url: benefit.url,
        ));
      }
      updated[key] = list;
      cursor = cursor.add(const Duration(days: 1));
    }

    calendarNotifier.value = updated;
    await _persistCalendar();

    // 마감일이 있는 경우 알림 스케줄링 등록 (마감일 3일 전)
    if (benefit.endDate != null) {
      final notiService = NotificationService();
      await notiService.scheduleDeadlineAlert(
        id: benefit.id.hashCode,
        title: '마감 임박 혜택 알림 🚨',
        body: '[${benefit.title}] 혜택의 마감일이 3일 앞으로 다가왔습니다!',
        deadline: benefit.endDate!,
      );
    }
  }

  /// 해당 날짜만 삭제
  Future<void> deleteEventsForDate(DateTime date) async {
    final updated =
        Map<String, List<CalendarEvent>>.from(calendarNotifier.value);
    updated.remove(_dateKey(date));
    calendarNotifier.value = updated;
    await _persistCalendar();
  }

  /// 특정 혜택과 관련된 모든 날짜의 일정을 삭제 ('전체 일정 삭제')
  Future<void> deleteAllEventsForBenefit(String benefitId) async {
    final updated =
        Map<String, List<CalendarEvent>>.from(calendarNotifier.value);

    final keysToRemove = <String>[];
    updated.forEach((key, events) {
      events.removeWhere((e) => e.benefitId == benefitId);
      if (events.isEmpty) keysToRemove.add(key);
    });
    for (final k in keysToRemove) {
      updated.remove(k);
    }

    calendarNotifier.value = updated;
    await _persistCalendar();

    // 관련 마감 알림 예약 취소
    final notiService = NotificationService();
    await notiService.cancelAlert(benefitId.hashCode);
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return calendarNotifier.value[_dateKey(date)] ?? <CalendarEvent>[];
  }

  bool hasEventsForDate(DateTime date) {
    final list = calendarNotifier.value[_dateKey(date)];
    return list != null && list.isNotEmpty;
  }

  Future<void> _persistCalendar() async {
    final encoded = jsonEncode(
      calendarNotifier.value.map(
        (key, events) => MapEntry(key, events.map((e) => e.toJson()).toList()),
      ),
    );
    await _prefs.setString(_calendarKey, encoded);
  }

  // ---------------------------------------------------------------------
  // 조회수 (View Count) — 혜택 상세화면 진입 시 1씩 증가, 조회수순 정렬에 사용
  // ---------------------------------------------------------------------

  int getViewCount(String benefitId) => viewCountNotifier.value[benefitId] ?? 0;

  Future<void> incrementViewCount(String benefitId) async {
    final updated = Map<String, int>.from(viewCountNotifier.value);
    updated[benefitId] = (updated[benefitId] ?? 0) + 1;
    viewCountNotifier.value = updated;
    await _prefs.setString(_viewCountKey, jsonEncode(updated));
  }
}