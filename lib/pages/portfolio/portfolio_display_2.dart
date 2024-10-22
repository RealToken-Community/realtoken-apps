import 'package:real_token/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_token/pages/token_bottom_sheet.dart'; // Import de la bibliothèque url_launcher
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import 'package:real_token/generated/l10n.dart'; // Import des traductions
import 'package:real_token/settings/manage_evm_addresses_page.dart'; // Import de la page de gestion des adresses EVM
import 'package:real_token/app_state.dart'; // Import de AppState

class PortfolioDisplay2 extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;

  const PortfolioDisplay2({super.key, required this.portfolio});

  @override
  PortfolioDisplay2State createState() => PortfolioDisplay2State();
}

class PortfolioDisplay2State extends State<PortfolioDisplay2> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à AppState
    final filteredPortfolio = widget.portfolio;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Affichage de la liste des tokens
          filteredPortfolio.isEmpty
              ? Expanded(
                  child: Center(
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
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    itemCount: filteredPortfolio.length,
                    itemBuilder: (context, index) {
                      final token = filteredPortfolio[index];
                      final isWallet = token['inWallet'] ?? false; // Modifier pour détecter si présent dans le wallet
                      final isRMM = token['inRMM'] ?? false; // Modifier pour détecter si présent dans le RMM
                      final city = Utils.extractCity(token['fullName'] ?? '');

                      // Vérifier si la date de 'rent_start' est dans le futur en utilisant le bon format
                      final rentStartDate = DateTime.tryParse(token['rentStartDate'] ?? '');
                      final bool isFutureRentStart = rentStartDate != null && rentStartDate.isAfter(DateTime.now());

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: GestureDetector(
                          onTap: () => showTokenDetails(context, token),
                          child: Card(
                            color: Theme.of(context).cardColor, // Appliquer la couleur du thème
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Empiler l'image et le texte en superposition
                                Stack(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 16 / 9, // Assurer que l'image prend toute la largeur de la carte
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: ColorFiltered(
                                          colorFilter: isFutureRentStart
                                              ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
                                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                          child: CachedNetworkImage(
                                            imageUrl: token['imageLink'][0] ?? '',
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Afficher un texte en superposition si 'rent_start' est dans le futur
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
                                                fontSize: 16 + appState.getTextSizeOffset(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Titre avec pastilles "Wallet" et "RMM" si disponibles
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              token['shortName'] ?? S.of(context).nameUnavailable,
                                              style: TextStyle(
                                                fontSize: 18 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (isWallet)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'Wallet',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              if (isWallet && isRMM) const SizedBox(width: 8), // Espacement entre les deux pastilles
                                              if (isRMM)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(255, 165, 100, 21),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'RMM',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 16 + appState.getTextSizeOffset(),
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${S.of(context).totalValue}: ${formatCurrency(context, token['totalValue'])}',
                                        style: TextStyle(
                                          fontSize: 15 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                      Text(
                                        '${S.of(context).amount}: ${token['amount'].toStringAsFixed(2)} / ${token['totalTokens']}',
                                        style: TextStyle(
                                          fontSize: 15 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                      Text(
                                        '${S.of(context).apy}: ${token['annualPercentageYield']?.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 15 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${S.of(context).revenue}:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Column(
                                              children: [
                                                Text(S.of(context).day,
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                                Text(formatCurrency(context, token['dailyIncome'] ?? 0),
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(S.of(context).week,
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                                Text(formatCurrency(context, token['dailyIncome'] * 7 ?? 0),
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(S.of(context).month,
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                                Text(formatCurrency(context, token['monthlyIncome'] ?? 0),
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(S.of(context).year,
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
                                                Text(formatCurrency(context, token['yearlyIncome'] ?? 0),
                                                    style: TextStyle(
                                                      fontSize: 13 + appState.getTextSizeOffset(),
                                                    )),
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
                ),
        ],
      ),
    );
  }
}
