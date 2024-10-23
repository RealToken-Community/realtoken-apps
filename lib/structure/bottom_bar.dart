import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/generated/l10n.dart'; // Import pour les traductions
import 'package:realtokens_apps/app_state.dart'; // Importer AppState

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Récupérer AppState
    final double textSizeOffset = appState.getTextSizeOffset(); // Obtenir l'offset de taille de texte

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, size: 24.0 + textSizeOffset), // Ajuster la taille de l'icône
          label: S.of(context).dashboard, // Traduction pour "Dashboard"
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart, size: 24.0 + textSizeOffset), // Ajuster la taille de l'icône
          label: S.of(context).portfolio, // Traduction pour "Portfolio"
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart, size: 24.0 + textSizeOffset), // Ajuster la taille de l'icône
          label: S.of(context).statistics, // Traduction pour "Statistiques"
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map, size: 24.0 + textSizeOffset), // Ajuster la taille de l'icône
          label: S.of(context).maps, // Traduction pour "Maps"
        ),
      ],
      currentIndex: selectedIndex,
      elevation: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.transparent,
      type: BottomNavigationBarType.fixed,
      onTap: onItemTapped,
      selectedLabelStyle: TextStyle(fontSize: 14.0 + textSizeOffset), // Ajuster la taille du texte sélectionné
      unselectedLabelStyle: TextStyle(fontSize: 12.0 + textSizeOffset), // Ajuster la taille du texte non sélectionné
    );
  }
}
