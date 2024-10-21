import 'package:flutter/material.dart';
import 'package:RealToken/pages/Statistics/RMM_stats.dart';
import 'package:RealToken/pages/Statistics/portfolio_stats.dart';  // Assurez-vous que ces pages existent dans votre projet
import 'package:provider/provider.dart';
import '../../app_state.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  _StatsSelectorPageState createState() => _StatsSelectorPageState();
}

class _StatsSelectorPageState extends State<StatsSelectorPage> {
  String _selectedStats = 'PortfolioStats'; // Valeur par défaut

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
          padding: const EdgeInsets.only(top: 80.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildStatsSelector(),
          const SizedBox(height: 5),

          // Affichage de la page en fonction du choix
          Expanded(
            child: _selectedStats == 'PortfolioStats'
                ? const PortfolioStats()
                : const RmmStats(),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildStatsSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Ajoute un padding horizontal
      child: Row(
        children: [
          _buildStatsButton('PortfolioStats', 'Portfolio Stats', isFirst: true),
          _buildStatsButton('RMMStats', 'RMM Stats', isLast: true),
        ],
      ),
    );
  }


  Widget _buildStatsButton(String value, String label, {bool isFirst = false, bool isLast = false}) {
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
