import 'package:RealToken/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/data_manager.dart'; // Assurez-vous d'importer votre DataManager
import '../../generated/l10n.dart'; // Import pour les traductions

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  _UpdatesPageState createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool showUserTokensOnly = false; // Ajout du booléen pour le switch

  @override
  void initState() {
    super.initState();

    // Déclencher la récupération des données après le rendu initial de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context); // Ajouter cette ligne pour récupérer appState

    if (dataManager.recentUpdates.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).recentUpdatesTitle), // Utilisation des traductions
        ),
        body: Center(
          child: Text(S.of(context).noRecentUpdates), // Utilisation des traductions
        ),
      );
    }

    // Filtrer les mises à jour en fonction du switch
    List recentUpdatesToShow = showUserTokensOnly
        ? dataManager.recentUpdates.where((update) {
            // Garder uniquement les tokens de l'utilisateur
            return dataManager.portfolio.any((token) => token['shortName'] == update['shortName']);
          }).toList()
        : dataManager.recentUpdates;

    // Regrouper les mises à jour par date puis par token
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedUpdates = {};
    for (var update in recentUpdatesToShow) {
      final String dateKey = DateTime.parse(update['timsync'])
          .toLocal()
          .toString()
          .split(' ')[0]; // Date sans l'heure
      final String tokenKey = update['shortName'] ?? S.of(context).unknownTokenName;

      // Si la date n'existe pas, on la crée
      if (!groupedUpdates.containsKey(dateKey)) {
        groupedUpdates[dateKey] = {};
      }

      // Si le token n'existe pas pour cette date, on le crée
      if (!groupedUpdates[dateKey]!.containsKey(tokenKey)) {
        groupedUpdates[dateKey]![tokenKey] = [];
      }

      // Ajouter les updates pour ce token
      groupedUpdates[dateKey]![tokenKey]!.add(update);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).recentUpdatesTitle), // Utilisation des traductions
        actions: [
          Row(
            children: [
              Text(S.of(context).portfolio),
              Transform.scale(
                scale: 0.7, // Appliquer le scale
                child: Switch(
                  value: showUserTokensOnly,
                  onChanged: (value) {
                    setState(() {
                      showUserTokensOnly = value;
                    });
                  },
                  activeColor: Colors.blue, // Couleur du bouton actif
                  activeTrackColor: Colors.blue[200], // Couleur de la piste active
                ),
              ),
            ],
          ),
        ],

      ),
      body: ListView.builder(
        itemCount: groupedUpdates.keys.length,
        itemBuilder: (context, dateIndex) {
          final String dateKey = groupedUpdates.keys.elementAt(dateIndex);
          final Map<String, List<Map<String, dynamic>>> updatesForDate = groupedUpdates[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  dateKey, // Afficher la date en gras
                  style: TextStyle(
                      fontSize: 18 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
                ),
              ),
              // Afficher les tokens et leurs infos regroupées
              ...updatesForDate.entries.map((tokenEntry) {
                final String tokenName = tokenEntry.key;
                final List<Map<String, dynamic>> updatesForToken = tokenEntry.value;

                // Assumer que toutes les mises à jour pour un token partagent la même image
                final String imageUrl = updatesForToken.first['imageLink'] ?? S.of(context).noImageAvailable;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    width: double.infinity, // Faire en sorte que la carte prenne toute la largeur disponible
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, // Utiliser la couleur du thème
                      borderRadius: BorderRadius.circular(8), // Ajout de coins arrondis
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Afficher l'image du token si elle est disponible
                        if (imageUrl != S.of(context).noImageAvailable)
                          Image.network(
                            imageUrl,
                            height: 100,
                            width: double.infinity, // Prendre toute la largeur disponible
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 8),
                        // Afficher le nom du token
                        Text(
                          tokenName,
                          style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // Afficher les informations formatées pour ce token
                        ...updatesForToken.map((update) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(update['formattedKey']),
                                Text("${update['formattedOldValue']} -> ${update['formattedNewValue']}"),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
