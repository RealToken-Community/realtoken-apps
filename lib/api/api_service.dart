import 'dart:async';
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
  static Future<List<dynamic>> fetchTokensFromUrl(String url, String cacheKey, {bool forceFetch = false}) async {
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
       print("apiService: theGraph -> requete lancée");
      final data = json.decode(response.body)['data']['accounts'];
      box.put('cachedTokenData_$cacheKey', json.encode(data));
      box.put('lastFetchTime_$cacheKey', now.toIso8601String());
      return data;
    } else {
      throw Exception('apiService: theGraph -> Failed to fetch tokens from $url');
    }
  }

  // Fetch depuis Gnosis
  static Future<List<dynamic>> fetchTokensFromGnosis(
      {bool forceFetch = false}) {
    return fetchTokensFromUrl(gnosisUrl, 'gnosis', forceFetch: forceFetch);
  }

  // Fetch depuis Etherum
  static Future<List<dynamic>> fetchTokensFromEtherum(
      {bool forceFetch = false}) {
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
        print("apiService: theGraph -> requete lancée");

        final decodedResponse = json.decode(response.body);
        if (decodedResponse['data'] != null &&
            decodedResponse['data']['users'] != null &&
            decodedResponse['data']['users'].isNotEmpty) {
          final data = decodedResponse['data']['users'][0]['balances'];
          allBalances.addAll(data);
        }
      } else {
        throw Exception('apiService: theGraph -> Failed to fetch RMM tokens for address: $address');
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
      print("apiService: pitSwap -> requete lancée");

      final data = json.decode(response.body);
      box.put('cachedRealTokens', json.encode(data));
      box.put('lastFetchTime', now.toIso8601String());
      return data;
    } else {
      throw Exception('apiService: pitSwap -> Failed to fetch RealTokens');
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
  final DateTime now = DateTime.now();

  // Vérifier si une réponse 429 a été reçue récemment
  final last429Time = box.get('lastRent429Time');
  if (last429Time != null) {
    final DateTime last429 = DateTime.parse(last429Time);
    // Si on est dans la période d'attente de 3 minutes
    if (now.difference(last429) < Duration(minutes: 3)) {
      print('apiService: ehpst -> 429 reçu, attente avant nouvelle requête.');
      // Retourner les données en cache si elles sont disponibles
      final cachedData = box.get('cachedRentData');
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(json.decode(cachedData));
      }
      return []; // Si pas de cache, on retourne une liste vide
    }
  }

  // Vérification du cache
  final lastFetchTime = box.get('lastRentFetchTime');
  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < ApiService.cacheDuration) {
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

    // Si on reçoit un code 429, sauvegarder l'heure et arrêter
    if (response.statusCode == 429) {
      print('apiService: ehpst -> 429 Too Many Requests');
      // Sauvegarder le temps où la réponse 429 a été reçue
      box.put('lastRent429Time', now.toIso8601String());
      break; // Sortir de la boucle et arrêter la méthode
    }

    if (response.statusCode == 200) {
      print("apiService: ehpst -> RentTracker, requete lancée");

      List<Map<String, dynamic>> rentData =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      for (var rentEntry in rentData) {
        final existingEntry = mergedRentData.firstWhere(
          (entry) => entry['date'] == rentEntry['date'],
          orElse: () => <String, dynamic>{},
        );

        if (existingEntry.isNotEmpty) {
          existingEntry['rent'] =
              (existingEntry['rent'] ?? 0) + (rentEntry['rent'] ?? 0);
        } else {
          mergedRentData.add({
            'date': rentEntry['date'],
            'rent': rentEntry['rent'] ?? 0,
          });
        }
      }
    } else {
      throw Exception('ehpst -> RentTracker, Failed to load rent data for wallet: $wallet');
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
    if (cachedData != null &&
        cacheTime != null &&
        (currentTime - cacheTime) < cacheDuration) {
      // Retourner les données du cache
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }

    // Sinon, récupérer les devises depuis l'API
    final url = 'https://api.coingecko.com/api/v3/coins/xdai';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currencies =
          data['market_data']['current_price'] as Map<String, dynamic>;

      // Stocker les devises en cache
      await prefs.setString('cachedCurrencies', jsonEncode(currencies));
      await prefs.setInt('cachedCurrenciesTime', currentTime); // Stocker l'heure actuelle
      return currencies;
    } else {
      throw Exception('Failed to load currencies');
    }
  }

