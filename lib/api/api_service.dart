import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const theGraphApiKey = 'c57eb2612e998502f4418378a4cb9f35';
  static const String gnosisUrl =
      'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
  static const String etherumUrl =
      'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
  static const String rmmUrl =
      'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
  static const String realTokensUrl =
      'https://pitswap-api.herokuapp.com/api/realTokens_mobileapps/';
  static const String rentTrackerUrl =
      'https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/';
  static const Duration cacheDuration = Duration(hours: 1);

  // Méthode factorisée pour fetch les tokens depuis The Graph
  static Future<List<dynamic>> fetchTokensFromUrl(String url, String cacheKey,
      {bool forceFetch = false}) async {
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
  static Future<List<dynamic>> fetchRealTokens(
      {bool forceFetch = false}) async {
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
  static Future<List<Map<String, dynamic>>> fetchRentData(
      {bool forceFetch = false}) async {
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
      await prefs.setInt(
          'cachedCurrenciesTime', currentTime); // Stocker l'heure actuelle

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
      final data = json.decode(response.body);
      final accounts = data['data']['accounts'];
      if (accounts != null && accounts.isNotEmpty) {
        return List<String>.from(accounts.map((account) => account['address']));
      }
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

    // Contrats pour USDC
    const String usdcDepositContract =
        '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1'; // Dépôt USDC
    const String usdcBorrowContract =
        '0x69c731ae5f5356a779f44c355abb685d84e5e9e6'; // Emprunt USDC

    // Contrats pour XDAI
    const String xdaiDepositContract =
        '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b'; // Dépôt XDAI
    const String xdaiBorrowContract =
        '0x9908801df7902675c3fedd6fea0294d18d5d5d34'; // Emprunt XDAI

    List<Map<String, dynamic>> allBalances = [];

    for (var address in evmAddresses) {
      // Requête pour le dépôt et l'emprunt de USDC
      final usdcDepositResponse =
          await _fetchBalance(usdcDepositContract, address);
      final usdcBorrowResponse =
          await _fetchBalance(usdcBorrowContract, address);

      // Requête pour le dépôt et l'emprunt de XDAI
      final xdaiDepositResponse =
          await _fetchBalance(xdaiDepositContract, address);
      final xdaiBorrowResponse =
          await _fetchBalance(xdaiBorrowContract, address);

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
  static Future<BigInt?> _fetchBalance(String contract, String address) async {
    final response = await http.post(
      Uri.parse('https://rpc.gnosischain.com'), // RPC Gnosis
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [
          {
            "to": contract, // Contrat à interroger
            "data":
                "0x70a08231000000000000000000000000${address.substring(2)}" // balanceOf(address)
          },
          "latest"
        ],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];

      if (result != null && result != "0x") {
        return BigInt.parse(result.substring(2), radix: 16);
      } else {
        print("Invalid response for contract $contract: $result");
      }
    } else {
      print(
          'Failed to fetch balance for contract $contract. Status code: ${response.statusCode}');
    }
    return null;
  }
}
