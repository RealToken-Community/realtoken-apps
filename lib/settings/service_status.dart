import 'package:realtokens_apps/generated/l10n.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/app_state.dart'; // Import AppState

class ServiceStatusPage extends StatelessWidget {
  const ServiceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('realTokens');
    final appState = Provider.of<AppState>(context);

    // Récupérer toutes les clés qui commencent par "lastExecutionTime_"
    Map<String, String> executionTimesMap = {};
    for (var key in box.keys) {
      if (key.toString().startsWith('lastExecutionTime_')) {
        String? executionTime = box.get(key); // Récupérer la dernière exécution
        if (executionTime != null) {
          executionTimesMap[key.toString()] = executionTime;
        }
      }
    }

    // Variable pour suivre l'état des services
    bool allAreUpToDate = true; // Par défaut à true

    // Vérifier la condition allAreUpToDate avant d'afficher la liste
    executionTimesMap.forEach((key, time) {
      try {
        DateTime lastExecution = DateTime.parse(time);
        Duration difference = DateTime.now().difference(lastExecution);

        // Si un service n'est pas à jour (plus d'une heure), mettre allAreUpToDate à false
        if (difference.inHours >= 1) {
          allAreUpToDate = false;
        }
      } catch (e) {
        allAreUpToDate = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).serviceStatusPage),
      ),
      body: executionTimesMap.isNotEmpty
          ? Column(
              children: [
                // Afficher le texte en fonction de allAreUpToDate
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    allAreUpToDate
                        ? S.of(context).allWorkCorrectly
                        : S.of(context).somethingWrong,
                    style: TextStyle(
                      fontSize: 18 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: executionTimesMap.length,
                    itemBuilder: (context, index) {
                      String key = executionTimesMap.keys.elementAt(index);
                      String time = executionTimesMap[key]!;

                      // Supprimer le préfixe "lastExecutionTime_"
                      String displayKey = key.replaceFirst('lastExecutionTime_', '');

                      // Convertir `time` en DateTime pour calculer la différence
                      DateTime lastExecution;
                      try {
                        lastExecution = DateTime.parse(time);
                      } catch (e) {
                        // Si une erreur de format de date se produit, on peut afficher un message d'erreur ou ignorer cette entrée
                        return ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text(displayKey),
                          subtitle: Text('Erreur de format de date.'),
                        );
                      }

                      Duration difference = DateTime.now().difference(lastExecution);

                      // Vérifier si la différence est inférieure à 1 heure
                      bool isLessThanAnHour = difference.inHours < 1;

                      return ListTile(
                        leading: Icon(
                          isLessThanAnHour
                              ? Icons.check_circle // Icône check vert si < 1 heure
                              : Icons.cancel, // Icône croix rouge si > 1 heure
                          color: isLessThanAnHour ? Colors.green : Colors.red,
                          size: 24 + appState.getTextSizeOffset(), // Ajuste la taille de l'icône
                        ),
                        title: Text(
                          displayKey,
                          style: TextStyle(
                            fontSize: 18 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                            '${S.of(context).lastExecution} : ${Utils.formatReadableDateWithTime(time)}',
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(), // Ajuste cette taille selon tes besoins
                            ),
                          ),                      );
                    },
                  ),
                ),
              ],
            )
          : Center(child: Text('Aucune exécution trouvée.')),
    );
  }
}
