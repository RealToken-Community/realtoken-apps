
class Parameters {

//Parameters apiService
  static const Duration apiCacheDuration = Duration(hours: 1);
  static const theGraphApiKey = 'c57eb2612e998502f4418378a4cb9f35';
  static const String gnosisUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
  static const String etherumUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
  static const String rmmUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
  static const String realTokensUrl = 'https://pitswap-api.herokuapp.com/api';
  static const String rentTrackerUrl = 'https://ehpst.duckdns.org/realt_rent_tracker/api';

// Parameters Settings
  static bool convertToSquareMeters = false; // Variable pour la conversion des pieds carrés
  static String selectedCurrency = 'usd'; // Déclarez la devise sélectionnée
  static List<String> languages = ['en', 'fr', 'es', "zh", "it", "pt"]; // Langues disponibles
  static List<String> textSizeOptions = ['verySmall', 'small', 'normal', 'big', 'veryBig']; // Options de taille de texte


  // Carte des abréviations d'États des États-Unis à leurs noms complets
  static final Map<String, String> usStateAbbreviations = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming'
  };

}