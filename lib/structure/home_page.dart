import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'drawer.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/portfolio/portfolio_page.dart';
import '../pages/statistics_page.dart';
import '../pages/maps_page.dart';
import 'dart:ui'; // Import pour le flou
import 'dart:io'; // Pour détecter la plateforme

class MyHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const MyHomePage({
    required this.onThemeChanged,
    super.key,
  });

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    PortfolioPage(),
    StatisticsPage(),
    MapsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages.elementAt(_selectedIndex),
          ),
          // Ajout de l'AppBar avec effet de flou
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: kToolbarHeight + 40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
          // Ajout de la BottomNavigationBar avec effet de flou descendant jusqu'en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: Platform.isAndroid
                      ? 65
                      : 80, // Augmenter légèrement la hauteur pour étendre le blur
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  child: SafeArea(
                    top:
                        false, // Désactiver le SafeArea pour le haut, ne le garder que pour le bas
                    child: CustomBottomNavigationBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onThemeChanged: widget
            .onThemeChanged, // Passer la fonction onThemeChanged uniquement
      ),
    );
  }
}
