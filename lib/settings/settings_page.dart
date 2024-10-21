import 'dart:convert';
import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:RealToken/app_state.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/data_manager.dart';
import '../generated/l10n.dart'; // Importer le fichier généré pour les traductions
import 'package:hive/hive.dart'; // Import pour Hive
import 'package:provider/provider.dart';
import '../api/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path; // Ajoute cet import pour manipuler les chemins de fichiers
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';

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
  final List<String> _textSizeOptions = ['verySmall', 'small', 'normal', 'big', 'veryBig']; // Options de taille de texte

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charger les paramètres initiaux
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
  }

  // Fonction pour charger les paramètres stockés localement (conversion des m² et devise)
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';
    });
  }

  // Fonction pour récupérer les devises depuis l'API
  Future<void> _fetchCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies(); // Utilisez l'instance pour appeler la méthode
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


Future<void> shareZippedHiveData() async {
  try {
    // Ouvrir la boîte Hive (par exemple 'realTokens')
    var box = await Hive.openBox('balanceHistory');

    // Récupérer les données de Hive
    Map hiveData = box.toMap();

    // Convertir les données en JSON
    String jsonData = jsonEncode(hiveData);

    // Obtenir le répertoire des documents de l'application
    Directory directory = await getApplicationDocumentsDirectory();

    // Créer un fichier JSON dans ce répertoire
    String jsonFilePath = path.join(directory.path, 'hiveDataBackup.json');
    File jsonFile = File(jsonFilePath);

    // Écrire les données JSON dans le fichier
    await jsonFile.writeAsString(jsonData);

    // Créer un fichier ZIP dans le même répertoire
    String zipFilePath = path.join(directory.path, 'hiveDataBackup.zip');
    final zipFile = File(zipFilePath);

    // Utiliser archive pour compresser le fichier JSON dans un fichier zip
    final archive = Archive();
    List<int> jsonBytes = jsonFile.readAsBytesSync();
    archive.addFile(ArchiveFile('hiveDataBackup.json', jsonBytes.length, jsonBytes));

    // Écrire le fichier zip
    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipFilePath);
    zipEncoder.addFile(jsonFile);
    zipEncoder.close();

    // Partager le fichier ZIP
    XFile xfile = XFile(zipFilePath);
    await Share.shareXFiles([xfile], text: 'Voici les données Hive sauvegardées sous forme de fichier zip.');

  } catch (e) {
    print('Erreur lors du partage des données Hive : $e');
  }
}

Future<void> importZippedHiveData() async {
  try {
    // Utiliser file_picker pour permettre à l'utilisateur de sélectionner un fichier ZIP
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'], // Limiter à l'importation de fichiers ZIP
    );

    if (result != null) {
      // Obtenir le fichier sélectionné
      File zipFile = File(result.files.single.path!);

      // Lire le fichier ZIP et le décompresser
      List<int> bytes = zipFile.readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      // Extraire le fichier JSON du ZIP
      for (ArchiveFile file in archive) {
        if (file.name == 'hiveDataBackup.json') {
          List<int> jsonBytes = file.content as List<int>;
          String jsonContent = utf8.decode(jsonBytes);

          // Décoder les données JSON
          Map<String, dynamic> importedData = jsonDecode(jsonContent);

          // Ouvrir la boîte Hive et insérer les données
          var box = await Hive.openBox('balanceHistory');
          await box.putAll(importedData);

          print('Données importées avec succès depuis le fichier ZIP.');
          break;
        }
      }
    } else {
      print('Importation annulée par l\'utilisateur.');
    }
  } catch (e) {
    print('Erreur lors de l\'importation des données Hive depuis le fichier ZIP : $e');
  }
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
              trailing: Transform.scale(
                scale: 0.8, // Réduit la taille du Switch à 80%
                child: Switch(
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
                  activeColor: Colors.blue, // Couleur du bouton en mode activé
                  inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                ),
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
                    appState.updateLanguage(newValue); // Utiliser AppState pour changer la langue
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
                S.of(context).textSize,
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
                S.of(context).convertSqft,
                style: TextStyle(fontSize: Platform.isAndroid ? 15.0 : 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: Transform.scale(
                scale: 0.8, // Réduit la taille du Switch à 80%
                child: Switch(
                  value: _convertToSquareMeters,
                  onChanged: (value) {
                    setState(() {
                      _convertToSquareMeters = value;
                    });
                    _saveConvertToSquareMeters(value); // Sauvegarder la préférence
                  },
                  activeColor: Colors.blue, // Couleur du bouton en mode activé
                  inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                ),
              ),

            ),
            Center(
  child: ElevatedButton(
    onPressed: () {
      shareZippedHiveData(); // Appelle la fonction d'export en zip
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
    ),
    child: Text(
      'Exporter les données (ZIP)',
      style: const TextStyle(color: Colors.white),
    ),
  ),
),

Center(
  child: ElevatedButton(
    onPressed: () {
      importZippedHiveData(); // Appelle la fonction d'import en zip
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
    ),
    child: Text(
      'Importer les données (ZIP)',
      style: const TextStyle(color: Colors.white),
    ),
  ),
),



            const Spacer(),

            // Bouton pour vider le cache et les données
Center(
  child: ElevatedButton(
    onPressed: () {
      // Afficher le modal de confirmation
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).confirmAction), // Titre du modal
            content: Text(S.of(context).areYouSureClearData), // Message de confirmation
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le modal sans rien faire
                },
                child: Text(S.of(context).cancel), // Texte du bouton "Annuler"
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le modal
                  _clearCacheAndData(); // Exécuter l'action une fois confirmé
                },
                child: Text(S.of(context).confirm), // Texte du bouton "Confirmer"
              ),
            ],
          );
        },
      );
    },
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
