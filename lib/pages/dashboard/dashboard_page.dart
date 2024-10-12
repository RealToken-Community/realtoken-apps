import 'dart:io'; // Import nécessaire pour Platform
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import pour SharedPreferences
import '../../api/data_manager.dart';
import '../../generated/l10n.dart';
import '/settings/manage_evm_addresses_page.dart'; // Import de la page pour gérer les adresses EVM
import 'dashboard_details_page.dart';
import '../../app_state.dart'; // Import AppState


// Fonction de formatage des valeurs monétaires avec des espaces pour les milliers
String formatCurrency(double value, String symbol) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: symbol, // Utilisation du symbole sélectionné
    decimalDigits: 2,
  );
  return formatter.format(value);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showAmounts = true; // Variable pour contrôler la visibilité des montants
  bool isLoading = true; // Ajoutez cette variable pour suivre l'état de chargement

  @override
  void initState() {
    super.initState();
    _loadPrivacyMode(); // Charger l'état du mode confidentialité au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(); // Charger les données au démarrage
    });
  }

    Future<void> _loadData() async {
    setState(() {
      isLoading = true; // Afficher le chargement avant de commencer à charger les données
    });

    final dataManager = Provider.of<DataManager>(context, listen: false);
    await Future.delayed(const Duration(seconds: 1)); 

    await dataManager.fetchRmmBalances();
    await dataManager.fetchAndCalculateData(); // Charger les données du portefeuille
    await dataManager.fetchRentData(); // Charger les données de loyer
    await dataManager.fetchPropertyData(); // Charger les données de propriété

    setState(() {
      isLoading = false; // Masquer l'indicateur de chargement après avoir chargé les données
    });
  }

  Future<void> _refreshData() async {
    // Forcer la mise à jour des données en appelant les méthodes de récupération avec forceFetch = true
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData(forceFetch: true);
    await dataManager.fetchRentData(forceFetch: true);
    await dataManager.fetchPropertyData(forceFetch: true);
    await dataManager.fetchRmmBalances();
  }

  // Méthode pour basculer l'état de visibilité des montants
  void _toggleAmountsVisibility() async {
    setState(() {
      _showAmounts = !_showAmounts;
    });
    // Sauvegarder l'état du mode "confidentialité" dans SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAmounts', _showAmounts);
  }

  // Charger l'état du mode "confidentialité" depuis SharedPreferences
  Future<void> _loadPrivacyMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAmounts = prefs.getBool('showAmounts') ?? true; // Par défaut, les montants sont visibles
    });
  }

  // Méthode pour formater ou masquer les montants en série de ****
  String _getFormattedAmount(double value, String symbol) {
    if (_showAmounts) {
      return formatCurrency(
          value, symbol); // Affiche le montant formaté si visible
    } else {
      String formattedValue =
          formatCurrency(value, symbol); // Format le montant normalement
      return '*' *
          formattedValue
              .length; // Retourne une série d'astérisques de la même longueur
    }
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
    final rentData = dataManager.rentData;

    if (rentData.isEmpty) {
      return S.of(context).noRentReceived;
    }

    rentData.sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Convertir et formater avec le symbole de la devise sélectionnée
    return formatCurrency(
        dataManager.convert(lastRent), dataManager.currencySymbol);
  }

  // Groupement mensuel sur les 12 derniers mois glissants pour la carte Rendement
  List<double> _getLast12MonthsRent(DataManager dataManager) {
    final currentDate = DateTime.now();
    final rentData = dataManager.rentData;

    Map<String, double> monthlyRent = {};

    for (var rentEntry in rentData) {
      DateTime date = DateTime.parse(rentEntry['date']);
      if (date.isAfter(currentDate.subtract(const Duration(days: 365)))) {
        String monthKey = DateFormat('yyyy-MM').format(date);
        monthlyRent[monthKey] =
            (monthlyRent[monthKey] ?? 0) + rentEntry['rent'];
      }
    }

    // Assurer que nous avons les 12 derniers mois dans l'ordre
    List<String> sortedMonths = List.generate(12, (index) {
      DateTime date = DateTime(currentDate.year, currentDate.month - index, 1);
      return DateFormat('yyyy-MM').format(date);
    }).reversed.toList();

    return sortedMonths.map((month) => monthlyRent[month] ?? 0).toList();
  }

 double _getPortfolioBarGraphData(DataManager dataManager) {
  // Calcul du pourcentage de rentabilité (ROI)
  return (dataManager.getTotalRentReceived() / dataManager.totalValue * 100); // ROI en %
}


