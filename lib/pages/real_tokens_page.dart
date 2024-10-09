import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importer provider
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../api/data_manager.dart';
import 'token_bottom_sheet.dart'; // Import du modal bottom sheet

String formatCurrency(double value) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '\$',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

class RealTokensPage extends StatefulWidget {
  const RealTokensPage({super.key});

  @override
  _RealTokensPageState createState() => _RealTokensPageState();
}

class _RealTokensPageState extends State<RealTokensPage> {
  @override
  void initState() {
    super.initState();
    // Appel à la méthode pour récupérer tous les tokens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RealTokens'),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.allTokens.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 20),
            itemCount: dataManager.allTokens.length,
            itemBuilder: (context, index) {
              final token = dataManager.allTokens[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => showTokenDetails(context,
                          token), // Appel à la méthode pour afficher les détails
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: token['imageLink'][0] ?? '',
                                width: 150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            token['shortName'] ??
                                                'Nom indisponible',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Asset price: ${formatCurrency(token['totalInvestment'] ?? 0)}',
                                      ),
                                      Text(
                                        'Token price: ${token['tokenPrice']}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Expected Yield: ${token['annualPercentageYield']}',
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
          );
        },
      ),
    );
  }
}
