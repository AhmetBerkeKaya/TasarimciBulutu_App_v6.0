// lib/features/notifications/widgets/notification_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_summary_model.dart';

// Gerekli ekranları import edelim
import '../../activity/screens/activity_screen.dart';
import '../../messages/screens/chat_screen.dart';
import '../../project/screens/project_detail_loader_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../skill_assessment/screens/skill_test_list_screen.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const NotificationTile({super.key, required this.notification});

  Map<String, dynamic> _getNotificationAppearance(NotificationType type, BuildContext context) {
    Color color = Theme.of(context).colorScheme.secondary;
    IconData icon = Icons.notifications;

    switch (type) {
      case NotificationType.newMessage:
        icon = Icons.message_rounded;
        color = Colors.blue;
        break;
      case NotificationType.applicationSubmitted:
      case NotificationType.applicationAccepted:
      case NotificationType.applicationRejected:
        icon = Icons.assignment_turned_in_rounded;
        color = Colors.orange;
        break;
      case NotificationType.projectDelivered:
      case NotificationType.deliveryAccepted:
      case NotificationType.revisionRequested:
        icon = Icons.construction_rounded;
        color = Colors.purple;
        break;
      case NotificationType.newReview:
        icon = Icons.star_rounded;
        color = Colors.amber;
        break;
      case NotificationType.postLiked:
      case NotificationType.commentLiked:
        icon = Icons.favorite_rounded;
        color = Colors.red;
        break;
      case NotificationType.postCommented:
      case NotificationType.commentReplied:
        icon = Icons.comment_rounded;
        color = Colors.green;
        break;
      case NotificationType.skillTestResult:
        icon = Icons.emoji_events_rounded;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
    }
    return {'icon': icon, 'color': color};
  }

  void _handleNavigation(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsRead(notification.id);

    switch (notification.type) {
      case NotificationType.newMessage:
        if (notification.actor != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatScreen(otherUser: notification.actor!),
          ));
        }
        break;

      case NotificationType.applicationAccepted:
      case NotificationType.applicationRejected:
      case NotificationType.applicationSubmitted:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ActivityScreen(initialTabIndex: 0),
        ));
        break;

      case NotificationType.newReview:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ProfileScreen(scrollToReviews: true),
        ));
        break;

      case NotificationType.projectDelivered:
      case NotificationType.deliveryAccepted:
      case NotificationType.revisionRequested:
      case NotificationType.projectCompleted:
        if (notification.relatedEntityId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProjectDetailLoaderScreen(projectId: notification.relatedEntityId!),
          ));
        }
        break;

      case NotificationType.postLiked:
      case NotificationType.postCommented:
      case NotificationType.commentLiked:
      case NotificationType.commentReplied:
        if (notification.relatedEntityId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vitrin gönderi detayı sayfası yakında eklenecek.')),
          );
        }
        break;

      case NotificationType.skillTestResult:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const SkillTestListScreen(),
        ));
        break;

      case NotificationType.welcome:
      case NotificationType.unknown:
      default:
        print("Bu bildirim türü için yönlendirme tanımlanmamış: ${notification.type}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = _getNotificationAppearance(notification.type, context);
    final IconData icon = appearance['icon'];
    final Color color = appearance['color'];

    timeago.setLocaleMessages('tr', timeago.TrMessages());
    final timeAgo = timeago.format(notification.createdAt, locale: 'tr');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: notification.isRead ? theme.cardColor.withOpacity(0.5) : color.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}