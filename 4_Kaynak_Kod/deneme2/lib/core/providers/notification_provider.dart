// lib/core/providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // --- YENİ EKLENEN STATE ---
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // Artık unreadCount'ı doğrudan bu değişkenden alacağız
  int get unreadCount => _unreadCount;

  // Uygulama ilk açıldığında veya periyodik olarak çağrılacak fonksiyon
  Future<void> fetchUnreadCount() async {
    _unreadCount = await _apiService.getUnreadNotificationCount();
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications();
      // Bildirim listesi çekildiğinde, okunmamış sayısını da yerel olarak güncelleyelim
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      _error = "Bildirimler yüklenemedi.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      // Sayacı anında azalt
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
      await _apiService.markNotificationAsRead(notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    // Tümünü yerel olarak okundu yap
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    // Sayacı sıfırla
    _unreadCount = 0;
    notifyListeners();
    // API'ye isteği gönder
    await _apiService.markAllNotificationsAsRead();
  }
}