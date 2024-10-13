import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool isDarkTheme = false;
  String selectedTextSize = 'normal'; // Default text size
  String selectedLanguage = 'en'; // Langue par défaut

  AppState() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    selectedTextSize = prefs.getString('textSize') ?? 'normal';
    selectedLanguage = prefs.getString('language') ?? 'en';

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
  selectedLanguage = languageCode; // Mettre à jour la variable privée
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
  notifyListeners(); // Notify listeners about the language change
}

  // Update text size and save to Shar  edPreferences
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
