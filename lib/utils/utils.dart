import 'package:intl/intl.dart';

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
}
