import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool isDarkTheme = false;
  String selectedTextSize = 'normal'; // Default text size
  String _selectedLanguage = 'en'; // Langue par défaut
  String get selectedLanguage => _selectedLanguage;

  AppState() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    selectedTextSize = prefs.getString('textSize') ?? 'normal';
    notifyListeners(); // Notify listeners to rebuild widgets
  }

  // Update theme and save to SharedPreferences
  void updateTheme(bool value) async {
    isDarkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    notifyListeners(); // Notify listeners about the theme change
  }

  // Update language and save to SharedPreferences
void updateLanguage(String languageCode) async {
  _selectedLanguage = languageCode; // Mettre à jour la variable privée
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
  notifyListeners(); // Notify listeners about the language change
}

  // Méthode pour mettre à jour la langue
  Future<void> updateLocale(String languageCode) async {
    _selectedLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners(); // Notifie les widgets écoutant ce changement
  }

  // Update text size and save to SharedPreferences
  void updateTextSize(String textSize) async {
    selectedTextSize = textSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('textSize', textSize);
    notifyListeners(); // Notify listeners about the text size change
  }

  // Get text size offset based on selected size
  double getTextSizeOffset() {
    switch (selectedTextSize) {
      case 'verySmall':
        return -4.0; // Reduce font size
      case 'small':
        return -2.0; // Reduce font size
      case 'big':
        return 2.0; // Increase font size
      case 'veryBig':
      return 4.0; // Increase font size
      default:
        return 0.0; // Default size
    }
  }
}
