import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/data_manager.dart';
import '../main.dart'; // Importer le fichier contenant MyApp
import '../generated/l10n.dart'; // Importer le fichier généré pour les traductions
import 'package:hive/hive.dart'; // Import pour Hive
import 'package:provider/provider.dart';
import '../api/api_service.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsPage({required this.onThemeChanged, super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkTheme = false;
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'usd'; // Devise par défaut
  Map<String, dynamic> _currencies = {}; // Stockage des devises

  final List<String> _languages = ['en', 'fr', 'es']; // Ajout de 'es' pour l'espagnol

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
  }

  // Fonction pour charger les paramètres
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'en';
      _selectedCurrency = prefs.getString('currency') ?? 'usd'; // Charger la devise
    });
  }

  // Fonction pour sauvegarder le thème
  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
  }

  // Fonction pour sauvegarder la langue
  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    MyApp.of(context)?.changeLanguage(language); // Mise à jour de la langue dans l'app
  }

  // Fonction pour récupérer les devises depuis l'API CoinGecko
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

  // Fonction pour sauvegarder la devise sélectionnée
  Future<void> _saveCurrency(String currency) async {
  final prefs = await SharedPreferences.getInstance();

  // Sauvegarder la devise sélectionnée
  await prefs.setString('selectedCurrency', currency);

  // Mettre à jour le taux de conversion et le symbole dans DataManager
  final dataManager = Provider.of<DataManager>(context, listen: false);
  
  // Passer la devise sélectionnée et le map des devises à `updateConversionRate`
  dataManager.updateConversionRate(currency, _selectedCurrency, _currencies);

  setState(() {
    _selectedCurrency = currency;
  });
}



  // Fonction pour vider le cache et les données
  Future<void> _clearCacheAndData() async {
    // Vider SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Réinitialiser toutes les préférences

    // Vider les données de Hive
    var box = await Hive.openBox('dashboardTokens');
    await box.clear(); // Effacer toutes les données de la boîte

    // Appeler la méthode de réinitialisation du DataManager
    final dataManager = DataManager();
    await dataManager.resetData();

    // Réinitialiser rentData en le vidant
    dataManager.rentData = []; // Vider rentData

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache and data cleared')),
    );

    // Recharger les paramètres par défaut (comme le thème et la langue)
    _loadSettings(); // Recharger les paramètres (thème, langue, etc.)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(S.of(context).settingsTitle)), // Utilisation de la traduction
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Paramètre pour le thème sombre
            ListTile(
              title: Text(
                S.of(context).darkTheme,
                style: TextStyle(
                  fontSize: Platform.isAndroid ? 15.0 : 16.0,
                ),
              ),
              trailing: Switch(
                value: _isDarkTheme,
                onChanged: (value) {
                  setState(() {
                    _isDarkTheme = value;
                  });
                  widget.onThemeChanged(value);
                  _saveTheme(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).themeUpdated(value ? S.of(context).dark : S.of(context).light))),
                  );
                },
              ),
            ),
            const Divider(),

            // Paramètre pour la langue
            ListTile(
              title: Text(
                S.of(context).language,
                style: TextStyle(
                  fontSize: Platform.isAndroid ? 15.0 : 16.0,
                ),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                items: _languages.map((String languageCode) {
                  return DropdownMenuItem<String>(
                    value: languageCode,
                    child: Text(
                      languageCode == 'en'
                          ? S.of(context).english
                          : languageCode == 'fr'
                              ? S.of(context).french
                              : S.of(context).spanish,
                      style: TextStyle(
                        fontSize: Platform.isAndroid ? 14.0 : 15.0,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                    _saveLanguage(newValue);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        S.of(context).languageUpdated(
                          newValue == 'en'
                              ? S.of(context).english
                              : newValue == 'fr'
                                  ? S.of(context).french
                                  : S.of(context).spanish,
                        ),
                      )),
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
                style: TextStyle(
                  fontSize: Platform.isAndroid ? 15.0 : 16.0,
                ),
              ),
              trailing: _currencies.isNotEmpty
                  ? DropdownButton<String>(
                      value: _selectedCurrency,
                      items: _currencies.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(
                            key.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _saveCurrency(newValue);
                        }
                      },
                    )
                  : CircularProgressIndicator(), // Loader si devises non chargées
            ),

            const Spacer(),

            // Bouton pour vider le cache et les données
            Center(
              child: ElevatedButton(
                onPressed: _clearCacheAndData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  textStyle: TextStyle(
                    fontSize: Platform.isAndroid ? 14.0 : 15.0,
                  ),
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
