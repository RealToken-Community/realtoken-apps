import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens_apps/pages/token_bottom_sheet.dart'; // Import de la bibliothèque url_launcher
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import 'package:realtokens_apps/generated/l10n.dart'; // Import des traductions
import 'package:realtokens_apps/settings/manage_evm_addresses_page.dart'; // Import de la page de gestion des adresses EVM
import 'package:realtokens_apps/app_state.dart'; // Import AppState

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
                          fontSize: 18 + appState.getTextSizeOffset(),
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
                            fontSize: 16 + appState.getTextSizeOffset(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 80),
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final token = portfolio[index];
                  final isWallet = token['inWallet'] ?? false; // Modifier pour détecter si présent dans le wallet
                  final isRMM = token['inRMM'] ?? false; // Modifier pour détecter si présent dans le RMM
                  final city = Utils.extractCity(token['fullName'] ?? '');

                  final rentedUnits = token['rentedUnits'] ?? 0;
                  final totalUnits = token['totalUnits'] ?? 1;

                  // Vérifier si la date de 'rent_start' est dans le futur
                  final rentStartDate = DateTime.parse(token['rentStartDate'] ?? DateTime.now().toString());
                  final bool isFutureRentStart = rentStartDate.isAfter(DateTime.now());

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
                                      ColorFiltered(
                                        colorFilter: isFutureRentStart
                                            ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
                                            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: SizedBox(
                                          width: 120,
                                          height: double.infinity,
                                          child: CachedNetworkImage(
                                            imageUrl: token['imageLink'][0] ?? '',
                                            httpHeaders: {'mode': 'no-cors'}, // Désactiver CORS
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      // Superposition du texte si 'rent_start' est dans le futur
                                      if (isFutureRentStart)
                                        Positioned.fill(
                                          child: Center(
                                            child: Container(
                                              color: Colors.black54,
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                S.of(context).rentStartFuture, // Texte indiquant que le loyer commence dans le futur
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12 + appState.getTextSizeOffset(),
                                                ),
                                              ),
                                            ),
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
                                                    color: Utils.getRentalStatusColor(
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
                                                    fontSize: 14 + appState.getTextSizeOffset(),
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
                                                    fontSize: 15 + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                    color:Theme.of(context).textTheme.bodyLarge?.color
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
                                                            fontSize: 10 + appState.getTextSizeOffset(),
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
                                                            fontSize: 10 + appState.getTextSizeOffset(),
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
                                            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                          ),
                                          Text(
                                            '${S.of(context).amount}: ${token['amount'].toStringAsFixed(2)} / ${token['totalTokens']}',
                                            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                          ),
                                          Text(
                                            '${S.of(context).apy}: ${token['annualPercentageYield']?.toStringAsFixed(2)}%',
                                            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${S.of(context).revenue}:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13 + appState.getTextSizeOffset(),
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
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['dailyIncome'] * 7 ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).month,
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['monthlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).year,
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['yearlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
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
              ),
              );
  }
}