// Méthode pour créer un graphique en barres en tant que jauge
Widget _buildVerticalGauge(double value, BuildContext context) {
  // Utiliser une valeur par défaut si 'value' est NaN ou négatif
  double displayValue = value.isNaN || value < 0 ? 0 : value;

  return Padding(
    padding: const EdgeInsets.only(right: 12.0), // Ajustez ici le décalage à gauche
    child: Column(
      mainAxisSize: MainAxisSize.min, // Ajuster la taille de la colonne au contenu
      children: [
        Text(
          "ROI", // Titre de la jauge
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8), // Espacement entre le titre et la jauge
        SizedBox(
          height: 100, // Hauteur totale de la jauge
          width: 40,   // Largeur de la jauge
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: 100, // Échelle sur 100%
              barTouchData: BarTouchData(enabled: false), // Désactiver les interactions
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 25 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10), // Définir la taille du texte
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: displayValue, // Utiliser la valeur corrigée
                      width: 20,  // Largeur de la barre
                      color: Colors.blue, // Couleur de la barre
                      borderRadius: BorderRadius.circular(5),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100, // Fond de la jauge
                        color: Colors.grey.shade400,
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(0, displayValue, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8), // Espacement entre le titre et la jauge
        Text(
          "${displayValue.toStringAsFixed(1)}%", // Valeur de la barre affichée en dessous
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blue, // Même couleur que la barre
          ),
        ),
      ],
    ),
  );
}

  // Méthode pour créer un mini graphique pour la carte Rendement
  Widget _buildMiniGraphForRendement(List<double> data, BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 60,
        width: 120,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: data.length.toDouble() - 1,
            minY: data.reduce((a, b) => a < b ? a : b),
            maxY: data.reduce((a, b) => a > b ? a : b),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length,
                    (index) => FlSpot(index.toDouble(), data[index])),
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 2,
                    color: Colors.blue,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construction des cartes du Dashboard
 Widget _buildCard(
  String title,
  IconData icon,
  Widget firstChild,
  List<Widget> otherChildren,
  DataManager dataManager,
  BuildContext context, {
  bool hasGraph = false,
  Widget? rightWidget, // Ajout du widget pour le graphique
}) {
  final appState = Provider.of<AppState>(context);
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24 + appState.getTextSizeOffset(),
                  color: title == S.of(context).rents
                      ? Colors.green
                      : title == S.of(context).tokens
                          ? Colors.orange
                          : title == S.of(context).properties
                              ? Colors.blue
                              : title == S.of(context).portfolio
                                  ? Colors.black
                                  : Colors.blue,
                                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   if (title == S.of(context).rents)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const DashboardRentsDetailsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              firstChild,
              const SizedBox(height: 3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: otherChildren,
              ),
            ],
          ),
          const Spacer(),
          if (hasGraph && rightWidget != null) rightWidget, // Affiche le graphique
        ],
      ),
    ),
  );
}

  // Construction d'une ligne pour afficher la valeur avant le texte
  Widget _buildValueBeforeText(String value, String text) {
    final appState = Provider.of<AppState>(context);
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16 + appState.getTextSizeOffset(), // Réduction pour Android
            fontWeight: FontWeight.bold, // Mettre la valeur en gras
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13 + appState.getTextSizeOffset(), // Réduction pour Android
          ),
        ),
      ],
    );
  }

  Widget _buildNoWalletCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Center(
      // Centrer la carte horizontalement
      child: Card(
        color: Colors.orange[200], // Couleur d'alerte
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Ajuster la taille de la colonne au contenu
            crossAxisAlignment:
                CrossAxisAlignment.center, // Centrer le contenu horizontalement
            children: [
              Text(
                S.of(context).noDataAvailable, // Utilisation de la traduction pour "Aucun wallet trouvé"
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center, // Centrer le texte
              ),
              const SizedBox(height: 10),
              Center(
                // Centrer le bouton dans la colonne
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageEvmAddressesPage(), // Ouvre la page de gestion des adresses
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue, // Texte blanc et fond bleu
                  ),
                  child: Text(S.of(context).manageAddresses), // Texte du bouton
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final appState = Provider.of<AppState>(context);

    IconButton visibilityButton = IconButton(
      icon: Icon(_showAmounts ? Icons.visibility : Icons.visibility_off),
      onPressed: _toggleAmountsVisibility,
    );

    final lastRentReceived = _getLastRentReceived(dataManager);
    final totalRentReceived = formatCurrency(dataManager.convert(dataManager.getTotalRentReceived()), dataManager.currencySymbol);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            displacement: 110,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 110.0, left: 12.0, right: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).hello,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        visibilityButton,
                      ],
                    ),
                    if (lastRentReceived == S.of(context).noRentReceived || dataManager.walletValue == 0) _buildNoWalletCard(context),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: S.of(context).lastRentReceived,
                            style: TextStyle(
                              fontSize: 15 + appState.getTextSizeOffset(),
                              color: textColor,
                            ),
                          ),
                          TextSpan(
                            text: lastRentReceived,
                            style: TextStyle(
                              fontSize: 18 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          TextSpan(
                            text: '\n${S.of(context).totalRentReceived}: ',
                            style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(),
                              color: textColor,
                            ),
                          ),
                          TextSpan(
                            text: totalRentReceived,
                            style: TextStyle(
                              fontSize: 18 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      S.of(context).portfolio,
                      Icons.dashboard,
                      _buildValueBeforeText(
                        _getFormattedAmount(dataManager.convert(dataManager.totalValue), dataManager.currencySymbol),
                        S.of(context).totalPortfolio,
                      ),
                      [
                        _buildIndentedBalance(
                          S.of(context).wallet,
                          dataManager.convert(dataManager.walletValue),
                          dataManager.currencySymbol,
                          true,
                          context,
                        ),
                        _buildIndentedBalance(
                          S.of(context).rmm,
                          dataManager.convert(dataManager.rmmValue),
                          dataManager.currencySymbol,
                          true,
                          context,
                        ),
                        _buildIndentedBalance(
                          S.of(context).rwaHoldings,
                          dataManager.convert(dataManager.rwaHoldingsValue),
                          dataManager.currencySymbol,
                          true,
                          context,
                        ),
                        const SizedBox(height: 10),
                        _buildIndentedBalance(
                          S.of(context).depositBalance,
                          dataManager.convert(dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance),
                          dataManager.currencySymbol,
                          true,
                          context,
                        ),
                        _buildIndentedBalance(
                          S.of(context).borrowBalance,
                          dataManager.convert(dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance),
                          dataManager.currencySymbol,
                          false,
                          context,
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: _buildVerticalGauge(_getPortfolioBarGraphData(dataManager), context),
                    ),
                    const SizedBox(height: 15),
                    _buildCard(
                      S.of(context).properties,
                      Icons.home,
                      _buildValueBeforeText(
                        '${(dataManager.rentedUnits / dataManager.totalUnits * 100).toStringAsFixed(2)}%',
                        S.of(context).rented,
                      ),
                      [
                        Text(
                          '${S.of(context).properties}: ${(dataManager.walletTokenCount + dataManager.rmmTokenCount)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).wallet}: ${dataManager.walletTokenCount}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).rmm}: ${dataManager.rmmTokenCount.toInt()}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).rentedUnits}: ${dataManager.rentedUnits} / ${dataManager.totalUnits}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                      ],
                      dataManager,
                      context,
                    ),
                    const SizedBox(height: 15),
                    _buildCard(
                      S.of(context).tokens,
                      Icons.account_balance_wallet,
                      _buildValueBeforeText('${dataManager.totalTokens.toStringAsFixed(2)}', S.of(context).totalTokens),
                      [
                        Text(
                          '${S.of(context).wallet}: ${dataManager.walletTokensSums.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).rmm}: ${dataManager.rmmTokensSums.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                      ],
                      dataManager,
                      context,
                    ),
                    const SizedBox(height: 15),
                    _buildCard(
                      S.of(context).rents,
                      Icons.attach_money,
                      _buildValueBeforeText('${dataManager.averageAnnualYield.toStringAsFixed(2)}%', S.of(context).annualYield),
                      [
                        Text(
                          '${S.of(context).daily}: ${_getFormattedAmount(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).weekly}: ${_getFormattedAmount(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).monthly}: ${_getFormattedAmount(dataManager.convert(dataManager.monthlyRent), dataManager.currencySymbol)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                        Text(
                          '${S.of(context).annually}: ${_getFormattedAmount(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol)}',
                          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: _buildMiniGraphForRendement(_getLast12MonthsRent(dataManager), context),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(), // Indicateur de chargement centré
            ),
        ],
      ),
    );
  }


  // Fonction utilitaire pour ajouter un "+" ou "-" et afficher entre parenthèses
  Widget _buildIndentedBalance(String label, double value, String symbol, bool isPositive, BuildContext context) {
    // Utiliser la fonction _getFormattedAmount pour gérer la visibilité des montants
    final appState = Provider.of<AppState>(context);
    String formattedAmount = _showAmounts
        ? (isPositive
            ? "+ ${formatCurrency(value, symbol)}"
            : "- ${formatCurrency(value, symbol)}")
        : (isPositive ? "+ " : "- ") +
            ('*' * 10); // Affiche une série d'astérisques si masqué

    return Padding(
      padding: const EdgeInsets.only(left: 15.0), // Ajoute une indentation pour décaler à droite
      child: Row(
        children: [
          Text(
            formattedAmount, // Affiche le montant ou des astérisques
            style: TextStyle(
              fontSize: 13, // Taille du texte ajustée
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color, // Couleur en fonction du thème
            ),
          ),
          const SizedBox(width: 8), // Espace entre le montant et le label
          Text(
            label, // Affiche le label après le montant
            style: TextStyle(
              fontSize: 11 + appState.getTextSizeOffset(), // Texte légèrement plus petit
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color, // Couleur en fonction du thème
            ),
          ),
        ],
      ),
    );
  }
}
