// lib/features/project/widgets/recommended_project_card.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/project_model.dart';
import '../../../common_widgets/status_chip.dart';

class RecommendedProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const RecommendedProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280, // Yatay liste için sabit genişlik
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(project.owner.name.substring(0, 1)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.owner.name,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(project.createdAt, locale: 'tr'),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  project.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    _InfoChip(text: project.category),
                    const Spacer(),
                    StatusChip(status: project.status),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}