import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import de la bibliothèque intl

// Fonction de formatage des valeurs monétaires avec des espaces pour les milliers
String formatCurrency(double value) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR',  // Utilisez 'fr_FR' pour les espaces entre milliers
    symbol: '\$',     // Symbole de la devise
    decimalDigits: 2, // Nombre de chiffres après la virgule
  );
  return formatter.format(value);
}

class PortfolioDisplay2 extends StatelessWidget {
  final List<Map<String, dynamic>> portfolio;

  const PortfolioDisplay2({super.key, required this.portfolio});

  // Méthode pour afficher les détails dans le BottomModalSheet
  void _showTokenDetails(BuildContext context, Map<String, dynamic> token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: token['imageLink'] ?? '',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Mise en vente', token['initialLaunchDate'] ?? 'Non spécifié'),
                _buildDetailRow('Valeur de l\'investissement', formatCurrency(token['totalInvestment'] ?? 0)),
                _buildDetailRow('Valeur du bien', formatCurrency(token['underlyingAssetPrice'] ?? 0)),
                _buildDetailRow('Réserve de maintenance', formatCurrency(token['initialMaintenanceReserve'] ?? 0)),
                _buildDetailRow('Type de location', token['rentalType'] ?? 'Non spécifié'),
                _buildDetailRow('Premier loyer', token['rentStartDate'] ?? 'Non spécifié'),
                _buildDetailRow('Logements loués', '${token['rentedUnits'] ?? 'Non spécifié'} / ${token['totalUnits'] ?? 'Non spécifié'}'),
                _buildDetailRow('Loyer brut mensuel', formatCurrency(token['grossRentMonth'] ?? 0)),
                _buildDetailRow('Loyer net mensuel', formatCurrency(token['netRentMonth'] ?? 0)),
                _buildDetailRow('Rendement annuel', '${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'Non spécifié'}%'),
                _buildDetailRow('Année de construction', token['constructionYear']?.toString() ?? 'Non spécifié'),
                _buildDetailRow('Nombre d\'étages', token['propertyStories']?.toString() ?? 'Non spécifié'),
                _buildDetailRow('Nombre de logements', token['totalUnits']?.toString() ?? 'Non spécifié'),
                _buildDetailRow('Taille du terrain', '${token['lotSize']?.toStringAsFixed(2) ?? 'Non spécifié'} sqft'),
                _buildDetailRow('Taille intérieure', '${token['squareFeet']?.toStringAsFixed(2) ?? 'Non spécifié'} sqft'),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer le popup
                  },
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthode pour construire les lignes de détails
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: portfolio.length,
      itemBuilder: (context, index) {
        final token = portfolio[index];
        final isWallet = token['source'] == 'Wallet'; // Vérification de la source

        return GestureDetector(
          onTap: () => _showTokenDetails(context, token), // Ouvrir le modal au clic
          child: Card(
            margin: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: token['imageLink'] ?? '',
                      width: 150,
                      height: 150,
                      fit: BoxFit.fitHeight,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(), // Placeholder pendant le chargement
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error), // En cas d'erreur
                    ), // Image à gauche
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  token['shortName'] ?? 'Nom indisponible',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                // Pastille pour source avec texte Wallet ou RMM
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: isWallet
                                        ? Colors.green
                                        : Colors.blue, // Couleur selon la source
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    isWallet ? 'Wallet' : 'RMM', // Texte de la pastille
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            // Affichage de Amount et Total Tokens
                            Text(
                              'Amount: ${token['amount']} / ${token['totalTokens']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            // Affichage de l'APY arrondi à 2 chiffres après la virgule
                            // Valeur totale
                            Text(
                              'Total Value: ${formatCurrency(token['totalValue'])}',
                            ),
                            Text(
                              'APY: ${token['annualPercentageYield']?.toStringAsFixed(2)}%',
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Revenue:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            // Tableau des revenus (Jour / Mois / Année)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Day'),
                                      Text(
                                          formatCurrency(token['dailyIncome'] ?? 0)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Month'),
                                      Text(
                                          formatCurrency(token['monthlyIncome'] ?? 0)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Year'),
                                      Text(
                                          formatCurrency(token['yearlyIncome'] ?? 0)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