// Récupérer le userId associé à une adresse Ethereum
  static Future<String?> fetchUserIdFromAddress(String address) async {
    const url = gnosisUrl;

    final query = '''
    {
      account(id: "$address") {
        userIds {
          userId
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"query": query}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final userIds = data['data']['account']['userIds'];
      if (userIds != null && userIds.isNotEmpty) {
        return userIds.first['userId']; // Retourne le premier userId
      }
    }
    return null; // Si aucun userId n'a été trouvé
  }

  // Récupérer les adresses associées à un userId
  static Future<List<String>> fetchAddressesForUserId(String userId) async {
    const url = gnosisUrl;

    final query = '''
    {
      accounts(where: { userIds: ["0x296033cb983747b68911244ec1a3f01d7708851b-$userId"] }) {
        address
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"query": query}),
    );

    if (response.statusCode == 200) {
            print("apiService: theGraph -> requete lancée");
      final data = json.decode(response.body);
      final accounts = data['data']['accounts'];
      if (accounts != null && accounts.isNotEmpty) {
        return List<String>.from(accounts.map((account) => account['address']));
      }
    } else {
      print("apiService: theGraph -> echec requete");

    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchRmmBalances(
      {bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? evmAddresses = prefs.getStringList('evmAddresses');

    if (evmAddresses == null || evmAddresses.isEmpty) {
      return [];
    }

    // Contrats pour USDC & XDAI
    const String usdcDepositContract = '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1'; // Dépôt USDC
    const String usdcBorrowContract = '0x69c731ae5f5356a779f44c355abb685d84e5e9e6'; // Emprunt USDC
    const String xdaiDepositContract = '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b'; // Dépôt XDAI
    const String xdaiBorrowContract = '0x9908801df7902675c3fedd6fea0294d18d5d5d34'; // Emprunt XDAI

    List<Map<String, dynamic>> allBalances = [];

    for (var address in evmAddresses) {
      // Requête pour le dépôt et l'emprunt de USDC
      final usdcDepositResponse = await _fetchBalance(usdcDepositContract, address);
      final usdcBorrowResponse = await _fetchBalance(usdcBorrowContract, address);

      // Requête pour le dépôt et l'emprunt de XDAI
      final xdaiDepositResponse = await _fetchBalance(xdaiDepositContract, address);
      final xdaiBorrowResponse = await _fetchBalance(xdaiBorrowContract, address);

      // Traitement des réponses
      if (usdcDepositResponse != null &&
          usdcBorrowResponse != null &&
          xdaiDepositResponse != null &&
          xdaiBorrowResponse != null) {
        allBalances.add({
          'address': address,
          'usdcDepositBalance': usdcDepositResponse.toString(),
          'usdcBorrowBalance': usdcBorrowResponse.toString(),
          'xdaiDepositBalance': xdaiDepositResponse.toString(),
          'xdaiBorrowBalance': xdaiBorrowResponse.toString(),
        });
      } else {
        throw Exception('Failed to fetch balances for address: $address');
      }
    }

    return allBalances;
  }

// Méthode pour simplifier la récupération des balances
static Future<BigInt?> _fetchBalance(String contract, String address, {bool forceFetch = false}) async {
  final String cacheKey = 'cachedBalance_${contract}_$address';
  final box = await Hive.openBox('balanceCache'); // Remplacez par le système de stockage persistant que vous utilisez
  final now = DateTime.now();

  // Récupérer l'heure de la dernière requête dans le cache
  final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

  // Vérifier si on doit utiliser le cache ou forcer une nouvelle requête
  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < ApiService.cacheDuration) {
      // Vérifier si le résultat est mis en cache
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        print('apiService: Utilisation des données du cache pour $contract');
        return BigInt.tryParse(cachedData);
      }
    }
  }

  // Effectuer la requête si les données ne sont pas en cache ou expirées
  final response = await http.post(
    Uri.parse('https://rpc.gnosischain.com'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": contract,
          "data": "0x70a08231000000000000000000000000${address.substring(2)}"
        },
        "latest"
      ],
      "id": 1
    }),
  );

  if (response.statusCode == 200) {
    final responseBody = json.decode(response.body);
    final result = responseBody['result'];
    print("apiService: RPC gnosis -> requête lancée");

    if (result != null && result != "0x") {
      final balance = BigInt.parse(result.substring(2), radix: 16);
      
      // Sauvegarder le résultat dans le cache
      await box.put(cacheKey, balance.toString());
      await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
      
      return balance;
    } else {
      print("apiService: RPC gnosis -> Invalid response for contract $contract: $result");
    }
  } else {
    print('apiService: RPC gnosis -> Failed to fetch balance for contract $contract. Status code: ${response.statusCode}');
  }

  return null;
}


  // Nouvelle méthode pour récupérer les détails des loyers
