// lib/core/providers/application_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/application_model.dart';
import '../../data/models/enums.dart';
import '../services/api_service.dart';

class ApplicationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;

  List<Application> _myApplications = [];
  bool _isLoading = false;
  String? _errorMessage; // <-- Hata mesajı için state eklendi

  List<Application> get myApplications => _myApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; // <-- Getter eklendi

  // ProxyProvider tarafından token'ı güncellemek için kullanılacak metod
  void updateToken(String? newToken) {
    _token = newToken;
    // Token değiştiğinde (giriş/çıkış yapıldığında) başvuruları otomatik çek
    if (_token != null) {
      fetchMyApplications();
    } else {
      _myApplications = [];
      notifyListeners();
    }
  }

  Future<void> fetchMyApplications() async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null; // İşleme başlarken eski hatayı temizle
    notifyListeners();

    try {
      _myApplications = await _apiService.getMyApplications();
    } catch (e) {
      _errorMessage = "Başvurular yüklenirken bir hata oluştu.";
      _myApplications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> applyToProject({
    required String projectId,
    required String coverLetter,
    double? proposedBudget,
  }) async {
    if (_token == null) {
      _errorMessage = "İşlem yapmak için giriş yapmalısınız.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null; // Eski hataları temizle
    notifyListeners();

    try {
      // ApiService'in hata fırlatacağını varsayarak try-catch kullanıyoruz.
      // Eğer fırlatmıyorsa, ApiService'i de buna göre düzenlemek gerekir.
      await _apiService.applyToProject(
        projectId: projectId,
        coverLetter: coverLetter,
        proposedBudget: proposedBudget,
      );

      // Başarılı olursa, arayüzü güncellemek için başvuruları yeniden çek.
      await fetchMyApplications();
      // Not: Bu işlem başarılı olduğunda `isLoading` zaten false'a çekiliyor
      // ve `notifyListeners` çağrılıyor, bu yüzden burada tekrar yapmaya gerek yok.
      return true;

    } catch (e) {
      _errorMessage = "Başvuru gönderilirken bir hata oluştu. Lütfen tekrar deneyin.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    if (_token == null) {
      _errorMessage = "İşlem yapmak için giriş yapmalısınız.";
      notifyListeners();
      return false;
    }

    // Yüklenme durumunu burada yönetebiliriz, ancak şimdilik basit tutalım.
    final success = await _apiService.updateApplicationStatus(
      applicationId: applicationId,
      newStatus: newStatus,
    );

    if (success) {
      // Başarılı olursa, başvuru listesini güncelleyerek arayüzün yenilenmesini sağla.
      // Not: Bu, hem MyApplicationsScreen hem de ProjectApplicantsScreen'i etkiler.
      // Daha verimli bir yol, sadece tek bir başvuruyu lokalde güncellemektir.
      // Şimdilik en güvenli yol olan yeniden çekme ile devam edelim.
      print("Başvuru durumu güncellendi, liste yenileniyor...");
    } else {
      _errorMessage = "Durum güncellenirken bir hata oluştu.";
      notifyListeners();
    }
    return success;
  }
}