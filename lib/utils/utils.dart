import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class Utils {
  static final logger = Logger();  // Initialiser une instance de logger

  // Méthode pour formater une date en une chaîne compréhensible
  static String formatReadableDate(String dateString) {
    try {
      // Parse la date depuis le format donné
      DateTime parsedDate = DateTime.parse(dateString);

      // Formater la date dans un format lisible, par exemple: 1 Dec 2024
      String formattedDate = DateFormat('d MMM yyyy').format(parsedDate);

      return formattedDate;
    } catch (e) {
      // Si une erreur survient, retourne la date d'origine
      return dateString;
    }
  }

  static Future<void> launchURL(String url) async {
  logger.i('Tentative d\'ouverture de l\'URL: $url'); // Log pour capturer l'URL
  final Uri uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView, // Ouvre dans un navigateur externe
      );
    } else {
      throw 'Impossible de lancer l\'URL : $url';
    }
  } catch (e) {
    logger.i('Erreur lors du lancement de l\'URL: $e');
  }
}

// Fonction pour obtenir un offset de taille de texte à partir des préférences
static Future<double> getTextSizeOffset() async {
  final prefs = await SharedPreferences.getInstance();
  String selectedTextSize = prefs.getString('selectedTextSize') ?? 'normal'; // 'normal' par défaut

  switch (selectedTextSize) {
    case 'petit':
      return -2.0; // Réduire la taille de 2
    case 'grand':
      return 2.0;  // Augmenter la taille de 2
    default:
      return 0.0;  // Taille normale
  }
}
}