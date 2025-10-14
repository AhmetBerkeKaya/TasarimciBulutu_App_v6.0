// lib/core/services/dio_client.dart

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  // Singleton pattern
  DioClient._();
  static final instance = DioClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000",
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.json,
    ),
  )..interceptors.addAll([
    AuthInterceptor(),
    LoggingInterceptor(),
  ]);

  Dio get dio => _dio;
}

// --- INTERCEPTOR'LAR ---

class AuthInterceptor extends Interceptor {
  // AuthService'in tamamını çağırmak yerine, sadece ihtiyacımız olan
  // FlutterSecureStorage'ı doğrudan kullanmak daha verimli ve temizdir.
  final _storage = const FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {

    // --- KALICI DÜZELTME ---
    // Token GEREKTİRMEYEN tüm endpoint'leri burada listeliyoruz.
    // Bu, gelecekte yeni public endpoint'ler eklendiğinde
    // sadece burayı güncellememizin yeterli olmasını sağlar.
    final publicPaths = [
      '/token',
      '/users/', // Sadece POST metodu için kontrol aşağıda yapılıyor
      '/password-recovery',
      '/reset-password',
      '/auth/google', // Google ile giriş de public olmalı
    ];

    // Mevcut isteğin yolu, public yollardan biriyle eşleşiyor mu?
    bool isPublic = publicPaths.contains(options.path);

    // Kayıt olma (/users/) endpoint'i sadece POST metodu ile public olmalı.
    if (options.path == '/users/' && options.method != 'POST') {
      isPublic = false;
    }

    // Eğer istek public DEĞİLSE, token eklemeyi dene.
    if (!isPublic) {
      final String? token = await _storage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        print('>>> AuthInterceptor: Token eklendi -> ${options.path}');
      } else {
        // Token gerektiren bir istekte token bulunamazsa, bu bir hatadır.
        // İsteği bir hata ile reddedebiliriz. Bu, uygulamanın
        // beklenmedik durumlarda çökmesini önler.
        print('>>> AuthInterceptor: Token bulunamadı, istek engellendi -> ${options.path}');
        handler.reject(
          DioException(
            requestOptions: options,
            error: "Authentication token not found.",
          ),
        );
        return; // reject'ten sonra devam etme
      }
    }
    // --- DÜZELTME SONU ---

    // İsteğin devam etmesine izin ver
    handler.next(options);
  }
}


class LoggingInterceptor extends Interceptor {
  final logger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    maxWidth: 90,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.onError(err, handler);
  }
}
