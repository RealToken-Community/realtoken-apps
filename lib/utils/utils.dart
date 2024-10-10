import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
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
  print('Tentative d\'ouverture de l\'URL: $url'); // Log pour capturer l'URL
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
    print('Erreur lors du lancement de l\'URL: $e');
  }
}
}
