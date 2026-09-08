import 'package:flutter/material.dart';

/// Widget de carte pour le tableau de bord.
class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Dashboard Card'),
      ),
    );
  }
}
