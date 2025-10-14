import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common_widgets/status_chip.dart';
import '../../../data/models/enums.dart';

class ApplicationCard extends StatelessWidget {
  final String projectTitle;
  final String companyName;
  final ApplicationStatus status;
  final DateTime appliedDate;
  final VoidCallback? onTap; // Tıklanma fonksiyonu

  const ApplicationCard({
    super.key,
    required this.projectTitle,
    required this.companyName,
    required this.status,
    required this.appliedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Card widget'ını InkWell ile sarmalayarak tıklanabilir hale getiriyoruz.
    return Card(
      clipBehavior: Clip.antiAlias, // Tıklama efektinin kartın köşelerinden taşmasını önler
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap, // Gelen onTap fonksiyonunu buraya bağlıyoruz
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Proje Başlığı ve Firma Adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(projectTitle, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(companyName, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  // Durum Etiketi
                  StatusChip(status: status),
                ],
              ),
              const Divider(height: 24),
              // Başvuru Tarihi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Başvuru Tarihi: ${DateFormat('dd.MM.yyyy').format(appliedDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}