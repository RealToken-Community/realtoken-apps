import 'package:flutter/material.dart';
import '../generated/l10n.dart'; // Import pour les traductions

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
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: S.of(context).dashboard), // Traduction pour "Dashboard"
        BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart),
            label: S.of(context).portfolio), // Traduction pour "Portfolio"
        BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: S.of(context).statistics), // Traduction pour "Statistiques"
        BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: S.of(context).maps), // Traduction pour "Maps"
      ],
      currentIndex: selectedIndex,
      elevation: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.transparent,
      type: BottomNavigationBarType.fixed,
      onTap: onItemTapped,
    );
  }
}
