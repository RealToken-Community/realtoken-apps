import 'dart:convert';
import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:real_token/app_state.dart';
import 'package:real_token/utils/parameters.dart';
import 'package:real_token/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_token/api/data_manager.dart';
import 'package:real_token/generated/l10n.dart'; // Importer le fichier généré pour les traductions
import 'package:hive/hive.dart'; // Import pour Hive
import 'package:provider/provider.dart';
import '/api/api_service.dart';
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
      Parameters.convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
      Parameters.selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';
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
    dataManager.updateConversionRate(currency, Parameters.selectedCurrency, _currencies);

    setState(() {
      Parameters.selectedCurrency = currency; // Mettre à jour la devise sélectionnée localement
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
      // Ouvrir les deux boîtes Hive
      var balanceHistoryBox = await Hive.openBox('balanceHistory');
      var walletValueArchiveBox = await Hive.openBox('walletValueArchive');

      // Récupérer les données de chaque boîte Hive
      Map balanceHistoryData = balanceHistoryBox.toMap();
      Map walletValueArchiveData = walletValueArchiveBox.toMap();

      // Convertir les données en JSON
      String balanceHistoryJson = jsonEncode(balanceHistoryData);
      String walletValueArchiveJson = jsonEncode(walletValueArchiveData);

      // Obtenir les données des SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> ethAddresses = prefs.getStringList('evmAddresses') ?? [];
      String? userIdToAddresses = prefs.getString('userIdToAddresses');
      String? selectedCurrency = prefs.getString('selectedCurrency');
      bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;

      // Créer un Map pour les préférences
      Map<String, dynamic> preferencesData = {
        'ethAddresses': ethAddresses,
        'userIdToAddresses': userIdToAddresses,
        'selectedCurrency': selectedCurrency,
        'convertToSquareMeters': convertToSquareMeters
      };

      // Convertir les préférences en JSON
      String preferencesJson = jsonEncode(preferencesData);

      // Obtenir le répertoire des documents de l'application
      Directory directory = await getApplicationDocumentsDirectory();

      // Créer des fichiers JSON dans ce répertoire pour chaque boîte et les préférences
      String balanceHistoryFilePath = path.join(directory.path, 'balanceHistoryBackup.json');
      String walletValueArchiveFilePath = path.join(directory.path, 'walletValueArchiveBackup.json');
      String preferencesFilePath = path.join(directory.path, 'preferencesBackup.json');

      File balanceHistoryFile = File(balanceHistoryFilePath);
      File walletValueArchiveFile = File(walletValueArchiveFilePath);
      File preferencesFile = File(preferencesFilePath);

      // Écrire les données JSON dans les fichiers
      await balanceHistoryFile.writeAsString(balanceHistoryJson);
      await walletValueArchiveFile.writeAsString(walletValueArchiveJson);
      await preferencesFile.writeAsString(preferencesJson);

      // Créer un fichier ZIP dans le même répertoire
      String zipFilePath = path.join(directory.path, 'realToken_Backup.zip');

      // Utiliser archive pour compresser les fichiers JSON dans un fichier zip
      final archive = Archive();

      // Ajouter chaque fichier JSON à l'archive
      archive.addFile(ArchiveFile('balanceHistoryBackup.json', balanceHistoryFile.lengthSync(), balanceHistoryFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('walletValueArchiveBackup.json', walletValueArchiveFile.lengthSync(), walletValueArchiveFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('preferencesBackup.json', preferencesFile.lengthSync(), preferencesFile.readAsBytesSync()));

      // Écrire le fichier zip
      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFilePath);
      for (var file in [balanceHistoryFile, walletValueArchiveFile, preferencesFile]) {
        zipEncoder.addFile(file);
      }
      zipEncoder.close();

      // Partager le fichier ZIP
      XFile xfile = XFile(zipFilePath);
      await Share.shareXFiles([xfile], text: 'Voici les données Hive et préférences sauvegardées sous forme de fichier zip.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data successfully exported')),
      );
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

        // Parcourir les fichiers dans l'archive ZIP
        for (ArchiveFile file in archive) {
          List<int> jsonBytes = file.content as List<int>;
          String jsonContent = utf8.decode(jsonBytes);

          if (file.name == 'balanceHistoryBackup.json') {
            // Décoder et insérer les données dans la boîte 'balanceHistory'
            Map<String, dynamic> balanceHistoryData = jsonDecode(jsonContent);
            var balanceHistoryBox = await Hive.openBox('balanceHistory');
            await balanceHistoryBox.putAll(balanceHistoryData);
          } else if (file.name == 'walletValueArchiveBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> walletValueArchiveData = jsonDecode(jsonContent);
            var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
            await walletValueArchiveBox.putAll(walletValueArchiveData);
          } else if (file.name == 'preferencesBackup.json') {
            // Décoder et insérer les préférences dans SharedPreferences
            Map<String, dynamic> preferencesData = jsonDecode(jsonContent);
            final prefs = await SharedPreferences.getInstance();

            // Restaurer les préférences sauvegardées
            List<String> ethAddresses = List<String>.from(preferencesData['ethAddresses'] ?? []);
            String? userIdToAddresses = preferencesData['userIdToAddresses'];
            String? selectedCurrency = preferencesData['selectedCurrency'];
            bool convertToSquareMeters = preferencesData['convertToSquareMeters'] ?? false;

            // Sauvegarder les préférences restaurées
            await prefs.setStringList('evmAddresses', ethAddresses);
            if (userIdToAddresses != null) await prefs.setString('userIdToAddresses', userIdToAddresses);
            if (selectedCurrency != null) await prefs.setString('selectedCurrency', selectedCurrency);
            await prefs.setBool('convertToSquareMeters', convertToSquareMeters);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data successfully imported')),
        );
        print('Données importées avec succès depuis le fichier ZIP.');
      } else {
        print('Importation annulée par l\'utilisateur.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error during importation')),
      );
      print('Erreur lors de l\'importation des données Hive depuis le fichier ZIP : $e');
    }
        Utils.loadData(context);
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
    style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
  ),
  trailing: DropdownButton<String>(
    value: appState.themeMode, // Utilisez themeMode ici
    items: [
      DropdownMenuItem(value: 'light', child: Text(S.of(context).light)),
      DropdownMenuItem(value: 'dark', child: Text(S.of(context).dark)),
      DropdownMenuItem(value: 'auto', child: Text('auto')), // Option auto
    ],
    onChanged: (String? newValue) {
      if (newValue != null) {
        appState.updateThemeMode(newValue); // Mettez à jour le mode
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).themeUpdated(
              newValue == 'dark' ? S.of(context).dark : newValue == 'auto' ? 'auto' : S.of(context).light)),
          ),
        );
      }
    },
  ),
),
 const Divider(),

            // Paramètre pour la langue
          ListTile(
  title: Text(
    S.of(context).language,
    style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
  ),
  trailing: DropdownButton<String>(
    value: appState.selectedLanguage,
    items: Parameters.languages.map((String languageCode) {
      return DropdownMenuItem<String>(
        value: languageCode,
        child: Text(
          languageCode == 'en'
              ? S.of(context).english
              : languageCode == 'fr'
                  ? S.of(context).french
                  : languageCode == 'es'
                      ? S.of(context).spanish
                      : languageCode == 'it'
                          ? S.of(context).italian
                          : languageCode == 'pt'
                              ? S.of(context).portuguese
                              : languageCode == 'zh'
                                  ? S.of(context).chinese
                                  : S.of(context).english, // Par défaut, anglais
          style: TextStyle(fontSize: 15.0 + appState.getTextSizeOffset()),
        ),
      );
    }).toList(),
    onChanged: (String? newValue) {
      if (newValue != null) {
        appState.updateLanguage(newValue); // Utiliser AppState pour changer la langue
        String languageName;

        switch (newValue) {
          case 'en':
            languageName = S.of(context).english;
            break;
          case 'fr':
            languageName = S.of(context).french;
            break;
          case 'es':
            languageName = S.of(context).spanish;
            break;
          case 'it':
            languageName = S.of(context).italian;
            break;
          case 'pt':
            languageName = S.of(context).portuguese;
            break;
          case 'zh':
            languageName = S.of(context).chinese;
            break;
          default:
            languageName = S.of(context).english; // Par défaut, anglais
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).languageUpdated(languageName))),
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
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: DropdownButton<String>(
                value: appState.selectedTextSize,
                items: Parameters.textSizeOptions.map((String sizeOption) {
                  return DropdownMenuItem<String>(
                    value: sizeOption,
                    child: Text(
                      sizeOption,
                      style: TextStyle(fontSize: 15.0 + appState.getTextSizeOffset()),
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
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: _currencies.isNotEmpty
                  ? DropdownButton<String>(
                      value: Parameters.selectedCurrency, // Utiliser _selectedCurrency ici
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
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: Transform.scale(
                scale: 0.8, // Réduit la taille du Switch à 80%
                child: Switch(
                  value: Parameters.convertToSquareMeters,
                  onChanged: (value) {
                    setState(() {
                      Parameters.convertToSquareMeters = value;
                    });
                    _saveConvertToSquareMeters(value); // Sauvegarder la préférence
                  },
                  activeColor: Colors.blue, // Couleur du bouton en mode activé
                  inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                ),
              ),

            ),
            const Divider(),
            Row(
              children: [
                // Le texte
                Text(
                  S.of(context).importExportData,
                  style: TextStyle(
                    fontSize: 16.0 + appState.getTextSizeOffset(),
                  ),
                ),
                
                // Un espace entre le texte et l'icône
                SizedBox(width: 8.0),
                
                // L'icône cliquable
                IconButton(
                  icon: Icon(Icons.info_outline), // Icône d'information
                  onPressed: () {
                    // Afficher un modal lors du clic
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(S.of(context).aboutImportExportTitle),
                          content: Text(S.of(context).aboutImportExport),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Ferme le modal
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Aligne les boutons au centre
              children: [
                ElevatedButton(
                  onPressed: () {
                    shareZippedHiveData(); // Appelle la fonction d'export en zip
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Exporter',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16), // Espace horizontal entre les deux boutons
                ElevatedButton(
                  onPressed: () {
                    importZippedHiveData(); // Appelle la fonction d'import en zip
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Importer',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(),




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
      textStyle: TextStyle(fontSize: 15.0 + appState.getTextSizeOffset()),
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
