import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/generated/l10n.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RealtPage extends StatefulWidget {
  const RealtPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<RealtPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Accéder à DataManager pour récupérer les valeurs calculées
    final dataManager = Provider.of<DataManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).realTTitle),  // Utilisation de S.of(context)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image centrée en haut
              Center(
                child: Image.asset(
                  'assets/RealT_Logo.png', // Chemin vers l'image dans assets
                  height: 100, // Ajuster la taille de l'image
                ),
              ),
              const SizedBox(height: 30), // Espace sous l'image
              _buildCard(
                S.of(context).totalTokens,  // Utilisation de S.of(context)
                Icons.token,
                _buildValueBeforeText(
                  '${dataManager.totalRealtTokens}',
                  S.of(context).tokens,  // Utilisation de S.of(context)
                ),
                [],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).totalInvestment,  // Utilisation de S.of(context)
                Icons.attach_money,
                _buildValueBeforeText(
                  Utils.formatCurrency(dataManager.convert(dataManager.totalRealtInvestment), dataManager.currencySymbol),
                  '',
                ),
                [],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).netAnnualRent,  // Utilisation de S.of(context)
                Icons.money,
                _buildValueBeforeText(
                  Utils.formatCurrency(dataManager.convert(dataManager.netRealtRentYear), dataManager.currencySymbol),
                  '',
                ),
                [],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).totalUnits,  // Utilisation de S.of(context)
                Icons.home,
                _buildValueBeforeText(
                  '${dataManager.totalRealtUnits}',
                  S.of(context).units,  // Utilisation de S.of(context)
                ),
                [
                  _buildValueBeforeText(
                    '${dataManager.rentedRealtUnits}',
                    S.of(context).rentedUnits,  // Utilisation de S.of(context)
                  ),
                ],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).realTPerformance,  // Utilisation de S.of(context)
                Icons.trending_up,
                _buildValueBeforeText(
                  '${dataManager.averageRealtAnnualYield.toStringAsFixed(2)}%',
                  S.of(context).annualYield,  // Utilisation de S.of(context)
                ),
                [
                  _buildValueBeforeText(
                    '',
                    S.of(context).annualYield,  // Utilisation de S.of(context)
                  ),
                ],
                dataManager,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour créer une carte similaire à DashboardPage
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
                    Icon(icon, size: 24, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
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
            if (hasGraph && rightWidget != null) rightWidget, // Affiche le graphique si nécessaire
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13),
        ),
      ],
    );
  }
}
