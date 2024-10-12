import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:RealToken/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/data_manager.dart';
import '../generated/l10n.dart'; // Importer le fichier généré pour les traductions
import 'package:hive/hive.dart'; // Import pour Hive
import 'package:provider/provider.dart';
import '../api/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic> _currencies = {}; // Stockage des devises
  bool _convertToSquareMeters = false; // Variable pour la conversion des pieds carrés
  String _selectedCurrency = 'usd'; // Déclarez la devise sélectionnée
  final List<String> _languages = ['en', 'fr', 'es']; // Langues disponibles
  final List<String> _textSizeOptions = ['verySmall','small', 'normal', 'big','veryBig']; // Options de taille de texte

  @override
  void initState() {
    super.initState();
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
  }

  // Fonction pour récupérer les devises depuis l'API
  Future<void> _fetchCurrencies() async {
    final apiService = ApiService(); // Créez une instance d'ApiService
    try {
      final currencies = await apiService.fetchCurrencies(); // Utilisez l'instance pour appeler la méthode
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies')),
      );
    }
  }

  // Fonction pour sauvegarder la conversion des sqft en m²
  Future<void> _saveConvertToSquareMeters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('convertToSquareMeters', value);
  }

  // Fonction pour sauvegarder la devise sélectionnée
  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);

    // Mettre à jour le taux de conversion et le symbole dans DataManager
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.updateConversionRate(currency, _selectedCurrency, _currencies);

    setState(() {
      _selectedCurrency = currency; // Mettre à jour la devise sélectionnée localement
    });
  }

  // Fonction pour vider le cache et les données
  Future<void> _clearCacheAndData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Réinitialiser toutes les préférences

    var box = await Hive.openBox('dashboardTokens');
    await box.clear(); // Effacer toutes les données de la boîte

    final dataManager = DataManager();
    await dataManager.resetData();
    dataManager.rentData = []; // Vider rentData

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache and data cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à l'état global

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(S.of(context).settingsTitle), // Utilisation de la traduction
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Paramètre pour le thème sombre
            ListTile(
              title: Text(
                S.of(context).darkTheme,
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: Switch(
                value: appState.isDarkTheme,
                onChanged: (value) {
                  appState.updateTheme(value); // Utilisation de AppState pour changer le thème
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).themeUpdated(
                          value ? S.of(context).dark : S.of(context).light)),
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // Paramètre pour la langue
            ListTile(
              title: Text(
                S.of(context).language,
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: DropdownButton<String>(
                value: appState.selectedLanguage,
                items: _languages.map((String languageCode) {
                  return DropdownMenuItem<String>(
                    value: languageCode,
                    child: Text(
                      languageCode == 'en'
                          ? S.of(context).english
                          : languageCode == 'fr'
                              ? S.of(context).french
                              : S.of(context).spanish,
                      style: TextStyle(fontSize: Platform.isAndroid ? 14.0 : 15.0 + appState.getTextSizeOffset()),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    appState.updateLocale(newValue); // Utiliser AppState pour changer la langue
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).languageUpdated(
                        newValue == 'en'
                          ? S.of(context).english
                          : newValue == 'fr'
                            ? S.of(context).french
                            : S.of(context).spanish,
                      ))),
                    );
                  }
                },
              ),
            ),
            const Divider(),

            // Paramètre pour la taille du texte
            ListTile(
              title: Text(
                'Taille du texte',
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: DropdownButton<String>(
                value: appState.selectedTextSize,
                items: _textSizeOptions.map((String sizeOption) {
                  return DropdownMenuItem<String>(
                    value: sizeOption,
                    child: Text(
                      sizeOption,
                      style: TextStyle(fontSize: Platform.isAndroid ? 14.0 : 15.0 + appState.getTextSizeOffset()),
                    ),
                  );
                }).toList(),
                onChanged: (String? newSize) {
                  if (newSize != null) {
                    appState.updateTextSize(newSize); // Utiliser AppState pour changer la taille du texte
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Taille du texte mise à jour: $newSize')),
                    );
                  }
                },
              ),
            ),
            const Divider(),

            // Paramètre pour la sélection de la devise
            ListTile(
              title: Text(
                S.of(context).currency,
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: _currencies.isNotEmpty
                  ? DropdownButton<String>(
                      value: _selectedCurrency, // Utiliser _selectedCurrency ici
                      items: _currencies.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(key.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _saveCurrency(newValue); // Sauvegarder la devise sélectionnée
                        }
                      },
                    )
                  : const CircularProgressIndicator(), // Loader si devises non chargées
            ),
            const Divider(),

            // Paramètre pour la conversion des sqft en m²
            ListTile(
              title: Text(
                'Convertir les sqft en m²',
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: Switch(
                value: _convertToSquareMeters,
                onChanged: (value) {
                  setState(() {
                    _convertToSquareMeters = value;
                  });
                  _saveConvertToSquareMeters(value); // Sauvegarder la préférence
                },
              ),
            ),
            const Spacer(),

            // Bouton pour vider le cache et les données
            Center(
              child: ElevatedButton(
                onPressed: _clearCacheAndData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  textStyle: TextStyle(fontSize: Platform.isAndroid ? 14.0 : 15.0 + appState.getTextSizeOffset()),
                ),
                child: Text(
                  S.of(context).clearCacheData,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
