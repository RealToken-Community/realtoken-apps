import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/data_manager.dart';

class RmmStats extends StatefulWidget {
  const RmmStats({super.key});

  @override
  _RmmStatsState createState() => _RmmStatsState();
}

class _RmmStatsState extends State<RmmStats> {
  String selectedPeriod = 'hour'; // Par défaut, afficher par heure

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Récupérer les valeurs APY depuis le dataManager
    final usdcDepositApy = dataManager.usdcDepositApy;
    final usdcBorrowApy = dataManager.usdcBorrowApy;
    final xdaiDepositApy = dataManager.xdaiDepositApy;
    final xdaiBorrowApy = dataManager.xdaiBorrowApy;
    final apyAverage = dataManager.apyAverage; // APY moyen global

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding général
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              
              // Carte pour les APY
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Explication APY Moyen'), // Titre du popup
                            content: const Text(
                              'L’APY moyen est calculé en moyenne sur les variations de balance entre plusieurs paires de données. '
                              'Les valeurs avec des variations anormales (dépôts ou retraits) sont écartées.',
                            ), // Texte explicatif
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Fermer le popup
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          'APY Moyen Global: ${apyAverage.toStringAsFixed(2)}%', // Affichage de l'APY moyen
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5), // Un petit espace entre le texte et l'icône
                        const Icon(
                          Icons.info_outline, // Icône à afficher
                          size: 20, // Taille de l'icône
                          color: Colors.blue, // Couleur de l'icône
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
                      Table(
                        border: TableBorder.all(), // Ajoute des bordures pour chaque cellule (facultatif)
                        columnWidths: const {
                          0: FlexColumnWidth(1), // Colonne pour les titres (Deposit/Borrow)
                          1: FlexColumnWidth(1), // Colonne pour les valeurs USDC
                          2: FlexColumnWidth(1), // Colonne pour les valeurs xDAI
                        },
                        children: [
                          // Ligne d'en-tête
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(''), // Cellule vide pour l'en-tête des lignes
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('USDC', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('xDAI', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          // Ligne Deposit
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${usdcDepositApy.toStringAsFixed(2)}%'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${xdaiDepositApy.toStringAsFixed(2)}%'),
                              ),
                            ],
                          ),
                          // Ligne Borrow
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Borrow', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${usdcBorrowApy.toStringAsFixed(2)}%'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${xdaiBorrowApy.toStringAsFixed(2)}%'),
                              ),
                            ],
                          ),
                        ],
                      )

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Carte pour le graphique des dépôts
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposits (Dépôts)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: screenHeight * 0.3, // Limite le graphique à 30% de la taille de l'écran
                        child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                          future: _fetchAndAggregateBalanceHistories(dataManager),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Erreur: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Pas de données disponibles.');
                            } else {
                              final allHistories = snapshot.data!;
                              return LineChart(_buildDepositChart(allHistories));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Carte pour le graphique des emprunts
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrows (Emprunts)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: screenHeight * 0.3, // Limite le graphique à 30% de la taille de l'écran
                        child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                          future: _fetchAndAggregateBalanceHistories(dataManager),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Erreur: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Pas de données disponibles.');
                            } else {
                              final allHistories = snapshot.data!;
                              return LineChart(_buildBorrowChart(allHistories));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

// Fonction pour créer le graphique des dépôts (Deposits)
LineChartData _buildDepositChart(Map<String, List<BalanceRecord>> allHistories) {
  final maxY = _getMaxY(allHistories, ['usdcDeposit', 'xdaiDeposit']);
  final maxX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a > b ? a : b);
  final minX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a < b ? a : b);

  // Intervalle dynamique pour l'axe X, avec une valeur par défaut si l'intervalle est trop petit
  final intervalX = (maxX - minX) > 0 ? (maxX - minX) / 6 : 86400000.0; // 1 jour en millisecondes

  return LineChartData(
    gridData: FlGridData(show: true, drawVerticalLine: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: intervalX, // Utiliser l'intervalle dynamique pour l'axe X
          getTitlesWidget: (value, meta) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return Text('${date.month}/${date.day}');
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: maxY > 0 ? maxY / 5 : 1, // Rétablir l'intervalle correct pour l'axe Y (vertical)
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return Text(value.toStringAsFixed(2));
          },
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    ),
    borderData: FlBorderData(show: true),
    minX: minX,
    maxX: maxX,
    minY: 0, // Laisser un peu d'espace en bas
    maxY: maxY, // Ajouter une marge en haut
    lineBarsData: [
      _buildLineBarData(allHistories['usdcDeposit']!, Colors.blue, "USDC Deposit"),
      _buildLineBarData(allHistories['xdaiDeposit']!, Colors.green, "xDai Deposit"),
    ],
  );
}

