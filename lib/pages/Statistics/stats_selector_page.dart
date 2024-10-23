import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:realtokens_apps/pages/Statistics/rmm_stats.dart';
import 'package:realtokens_apps/pages/Statistics/portfolio_stats.dart'; // Assurez-vous que ces pages existent dans votre projet
import 'package:provider/provider.dart';
import 'package:realtokens_apps/app_state.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage> {
  String _selectedStats = 'PortfolioStats'; // Valeur par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true, // Rend l'AppBar rétractable
              snap: true, // Permet de faire réapparaître l'AppBar automatiquement
              expandedHeight: Utils.getSliverAppBarHeight(context), // Hauteur étendue si besoin
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end, // Aligne les éléments vers le bas
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0), // Ajustez les marges si nécessaire
                        child: _buildStatsSelector(), // Place votre sélecteur ici
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _selectedStats == 'PortfolioStats'
            ? const PortfolioStats()
            : const RmmStats(),
      ),
    );
  }

  Widget _buildStatsSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildStatsButton('PortfolioStats', 'Portfolio Stats', isFirst: true),
          _buildStatsButton('RMMStats', 'RMM Stats', isLast: true),
        ],
      ),
    );
  }

  Widget _buildStatsButton(String value, String label,
      {bool isFirst = false, bool isLast = false}) {
    bool isSelected = _selectedStats == value;
    final appState = Provider.of<AppState>(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStats = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Theme.of(context).cardColor,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
