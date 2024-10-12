import 'dart:io'; // Import pour Platform
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import de la bibliothèque intl
import '../token_bottom_sheet.dart'; // Import de la bibliothèque url_launcher
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import '../../api/data_manager.dart'; // Import de DataManager
import '../../generated/l10n.dart'; // Import des traductions
import '../../settings/manage_evm_addresses_page.dart'; // Import de la page de gestion des adresses EVM
import '../../app_state.dart'; // Import AppState

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

class PortfolioDisplay1 extends StatelessWidget {
  final List<Map<String, dynamic>> portfolio;
  const PortfolioDisplay1({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à l'état global

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
                        S.of(context).noDataAvailable, // Traduction pour "Aucune donnée disponible"
                        style: TextStyle(
                          fontSize: (Platform.isAndroid ? 16 : 18) + appState.getTextSizeOffset(),
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
                              builder: (context) => const ManageEvmAddressesPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue, // Texte blanc
                        ),
                        child: Text(
                          S.of(context).manageAddresses, // Traduction pour "Gérer les adresses"
                          style: TextStyle(
                            fontSize: (Platform.isAndroid ? 14 : 16) + appState.getTextSizeOffset(),
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
                  final isWallet = token['inWallet'] ?? false; // Modifier pour détecter si présent dans le wallet
                  final isRMM = token['inRMM'] ?? false; // Modifier pour détecter si présent dans le RMM
                  final city = extractCity(token['fullName'] ?? '');

                  final rentedUnits = token['rentedUnits'] ?? 0;
                  final totalUnits = token['totalUnits'] ?? 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => showTokenDetails(context, token),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image avec la ville et le statut de location
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: double.infinity,
                                        child: CachedNetworkImage(
                                          imageUrl: token['imageLink'][0] ?? '',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          color: Colors.black54,
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: getRentalStatusColor(
                                                      rentedUnits,
                                                      totalUnits,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  city,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: (Platform.isAndroid ? 13 : 14) + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Card(
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    color: Theme.of(context).cardColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Tronquer le shortName si trop long
                                              Expanded(
                                                child: Text(
                                                  token['shortName'] ?? S.of(context).nameUnavailable,
                                                  style: TextStyle(
                                                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1, // Limite à une seule ligne
                                                  overflow: TextOverflow.ellipsis, // Tronque avec "..."
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Affichage des pastilles pour wallet et RMM
                                              if (isWallet || isRMM)
                                                Row(
                                                  children: [
                                                    if (isWallet)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey,
                                                          shape: BoxShape.rectangle,
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        child: Text(
                                                          S.of(context).wallet,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: (Platform.isAndroid ? 9 : 10) + appState.getTextSizeOffset(),
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 4),
                                                    if (isRMM)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                                        decoration: BoxDecoration(
                                                          color: const Color.fromARGB(255, 165, 100, 21),
                                                          shape: BoxShape.rectangle,
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        child: Text(
                                                          'RMM',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: (Platform.isAndroid ? 9 : 10) + appState.getTextSizeOffset(),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${S.of(context).totalValue}: ${formatCurrency(context, token['totalValue'])}',
                                            style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset()),
                                          ),
                                          Text(
                                            '${S.of(context).amount}: ${token['amount']} / ${token['totalTokens']}',
                                            style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset()),
                                          ),
                                          Text(
                                            '${S.of(context).apy}: ${token['annualPercentageYield']?.toStringAsFixed(2)}%',
                                            style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset()),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${S.of(context).revenue}:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset(),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Column(
                                                  children: [
                                                    Text(S.of(context).week,
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['dailyIncome'] * 7 ?? 0),
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).month,
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['monthlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).year,
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['yearlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: (Platform.isAndroid ? 12 : 13) + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ));
  }
}
