// lib/features/auth/screens/home_screen.dart

import 'dart:ui'; // Blur efekti için gerekli
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

  // --- FREELANCER SAYFALARI ---
  static const List<Widget> _freelancerPages = [
    ShowcaseFeedScreen(),
    ProjectListScreen(),
    ActivityScreen(),
    MessageListScreen(),
    ProfileScreen(),
  ];

  // --- CLIENT SAYFALARI ---
  static const List<Widget> _clientPages = [
    DashboardScreen(),
    ShowcaseFeedScreen(),
    MessageListScreen(),
    ProfileScreen(),
  ];

  // Navigasyon Öğeleri (Custom Yapı için Map Listesi)
  final List<Map<String, dynamic>> _freelancerNavItems = [
    {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
    {'icon': Icons.work_outline_rounded, 'label': 'İşler'},
    {'icon': Icons.assessment_outlined, 'label': 'Aktivite'},
    {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Mesaj'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
  ];

  final List<Map<String, dynamic>> _clientNavItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Panel'},
    {'icon': Icons.explore_outlined, 'label': 'Keşfet'},
    {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Mesaj'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rol Kontrolü
    final user = context.watch<AuthProvider>().user;
    final isClient = user?.role == UserRole.client;

    final List<Widget> pages = isClient ? _clientPages : _freelancerPages;
    final List<Map<String, dynamic>> navItems = isClient ? _clientNavItems : _freelancerNavItems;

    // Index taşması güvenliği
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      extendBody: true, // İçeriğin barın arkasına taşmasını sağlar (Glass effect için şart)

      // ÇAKIŞMA ÇÖZÜMÜ:
      // Alt ekranlara (ShowcaseFeedScreen vb.) ekstra bir 'bottom padding' enjekte ediyoruz.
      // Böylece o ekranlar FAB'larını bu boşluğun (yani bizim Nav Bar'ımızın) üzerine çiziyor.
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            // Mevcut güvenli alana +90px ekleyerek FAB'ı yukarı itiyoruz.
            // Bu, içeriğin barın arkasına geçmesini engellemez, sadece FAB'ı etkiler.
            bottom: MediaQuery.of(context).padding.bottom + 90.0,
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _buildGlassBottomBar(context, navItems),
    );
  }

  Widget _buildGlassBottomBar(BuildContext context, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // "Grimsi" ve Opaklığı düşük renk paleti
    final backgroundColor = isDark
        ? const Color(0xFF121212).withOpacity(0.85) // Dark Mode: Çok koyu gri/siyah
        : const Color(0xFFB5B5B5).withOpacity(0.85); // Light Mode: Koyu Antrasit Gri

    return ClipRRect(
      // Sadece üst köşeleri hafif yuvarlatarak modern bir bitiş sağlıyoruz
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Buzlu cam efekti
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 20,
              top: 16,
              left: 12,
              right: 12
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(index),
                  // Tıklama efekti için yuvarlak sınır
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: isSelected
                        ? BoxDecoration(
                      // Seçili olduğunda arkaya çok hafif bir aydınlık veriyoruz
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    )
                        : const BoxDecoration(color: Colors.transparent),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İKON
                        Icon(
                          item['icon'] as IconData,
                          // Seçiliyse Tam Beyaz, değilse opak siyah/beyaz
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)),
                          size: 26,
                        ),

                        // YAZI
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)),
                          ),
                          child: Text(item['label']),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}