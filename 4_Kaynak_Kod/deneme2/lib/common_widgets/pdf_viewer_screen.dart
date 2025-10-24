import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl; // Gösterilecek PDF'in sunucudaki yolu
  final String title;   // AppBar'da gösterilecek başlık

  const PdfViewerScreen({super.key, required this.fileUrl, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  // PDF'i internetten indirip geçici bir dosyaya kaydeden fonksiyon
  Future<void> _loadPdf() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/${widget.fileUrl}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${widget.fileUrl.split('/').last}');
        await file.writeAsBytes(response.bodyBytes, flush: true);
        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Dosya indirilemedi: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'PDF yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _localFilePath != null
          ? PDFView(
        filePath: _localFilePath,
      )
          : const Center(child: Text('PDF yüklenemedi.')),
    );
  }
}