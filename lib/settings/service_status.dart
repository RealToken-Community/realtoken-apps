import 'package:RealToken/generated/l10n.dart';
import 'package:RealToken/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ServiceStatusPage extends StatelessWidget {
  const ServiceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('realTokens');

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

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).serviceStatusPage),
      ),
      body: executionTimesMap.isNotEmpty
          ? ListView.builder(
              itemCount: executionTimesMap.length,
              itemBuilder: (context, index) {
                String key = executionTimesMap.keys.elementAt(index);
                String time = executionTimesMap[key]!;

                // Supprimer le préfixe "lastExecutionTime_"
                String displayKey = key.replaceFirst('lastExecutionTime_', '');

                return ListTile(
                  title: Text('Clé : $displayKey'),
                  subtitle: Text('${S.of(context).lastExecution} : ${Utils.formatReadableDateWithTime(time)}'),
                );
              },
            )
          : Center(child: Text('Aucune exécution trouvée.')),
    );
  }
}
