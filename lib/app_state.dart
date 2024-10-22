import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  bool isDarkTheme = false;
  String themeMode = 'auto'; // light, dark, auto
  String selectedTextSize = 'normal'; // Default text size
  String selectedLanguage = 'en'; // Default language
  List<String>? evmAddresses; // Variable for storing EVM addresses

  AppState() {
    _loadSettings();
    WidgetsBinding.instance.addObserver(this); // Add observer to listen to system changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer when AppState is disposed
    super.dispose();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    themeMode = prefs.getString('themeMode') ?? 'auto'; // Load theme mode
    selectedTextSize = prefs.getString('textSize') ?? 'normal';
    selectedLanguage = prefs.getString('language') ?? 'en';
    evmAddresses = prefs.getStringList('evmAddresses'); // Load EVM addresses

    _applyTheme(); // Apply the theme based on the loaded themeMode
    notifyListeners(); // Notify listeners to rebuild widgets
  }

  // Update theme mode and save to SharedPreferences
  void updateThemeMode(String mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
    
    _applyTheme(); // Apply the theme immediately after updating the mode
    notifyListeners(); // Notify listeners about the theme mode change
  }

  // Apply theme based on themeMode
  void _applyTheme() {
    if (themeMode == 'auto') {
      // Detect system theme and apply
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkTheme = brightness == Brightness.dark;
    } else {
      isDarkTheme = themeMode == 'dark';
    }
    notifyListeners();
  }

  // Overriding the didChangePlatformBrightness method to detect theme changes dynamically
  @override
  void didChangePlatformBrightness() {
    if (themeMode == 'auto') {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkTheme = brightness == Brightness.dark;
      notifyListeners(); // Notify listeners to rebuild UI when system theme changes
    }
  }

  // Update dark/light theme directly and save to SharedPreferences (for manual switch)
  void updateTheme(bool value) async {
    isDarkTheme = value;
    themeMode = value ? 'dark' : 'light'; // Set theme mode based on manual selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    await prefs.setString('themeMode', themeMode); // Save theme mode
    notifyListeners(); // Notify listeners about the theme change
  }

  // Update language and save to SharedPreferences
  void updateLanguage(String languageCode) async {
    selectedLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners(); // Notify listeners about the language change
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
