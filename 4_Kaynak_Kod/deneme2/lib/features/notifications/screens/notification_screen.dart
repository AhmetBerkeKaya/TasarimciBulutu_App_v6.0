// lib/features/notifications/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açılırken veriyi çek, ama sadece ilk açılışta
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Tümünü Oku'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              message: 'Bir Hata Oluştu',
              suggestion: provider.error,
              actionButton: ElevatedButton(
                onPressed: () => provider.fetchNotifications(),
                child: const Text('Tekrar Dene'),
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_off_outlined,
              message: 'Yeni Bildirim Yok',
              suggestion: 'Yeni bir gelişme olduğunda burada görünecektir.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}