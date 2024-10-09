import 'package:RealToken/structure/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/data_manager.dart';
import 'settings/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart'; // Import du fichier généré pour les traductions
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Import du package pour le splashscreen

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // Préserver le splash screen natif

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('dashboardTokens');
  await Hive.openBox('realTokens');
  await Hive.openBox('rentData');

  // Initialisation de SharedPreferences et DataManager
  final dataManager = DataManager();
  await dataManager.loadSelectedCurrency(); // Charger la devise sélectionnée
  await dataManager.loadUserIdToAddresses(); // Charger les userIds et adresses
  await dataManager.fetchAndCalculateData();

  FlutterNativeSplash.remove(); // Supprimer le splash screen natif après l'initialisation

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager), // Utilisez ici la même instance
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<bool> _isDarkTheme = ValueNotifier(false);
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme.value = prefs.getBool('isDarkTheme') ?? false;
    String? languageCode = prefs.getString('language') ?? 'en';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  // Ajout de la méthode pour changer la langue
  void changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkTheme,
      builder: (context, isDarkTheme, child) {
        return MaterialApp(
          title: 'RealT mobile app',
          locale: _locale,  // Utiliser la locale définie
          supportedLocales: S.delegate.supportedLocales,  // Support des langues
          localizationsDelegates: const [
            S.delegate,  // Générateur de localisation
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: MyHomePage(
            onThemeChanged: (value) {
              _isDarkTheme.value = value;
            },
          ),
        );
      },
    );
  }
}
