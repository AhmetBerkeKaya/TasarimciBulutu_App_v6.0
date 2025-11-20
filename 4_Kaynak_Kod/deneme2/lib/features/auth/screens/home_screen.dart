// lib/features/auth/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';

// Ekran importları
import '../../dashboard/screens/dashboard_screen.dart';
import '../../messages/screens/message_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../project/screens/project_list_screen.dart';
import '../../showcase/screens/showcase_feed_screen.dart';
import '../../activity/screens/activity_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- FREELANCER İÇİN NAVİGASYON (5 MADDE) ---
  static const List<Widget> _freelancerPages = [
    ShowcaseFeedScreen(),     // 1. Ana Sayfa (Vitrini)
    ProjectListScreen(),      // 2. İş İlanları
    ActivityScreen(),         // 3. Aktivitem (Başvurular + Projeler)
    MessageListScreen(),      // 4. Mesajlar
    ProfileScreen(),          // 5. Profil
  ];

  static const List<BottomNavigationBarItem> _freelancerNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
    BottomNavigationBarItem(icon: Icon(Icons.work_outline_rounded), label: 'İş İlanları'),
    BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Aktivitem'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  // --- FİRMA (CLIENT) İÇİN NAVİGASYON (4 MADDE) ---
  static const List<Widget> _clientPages = [
    DashboardScreen(),        // 1. Panelim (Kendi Projeleri)
    ShowcaseFeedScreen(),     // 2. Vitrini Keşfet (Tasarımcı Bul)
    MessageListScreen(),      // 3. Mesajlar
    ProfileScreen(),          // 4. Profil
  ];

  static const List<BottomNavigationBarItem> _clientNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Panelim'),
    BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Keşfet'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isClient = user?.role == UserRole.client;

    final List<Widget> pages = isClient ? _clientPages : _freelancerPages;
    final List<BottomNavigationBarItem> navItems = isClient ? _clientNavItems : _freelancerNavItems;

    // Güvenlik kontrolü: Index liste dışına taşarsa sıfırla
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        // Hafif bir gölge ekleyerek tab bar'ı içerikten ayıralım (Cila)
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: navItems,
          // Tema Ayarları (AppTheme ile uyumlu)
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          showUnselectedLabels: true,
          elevation: 0, // Container'da gölge verdiğimiz için burada 0 yapıyoruz
        ),
      ),
    );
  }
}