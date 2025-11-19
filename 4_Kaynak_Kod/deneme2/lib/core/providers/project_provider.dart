import 'package:flutter/foundation.dart';
import '../../data/models/enums.dart';
import '../../data/models/project_model.dart';
import '../../data/models/review_model.dart';
import '../services/api_service.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;

  // --- TÜM PROJE STATE'LERİ ---
  List<Project> _allOpenProjects = [];
  List<Project> _myActiveProjects = [];
  List<Project> _myPendingReviewProjects = [];
  List<Project> _myCompletedProjects = [];

  // --- AKTİF FİLTRELER İÇİN HAFIZA ---
  String? _activeSearchQuery;
  String? _activeCategory;
  int? _activeMinBudget;
  int? _activeMaxBudget;
  String? _activeSortBy = 'newest';

  bool _isLoading = false;
  String? _errorMessage;

  // --- PUBLIC GETTER'LAR ---
  List<Project> get allOpenProjects => _allOpenProjects;
  List<Project> get myActiveProjects => _myActiveProjects;
  List<Project> get myPendingReviewProjects => _myPendingReviewProjects;
  List<Project> get myCompletedProjects => _myCompletedProjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeCategory => _activeCategory;
  String? get activeSortBy => _activeSortBy;
  int? get activeMinBudget => _activeMinBudget;
  int? get activeMaxBudget => _activeMaxBudget;
  List<Project> _recommendedProjects = [];
  List<Project> get recommendedProjects => _recommendedProjects;
  bool _isRecommendationsLoading = false;
  bool get isRecommendationsLoading => _isRecommendationsLoading;
  void updateToken(String? newToken) {
    _token = newToken;
  }

  // YENİ EKLENEN FONKSİYON
  Future<bool> createProject({
    required String title,
    required String description,
    required String category,
    required List<String> skillIds,
    int? budgetMin,
    int? budgetMax,
    DateTime? deadline,
  }) async {
    if (_token == null) {
      _errorMessage = "İşlem yapmak için giriş yapmalısınız.";
      notifyListeners();
      return false;
    }

    _isLoading = true; // İşlemin başladığını UI'a bildir
    notifyListeners();

    try {
      // Proje oluşturma isteğini API servisine gönder
      await _apiService.createProject(
        title: title,
        description: description,
        category: category,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        deadline: deadline,
        skillIds: skillIds,
      );

      // BAŞARILI! En kritik adım:
      // Proje listesini yeniden çekerek arayüzün güncellenmesini sağla.
      await fetchOpenProjects();

      // Aynı zamanda "Projelerim" panelinin de güncel olması için bunu da çekelim.
      await fetchMyProjects();

      // Not: fetch... fonksiyonları zaten `_isLoading = false` ve `notifyListeners()` çağırıyor.
      return true;

    } catch (e) {
      _errorMessage = "Proje oluşturulurken bir hata oluştu: ${e.toString()}";
      _isLoading = false; // Hata durumunda yükleniyor durumunu kapat
      notifyListeners();
      return false;
    }
  }

  // Genel proje ilanlarını filtre ve sıralama ile çeker.
  Future<void> fetchOpenProjects() async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      _allOpenProjects = await _apiService.getProjects(
        searchQuery: _activeSearchQuery,
        category: _activeCategory,
        minBudget: _activeMinBudget,
        maxBudget: _activeMaxBudget,
        sortBy: _activeSortBy,
      );
    } catch (e) {
      _errorMessage = "Projeler yüklenirken bir hata oluştu.";
      _allOpenProjects = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // Gelen filtreleri state'e kaydedip projeleri yeniden çeker.
  void applyFiltersAndFetch({
    String? searchQuery,
    String? category,
    int? minBudget,
    int? maxBudget,
    String? sortBy,
  }) {
    _activeSearchQuery = searchQuery;
    _activeCategory = category;
    _activeMinBudget = minBudget;
    _activeMaxBudget = maxBudget;
    _activeSortBy = sortBy;
    fetchOpenProjects();
  }

  // Arama sorgusu hariç tüm filtreleri temizler.
  void clearFiltersAndFetch({String? currentSearchQuery}) {
    _activeCategory = null;
    _activeMinBudget = null;
    _activeMaxBudget = null;
    _activeSortBy = 'newest';
    _activeSearchQuery = currentSearchQuery;
    fetchOpenProjects();
  }

  // Kullanıcının kendi projelerini çeker (Dashboard için)
  Future<void> fetchMyProjects() async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final myProjects = await _apiService.getMyProjects();
      _myActiveProjects = myProjects.where((p) => p.status == ProjectStatus.open || p.status == ProjectStatus.in_progress).toList();
      _myPendingReviewProjects = myProjects.where((p) => p.status == ProjectStatus.pending_review).toList();
      _myCompletedProjects = myProjects.where((p) => p.status == ProjectStatus.completed).toList();
    } catch (e) {
      _errorMessage = "Projelerim yüklenirken bir hata oluştu: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  // Proje yaşam döngüsü aksiyonları...
  Future<bool> deliverProject(String projectId) async {
    if (_token == null) return false;
    final updatedProject = await _apiService.deliverProject(projectId: projectId);
    if (updatedProject != null) {
      _myActiveProjects.removeWhere((p) => p.id == projectId);
      _myPendingReviewProjects.insert(0, updatedProject);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> acceptDelivery(String projectId) async {
    if (_token == null) return false;
    final updatedProject = await _apiService.acceptDelivery(projectId: projectId);
    if (updatedProject != null) {
      _myPendingReviewProjects.removeWhere((p) => p.id == projectId);
      _myCompletedProjects.insert(0, updatedProject);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> requestRevision(String projectId, String reason) async {
    _isLoading = true;
    notifyListeners();

    final updatedProject = await _apiService.requestRevision(
        projectId: projectId,
        reason: reason // <-- EKLENDİ
    );

    if (updatedProject != null) {
      // Listeyi güncelle veya detay sayfasını yenile
      await fetchMyProjects();
      // Eğer detay sayfasındaysan ve o projeyi tutuyorsan onu da güncellemen gerekebilir
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- YENİ EKLENECEK FONKSİYON ---
  Future<bool> submitReview({required ReviewCreate reviewData}) async {
    if (_token == null) {
      _errorMessage = "Yorum göndermek için giriş yapmalısınız.";
      notifyListeners();
      return false;
    }

    final newReview = await _apiService.submitReview(reviewData: reviewData);

    if (newReview != null) {
      // Değerlendirme başarılı olursa, paneldeki verileri yenileyerek
      // arayüzün "daha önce yorum yapıldı" durumunu anlamasını sağla.
      await fetchMyProjects();
      return true;
    } else {
      _errorMessage = "Yorumunuz gönderilirken bir hata oluştu.";
      notifyListeners();
      return false;
    }
  }
  Future<bool> updateProject({
    required String projectId,
    required String title,
    required String description,
    required String category,
    int? budgetMin,
    int? budgetMax,
    DateTime? deadline,
    // Yetenek listesini güncelleme şimdilik dışarıda tutuldu, istersen eklenebilir.
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final updateData = {
        'title': title,
        'description': description,
        'category': category,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        // API'ye ISO8601 formatında gönderiyoruz
        'deadline': deadline?.toIso8601String(),
      };

      final updatedProject = await _apiService.updateProject(
        projectId: projectId,
        updateData: updateData,
      );

      if (updatedProject != null) {
        // Kritik adım: Güncellenen projeyi ilgili listede bul ve değiştir.
        final index = _myActiveProjects.indexWhere((p) => p.id == projectId);
        if (index != -1) {
          _myActiveProjects[index] = updatedProject;
        }
        // Projelerim listesini toplu güncelleme ihtiyacını ortadan kaldırır.
        notifyListeners();
        return true;
      }
      return false;

    } catch (e) {
      _errorMessage = "Proje güncellenirken bir hata oluştu: ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// --- YENİ: Proje Silme Fonksiyonu ---
  Future<bool> deleteProject(String projectId) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.deleteProject(projectId: projectId);

      if (success) {
        // Kritik adım: Projeyi tüm listelerden (active, pending, completed) kaldır.
        _myActiveProjects.removeWhere((p) => p.id == projectId);
        _myPendingReviewProjects.removeWhere((p) => p.id == projectId);
        _myCompletedProjects.removeWhere((p) => p.id == projectId);

        // Arayüzün güncellenmesi için bir kez daha MyProjects'i çekmek daha güvenli olabilir.
        await fetchMyProjects();

        notifyListeners();
        return true;
      }
      return false;

    } catch (e) {
      _errorMessage = "Proje silinirken bir hata oluştu: ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // --- YENİ FONKSİYON ---
  Future<void> fetchRecommendedProjects() async {
    if (_token == null) return;
    _isRecommendationsLoading = true;
    notifyListeners();
    try {
      _recommendedProjects = await _apiService.getRecommendedProjects();
    } catch (e) {
      // Hata durumunda listeyi boşalt
      _recommendedProjects = [];
    }
    _isRecommendationsLoading = false;
    notifyListeners();
  }
}