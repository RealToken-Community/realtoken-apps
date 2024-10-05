import 'dart:async';
import 'package:flutter/material.dart';
import 'structure/home_page.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simule un délai de 3 secondes avant de naviguer vers la page principale
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les couleurs du thème actuel
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor, // Utiliser la couleur de fond du thème
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // Remplace par le chemin de ton icône
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20), // Espacement entre l'icône et le texte
            Text(
              'RealToken mobile app', // Texte à afficher
              style: TextStyle(
                fontSize: 20, // Taille du texte
                fontWeight: FontWeight.bold, // Gras
                color: textColor, // Couleur du texte basée sur le thème
              ),
            ),
          ],
        ),
      ),
    );
  }
}
