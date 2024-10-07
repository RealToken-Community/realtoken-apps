import 'dart:io'; // Import nécessaire pour Platform
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/data_manager.dart';
import 'package:intl/intl.dart';
import '../generated/l10n.dart';
import '/settings/manage_evm_addresses_page.dart'; // Import de la page pour gérer les adresses EVM

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
  @override
  void initState() {
    super.initState();
    // Utiliser des WidgetsBinding pour s'assurer que le contexte est disponible après l'initialisation de l'état
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(); // Charger les données au démarrage
    });
  }

  Future<void> _loadData() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData(); // Charger les données du portefeuille
    await dataManager.fetchRentData(); // Charger les données de loyer
    await dataManager.fetchPropertyData(); // Charger les données de propriété
    await dataManager.fetchRmmBalances();
  }

  Future<void> _refreshData() async {
    // Forcer la mise à jour des données en appelant les méthodes de récupération avec forceFetch = true
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData(forceFetch: true);
    await dataManager.fetchRentData(forceFetch: true);
    await dataManager.fetchPropertyData(forceFetch: true);
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
  final rentData = dataManager.rentData;

  if (rentData.isEmpty) {
    return S.of(context).noRentReceived;
  }

  rentData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
  final lastRent = rentData.first['rent'];

  // Convertir et formater avec le symbole de la devise sélectionnée
  return formatCurrency(dataManager.convert(lastRent), dataManager.currencySymbol);
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
        monthlyRent[monthKey] = (monthlyRent[monthKey] ?? 0) + rentEntry['rent'];
      }
    }

    // Assurer que nous avons les 12 derniers mois dans l'ordre
    List<String> sortedMonths = List.generate(12, (index) {
      DateTime date = DateTime(currentDate.year, currentDate.month - index, 1);
      return DateFormat('yyyy-MM').format(date);
    }).reversed.toList();

    return sortedMonths.map((month) => monthlyRent[month] ?? 0).toList();
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
                spots: List.generate(data.length, (index) => FlSpot(index.toDouble(), data[index])),
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
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
}) {
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
                  Icon(
                    icon,
                    size: 24,
                    color: title == S.of(context).rents ? Colors.green :
                      title == S.of(context).tokens ? Colors.orange :
                      title == S.of(context).properties ? Colors.blue :
                      title == S.of(context).portfolio ? Colors.black :  
                      Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Platform.isAndroid ? 18 : 19,
                      fontWeight: FontWeight.bold,
                    ),
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
          if (hasGraph) _buildMiniGraphForRendement(_getLast12MonthsRent(dataManager), context),
        ],
      ),
    ),
  );
}

  // Construction d'une ligne pour afficher la valeur avant le texte
  Widget _buildValueBeforeText(String value, String text) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Platform.isAndroid ? 15 : 16, // Réduction pour Android
            fontWeight: FontWeight.bold, // Mettre la valeur en gras
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: Platform.isAndroid ? 12 : 13, // Réduction pour Android
          ),
        ),
      ],
    );
  }

  Widget _buildNoWalletCard(BuildContext context) {
    return Center( // Centrer la carte horizontalement
      child: Card(
        color: Colors.orange[200], // Couleur d'alerte
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ajuster la taille de la colonne au contenu
            crossAxisAlignment: CrossAxisAlignment.center, // Centrer le contenu horizontalement
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
              Center( // Centrer le bouton dans la colonne
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ManageEvmAddressesPage(), // Ouvre la page de gestion des adresses
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Texte blanc et fond bleu
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

    // Récupérer la couleur de texte à partir du thème actuel
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Récupérer la dernière valeur du loyer
    final lastRentReceived = _getLastRentReceived(dataManager);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Applique le background du thème
      body: RefreshIndicator(
        onRefresh: _refreshData,
        displacement: 110,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 110.0, left: 12.0, right: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Aligner tout à gauche
              children: [
                Text(
                  S.of(context).hello, // Utilisation de la traduction
                  style: TextStyle(
                    fontSize: Platform.isAndroid ? 23 : 24, // Réduction pour Android
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left, // Alignement à gauche
                ),
                if (dataManager.walletValue == 0) // Si aucune adresse EVM n'est trouvée
                  _buildNoWalletCard(context), // Afficher la carte de notification
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: S.of(context).lastRentReceived, // Utilisation de la traduction
                        style: TextStyle(
                          fontSize: Platform.isAndroid ? 15 : 16, // Réduction pour Android
                          color: textColor, // Applique la couleur du thème
                        ),
                      ),
                      TextSpan(
                        text: lastRentReceived,
                        style: TextStyle(
                          fontSize: Platform.isAndroid ? 17 : 18, // Réduction pour Android
                          fontWeight: FontWeight.bold, // Texte en gras
                          color: textColor, // Applique la couleur du thème
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCard(
  S.of(context).portfolio, // Utilisation de la traduction
  Icons.dashboard,
  _buildValueBeforeText(
    formatCurrency(dataManager.convert(dataManager.totalValue), dataManager.currencySymbol),
    S.of(context).totalPortfolio), // Première ligne avec le total du portfolio
  [
    // Section pour Wallet
    Text(
      '${S.of(context).wallet}: ${formatCurrency(dataManager.convert(dataManager.walletValue), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
    Text(
      '${S.of(context).rmm}: ${formatCurrency(dataManager.convert(dataManager.rmmValue), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
    Text(
      '${S.of(context).rwaHoldings}: ${formatCurrency(dataManager.convert(dataManager.rwaHoldingsValue), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
    
    const SizedBox(height: 10), // Ajout d'un espace pour séparer les sections

    // Section pour les balances USDC
    Text(
      '${S.of(context).usdcDepositBalance}: ${formatCurrency(dataManager.convert(dataManager.totalUsdcDepositBalance), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
    Text(
      '${S.of(context).usdcBorrowBalance}: ${formatCurrency(dataManager.convert(dataManager.totalUsdcBorrowBalance), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),

    const SizedBox(height: 10), // Ajout d'un espace pour séparer les sections

    // Section pour les balances XDAI
    Text(
      '${S.of(context).xdaiDepositBalance}: ${formatCurrency(dataManager.convert(dataManager.totalXdaiDepositBalance), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
    Text(
      '${S.of(context).xdaiBorrowBalance}: ${formatCurrency(dataManager.convert(dataManager.totalXdaiBorrowBalance), dataManager.currencySymbol)}',
      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
    ),
  ],
  dataManager,
  context,
),

const SizedBox(height: 15),
                _buildCard(
                  S.of(context).properties, // Utilisation de la traduction
                  Icons.home,
                  _buildValueBeforeText(
                      '${(dataManager.rentedUnits / dataManager.totalUnits * 100).toStringAsFixed(2)}%', S.of(context).rented),
                  [
                    Text('${S.of(context).properties}: ${(dataManager.walletTokenCount + dataManager.rmmTokenCount)}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    Text('${S.of(context).wallet}: ${dataManager.walletTokenCount}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    Text('${S.of(context).rmm}: ${dataManager.rmmTokenCount.toInt()}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    Text('${S.of(context).rentedUnits}: ${dataManager.rentedUnits} / ${dataManager.totalUnits}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                  ],
                  dataManager,
                  context,
                ),
                const SizedBox(height: 15),
                _buildCard(
                  S.of(context).tokens, // Utilisation de la traduction
                  Icons.account_balance_wallet,
                  _buildValueBeforeText('${dataManager.totalTokens}', S.of(context).totalTokens),
                  [
                    Text('${S.of(context).wallet}: ${dataManager.walletTokensSums.toInt()}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    Text('${S.of(context).rmm}: ${dataManager.rmmTokensSums.toInt()}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                  ],
                  dataManager,
                  context,
                ),
                const SizedBox(height: 15),
                _buildCard(
                  S.of(context).rents, // Utilisation de la traduction
                  Icons.attach_money,
                  _buildValueBeforeText(
                      '${dataManager.averageAnnualYield.toStringAsFixed(2)}%', S.of(context).annualYield),
                  [
                    Text(
                      '${S.of(context).daily}: ${formatCurrency(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol)}',
                      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                    ),
                    Text(
                      '${S.of(context).weekly}: ${formatCurrency(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol)}',
                      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                    ),
                    Text(
                      '${S.of(context).monthly}: ${formatCurrency(dataManager.convert(dataManager.monthlyRent), dataManager.currencySymbol)}',
                      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                    ),
                    Text(
                      '${S.of(context).annually}: ${formatCurrency(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol)}',
                      style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                    ),
                  ],
                  dataManager,
                  context,
                  hasGraph: true, // Seule la carte "Rendement" aura un graphique
                ),
                const SizedBox(height: 80), // Ajout d'un padding en bas pour laisser de l'espace pour la BottomBar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
