import 'package:RealToken/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/data_manager.dart';
import 'package:intl/intl.dart';

class DashboardRentsDetailsPage extends StatelessWidget {
  const DashboardRentsDetailsPage({super.key});

  // Fonction utilitaire pour formater la date et le montant
  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  

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
                        final rentDate = _formatDate(rentEntry['date']);
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
