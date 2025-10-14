import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/services/api_service.dart'; // AuthProvider yerine ApiService'i import ediyoruz

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

  // ================== ANA DÜZELTME BURADA ==================
  // Ekrana özel bir ApiService instance'ı oluşturuyoruz.
  // Bu, Provider'a erişim sorununu çözer.
  final ApiService _apiService = ApiService();
  // ==========================================================

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

    final htmlString = await rootBundle.loadString('assets/html/autodesk_viewer.html');
    if (mounted) {
      setState(() {
        _htmlContent = htmlString;
      });
    }
  }

  Future<void> _injectDataIntoWebView() async {
    if (_webViewController == null || !mounted) return;

    try {
      // ================== ANA DÜZELTME BURADA ==================
      // Artık AuthProvider yerine doğrudan oluşturduğumuz _apiService'i kullanıyoruz.
      final tokenData = await _apiService.getViewerToken();
      // ==========================================================

      if (tokenData == null) {
        throw Exception("Görüntüleyici token'ı alınamadı.");
      }
      final accessToken = tokenData['access_token'];

      await _webViewController!.evaluateJavascript(source: "setToken('$accessToken');");
      await _webViewController!.evaluateJavascript(source: "loadModel('${widget.modelUrn}');");

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Model yüklenirken bir hata oluştu: ${e.toString()}";
          _isPageLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_htmlContent != null)
            InAppWebView(
              initialData: InAppWebViewInitialData(data: _htmlContent!),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
                useWideViewPort: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (controller, url) {
                _injectDataIntoWebView();
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100 && mounted) {
                  setState(() {
                    _isPageLoading = false;
                  });
                }
              },
            ),

          if (_isPageLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text('Model Yüklenemedi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
