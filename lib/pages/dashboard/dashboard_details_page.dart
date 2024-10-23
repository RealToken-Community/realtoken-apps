import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/api/data_manager.dart';

class DashboardRentsDetailsPage extends StatelessWidget {
  const DashboardRentsDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rents Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding général
        child: dataManager.rentData.isEmpty
            ? Center(
                child: Text(
                  'No rent data available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titres des colonnes
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Montant',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(), // Ligne de séparation entre les titres et les données
                  Expanded(
                    child: ListView.builder(
                      itemCount: dataManager.rentData.length,
                      itemBuilder: (context, index) {
                        final rentEntry = dataManager.rentData[index];
                        final rentDate = Utils.formatDate(rentEntry['date']);
                        final rentAmount = Utils.formatCurrency(dataManager.convert(rentEntry['rent']), dataManager.currencySymbol);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding pour chaque ligne
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rentDate,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                rentAmount,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
