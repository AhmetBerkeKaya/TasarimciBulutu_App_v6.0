// lib/features/activity/screens/activity_screen.dart

import 'package:flutter/material.dart';
import '../../applications/screens/my_applications_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aktivitem'),
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.file_copy_outlined),
                text: 'Başvurularım',
              ),
              Tab(
                icon: Icon(Icons.dashboard_customize_outlined),
                text: 'Yürüttüğüm Projeler',
              ),
            ],
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
          ),
        ),
        body: const TabBarView(
          children: [
            MyApplicationsScreen(),
            DashboardScreen(), // Dashboard'un freelancer versiyonu
          ],
        ),
      ),
    );
  }
}
