// Import pour Platform
import 'package:real_token/utils/parameters.dart';
import 'package:real_token/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:real_token/api/data_manager.dart';
import 'package:real_token/generated/l10n.dart'; // Import pour les traductions
import 'package:real_token/app_state.dart'; // Import AppState
import 'package:logger/logger.dart';

class PortfolioStats  extends StatefulWidget {
  const PortfolioStats ({super.key});

  @override
  _PortfolioStats createState() => _PortfolioStats();
}

class _PortfolioStats extends State<PortfolioStats > {
  static final logger = Logger();  // Initialiser une instance de logger

  late String _selectedPeriod;


  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        logger.i("Fetching rent data and property data...");
        Utils.loadData(context);
                dataManager.fetchPropertyData();

      } catch (e, stacktrace) {
        logger.i("Error during initState: $e");
        logger.i("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedPeriod = S.of(context).month; // Initialisation avec la traduction après que le contexte est disponible.
  }

  List<Map<String, dynamic>> _groupRentDataByPeriod(DataManager dataManager) {
    if (_selectedPeriod == S.of(context).week) {
      return _groupByWeek(dataManager.rentData);
    } else if (_selectedPeriod == S.of(context).month) {
      return _groupByMonth(dataManager.rentData);
    } else {
      return _groupByYear(dataManager.rentData);
    }
  }

  List<Map<String, dynamic>> _groupByWeek(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    
    for (var entry in data) {
      if (entry.containsKey('date') && entry.containsKey('rent')) {
        try {
          DateTime date = DateTime.parse(entry['date']);
          String weekKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}"; // Semaine formatée avec deux chiffres
          groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
        } catch (e) {
          // En cas d'erreur de parsing de date ou autre, vous pouvez ignorer cette entrée ou la traiter différemment
          logger.w("Erreur lors de la conversion de la date : ${entry['date']}");
        }
      }
    }
    
    // Conversion de groupedData en une liste de maps
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yyyy-MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByYear(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String yearKey = date.year.toString();
      groupedData[yearKey] = (groupedData[yearKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<FlSpot> _buildChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    for (var i = 0; i < data.length; i++) {
      double rentValue = data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), rentValue));
    }
    return spots;
  }

  List<String> _buildDateLabels(List<Map<String, dynamic>> data) {
    return data.map((entry) => entry['date'].toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    DataManager? dataManager;

    try {
      dataManager = Provider.of<DataManager>(context);
    } catch (e, stacktrace) {
      logger.i("Error accessing DataManager: $e");
      logger.i("Stacktrace: $stacktrace");
      return Center(child: Text("Error loading data"));
    }

    List<Map<String, dynamic>> groupedData = _groupRentDataByPeriod(dataManager);
return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  body: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 80.0), // Padding général
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildRentGraphCard(groupedData, dataManager),
          const SizedBox(height: 20),
          _buildWalletBalanceCard(dataManager),
          const SizedBox(height: 20),
          _buildTokenDistributionCard(dataManager),
          const SizedBox(height: 20),
          _buildTokenDistributionByCountryCard(dataManager),
          const SizedBox(height: 20),
          _buildTokenDistributionByRegionCard(dataManager),
          const SizedBox(height: 20),
          _buildTokenDistributionByCityCard(dataManager),
          // Ajouter un padding tout en bas
          const Padding(
            padding: EdgeInsets.only(bottom: 80.0), // Padding de 80 pixels en bas
          ),
        ],
      ),
    ),
  ),
);

  }

  bool _showCumulativeRent = false;

  Widget _buildRentGraphCard(List<Map<String, dynamic>> groupedData, DataManager dataManager) {
    const int maxPoints = 1000;
    final appState = Provider.of<AppState>(context);

    List<Map<String, dynamic>> limitedData = groupedData.length > maxPoints
        ? groupedData.sublist(0, maxPoints)
        : groupedData;

    List<Map<String, dynamic>> convertedData = limitedData.map((entry) {
      double convertedRent = dataManager.convert(entry['rent'] ?? 0.0);
      return {
        'date': entry['date'],
        'rent': convertedRent,
        'cumulativeRent': entry['cumulativeRent'] ?? 0.0,
      };
    }).toList();

    // Trier les données par date croissante
    convertedData.sort((a, b) => a['date'].compareTo(b['date']));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _showCumulativeRent
                        ? S.of(context).cumulativeRentGraph
                        : S.of(context).groupedRentGraph,
                    style: TextStyle(
                      fontSize: 20 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Transform.scale(
                    scale: 0.8, // Réduit la taille à 80% de la taille originale
                    child: Switch(
                      value: _showCumulativeRent,
                      onChanged: (value) {
                        setState(() {
                          _showCumulativeRent = value;
                        });
                      },
                      activeColor: Colors.blue, // Couleur d'accentuation en mode activé
                      inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                    ),
                  )
                ],
              ),
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          interval: _calculateLeftInterval(convertedData),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              Utils.formatCurrency(dataManager.convert(value), dataManager.currencySymbol),
                              style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                            );
                          },
                        ),
                      ),  
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateBottomInterval(convertedData),
                          getTitlesWidget: (value, meta) {
                            List<String> labels = _buildDateLabels(convertedData);
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  labels[value.toInt()],
                                  style: TextStyle(fontSize: 8 + appState.getTextSizeOffset()),
                                ),
                              );
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (convertedData.length - 1).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _showCumulativeRent
                            ? _buildCumulativeChartData(convertedData)
                            : _buildChartData(convertedData),
                        isCurved: false,
                        barWidth: 2,
                        color: _showCumulativeRent ? Colors.green : Colors.blue,
                        dotData: FlDotData(show: false), // Cache les points par défaut
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0.4),
                              (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final value = touchedSpot.y;
                            return LineTooltipItem(
                              '${Utils.formatCurrency(dataManager.convert(value),dataManager.currencySymbol)} ', // Formater avec 2 chiffres après la virgule
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    // Récupérer les données de l'historique des balances du wallet
    List<FlSpot> walletBalanceData = _buildWalletBalanceChartData(dataManager);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).walletBalanceHistory, // Ajouter une clé de traduction pour "Historique du Wallet"
                style: TextStyle(
                  fontSize: 20 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          interval: _calculateWalletBalanceLeftInterval(walletBalanceData),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              Utils.formatCurrency(value, dataManager.currencySymbol),
                              style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateBottomInterval(walletBalanceData.cast<Map<String, dynamic>>()),
                          getTitlesWidget: (value, meta) {
                            // Labels bas pour les dates du graphique des balances
                            List<String> labels = _buildDateLabelsForWallet(dataManager);
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  labels[value.toInt()],
                                  style: TextStyle(fontSize: 8 + appState.getTextSizeOffset()),
                                ),
                              );
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (walletBalanceData.length - 1).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: walletBalanceData,
                        isCurved: false,
                        barWidth: 2,
                        color: Colors.purple,
                        dotData: FlDotData(show: false), // Cache les points par défaut
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(0.4),
                              Colors.purple.withOpacity(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                                      lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final value = touchedSpot.y;
                            return LineTooltipItem(
                              '${Utils.formatCurrency(dataManager.convert(value),dataManager.currencySymbol)} ', // Formater avec 2 chiffres après la virgule
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildWalletBalanceChartData(DataManager dataManager) {
    List<FlSpot> spots = [];
    List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

    for (var i = 0; i < walletHistory.length; i++) {
      double balanceValue = walletHistory[i].balance;
      spots.add(FlSpot(i.toDouble(), balanceValue));
    }
    return spots;
  }

  List<String> _buildDateLabelsForWallet(DataManager dataManager) {
    return dataManager.walletBalanceHistory
        .map((record) => DateFormat('yyyy-MM-dd').format(record.timestamp))
        .toList();
  }

  double _calculateWalletBalanceLeftInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;

    double maxBalance = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Calculer l'intervalle et s'assurer qu'il est supérieur à 1
    double interval = maxBalance / 4;

    // Retourner au moins 1 pour éviter l'erreur d'intervalle 0
  return interval < 1 ? 1 : interval;
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des valeurs
  double _calculateLeftInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    double maxRent = data.map((d) => d['rent'] ?? 0).reduce((a, b) => a > b ? a : b);
    return maxRent / 2; // Diviser les titres en 5 intervalles
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des dates
  double _calculateBottomInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    
    double interval = (data.length / 6).roundToDouble(); // Calculer l'intervalle

    // S'assurer que l'intervalle est au moins 1
    return interval > 0 ? interval : 1;
  }

  Widget _buildTokenDistributionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).tokenDistribution,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartData(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLegend(dataManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByCountryCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).tokenDistributionByCountry,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByCountry(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLegendByCountry(dataManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByRegionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).tokenDistributionByRegion,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByRegion(dataManager, othersDetails),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                      final section = pieTouchResponse.touchedSection!.touchedSection;

                      if (event is FlTapUpEvent) {  // Gérer uniquement les événements de tap final
                        if (section!.title.contains(S.of(context).others)) {
                          _showOtherDetailsModal(dataManager, othersDetails, 'region'); // Passer les détails de "Autres"
                        }
                      }
                    }
                  },
                ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLegendByRegion(dataManager, othersDetails),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByCityCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).tokenDistributionByCity,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByCity(dataManager, othersDetails),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                        final section = pieTouchResponse.touchedSection!.touchedSection;

                        if (event is FlTapUpEvent) {  // Gérer uniquement les événements de tap final
                          if (section!.title.contains(S.of(context).others)) {
                            _showOtherDetailsModal(dataManager, othersDetails, 'city'); // Passer les détails de "Autres"
                          }
                        }
                      }
                    },
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLegendByCity(dataManager, othersDetails),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton(S.of(context).week, isFirst: true),
        _buildPeriodButton(S.of(context).month),
        _buildPeriodButton(S.of(context).year, isLast: true),
      ],
    );
  }

  Widget _buildPeriodButton(String period, {bool isFirst = false, bool isLast = false}) {
    bool isSelected = _selectedPeriod == period;
    final appState = Provider.of<AppState>(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return dataManager.propertyData.map((data) {
      final double percentage = (data['count'] / dataManager.propertyData.fold(0.0, (double sum, item) => sum + item['count'])) * 100;

      // Obtenir la couleur de base et créer des nuances
      final Color baseColor = _getPropertyColor(data['propertyType']);
      final Color lighterColor = Utils.shadeColor(baseColor, 1); // plus clair
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7);  // plus foncé

      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        // Supposons que le champ 'gradient' soit pris en charge
        gradient: LinearGradient(
          colors: [lighterColor, darkerColor], // Appliquer le dégradé avec les deux nuances
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),
      );
    }).toList();
  }

  Widget _buildLegend(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: dataManager.propertyData.map((data) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: _getPropertyColor(data['propertyType']),
            ),
            const SizedBox(width: 4),
            Text(
              getPropertyTypeName(data['propertyType']),
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLegendByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = '';

      if (parts.length == 4) {
        country = parts[3].trim();
      } else {
        country = 'United States';
      }

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: countryCount.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.cyan[100 *
                      (countryCount.keys.toList().indexOf(entry.key) % 9)] ??
                  Colors.cyan,
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLegendByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String regionCode = parts.length >= 3
          ? parts[2].trim().substring(0, 2)
          : S.of(context).unknown;

      String regionName = Parameters.usStateAbbreviations[regionCode] ?? regionCode;

      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Trier les régions par nombre croissant de tokens
    var sortedEntries = regionCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Créer une map pour les couleurs, basée sur les mêmes couleurs que le donut
    Map<String, Color> regionColors = {};
    final List<Color> colorPalette = Colors.accents; // Choisir une palette de couleurs
    for (int i = 0; i < sortedEntries.length; i++) {
      regionColors[sortedEntries[i].key] = colorPalette[i % colorPalette.length];
    }

    List<Widget> legendItems = [];
    int othersValue = 0;

    // Parcourir les régions et regrouper celles avec < 2%
    for (var entry in sortedEntries) {
      final double percentage = (entry.value / regionCount.values.fold(0, (sum, value) => sum + value)) * 100;

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += entry.value;
        othersDetails.add({'region': entry.key, 'count': entry.value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter un élément de légende pour cette région
        legendItems.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: regionColors[entry.key], // Utiliser la couleur attribuée à cette région
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        ));
      }
    }

    // Ajouter une légende pour "Autres" si nécessaire
    if (othersValue > 0) {
      legendItems.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            '${S.of(context).others}: $othersValue',
            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
          ),
        ],
      ));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: legendItems,
    );
  }

  Widget _buildLegendByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';

      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par nombre croissant de tokens
    var sortedEntries = cityCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Créer une map pour les couleurs, basée sur les mêmes couleurs que le donut
    Map<String, Color> cityColors = {};
    final List<Color> colorPalette = Colors.primaries; // Choisir une palette de couleurs
    for (int i = 0; i < sortedEntries.length; i++) {
      cityColors[sortedEntries[i].key] = colorPalette[i % colorPalette.length];
    }

    List<Widget> legendItems = [];
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedEntries) {
      final double percentage = (entry.value / totalCount) * 100;

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += entry.value;
        othersDetails.add({'city': entry.key, 'count': entry.value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter un élément de légende pour cette ville
        legendItems.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: cityColors[entry.key], // Utiliser la couleur attribuée à cette ville
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        ));
      }
    }

    // Ajouter une légende pour "Autres" si nécessaire
    if (othersValue > 0) {
      legendItems.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            '${S.of(context).others}: $othersValue',
            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
          ),
        ],
      ));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: legendItems,
    );
  }

  List<FlSpot> _buildCumulativeChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    double cumulativeRent = 0.0;

    for (var i = 0; i < data.length; i++) {
      cumulativeRent += data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), cumulativeRent));
    }
    return spots;
  }

  List<PieChartSectionData> _buildDonutChartDataByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par pays
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = parts.length == 4 ? parts[3].trim() : 'United States';

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Trier les pays par nombre croissant de tokens
    var sortedEntries = countryCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Créer les sections du graphique à secteurs avec des gradients
    return sortedEntries.map((entry) {
      final double percentage = (entry.value /
              sortedEntries.fold(0, (sum, value) => sum + value.value)) *
          100;

      // Obtenir un index unique pour chaque pays
      final int index = sortedEntries.indexOf(entry);
      final Color baseColor = Colors.cyan[100 * (index % 9)] ?? Colors.cyan;

      // Créer des nuances pour le gradient
      final Color lighterColor = Utils.shadeColor(baseColor, 1); // Nuance plus claire
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7);  // Nuance plus foncée

      return PieChartSectionData(
        value: entry.value.toDouble(),
        // Conditionner l'affichage du texte selon le pourcentage
        title: percentage < 1 ? '' : '${percentage.toStringAsFixed(1)}%',
        // Appliquer un gradient en fonction de la couleur de base
        gradient: LinearGradient(
          colors: [lighterColor, darkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildDonutChartDataByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String region = '';

      if (parts.length >= 3 &&
          RegExp(r'^[A-Z]{2}\s\d{5}$').hasMatch(parts[2].trim())) {
        region = parts[2].trim().substring(0, 2);
      } else if (parts.length >= 3) {
        region = parts[2].trim();
      }

      if (Parameters.usStateAbbreviations.containsKey(region)) {
        region = Parameters.usStateAbbreviations[region]!;
      }

      regionCount[region] = (regionCount[region] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

    // Trier les régions par nombre croissant de tokens
    var sortedEntries = regionCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Créer une map pour les couleurs
    Map<String, Color> regionColors = {};
    final List<Color> colorPalette = Colors.accents; // Choisir une palette de couleurs
    for (int i = 0; i < sortedEntries.length; i++) {
      regionColors[sortedEntries[i].key] = colorPalette[i % colorPalette.length];
    }

    // Initialiser les sections pour les régions et une section pour "Autres"
    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les régions et regrouper celles avec < 2%
    for (var entry in sortedEntries) {
      final double percentage = (entry.value / totalCount) * 100;

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += entry.value;
        othersDetails.add({'region': entry.key, 'count': entry.value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter une section pour cette région
        sections.add(PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: regionColors[entry.key], // Utiliser la couleur attribuée à cette région
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 10 + appState.getTextSizeOffset(),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    // Ajouter la section "Autres" si nécessaire
    if (othersValue > 0) {
      final double othersPercentage = (othersValue / totalCount) * 100;
      sections.add(PieChartSectionData(
        value: othersValue.toDouble(),
        title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';

      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par nombre croissant de tokens
    var sortedEntries = cityCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Créer une map pour les couleurs
    Map<String, Color> cityColors = {};
    final List<Color> colorPalette = Colors.primaries; // Choisir une palette de couleurs
    for (int i = 0; i < sortedEntries.length; i++) {
      cityColors[sortedEntries[i].key] = colorPalette[i % colorPalette.length];
    }

    // Initialiser les sections pour les villes et une section pour "Autres"
    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedEntries) {
      final double percentage = (entry.value / totalCount) * 100;

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += entry.value;
        othersDetails.add({'city': entry.key, 'count': entry.value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter une section pour cette ville
        sections.add(PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: cityColors[entry.key], // Utiliser la couleur attribuée à cette ville
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 10 + appState.getTextSizeOffset(),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    // Ajouter la section "Autres" si nécessaire
    if (othersValue > 0) {
      final double othersPercentage = (othersValue / totalCount) * 100;
      sections.add(PieChartSectionData(
        value: othersValue.toDouble(),
        title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  void _showOtherDetailsModal(DataManager dataManager, List<Map<String, dynamic>> othersDetails, String key) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 500,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                S.of(context).othersTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildOtherDetailsDonutData(othersDetails, key),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Ajout de la légende en dessous du donut
              _buildLegendForModal(othersDetails, key),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildOtherDetailsDonutData(List<Map<String, dynamic>> othersDetails, String key) {
    final List<Color> sectionColors = Colors.primaries; // Utilisez une palette de couleurs

    // Utiliser un Set pour éviter les doublons
    final Set<String> uniqueEntries = {};
    
    return othersDetails.asMap().entries.map((entry) {
      final int index = entry.key;
      final String entryName = entry.value[key] ?? 'Unknown';

      // Ajouter uniquement les entrées uniques
      if (uniqueEntries.add(entryName)) {
        final double percentage = (entry.value['count'] / othersDetails.fold<double>(0.0, (sum, e) => sum + e['count'])) * 100;

        return PieChartSectionData(
          value: entry.value['count'].toDouble(),
          title: '${percentage.toStringAsFixed(1)}%', // Afficher uniquement le pourcentage
          color: sectionColors[index % sectionColors.length], // Couleurs uniques pour chaque section
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return null;  // Ignorer les doublons
      }
    }).where((section) => section != null).toList().cast<PieChartSectionData>();
  }

  Widget _buildLegendForModal(List<Map<String, dynamic>> othersDetails, String key) {
    final List<Color> sectionColors = Colors.primaries; // Utiliser une palette de couleurs
    final Set<String> uniqueEntries = {}; // Utiliser un Set pour éviter les doublons

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: othersDetails.asMap().entries.map((entry) {
        final int index = entry.key;
        final String name = entry.value[key] ?? 'Unknown';

        // Ajouter uniquement les entrées uniques
        if (uniqueEntries.add(name)) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                color: sectionColors[index % sectionColors.length], // Couleur identique au donut
              ),
              const SizedBox(width: 4),
              Text(
                name,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        } else {
          return Container(); // Ignorer les doublons
        }
      }).toList(),
    );
  }

  Color _getPropertyColor(int propertyType) {
  switch (propertyType) {
    case 1:
      return Colors.blue;
    case 2:
      return Colors.green;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.red;
    case 5:
      return Colors.purple;
    case 6:
      return Colors.yellow;
    case 7:
      return Colors.teal;
    case 8:
      return Colors.brown;
    case 9:
      return Colors.pink;
    case 10:
      return Colors.cyan;
    case 11:
      return Colors.lime;
    case 12:
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

  String getPropertyTypeName(int propertyType) {
    switch (propertyType) {
      case 1:
        return S.of(context).singleFamily;
      case 2:
        return S.of(context).multiFamily;
      case 3:
        return S.of(context).duplex;
      case 4:
        return S.of(context).condominium;
      case 6:
        return S.of(context).mixedUse;
      case 8:
        return S.of(context).multiFamily;
      case 9:
        return S.of(context).commercial;
      case 10:
        return S.of(context).sfrPortfolio;
      case 11:
        return S.of(context).mfrPortfolio;
      case 12:
        return S.of(context).resortBungalow;
      default:
        return S.of(context).unknown;
    }
  }
}
