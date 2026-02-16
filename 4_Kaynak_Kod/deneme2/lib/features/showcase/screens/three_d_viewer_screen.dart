// lib/features/showcase/screens/three_d_viewer_screen.dart

import 'dart:ui'; // Glassmorphism için
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/services/api_service.dart';

class ThreeDViewerScreen extends StatefulWidget {
  final String modelUrn;
  final String title;

  const ThreeDViewerScreen({
    super.key,
    required this.modelUrn,
    required this.title,
  });

  @override
  State<ThreeDViewerScreen> createState() => _ThreeDViewerScreenState();
}

class _ThreeDViewerScreenState extends State<ThreeDViewerScreen> {
  InAppWebViewController? _webViewController;
  String? _errorMessage;
  String? _htmlContent;
  bool _isPageLoading = true;

  // API Service
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadHtmlAndSetupViewer();
  }

  Future<void> _loadHtmlAndSetupViewer() async {
    if (widget.modelUrn.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Geçerli bir model URN'si bulunamadı.";
          _isPageLoading = false;
        });
      }
      return;
    }

    try {
      final htmlString = await rootBundle.loadString('assets/html/autodesk_viewer.html');
      if (mounted) {
        setState(() {
          _htmlContent = htmlString;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Viewer dosyaları yüklenemedi: $e";
          _isPageLoading = false;
        });
      }
    }
  }

  Future<void> _injectDataIntoWebView() async {
    if (_webViewController == null || !mounted) return;

    try {
      final tokenData = await _apiService.getViewerToken();

      if (tokenData == null) {
        throw Exception("Görüntüleyici token'ı alınamadı.");
      }
      final accessToken = tokenData['access_token'];

      await _webViewController!.evaluateJavascript(source: "setToken('$accessToken');");
      await _webViewController!.evaluateJavascript(source: "loadModel('${widget.modelUrn}');");

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Model yüklenirken hata: ${e.toString()}";
          _isPageLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3D Görüntülemede tema ne olursa olsun arka plan SİYAH olmalı ki model parlasın.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. WEBVIEW KATMANI
          if (_htmlContent != null)
            InAppWebView(
              initialData: InAppWebViewInitialData(data: _htmlContent!),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true, // Arka plan şeffaf olsun ki bizim siyah zemin gözüksün
                useWideViewPort: false,
                supportZoom: false, // Viewer kendi zoom'unu kullanır
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (controller, url) {
                _injectDataIntoWebView();
              },
              onProgressChanged: (controller, progress) {
                // Autodesk Viewer kendi içinde de yükleme yapar, %100 olması webview'in bittiğini gösterir
                if (progress == 100 && mounted && _isPageLoading) {
                  // Yükleme animasyonunu biraz daha tutabiliriz (Viewer init süresi için)
                  // Ancak şimdilik webview yüklenince loading'i kaldırıyoruz.
                  // Gerçek model yüklemesini JS tarafı halledecek.
                  setState(() {
                    _isPageLoading = false;
                  });
                }
              },
            ),

          // 2. CUSTOM GLASS HEADER (GERİ BUTONU & BAŞLIK)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 12,
                  left: 16,
                  right: 16
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  _buildGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. LOADING EKRANI (TAM EKRAN SİYAH)
          if (_isPageLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    const SizedBox(height: 24),
                    const Text(
                      '3D Ortam Hazırlanıyor...',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Büyük modellerin yüklenmesi zaman alabilir.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // 4. HATA EKRANI
          if (_errorMessage != null)
            Container(
              color: Colors.black87, // Arka planı hafif karart
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_off_rounded, color: Colors.red.shade400, size: 48),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Model Yüklenemedi',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Geri Dön'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- MODERN GLASS BUTON ---
  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}