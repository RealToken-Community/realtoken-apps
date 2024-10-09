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
    bool _showAmounts =
        true; // Variable pour contrôler la visibilité des montants

    @override
    void initState() {
      super.initState();
      _loadPrivacyMode(); // Charger l'état du mode confidentialité au démarrage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData(); // Charger les données au démarrage
      });
    }

    Future<void> _loadData() async {
      final dataManager = Provider.of<DataManager>(context, listen: false);
      await dataManager.fetchRmmBalances();
      await dataManager.fetchAndCalculateData(); // Charger les données du portefeuille
      await dataManager.fetchRentData(); // Charger les données de loyer
      await dataManager.fetchPropertyData(); // Charger les données de propriété
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
        _showAmounts = prefs.getBool('showAmounts') ??
            true; // Par défaut, les montants sont visibles
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
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row pour le titre et l'icône ->
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Platform.isAndroid ? 18 : 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // L'icône -> calée à droite
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
            // Texte et autres enfants sous le titre
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      firstChild,
                      const SizedBox(height: 3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: otherChildren,
                      ),
                    ],
                  ),
                ),
                // Graphique aligné à droite de la zone de texte, légèrement décalé vers le bas
                if (hasGraph)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 20.0), // Décalage vertical ajouté ici
                    child: _buildMiniGraphForRendement(
                      _getLast12MonthsRent(dataManager), context),
                  ),
              ],
            ),
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
                  S
                      .of(context)
                      .noDataAvailable, // Utilisation de la traduction pour "Aucun wallet trouvé"
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

      // Récupérer la couleur de texte à partir du thème actuel
      final textColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

      // Bouton pour basculer l'état de visibilité des montants
      IconButton visibilityButton = IconButton(
        icon: Icon(_showAmounts
            ? Icons.visibility
            : Icons.visibility_off), // Afficher l'icône appropriée
        onPressed:
            _toggleAmountsVisibility, // Appel à la fonction pour basculer l'état
      );

      // Récupérer la dernière valeur du loyer
      final lastRentReceived = _getFormattedAmount(
      dataManager.convert(dataManager.rentData.isNotEmpty ? dataManager.rentData.last['rent'] : 0.0),
      dataManager.currencySymbol
    );

    final totalRentReceived = _getFormattedAmount(
      dataManager.convert(dataManager.getTotalRentReceived()),
      dataManager.currencySymbol
    );
      return Scaffold(
        backgroundColor: Theme.of(context)
            .scaffoldBackgroundColor, // Applique le background du thème
        body: RefreshIndicator(
          onRefresh: _refreshData,
          displacement: 110,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 110.0, left: 12.0, right: 12.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Aligner tout à gauche
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).hello, // Utilisation de la traduction
                        style: TextStyle(
                          fontSize: Platform.isAndroid
                              ? 23
                              : 24, // Réduction pour Android
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left, // Alignement à gauche
                      ),
                      visibilityButton, // Bouton pour basculer la visibilité des montants
                    ],
                  ),
                  if (dataManager.walletValue ==
                      0) // Si aucune adresse EVM n'est trouvée
                    _buildNoWalletCard(context),
                  const SizedBox(height: 8),
                  // Ajout de la phrase en dessous de "hello"
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: S
                              .of(context)
                              .lastRentReceived, // Utilisation de la traduction
                          style: TextStyle(
                            fontSize: Platform.isAndroid
                                ? 15
                                : 16, // Réduction pour Android
                            color: textColor, // Applique la couleur du thème
                          ),
                        ),
                        TextSpan(
                          text: lastRentReceived,
                          style: TextStyle(
                            fontSize: Platform.isAndroid
                                ? 17
                                : 18, // Réduction pour Android
                            fontWeight: FontWeight.bold, // Texte en gras
                            color: textColor, // Applique la couleur du thème
                          ),
                        ),
                        TextSpan(
                          text:
                              '\n${S.of(context).totalRentReceived}: ', // Texte pour le total des loyers reçus
                          style: TextStyle(
                            fontSize: Platform.isAndroid
                                ? 15
                                : 16, // Réduction pour Android
                            color: textColor, // Applique la couleur du thème
                          ),
                        ),
                        TextSpan(
                          text:
                              totalRentReceived, // Affiche le total des loyers reçus
                          style: TextStyle(
                            fontSize: Platform.isAndroid
                                ? 17
                                : 18, // Réduction pour Android
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
                        _getFormattedAmount(
                            dataManager.convert(dataManager.totalValue),
                            dataManager.currencySymbol),
                        S
                            .of(context)
                            .totalPortfolio), // Première ligne avec le total du portfolio
                    [
                      // Dépôts (avec un "+" devant le montant)
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
                      const SizedBox(
                          height:
                              10), // Ajout d'un espace pour séparer les sections
                      // Dépôts cumulés USDC et XDAI avec "+" et parenthèses
                      _buildIndentedBalance(
                        S.of(context).depositBalance,
                        dataManager.convert(dataManager.totalUsdcDepositBalance +
                            dataManager.totalXdaiDepositBalance),
                        dataManager.currencySymbol,
                        true,
                        context,
                      ),
                      // Emprunts cumulés USDC et XDAI avec "-" et parenthèses
                      _buildIndentedBalance(
                        S.of(context).borrowBalance,
                        dataManager.convert(dataManager.totalUsdcBorrowBalance +
                            dataManager.totalXdaiBorrowBalance),
                        dataManager.currencySymbol,
                        false, // Signe "-" pour les emprunts
                        context,
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
                        '${(dataManager.rentedUnits / dataManager.totalUnits * 100).toStringAsFixed(2)}%',
                        S.of(context).rented),
                    [
                      Text(
                          '${S.of(context).properties}: ${(dataManager.walletTokenCount + dataManager.rmmTokenCount)}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                      Text(
                          '${S.of(context).wallet}: ${dataManager.walletTokenCount}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                      Text(
                          '${S.of(context).rmm}: ${dataManager.rmmTokenCount.toInt()}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                      Text(
                          '${S.of(context).rentedUnits}: ${dataManager.rentedUnits} / ${dataManager.totalUnits}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    ],
                    dataManager,
                    context,
                  ),
                  const SizedBox(height: 15),
                  _buildCard(
                    S.of(context).tokens, // Utilisation de la traduction
                    Icons.account_balance_wallet,
                    _buildValueBeforeText(
                        '${dataManager.totalTokens}', S.of(context).totalTokens),
                    [
                      Text(
                          '${S.of(context).wallet}: ${dataManager.walletTokensSums.toInt()}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                      Text(
                          '${S.of(context).rmm}: ${dataManager.rmmTokensSums.toInt()}',
                          style:
                              TextStyle(fontSize: Platform.isAndroid ? 12 : 13)),
                    ],
                    dataManager,
                    context,
                  ),
                  const SizedBox(height: 15),
                  _buildCard(
                    S.of(context).rents, // Utilisation de la traduction
                    Icons.attach_money,
                    _buildValueBeforeText(
                        '${dataManager.averageAnnualYield.toStringAsFixed(2)}%',
                        S.of(context).annualYield),
                    [
                      Text(
                        '${S.of(context).daily}: ${_getFormattedAmount(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol)}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                      ),
                      Text(
                        '${S.of(context).weekly}: ${_getFormattedAmount(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol)}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                      ),
                      Text(
                        '${S.of(context).monthly}: ${_getFormattedAmount(dataManager.convert(dataManager.monthlyRent), dataManager.currencySymbol)}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                      ),
                      Text(
                        '${S.of(context).annually}: ${_getFormattedAmount(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol)}',
                        style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),
                      ),
                    ],
                    dataManager,
                    context,
                    hasGraph:
                        true, // Seule la carte "Rendement" aura un graphique
                  ),
                  const SizedBox(
                      height:
                          80), // Ajout d'un padding en bas pour laisser de l'espace pour la BottomBar
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Fonction utilitaire pour ajouter un "+" ou "-" et afficher entre parenthèses
    Widget _buildIndentedBalance(String label, double value, String symbol,
        bool isPositive, BuildContext context) {
      // Utiliser la fonction _getFormattedAmount pour gérer la visibilité des montants
      String formattedAmount = _showAmounts
          ? (isPositive
              ? "+ ${formatCurrency(value, symbol)}"
              : "- ${formatCurrency(value, symbol)}")
          : (isPositive ? "+ " : "- ") +
              ('*' * 10); // Affiche une série d'astérisques si masqué

      return Padding(
        padding: const EdgeInsets.only(
            left: 15.0), // Ajoute une indentation pour décaler à droite
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
                fontSize: 11, // Texte légèrement plus petit
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
