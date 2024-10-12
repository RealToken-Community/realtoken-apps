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
import 'app_state.dart'; // Import the global AppState

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
  await Hive.openBox('detailedRentDataBox');

  // Initialisation de SharedPreferences et DataManager
  final dataManager = DataManager();
  await dataManager.loadSelectedCurrency(); // Charger la devise sélectionnée
  await dataManager.loadUserIdToAddresses(); // Charger les userIds et adresses
  FlutterNativeSplash.remove(); // Supprimer le splash screen natif après l'initialisation
  await dataManager.fetchAndCalculateData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager), // Utilisez ici la même instance
        ChangeNotifierProvider(create: (_) => AppState()), // AppState for global settings
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'RealToken mobile app',
          locale: Locale(appState.selectedLanguage), // Use the global locale from AppState
          supportedLocales: S.delegate.supportedLocales, // Support des langues
          localizationsDelegates: const [
            S.delegate, // Générateur de localisation
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: appState.isDarkTheme ? ThemeMode.dark : ThemeMode.light, // Switch between light and dark mode
          home: const MyHomePage(), // No need to pass onThemeChanged anymore
        );
      },
    );
  }
}
