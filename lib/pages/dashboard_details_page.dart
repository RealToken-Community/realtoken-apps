import 'package:flutter/material.dart';

class DashboardRentsDetailsPage extends StatelessWidget {
  const DashboardRentsDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rents Details'),
      ),
      body: Center(
        child: Text(
          'Details of rents will be displayed here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
