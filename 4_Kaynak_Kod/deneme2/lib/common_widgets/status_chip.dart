// lib/common_widgets/status_chip.dart dosyasının tamamı

import 'package:flutter/material.dart';
import '../data/models/enums.dart';

class StatusChip extends StatelessWidget {
  final dynamic status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData? icon;

    if (status is ApplicationStatus) {
      switch (status as ApplicationStatus) {
        case ApplicationStatus.pending:
          text = 'Beklemede';
          color = Colors.orange;
          icon = Icons.hourglass_top_rounded;
          break;
        case ApplicationStatus.accepted:
          text = 'Kabul Edildi';
          color = Colors.green;
          icon = Icons.check_circle_outline;
          break;
        case ApplicationStatus.rejected:
          text = 'Reddedildi';
          color = Colors.red;
          icon = Icons.cancel_outlined;
          break;
      }
    } else if (status is ProjectStatus) {
      switch (status as ProjectStatus) {
        case ProjectStatus.open:
          text = 'Açık';
          color = Colors.blue;
          icon = Icons.rocket_launch_outlined;
          break;
        case ProjectStatus.in_progress: // <-- DÜZELTME BURADA
          text = 'Devam Ediyor';
          color = Colors.purple;
          icon = Icons.construction;
          break;
        case ProjectStatus.pending_review:
          text = 'Onay Bekleniyor';
          color = Colors.orange;
          icon = Icons.hourglass_top_rounded;
          break;
        case ProjectStatus.completed:
          text = 'Tamamlandı';
          color = Colors.green;
          icon = Icons.verified_outlined;
          break;
        case ProjectStatus.cancelled:
          text = 'İptal Edildi';
          color = Colors.grey;
          icon = Icons.do_not_disturb;
          break;
      }
    } else {
      text = 'Bilinmiyor';
      color = Colors.grey;
    }

    return Chip(
      avatar: icon != null ? Icon(icon, color: color, size: 18) : null,
      label: Text(text),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}