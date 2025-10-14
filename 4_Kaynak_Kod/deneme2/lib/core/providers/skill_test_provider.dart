// lib/core/providers/skill_test_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/skill_test.dart';
import '../../data/models/test_result_model.dart';
import '../services/api_service.dart';

class SkillTestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;

  void updateToken(String? newToken) {
    _token = newToken;
  }

  // --- Durum (State) Değişkenleri ---
  bool _isLoading = false;
  List<SkillTest> _tests = [];
  SkillTest? _activeTest;
  TestResult? _activeTestResult;
  Map<String, String> _userAnswers = {};
  TestResult? _finalResult;

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  List<SkillTest> get tests => _tests;
  SkillTest? get activeTest => _activeTest;
  TestResult? get activeTestResult => _activeTestResult;
  Map<String, String> get userAnswers => _userAnswers;
  TestResult? get finalResult => _finalResult;

  // --- Metodlar ---

  Future<void> fetchSkillTests() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tests = await _apiService.getSkillTests();
    } catch (e) {
      print('fetchSkillTests Provider HATA: $e');
      _tests = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // YENİ METOD: Sadece test detaylarını çeker.
  Future<void> fetchTestDetails(String testId) async {
    _isLoading = true;
    _activeTest = null;
    notifyListeners();
    try {
      final testDetails = await _apiService.getSkillTestDetails(testId: testId);
      _activeTest = testDetails;
    } catch (e) {
      print('fetchTestDetails Provider HATA: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // GÜNCELLENMİŞ METOD: Artık sadece testi başlatır, detay çekmez.
  Future<bool> startTest() async {
    if (_token == null || _activeTest == null) return false;
    _isLoading = true;
    _finalResult = null;
    _userAnswers = {};
    notifyListeners();

    try {
      final testResult = await _apiService.startTest(testId: _activeTest!.id);
      if (testResult != null) {
        _activeTestResult = testResult;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('startTest Provider HATA: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void selectAnswer(String questionId, String choiceId) {
    _userAnswers[questionId] = choiceId;
    notifyListeners();
  }

  Future<bool> submitTest() async {
    if (_activeTestResult == null || _token == null) return false;
    _isLoading = true;
    notifyListeners();

    final List<Map<String, String>> answersList = _userAnswers.entries.map((entry) {
      return {'question_id': entry.key, 'selected_choice_id': entry.value};
    }).toList();
    final submissionData = {'answers': answersList};

    try {
      final result = await _apiService.submitTest(
        resultId: _activeTestResult!.id,
        submission: submissionData,
      );
      if (result != null) {
        _finalResult = result;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('submitTest Provider HATA: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearTestState() {
    _activeTest = null;
    _activeTestResult = null;
    _finalResult = null;
    _userAnswers = {};
    notifyListeners();
  }


}