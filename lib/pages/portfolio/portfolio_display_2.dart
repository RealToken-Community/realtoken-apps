import 'dart:io'; // Import pour Platform
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import de la bibliothèque intl
import '../token_bottom_sheet.dart'; // Import de la bibliothèque url_launcher
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import '../../api/data_manager.dart'; // Import de DataManager
import '../../generated/l10n.dart'; // Import des traductions
import '../../settings/manage_evm_addresses_page.dart'; // Import de la page de gestion des adresses EVM

// Fonction pour extraire le nom de la ville à partir du fullName
String extractCity(String fullName) {
  List<String> parts = fullName.split(',');
  return parts.length >= 2
      ? parts[1].trim()
      : S.current.unknownCity; // Traduction pour "Ville inconnue"
}

// Fonction pour déterminer la couleur de la pastille en fonction du taux de location
Color getRentalStatusColor(int rentedUnits, int totalUnits) {
  if (rentedUnits == 0) {
    return Colors.red; // Aucun logement loué
  } else if (rentedUnits == totalUnits) {
    return Colors.green; // Tous les logements sont loués
  } else {
    return Colors.orange; // Partiellement loué
  }
}

// Fonction modifiée pour formater la monnaie avec le taux de conversion et le symbole
String formatCurrency(BuildContext context, double value) {
  final dataManager =
      Provider.of<DataManager>(context, listen: false); // Récupérer DataManager
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR', // Vous pouvez adapter la locale selon vos besoins
    symbol: dataManager.currencySymbol, // Utilise le symbole de la devise
    decimalDigits: 2,
  );
  return formatter.format(
      dataManager.convert(value)); // Conversion selon la devise sélectionnée
}

class PortfolioDisplay2 extends StatelessWidget {
  final List<Map<String, dynamic>> portfolio;

  const PortfolioDisplay2({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: portfolio.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S
                          .of(context)
                          .noDataAvailable, // Traduction pour "Aucune donnée disponible"
                      style: TextStyle(
                        fontSize: Platform.isAndroid ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ManageEvmAddressesPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue, // Texte blanc
                      ),
                      child: Text(
                        S
                            .of(context)
                            .manageAddresses, // Traduction pour "Gérer les adresses"
                        style: TextStyle(
                          fontSize: Platform.isAndroid ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 20),
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final token = portfolio[index];
                final isWallet = token['source'] == 'Wallet';
                final isRMM = token['source'] == 'RMM';
                final city = extractCity(token['fullName'] ?? '');

                final rentedUnits = token['rentedUnits'] ?? 0;
                final totalUnits = token['totalUnits'] ?? 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: GestureDetector(
                    onTap: () => showTokenDetails(context, token),
                    child: Card(
                      color: Theme.of(context)
                          .cardColor, // Ajout de cette ligne pour appliquer la couleur du thème
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image prenant toute la largeur
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: token['imageLink'][0] ?? '',
                              fit: BoxFit.cover,
                              height: 200,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre avec pastille "Wallet" ou "RMM"
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        token['shortName'] ??
                                            S.of(context).nameUnavailable,
                                        style: TextStyle(
                                          fontSize:
                                              Platform.isAndroid ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isWallet || isRMM)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isWallet
                                              ? Colors.grey
                                              : isRMM
                                                  ? const Color.fromARGB(
                                                      255, 165, 100, 21)
                                                  : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isWallet ? 'Wallet' : 'RMM',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: Platform.isAndroid ? 14 : 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${S.of(context).totalValue}: ${formatCurrency(context, token['totalValue'])}',
                                  style: TextStyle(
                                      fontSize: Platform.isAndroid ? 14 : 15),
                                ),
                                Text(
                                  '${S.of(context).amount}: ${token['amount']} / ${token['totalTokens']}',
                                  style: TextStyle(
                                      fontSize: Platform.isAndroid ? 14 : 15),
                                ),
                                Text(
                                  '${S.of(context).apy}: ${token['annualPercentageYield']?.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      fontSize: Platform.isAndroid ? 14 : 15),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${S.of(context).revenue}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Platform.isAndroid ? 14 : 16,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(S.of(context).day,
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                          Text(
                                              formatCurrency(context,
                                                  token['dailyIncome'] ?? 0),
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(S.of(context).week,
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                          Text(
                                              formatCurrency(context,
                                                  token['dailyIncome'] * 7 ?? 0),
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(S.of(context).month,
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                          Text(
                                              formatCurrency(context,
                                                  token['monthlyIncome'] ?? 0),
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(S.of(context).year,
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                          Text(
                                              formatCurrency(context,
                                                  token['yearlyIncome'] ?? 0),
                                              style: TextStyle(
                                                  fontSize: Platform.isAndroid
                                                      ? 12
                                                      : 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
