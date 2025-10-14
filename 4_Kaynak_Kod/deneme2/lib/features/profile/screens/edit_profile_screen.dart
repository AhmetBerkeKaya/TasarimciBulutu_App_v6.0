// lib/features/profile/screens/edit_profile_screen.dart
import 'dart:io'; // Dosya işlemleri için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Resim seçmek için
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/user_model.dart'; // User modeli için

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  // YENİ: Yükleme durumunu ve seçilen dosyayı takip etmek için state'ler
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Sağlayıcıdan mevcut kullanıcı verilerini alıp controller'ları dolduruyoruz.
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name);
    _bioController = TextEditingController(text: user?.bio);
  }

  // YENİ: Galeriden resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool overallSuccess = true;

    if (_selectedImage != null) {
      final pictureSuccess = await authProvider.updateProfilePicture(_selectedImage!);
      if (!pictureSuccess) {
        overallSuccess = false;
      }
    }

    // Resim yükleme başarısız olsa bile diğer bilgileri güncellemeyi deneyebiliriz.
    final profileData = {
      'name': _nameController.text,
      'bio': _bioController.text,
    };
    final profileSuccess = await authProvider.updateProfile(profileData);
    if (!profileSuccess) {
      overallSuccess = false;
    }

    if (!mounted) return;

    // DEĞİŞİKLİK BURADA: Başarılı olursa geri dönerken 'true' değeri gönderiyoruz.
    if (overallSuccess) {
      Navigator.of(context).pop(true); // <--- ÖNEMLİ DEĞİŞİKLİK
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellenirken bir veya daha fazla hata oluştu.'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consumer widget'ı ile AuthProvider'daki anlık kullanıcı verisine ulaşıyoruz.
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Kaydet',
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // YENİ: Profil resmi değiştirme UI bölümü
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    // Önce seçilen yeni resmi, yoksa mevcut URL'yi göster
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(user.profilePictureUrl!)
                        : null),
                    child: (_selectedImage == null && (user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty))
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value!.isEmpty ? 'İsim alanı boş bırakılamaz.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Hakkımda (Bio)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 5,
              maxLength: 250, // Kullanıcıya bir karakter limiti verelim.
            ),
          ],
        ),
      ),
    );
  }
}