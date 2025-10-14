// lib/core/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/enums.dart';
import '../../data/models/user_model.dart';
import 'dio_client.dart';

class AuthService {
  final Dio _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  // --- YENİ FONKSİYONLAR ---

  /// Backend'e şifre sıfırlama kodu gönderilmesi için istek atar.
  Future<bool> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        '/password-recovery',
        data: {'email': email},
      );
      // Backend her zaman 200 OK döneceği için (güvenlik gereği),
      // bir hata fırlatılmadığı sürece başarılı kabul ediyoruz.
      return true;
    } on DioException catch (e) {
      print('requestPasswordReset DioException: ${e.response?.data}');
      return false;
    }
  }

  /// Verilen token ve yeni şifre ile şifreyi sıfırlar.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('resetPassword DioException: ${e.response?.data}');
      return false;
    }
  }

  // --- MEVCUT FONKSİYONLAR (DEĞİŞİKLİK YOK) ---

  Future<User?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/users/',
        data: {
          'email': email,
          'name': name,
          'password': password,
          'role': role.name,
          'phone_number': phoneNumber,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Signup DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/token',
        data: {'username': email, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        // "Beni Hatırla" için refresh_token'ı saklayalım
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        return accessToken;
      }
      return null;
    } on DioException catch (e) {
      print('Login DioException: ${e.response?.data}');
      return null;
    }
  }

  // Diğer fonksiyonlar (getMe, logout, getToken) aynı kalacak
  Future<User?> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('getMe DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll(); // Hem access hem de refresh token'ı sil
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}
