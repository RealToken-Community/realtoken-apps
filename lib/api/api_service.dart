import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const theGraphApiKey = 'c57eb2612e998502f4418378a4cb9f35';
  static const String gnosisUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
  static const String etherumUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
  static const String rmmUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
  static const String realTokensUrl = 'https://pitswap-api.herokuapp.com/api/realTokens_mobileapps/';
  static const String rentTrackerUrl = 'https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/';
  static const Duration cacheDuration = Duration(hours: 1);

  // Méthode factorisée pour fetch les tokens depuis The Graph
  static Future<List<dynamic>> fetchTokensFromUrl(String url, String cacheKey ,{bool forceFetch = false}) async {
    var box = Hive.box('dashboardTokens');
    final lastFetchTime = box.get('lastFetchTime_$cacheKey');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String>? evmAddresses = prefs.getStringList('evmAddresses');

    if (evmAddresses == null || evmAddresses.isEmpty) {
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < cacheDuration) {
        final cachedData = box.get('cachedTokenData_$cacheKey');
        if (cachedData != null) {
          return List<dynamic>.from(json.decode(cachedData));
        }
      }
    }

    // Requête GraphQL
    final query = '''
      query RealtokenQuery(\$addressList: [String]!) {
        accounts(where: { address_in: \$addressList }) {
          address
          balances(where: { amount_gt: "0" }, first: 1000, orderBy: amount, orderDirection: desc) {
            token {
              address
            }
            amount
          }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "query": query,
        "variables": {"addressList": evmAddresses}
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['accounts'];
      box.put('cachedTokenData_$cacheKey', json.encode(data));
      box.put('lastFetchTime_$cacheKey', now.toIso8601String());
      return data;
    } else {
      throw Exception('Failed to fetch tokens from $url');
    }
  }

  // Fetch depuis Gnosis
  static Future<List<dynamic>> fetchTokensFromGnosis({bool forceFetch = false}) {
    return fetchTokensFromUrl(gnosisUrl, 'gnosis', forceFetch: forceFetch);
  }

  // Fetch depuis Etherum
  static Future<List<dynamic>> fetchTokensFromEtherum({bool forceFetch = false}) {
    return fetchTokensFromUrl(etherumUrl, 'etherum', forceFetch: forceFetch);
  }

  // Récupérer les tokens sur le RealToken Marketplace (RMM)
  static Future<List<dynamic>> fetchRMMTokens({bool forceFetch = false}) async {
    var box = Hive.box('dashboardTokens');
    final lastFetchTime = box.get('lastRMMFetchTime');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String>? evmAddresses = prefs.getStringList('evmAddresses');

    if (evmAddresses == null || evmAddresses.isEmpty) {
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < cacheDuration) {
        final cachedData = box.get('cachedRMMData');
        if (cachedData != null) {
          return List<dynamic>.from(json.decode(cachedData));
        }
      }
    }

    List<dynamic> allBalances = [];
    for (var address in evmAddresses) {
      final response = await http.post(
        Uri.parse(rmmUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "query": '''
            query RmmQuery(\$addressList: String!) {
              users(where: { id: \$addressList }) {
                balances(
                  where: { amount_gt: 0 },
                  first: 1000,
                  orderBy: amount,
                  orderDirection: desc,
                  skip: 0
                ) {
                  amount
                  token {
                    decimals
                    id
                    __typename
                  }
                  __typename
                }
                __typename
              }
            }
          ''',
          "variables": {
            "addressList": address,
          }
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['data'] != null &&
            decodedResponse['data']['users'] != null &&
            decodedResponse['data']['users'].isNotEmpty) {
          final data = decodedResponse['data']['users'][0]['balances'];
          allBalances.addAll(data);
        }
      } else {
        throw Exception('Failed to fetch RMM tokens for address: $address');
      }
    }

    box.put('cachedRMMData', json.encode(allBalances));
    box.put('lastRMMFetchTime', now.toIso8601String());

    return allBalances;
  }

  // Récupérer la liste complète des RealTokens depuis l'API pitswap
  static Future<List<dynamic>> fetchRealTokens({bool forceFetch = false}) async {
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastFetchTime');
    final DateTime now = DateTime.now();

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < cacheDuration) {
        final cachedData = box.get('cachedRealTokens');
        if (cachedData != null) {
          return List<dynamic>.from(json.decode(cachedData));
        }
      }
    }

    final response = await http.get(Uri.parse(realTokensUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      box.put('cachedRealTokens', json.encode(data));
      box.put('lastFetchTime', now.toIso8601String());
      return data;
    } else {
      throw Exception('Failed to fetch RealTokens');
    }
  }

  // Récupérer les données de loyer pour chaque wallet et les fusionner avec cache
static Future<List<Map<String, dynamic>>> fetchRentData({bool forceFetch = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> wallets = prefs.getStringList('evmAddresses') ?? [];
  
  if (wallets.isEmpty) {
    return []; // Ne pas exécuter si la liste des wallets est vide
  }

  var box = Hive.box('rentData');
  final lastFetchTime = box.get('lastRentFetchTime');
  final DateTime now = DateTime.now();

  // Si forceFetch est false, on vérifie le cache
  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < cacheDuration) {
      final cachedData = box.get('cachedRentData');
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(json.decode(cachedData));
      }
    }
  }

  // Sinon, on effectue la requête API
  List<Map<String, dynamic>> mergedRentData = [];

  for (String wallet in wallets) {
    final url = '$rentTrackerUrl$wallet';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));
      for (var rentEntry in rentData) {
        final existingEntry = mergedRentData.firstWhere(
          (entry) => entry['date'] == rentEntry['date'],
          orElse: () => <String, dynamic>{},
        );

        if (existingEntry.isNotEmpty) {
          existingEntry['rent'] = (existingEntry['rent'] ?? 0) + (rentEntry['rent'] ?? 0);
        } else {
          mergedRentData.add({
            'date': rentEntry['date'],
            'rent': rentEntry['rent'] ?? 0,
          });
        }
      }
    } else {
      throw Exception('Failed to load rent data for wallet: $wallet');
    }
  }

  mergedRentData.sort((a, b) => a['date'].compareTo(b['date']));

  // Mise à jour du cache après la récupération des données
  box.put('cachedRentData', json.encode(mergedRentData));
  box.put('lastRentFetchTime', now.toIso8601String());

  return mergedRentData;
}

Future<Map<String, dynamic>> fetchCurrencies() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Vérifier si les devises sont déjà en cache
  final cachedData = prefs.getString('cachedCurrencies');
  final cacheTime = prefs.getInt('cachedCurrenciesTime');
  
  final currentTime = DateTime.now().millisecondsSinceEpoch;
  const cacheDuration = 3600000; // 1 heure en millisecondes
  
  // Si les données sont en cache et n'ont pas expiré
  if (cachedData != null && cacheTime != null && (currentTime - cacheTime) < cacheDuration) {
    // Retourner les données du cache
    return jsonDecode(cachedData) as Map<String, dynamic>;
  }

  // Sinon, récupérer les devises depuis l'API
  final url = 'https://api.coingecko.com/api/v3/coins/xdai';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final currencies = data['market_data']['current_price'] as Map<String, dynamic>;
    
    // Stocker les devises en cache
    await prefs.setString('cachedCurrencies', jsonEncode(currencies));
    await prefs.setInt('cachedCurrenciesTime', currentTime); // Stocker l'heure actuelle

    return currencies;
  } else {
    throw Exception('Failed to load currencies');
  }
}

}
