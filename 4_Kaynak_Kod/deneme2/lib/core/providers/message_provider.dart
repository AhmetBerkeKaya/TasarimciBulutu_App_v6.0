// lib/core/providers/message_provider.dart (YEPYENİ)

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../data/models/message_model.dart';

class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Message> _conversations = []; // Orijinal liste
  List<Message> _filteredConversations = []; // Arama yapılmış liste
  bool _isLoading = false;
  String? _errorMessage;

  // --- SEÇİM MODU İÇİN ---
  bool _isSelectionMode = false;
  final Set<String> _selectedConversationIds = {}; // Seçilenlerin ID'leri

  // GETTER'lar
  List<Message> get conversations => _filteredConversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedConversationIds.length;

  bool isSelected(String id) => _selectedConversationIds.contains(id);

  // --- VERİ ÇEKME ---
  // Parametreye 'silent' eklendi, varsayılanı false (yani normalde loading gösterir)
  Future<void> fetchConversations({bool silent = false}) async {
    // Eğer sessiz değilse loading'i aç
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _apiService.getConversations();

      // Veri değişti mi kontrolü yapabiliriz ama şimdilik direkt atayalım.
      _conversations = data;

      // Eğer arama yapılmıyorsa (arama kutusu boşsa), filtreli listeyi de güncelle
      // (Arama yaparken liste aniden değişmesin diye kontrol edebiliriz, şimdilik direkt güncelliyoruz)
      _filteredConversations = data;

    } catch (e) {
      // Sessiz modda hata olsa bile kullanıcıya gösterme, sessizce geç.
      if (!silent) {
        _errorMessage = "Mesajlar yüklenemedi.";
        _conversations = [];
        _filteredConversations = [];
      }
    }

    // İşlem bitti
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners(); // Her durumda UI güncellensin (yeni mesaj varsa görünsün)
  }

  // --- ARAMA ---
  void searchConversations(String query) {
    if (query.isEmpty) {
      _filteredConversations = _conversations;
    } else {
      _filteredConversations = _conversations.where((msg) {
        // Karşı tarafın isminde veya son mesaj içeriğinde arama yap
        final otherUser = msg.sender.id == msg.receiver.id ? msg.receiver : (msg.sender.id == 'ME' ? msg.receiver : msg.sender);
        // Not: 'ME' kontrolü temsili, normalde currentUser ID ile kontrol edilir.
        // Basitlik için isme bakıyoruz:
        final nameMatch = msg.sender.name.toLowerCase().contains(query.toLowerCase()) ||
            msg.receiver.name.toLowerCase().contains(query.toLowerCase());
        final contentMatch = msg.content.toLowerCase().contains(query.toLowerCase());
        return nameMatch || contentMatch;
      }).toList();
    }
    notifyListeners();
  }

  // --- SEÇİM MODU YÖNETİMİ ---
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selectedConversationIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedConversationIds.contains(id)) {
      _selectedConversationIds.remove(id);
    } else {
      _selectedConversationIds.add(id);
    }

    // Hiçbiri seçili değilse moddan çıkma (İsteğe bağlı, şimdilik kalabilir)
    if (_selectedConversationIds.isEmpty && !_isSelectionMode) {
      // _isSelectionMode = false;
    }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedConversationIds.length == _filteredConversations.length) {
      _selectedConversationIds.clear(); // Zaten hepsi seçiliyse kaldır
    } else {
      // Hepsini seç
      _selectedConversationIds.clear();
      for (var c in _filteredConversations) {
        // Burada conversation ID'si yoksa mesaj ID'sini veya karşı kullanıcının ID'sini kullanabiliriz.
        // API genellikle son mesajı döner. Benzersiz bir ID bulmalıyız.
        // En doğrusu 'Other User ID'sini kullanmaktır.
        // Ancak basitlik için şimdilik mesaj ID'sini kullanalım, ama backend 'other_user_id' bekliyor.
        // Bu yüzden UI tarafında ID çıkarma mantığını iyi kurmalıyız.
        // Şimdilik 'otherUser' ID'sini bulup ekleyelim.
        // (Bu mantığı UI tarafına bırakmak daha güvenli olabilir ama burada deneyelim)
        // HATA RİSKİ: CurrentUser ID'ye erişimimiz yok burada.
        // ÇÖZÜM: UI'dan ID göndererek toggle yapacağız. selectAll için ise UI tarafında döngü kuracağız.
      }
    }
    notifyListeners();
  }

  // --- TOPLU SİLME ---
  Future<bool> deleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Seçili ID'leri listeye çevir
      final idsToDelete = _selectedConversationIds.toList();

      // 2. API'yi çağır (Az önce yazdığımız fonksiyon)
      final success = await _apiService.deleteBulkConversations(idsToDelete);

      if (success) {
        // 3. Başarılıysa yerel listeden de sil (Ekran anında güncellensin)
        _conversations.removeWhere((msg) {
          // Mesajın karşı tarafının ID'si silinenler listesinde var mı?
          // Not: Message modelinde sender/receiver kontrolü yapmamız lazım.
          // Basitlik için: Listeyi komple yenileyelim, en temizidir.
          return false;
        });

        // Listeyi sunucudan taze çek
        await fetchConversations();

        // 4. Seçim modunu kapat
        _isSelectionMode = false;
        _selectedConversationIds.clear();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Silme işlemi başarısız oldu.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Bir hata oluştu.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}