static Future<List<Map<String, dynamic>>> fetchDetailedRentDataForAllWallets({bool forceFetch = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? []; // Récupérer les adresses de tous les wallets

  if (evmAddresses.isEmpty) {
    return []; // Ne pas exécuter si la liste des wallets est vide
  }

  // Ouvrir la boîte Hive pour stocker en cache
  var box = await Hive.openBox('detailedRentData');
  final DateTime now = DateTime.now();

  // Vérifier si une réponse 429 a été reçue récemment
  final last429Time = box.get('last429Time');
  if (last429Time != null) {
    final DateTime last429 = DateTime.parse(last429Time);
    // Si on est dans la période d'attente de 3 minutes
    if (now.difference(last429) < Duration(minutes: 3)) {
      print('apiService: ehpst -> 429 reçu, attente avant nouvelle requête.');
      // Retourner les données en cache si elles sont disponibles
      List<Map<String, dynamic>> cachedData = [];
      for (var walletAddress in evmAddresses) {
        final cachedWalletData = box.get('cachedDetailedRentData_$walletAddress');
        if (cachedWalletData != null) {
          cachedData.addAll(List<Map<String, dynamic>>.from(json.decode(cachedWalletData)));
        }
      }
      return cachedData;
    }
  }

  // Initialiser une liste pour stocker les données brutes
  List<Map<String, dynamic>> allRentData = [];

  // Boucle pour chaque adresse de wallet
  for (var walletAddress in evmAddresses) {
    final lastFetchTime = box.get('lastDetailedRentFetchTime_$walletAddress');

    // Si le cache est valide, utiliser les données mises en cache
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < ApiService.cacheDuration) {
        final cachedData = box.get('cachedDetailedRentData_$walletAddress');
        if (cachedData != null) {
          final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(cachedData));
          allRentData.addAll(rentData); // Ajouter les données brutes au tableau
          continue;
        }
      }
    }

    // Si le cache n'est pas valide, effectuer la requête HTTP avec un timeout de 2 minutes
    final url = 'https://ehpst.duckdns.org/realt_rent_tracker/api/detailed_rent_holder/$walletAddress';
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(minutes: 2), onTimeout: () {
        // Gérer le timeout ici
        throw TimeoutException('La requête a expiré après 2 minutes');
      });

      // Si on reçoit un code 429, sauvegarder l'heure et arrêter
      if (response.statusCode == 429) {
        print('apiService: ehpst -> 429 Too Many Requests');
        // Sauvegarder le temps où la réponse 429 a été reçue
        box.put('last429Time', now.toIso8601String());
        break; // Sortir de la boucle et arrêter la méthode
      }

      // Si la requête réussit avec un code 200, traiter les données
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));
      
        // Sauvegarder dans le cache
        box.put('cachedDetailedRentData_$walletAddress', json.encode(rentData));
        box.put('lastDetailedRentFetchTime_$walletAddress', now.toIso8601String());
        print("apiService: ehpst -> detailRent, requete lancée");

        // Ajouter les données brutes au tableau
        allRentData.addAll(rentData);
      } else {
        throw Exception('apiService: ehpst -> detailRent, Failed to fetch detailed rent data for wallet: $walletAddress');
      }
    } catch (e) {
      print('Erreur lors de la requête HTTP : $e');
      // Vous pouvez gérer les exceptions ici (timeout ou autres erreurs)
    }
  }

  // Retourner les données brutes pour traitement dans DataManager
  return allRentData;
}


}
