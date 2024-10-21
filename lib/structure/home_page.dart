import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'drawer.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/portfolio/portfolio_page.dart';
import '../pages/Statistics/stats_selector_page.dart';
import '../pages/maps_page.dart';
import 'dart:ui'; // Import for blur effect
import 'package:provider/provider.dart';
import '../app_state.dart'; // Import the global AppState

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    PortfolioPage(),
    StatsSelectorPage(),
    MapsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Access AppState

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages.elementAt(_selectedIndex),
          ),
          // AppBar with blur effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: kToolbarHeight + 20,
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
          // BottomNavigationBar with blur effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60, // Adjust height for blur
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  child: SafeArea(
                    top: false, // Disable top SafeArea
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
        onThemeChanged: (value) {
          appState.updateTheme(value); // Update theme using AppState
        },
      ),
    );
  }
}
