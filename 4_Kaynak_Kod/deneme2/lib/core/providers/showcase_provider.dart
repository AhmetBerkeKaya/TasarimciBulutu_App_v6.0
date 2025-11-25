// lib/core/providers/showcase_provider.dart (DÜZELTİLMİŞ TAM HALİ)

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/models/comment_model.dart';
import '../../data/models/showcase_post_model.dart';
import '../services/api_service.dart';

enum ShowcaseState { initial, loading, loaded, loadingMore, error }

class ShowcaseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;

  List<ShowcasePost> _posts = [];
  ShowcaseState _state = ShowcaseState.initial;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isCreatingPost = false;

  // Arama ve Sıralama State'leri
  String _searchQuery = '';
  String _sortBy = 'newest';

  // Getter'lar
  List<ShowcasePost> get posts => _posts;
  ShowcaseState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMorePosts => _hasMorePosts;
  bool get isCreatingPost => _isCreatingPost;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  void updateToken(String? token) {
    if (token != null && _state == ShowcaseState.initial) {
      fetchPosts();
    }
  }

  // === SIRALAMA DEĞİŞTİRME ===
  Future<void> setSortBy(String sortOption) async {
    _sortBy = sortOption;
    _posts = [];
    _hasMorePosts = true;
    _currentPage = 0;
    await fetchPosts();
  }

  // === ARAMA YAPMA ===
  Future<void> searchPosts(String query) async {
    _searchQuery = query;
    _posts = [];
    _hasMorePosts = true;
    _currentPage = 0;
    await fetchPosts();
  }

  // === VERİ ÇEKME (FETCH) ===
  Future<void> fetchPosts() async {
    if (_state == ShowcaseState.loading) return;
    _state = ShowcaseState.loading;
    notifyListeners();

    try {
      _currentPage = 0;
      final newPosts = await _apiService.getShowcasePosts(
          page: _currentPage,
          limit: _pageSize,
          search: _searchQuery,
          sortBy: _sortBy // <-- Virgül hatası buradaydı, düzeltildi
      );
      _posts = newPosts;
      _hasMorePosts = newPosts.length == _pageSize;
      _state = ShowcaseState.loaded;
    } catch (e) {
      _errorMessage = "Gönderiler yüklenirken bir hata oluştu: $e";
      _state = ShowcaseState.error;
    } finally {
      notifyListeners();
    }
  }

  // === DAHA FAZLA YÜKLE (PAGINATION) ===
  Future<void> fetchMorePosts() async {
    if (_state == ShowcaseState.loadingMore || !_hasMorePosts) return;
    _state = ShowcaseState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      final newPosts = await _apiService.getShowcasePosts(
          page: _currentPage,
          limit: _pageSize,
          search: _searchQuery,
          sortBy: _sortBy // <-- Virgül hatası düzeltildi
      );
      if (newPosts.length < _pageSize) {
        _hasMorePosts = false;
      }
      _posts.addAll(newPosts);
      _state = ShowcaseState.loaded;
    } catch (e) {
      _errorMessage = "Daha fazla gönderi yüklenemedi: $e";
      _state = ShowcaseState.error;
    } finally {
      notifyListeners();
    }
  }

  // --- DİĞER İŞLEMLER (CREATE, DELETE, LIKE, COMMENT) ---

  Future<bool> createPost({
    required String title,
    String? description,
    required File fileToUpload,
  }) async {
    _isCreatingPost = true;
    _errorMessage = null;
    notifyListeners();

    try {
      File zipFile;
      const supported3DModelExtensions = [
        '.obj', '.stl', '.step', '.stp', '.iges', '.igs', '.fbx', '.x_t', '.x_b',
        '.gltf', '.glb', '.3ds', '.x3d', '.sldprt', '.sldasm', '.ipt', '.iam',
        '.rvt', '.catpart', '.catproduct', '.cgr', '.prt', '.asm'
      ];
      final fileExtension = path.extension(fileToUpload.path).toLowerCase();
      if (supported3DModelExtensions.contains(fileExtension)) {
        zipFile = await _createZipFromFile(fileToUpload, 'model$fileExtension');
      } else {
        zipFile = fileToUpload;
      }
      final initResponse = await _apiService.initializePostUpload(
        title: title,
        description: description,
        originalFilename: path.basename(zipFile.path),
      );
      if (initResponse == null) {
        throw Exception("Backend'den yükleme linki alınamadı.");
      }
      final uploadSuccess = await _apiService.uploadFileToS3(
        presignedData: initResponse.uploadData,
        file: zipFile,
      );
      if (!uploadSuccess) {
        throw Exception("Dosya S3'e yüklenemedi.");
      }
      await fetchPosts();
      return true;
    } catch (e) {
      _errorMessage = "Gönderi oluşturulurken bir hata oluştu: ${e.toString().replaceAll("Exception: ", "")}";
      return false;
    } finally {
      _isCreatingPost = false;
      notifyListeners();
    }
  }

  Future<File> _createZipFromFile(File sourceFile, String fileNameInZip) async {
    final bytes = await sourceFile.readAsBytes();
    final archive = Archive();
    final archiveFile = ArchiveFile(fileNameInZip, bytes.length, bytes);
    archive.addFile(archiveFile);
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData == null) throw Exception('ZIP verisi oluşturulamadı.');
    final tempDir = Directory.systemTemp;
    final zipFileName = '${path.basenameWithoutExtension(sourceFile.path)}.zip';
    final zipFile = File(path.join(tempDir.path, zipFileName));
    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  Future<bool> deletePost(String postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return false;
    final postToRemove = _posts.removeAt(postIndex);
    notifyListeners();
    final success = await _apiService.deleteShowcasePost(postId: postId);
    if (!success) {
      _posts.insert(postIndex, postToRemove);
      _errorMessage = "Gönderi silinemedi. Lütfen tekrar deneyin.";
      notifyListeners();
    }
    return success;
  }

  Future<void> toggleLike(String postId, String currentUserId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    final post = _posts[postIndex];
    final isLiked = post.likes.any((like) => like.userId == currentUserId);
    if (isLiked) {
      post.likes.removeWhere((like) => like.userId == currentUserId);
    } else {
      post.likes.add(PostLike(userId: currentUserId, postId: postId));
    }
    notifyListeners();
    try {
      if (isLiked) {
        await _apiService.unlikePost(postId: postId);
      } else {
        await _apiService.likePost(postId: postId);
      }
    } catch (e) {
      print("Beğenme işlemi başarısız: $e");
      if (isLiked) {
        post.likes.add(PostLike(userId: currentUserId, postId: postId));
      } else {
        post.likes.removeWhere((like) => like.userId == currentUserId);
      }
      notifyListeners();
    }
  }

  Future<bool> addComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final newComment = await _apiService.addComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );
      if (newComment != null) {
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          if (parentCommentId != null) {
            _findAndAddReply(_posts[postIndex].comments, parentCommentId, newComment);
          } else {
            _posts[postIndex].comments.insert(0, newComment);
          }
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Yorum eklenemedi: $e");
      return false;
    }
  }

  void _findAndAddReply(List<Comment> comments, String parentId, Comment reply) {
    for (var comment in comments) {
      if (comment.id == parentId) {
        comment.replies.insert(0, reply);
        return;
      }
      if (comment.replies.isNotEmpty) {
        _findAndAddReply(comment.replies, parentId, reply);
      }
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId, String currentUserId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    Comment? targetComment = findComment(_posts[postIndex].comments, commentId);
    if (targetComment == null) return;
    final isLiked = targetComment.likes.any((like) => like.userId == currentUserId);
    if (isLiked) {
      targetComment.likes.removeWhere((like) => like.userId == currentUserId);
    } else {
      targetComment.likes.add(CommentLike(userId: currentUserId, commentId: commentId));
    }
    notifyListeners();
    try {
      if (isLiked) {
        await _apiService.unlikeComment(commentId: commentId);
      } else {
        await _apiService.likeComment(commentId: commentId);
      }
    } catch (e) {
      if (isLiked) {
        targetComment.likes.add(CommentLike(userId: currentUserId, commentId: commentId));
      } else {
        targetComment.likes.removeWhere((like) => like.userId == currentUserId);
      }
      notifyListeners();
    }
  }

  Comment? findComment(List<Comment> comments, String commentId) {
    for (var comment in comments) {
      if (comment.id == commentId) return comment;
      final foundInReply = findComment(comment.replies, commentId);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    final success = await _apiService.deleteComment(commentId: commentId);
    if (success) {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final removed = _findAndRemoveComment(_posts[postIndex].comments, commentId);
        if (removed) {
          notifyListeners();
        }
      }
    }
    return success;
  }
  // === YENİ EKLENEN: GÖNDERİ BİLDİRME ===
  Future<bool> reportPost(String postId, String reason, String description) async {
    try {
      // ApiService üzerinden backend'e istek atıyoruz
      await _apiService.reportShowcasePost(
          postId: postId,
          reason: reason,
          description: description
      );

      // İşlem başarılı olursa true dön
      return true;
    } catch (e) {
      print("Raporlama hatası: $e");
      _errorMessage = "Bildirim gönderilemedi: $e";
      notifyListeners();
      return false;
    }
  }
  bool _findAndRemoveComment(List<Comment> comments, String commentId) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        comments.removeAt(i);
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        if (_findAndRemoveComment(comments[i].replies, commentId)) {
          return true;
        }
      }
    }
    return false;
  }
}