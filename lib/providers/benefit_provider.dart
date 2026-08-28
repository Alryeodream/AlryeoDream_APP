import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/benefit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

List<Benefit> _parseBenefits(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is List) {
    return decoded.map((e) => Benefit.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
}

class BenefitProvider extends ChangeNotifier {
  List<Benefit> _benefits = [];
  bool _isLoading = false;

  List<Benefit> get benefits => _benefits;
  bool get isLoading => _isLoading;

  /// GitHub Actions를 통해 자동 업데이트되는 최신 공공데이터 JSON 파일의 Raw URL
  static const String _githubRawDataBaseUrl =
      'https://raw.githubusercontent.com/seonghyeon1221/Youth_Benefits_Project/main/assets/data/benefits_data.json';


  Future<void> fetchBenefits() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 클라우드 Firestore에서 데이터 가져오기
      final querySnapshot = await FirebaseFirestore.instance.collection('benefits').get();
      
      _benefits = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // ID 누락 시 문서 ID 사용
        if (!data.containsKey('benefit_id')) {
          data['benefit_id'] = doc.id;
        }
        return Benefit.fromJson(data);
      }).toList();
      
    } catch (e) {
      debugPrint('Firestore 데이터 로드 실패, 로컬 에셋(assets/data) 폴백 시도: $e');
      try {
        final jsonString = await rootBundle.loadString('assets/data/benefits_data.json');
        _benefits = await compute(_parseBenefits, jsonString);
      } catch (assetError) {
        debugPrint('에셋 로드 실패, 데모 데이터 사용: $assetError');
        if (_benefits.isEmpty) {
          _benefits = demoBenefits;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Benefit>> fetchCustomBenefits() async {
    // 맞춤 검색도 임시로 전체 혜택을 리턴 (클라이언트에서 자체 필터링 가능)
    await fetchBenefits();
    return _benefits;
  }
}