// Fonction pour créer le graphique des emprunts (Borrows)
LineChartData _buildBorrowChart(Map<String, List<BalanceRecord>> allHistories) {
  final maxY = _getMaxY(allHistories, ['usdcBorrow', 'xdaiBorrow']);
  final maxX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a > b ? a : b);
  final minX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a < b ? a : b);

  // Intervalle dynamique pour l'axe X, avec une valeur par défaut si l'intervalle est trop petit
  final intervalX = (maxX - minX) > 0 ? (maxX - minX) / 6 : 86400000.0; // 1 jour en millisecondes

  return LineChartData(
    gridData: FlGridData(show: true, drawVerticalLine: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: intervalX, // Utiliser l'intervalle dynamique pour l'axe X
          getTitlesWidget: (value, meta) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return Text('${date.month}/${date.day}');
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: maxY > 0 ? maxY / 5 : 1, // Rétablir l'intervalle correct pour l'axe Y (vertical)
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return Text(value.toStringAsFixed(2));
          },
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    ),
    borderData: FlBorderData(show: true),
    minX: minX,
    maxX: maxX,
    minY: 0, // Laisser un peu d'espace en bas
    maxY: maxY, // Ajouter une marge en haut
    lineBarsData: [
      _buildLineBarData(allHistories['usdcBorrow']!, Colors.orange, "USDC Borrow"),
      _buildLineBarData(allHistories['xdaiBorrow']!, Colors.red, "xDai Borrow"),
    ],
  );
}

  // Fonction pour calculer un intervalle adapté à l'axe vertical gauche
  double _getMaxY(Map<String, List<BalanceRecord>> allHistories, List<String> types) {
    double maxY = types
        .expand((type) => allHistories[type] ?? [])
        .map((record) => record.balance)
        .reduce((a, b) => a > b ? a : b);
    return maxY > 0 ? maxY * 1.2 : 10; // Ajouter 20% de marge ou fixer une valeur par défaut si tout est à 0
  }

  // Fonction pour créer une ligne pour un type de token spécifique
  LineChartBarData _buildLineBarData(List<BalanceRecord> history, Color color, String label) {
    return LineChartBarData(
      spots: history
          .map((record) => FlSpot(
                record.timestamp.millisecondsSinceEpoch.toDouble(),
                double.parse(record.balance.toStringAsFixed(2)), // Limiter à 2 décimales
              ))
          .toList(),
      isCurved: true,
      dotData: FlDotData(show: false), // Afficher les points sur chaque valeur
      belowBarData: BarAreaData(show: false),
      barWidth: 2,
      isStrokeCapRound: true,
      color: color,
    );
  }

  // Fonction pour récupérer et agréger les historiques des balances pour tous les types de tokens
  Future<Map<String, List<BalanceRecord>>> _fetchAndAggregateBalanceHistories(DataManager dataManager) async {
    Map<String, List<BalanceRecord>> allHistories = {};

    allHistories['usdcDeposit'] = await dataManager.getBalanceHistory('usdcDeposit');
    allHistories['usdcBorrow'] = await dataManager.getBalanceHistory('usdcBorrow');
    allHistories['xdaiDeposit'] = await dataManager.getBalanceHistory('xdaiDeposit');
    allHistories['xdaiBorrow'] = await dataManager.getBalanceHistory('xdaiBorrow');

    for (String tokenType in allHistories.keys) {
      allHistories[tokenType] = await _aggregateByPeriod(allHistories[tokenType]!, selectedPeriod);
    }

    return allHistories;
  }

  // Fonction pour regrouper les données par période (minute, heure, jour) et calculer la moyenne
  Future<List<BalanceRecord>> _aggregateByPeriod(List<BalanceRecord> records, String period) async {
    Map<DateTime, List<double>> groupedByPeriod = {};

    for (var record in records) {
      DateTime truncatedToPeriod;

      switch (period) {
        case 'minute':
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
            record.timestamp.hour,
            record.timestamp.minute,
          );
          break;
        case 'hour':
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
            record.timestamp.hour,
          );
          break;
        case 'day':
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          break;
        default:
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
            record.timestamp.hour,
          );
      }

      if (!groupedByPeriod.containsKey(truncatedToPeriod)) {
        groupedByPeriod[truncatedToPeriod] = [];
      }
      groupedByPeriod[truncatedToPeriod]!.add(record.balance);
    }

    List<BalanceRecord> averagedRecords = [];
    groupedByPeriod.forEach((timestamp, balances) {
      double averageBalance = balances.reduce((a, b) => a + b) / balances.length;
      averagedRecords.add(BalanceRecord(
        tokenType: records.first.tokenType,
        balance: averageBalance,
        timestamp: timestamp,
      ));
    });

    return averagedRecords;
  }
}
