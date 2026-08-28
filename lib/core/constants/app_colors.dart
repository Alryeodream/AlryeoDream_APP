import 'package:flutter/material.dart';

/// 앱 전역에서 반복적으로 쓰이는 색상 값을 한 곳에 모아둔 상수 파일.
class AppColors {
  AppColors._(); // 인스턴스화 방지

  /// 앱의 메인 포인트 컬러 (보라색)
  static const Color accentPurple = Color(0xFF6B48FF);
  
  /// 보조 포인트 컬러
  static const Color accentSecondary = Color(0xFF00D4FF);

  /// 그라데이션 프리셋 (메인 버튼/헤더 등에 사용)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B48FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// '전국' 배지 등에 쓰이는 보조 컬러
  static const Color nationwideBadge = Color(0xFF20C997);

  /// 찜하기(하트) 활성 색상
  static const Color wishlistActive = Color(0xFFFF4B4B);

  /// 카드 배경색 (다크/라이트에 따라 투명도 조절용 기본 색상)
  static const Color cardSurface = Color(0xFFF8F9FA);
  
  /// 다크 모드 카드 배경색
  static const Color darkCardSurface = Color(0xFF1E1E2C);

  /// 주요 텍스트 색상
  static const Color textPrimary = Color(0xFF1F2937);
  
  /// 보조 텍스트 색상
  static const Color textSecondary = Color(0xFF6B7280);
}