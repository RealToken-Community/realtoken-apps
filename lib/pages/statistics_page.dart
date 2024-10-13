// Import pour Platform
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import '../api/data_manager.dart';
import '../generated/l10n.dart'; // Import pour les traductions
import '../app_state.dart'; // Import AppState
import 'package:logger/logger.dart';


String formatCurrency(double value, String symbol) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: symbol, // Utilisation du symbole sélectionné
    decimalDigits: 2,
  );
  return formatter.format(value);
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static final logger = Logger();  // Initialiser une instance de logger

  late String _selectedPeriod;

  // Carte des abréviations d'États des États-Unis à leurs noms complets
  final Map<String, String> _usStateAbbreviations = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming'
  };

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        logger.i("Fetching rent data and property data...");
        dataManager.fetchRentData();
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
    _selectedPeriod = S
        .of(context)
        .month; // Initialisation avec la traduction après que le contexte est disponible.
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
      DateTime date = DateTime.parse(entry['date']);
      String weekKey = "${date.year}-S ${_weekNumber(date)}";
      groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries
        .map((entry) => {'date': entry.key, 'rent': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yyyy-MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries
        .map((entry) => {'date': entry.key, 'rent': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _groupByYear(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String yearKey = date.year.toString();
      groupedData[yearKey] = (groupedData[yearKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries
        .map((entry) => {'date': entry.key, 'rent': entry.value})
        .toList();
  }

  int _weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber;
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

    List<Map<String, dynamic>> groupedData =
        _groupRentDataByPeriod(dataManager);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 40.0, bottom: 80.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildRentGraphCard(groupedData, dataManager),
              const SizedBox(height: 20),
              _buildTokenDistributionCard(dataManager),
              const SizedBox(height: 20),
              _buildTokenDistributionByCountryCard(dataManager),
              const SizedBox(height: 20),
              _buildTokenDistributionByRegionCard(dataManager),
              const SizedBox(height: 20),
              _buildTokenDistributionByCityCard(dataManager),
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
        'cumulativeRent': entry['cumulativeRent'] ?? 0.0, // Ajout des données cumulatives
      };
    }).toList();

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
                  Spacer(), // Ajoute de l'espace flexible
                  Switch(
                    value: _showCumulativeRent,
                    onChanged: (value) {
                      setState(() {
                        _showCumulativeRent = value;
                      });
                    },
                  ),
                ],
              ),
              _buildPeriodSelector(),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55, // Augmenter la taille réservée à l'échelle de gauche
                          interval: _calculateLeftInterval(convertedData),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatCurrency(value, dataManager.currencySymbol),
                              style: TextStyle( fontSize: 10 + appState.getTextSizeOffset()),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Désactiver l'échelle de droite
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateBottomInterval(convertedData),
                          getTitlesWidget: (value, meta) {
                            List<String> labels =
                                _buildDateLabels(convertedData);
                            if (value.toInt() >= 0 &&
                                value.toInt() < labels.length) {
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  labels[value.toInt()],
                                  style: TextStyle(
                                      fontSize: 8 + appState.getTextSizeOffset()),
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
                            ? _buildCumulativeChartData(
                                convertedData) // Ligne verte (cumulative)
                            : _buildChartData(
                                convertedData), // Ligne bleue (rent)
                        isCurved: true,
                        barWidth: 2,
                        color: _showCumulativeRent ? Colors.green : Colors.blue,
                        belowBarData: BarAreaData(
                          show: true,
                          color: (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des valeurs
  double _calculateLeftInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    double maxRent =
        data.map((d) => d['rent'] ?? 0).reduce((a, b) => a > b ? a : b);
    return maxRent / 2; // Diviser les titres en 5 intervalles
  }

  double _calculateRightInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    double maxCumulativeRent = data
        .map((d) => d['cumulativeRent'] ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Si maxCumulativeRent est zéro, on retourne un intervalle de 1 pour éviter l'erreur
    return (maxCumulativeRent > 0 ? maxCumulativeRent / 100 : 1000);
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des dates
  double _calculateBottomInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    return (data.length / 6).roundToDouble(); // Montrer 6 dates maximum
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
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartData(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByCountry(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLegendByCountry(dataManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByRegionCard(DataManager dataManager) {
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
                S.of(context).tokenDistributionByRegion,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByRegion(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLegendByRegion(dataManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByCityCard(DataManager dataManager) {
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
                S.of(context).tokenDistributionByCity,
                style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutChartDataByCity(dataManager),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLegendByCity(dataManager),
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
              left: isFirst ? const Radius.circular(20) : Radius.zero,
              right: isLast ? const Radius.circular(20) : Radius.zero,
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
      final double percentage = (data['count'] /
              dataManager.propertyData
                  .fold(0.0, (double sum, item) => sum + item['count'])) *
          100;
      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getPropertyColor(data['propertyType']),
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12 + appState.getTextSizeOffset(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
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

  Widget _buildLegendByRegion(DataManager dataManager) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String regionCode = parts.length >= 3
          ? parts[2].trim().substring(0, 2)
          : S.of(context).unknown;

      String regionName = _usStateAbbreviations[regionCode] ?? regionCode;

      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: regionCount.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.accents[
                  regionCount.keys.toList().indexOf(entry.key) %
                      Colors.accents.length],
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

  Widget _buildLegendByCity(DataManager dataManager) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';

      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: cityCount.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.primaries[
                  cityCount.keys.toList().indexOf(entry.key) %
                      Colors.primaries.length],
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

    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = parts.length == 4 ? parts[3].trim() : 'United States';

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    return countryCount.entries.map((entry) {
      final double percentage = (entry.value /
              countryCount.values.fold(0, (sum, value) => sum + value)) *
          100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: Colors.cyan[
                100 * (countryCount.keys.toList().indexOf(entry.key) % 9)] ??
            Colors.cyan,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12 + appState.getTextSizeOffset(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildDonutChartDataByRegion(DataManager dataManager) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

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

      if (_usStateAbbreviations.containsKey(region)) {
        region = _usStateAbbreviations[region]!;
      }

      regionCount[region] = (regionCount[region] ?? 0) + 1;
    }

    return regionCount.entries.map((entry) {
      final double percentage = (entry.value /
              regionCount.values.fold(0, (sum, value) => sum + value)) *
          100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: Colors.accents[regionCount.keys.toList().indexOf(entry.key) %
            Colors.accents.length],
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12 + appState.getTextSizeOffset(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';

      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    return cityCount.entries.map((entry) {
      final double percentage = (entry.value /
              cityCount.values.fold(0, (sum, value) => sum + value)) *
          100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: Colors.primaries[cityCount.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12 + appState.getTextSizeOffset(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
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
