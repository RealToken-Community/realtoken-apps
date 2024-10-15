import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:logger/logger.dart';

class DataManager extends ChangeNotifier {
  static final logger = Logger();  // Initialiser une instance de logger

  // Variables partagées pour le Dashboard et Portfolio
  double totalValue = 0;
  double walletValue = 0;
  double rmmValue = 0;
  double rwaHoldingsValue = 0;
  int rentedUnits = 0;
  int totalUnits = 0;
  double totalTokens = 0.0;
  double walletTokensSums  = 0.0;
  double rmmTokensSums = 0.0;
  double averageAnnualYield = 0;
  double dailyRent = 0;
  double weeklyRent = 0;
  double monthlyRent = 0;
  double yearlyRent = 0;
  double conversionRate = 1.0; // Taux de conversion par défaut (USD)
  String currencySymbol = '\$'; // Symbole par défaut (USD)
  String selectedCurrency = 'usd'; // Devise par défaut
  Map<String, List<String>> userIdToAddresses = {};
  double totalUsdcDepositBalance = 0;
  double totalUsdcBorrowBalance = 0;
  double totalXdaiDepositBalance = 0;
  double totalXdaiBorrowBalance = 0;
  List<Map<String, dynamic>> rentData = [];
  List<Map<String, dynamic>> detailedRentData = [];
  List<Map<String, dynamic>> propertyData = [];
  List<Map<String, dynamic>> rmmBalances = [];

  // Ajout des variables pour compter les tokens dans le wallet et RMM
  int walletTokenCount = 0;
  int rmmTokenCount = 0;
  int totalTokenCount = 0;
  int duplicateTokenCount = 0;

  bool isLoading = true;

  List<Map<String, dynamic>> _allTokens = []; // Liste privée pour tous les tokens

  // Getter pour accéder à tous les tokens
  List<Map<String, dynamic>> get allTokens => _allTokens;

  // Portfolio data for PortfolioPage
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> get portfolio => _portfolio;

  // Ajout des données pour les mises à jour récentes
  List<Map<String, dynamic>> _recentUpdates = [];
  List<Map<String, dynamic>> get recentUpdates => _recentUpdates;
  // Initialisation des variables pour les données
  List<Map<String, dynamic>> walletTokensGnosis = [];
  List<Map<String, dynamic>> walletTokensEtherum = [];
  List<Map<String, dynamic>> rmmTokens = [];
  List<Map<String, dynamic>> realTokens = [];
  List<Map<String, dynamic>> tempRentData = [];

  final String rwaTokenAddress = '0x0675e8f4a52ea6c845cb6427af03616a2af42170';



  Future<void> updateGlobalVariables({bool forceFetch = false}) async {
  var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache
  
  try {
    // Mise à jour des données Gnosis
    var gnosisData = await ApiService.fetchTokensFromGnosis(forceFetch: forceFetch);
    if (gnosisData.isNotEmpty) {
      logger.i("Mise à jour des données Gnosis avec de nouvelles valeurs.");
      box.put('cachedTokenData_gnosis', json.encode(gnosisData));
      walletTokensGnosis = gnosisData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les résultats Gnosis sont vides, pas de mise à jour.");
    }

    // Mise à jour des données Ethereum
    var etherumData = await ApiService.fetchTokensFromEtherum(forceFetch: forceFetch);
    if (etherumData.isNotEmpty) {
      logger.i("Mise à jour des données Ethereum avec de nouvelles valeurs.");
      box.put('cachedTokenData_etherum', json.encode(etherumData));
      walletTokensEtherum = etherumData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les résultats Ethereum sont vides, pas de mise à jour.");
    }

    // Mise à jour des données RMM
    var rmmData = await ApiService.fetchRMMTokens(forceFetch: forceFetch);
    if (rmmData.isNotEmpty) {
      logger.i("Mise à jour des données RMM avec de nouvelles valeurs.");
      box.put('cachedRMMData', json.encode(rmmData));
      rmmTokens = rmmData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les résultats RMM sont vides, pas de mise à jour.");
    }

    // Mise à jour des RealTokens
    var realTokensData = await ApiService.fetchRealTokens(forceFetch: forceFetch);
    if (realTokensData.isNotEmpty) {
      logger.i("Mise à jour des RealTokens avec de nouvelles valeurs.");
      box.put('cachedRealTokens', json.encode(realTokensData));
      realTokens = realTokensData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les RealTokens sont vides, pas de mise à jour.");
    }

    // Mise à jour des RMM Balances
    var rmmBalancesData = await ApiService.fetchRmmBalances();
    if (rmmBalancesData.isNotEmpty) {
      logger.i("Mise à jour des RMM Balances avec de nouvelles valeurs.");
      box.put('rmmBalances', json.encode(rmmBalancesData));
      rmmBalances = rmmBalancesData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les RMM Balances sont vides, pas de mise à jour.");
    }

    // Mise à jour des données de loyer temporaires
    var rentData = await ApiService.fetchRentData(forceFetch: forceFetch);
    if (rentData.isNotEmpty) {
      logger.i("Mise à jour des données de loyer temporaires avec de nouvelles valeurs.");
      box.put('tempRentData', json.encode(rentData));
      tempRentData = rentData.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les données de loyer temporaires sont vides, pas de mise à jour.");
    }

  } catch (error) {
    logger.w("Erreur lors de la récupération des données: $error");
  }
}

 Future<void> updatedDetailRentVariables({bool forceFetch = false}) async {
  var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache
  
  try {

    // Mise à jour des détails de loyer détaillés
    var detailedRentDataResult = await ApiService.fetchDetailedRentDataForAllWallets();
    if (detailedRentDataResult.isNotEmpty) {
      logger.i("Mise à jour des détails de loyer avec de nouvelles valeurs.");
      box.put('detailedRentData', json.encode(detailedRentDataResult));
      detailedRentData = detailedRentDataResult.cast<Map<String, dynamic>>();
      notifyListeners(); // Notifier les listeners après la mise à jour
    } else {
      logger.d("Les détails de loyer sont vides, pas de mise à jour.");
    }


  } catch (error) {
    logger.w("Erreur lors de la récupération des données: $error");
  }
}




// Méthode pour ajouter des adresses à un userId
  void addAddressesForUserId(String userId, List<String> addresses) {
    if (userIdToAddresses.containsKey(userId)) {
      userIdToAddresses[userId]!.addAll(addresses);
    } else {
      userIdToAddresses[userId] = addresses;
    }
    saveUserIdToAddresses(); // Sauvegarder après modification
    notifyListeners();
  }

  // Sauvegarder la Map des userIds et adresses dans SharedPreferences
  Future<void> saveUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdToAddressesJson = userIdToAddresses.map((userId, addresses) {
      return MapEntry(
          userId, jsonEncode(addresses)); // Encoder les adresses en JSON
    });

    prefs.setString('userIdToAddresses', jsonEncode(userIdToAddressesJson));
  }

  // Charger les userIds et leurs adresses depuis SharedPreferences
  Future<void> loadUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('userIdToAddresses');

    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      userIdToAddresses = decodedMap.map((userId, encodedAddresses) {
        final addresses = List<String>.from(jsonDecode(encodedAddresses));
        return MapEntry(userId, addresses);
      });
    }
    notifyListeners();
  }

  // Supprimer une adresse spécifique
  void removeAddressForUserId(String userId, String address) {
    if (userIdToAddresses.containsKey(userId)) {
      userIdToAddresses[userId]!.remove(address);
      if (userIdToAddresses[userId]!.isEmpty) {
        userIdToAddresses
            .remove(userId); // Supprimer le userId si plus d'adresses
      }
      saveUserIdToAddresses(); // Sauvegarder après suppression
      notifyListeners();
    }
  }

  // Supprimer un userId et toutes ses adresses
  void removeUserId(String userId) {
    userIdToAddresses.remove(userId);
    saveUserIdToAddresses(); // Sauvegarder après suppression
    notifyListeners();
  }

  // Méthode pour récupérer les adresses associées à un userId
  List<String>? getAddressesForUserId(String userId) {
    return userIdToAddresses[userId];
  }

  // Méthode pour obtenir tous les userIds
  List<String> getAllUserIds() {
    return userIdToAddresses.keys.toList();
  }

  // Dictionnaire des symboles de devises
  final Map<String, String> _currencySymbols = {
    'usd': '\$', 'eur': '€', 'gbp': '£', 'jpy': '¥', 'inr': '₹', 'btc': '₿', 'eth': 'Ξ', // Ajouter plus de devises selon vos besoins
  };

 

 Future<void> fetchAndStoreAllTokens() async {
  var box = Hive.box('realTokens');

    final cachedRealTokens = box.get('cachedRealTokens');
  if (cachedRealTokens != null) {
    realTokens = List<Map<String, dynamic>>.from(json.decode(cachedRealTokens));
    logger.i("Données RealTokens en cache utilisées.");
  }
  List<Map<String, dynamic>> allTokensList = [];

  // Si des tokens existent, les ajouter à la liste des tokens
  if (realTokens.isNotEmpty) {
    _recentUpdates = _extractRecentUpdates(realTokens);
    for (var realToken in realTokens.cast<Map<String, dynamic>>()) {
      // Vérification: Ne pas ajouter si totalTokens est 0 ou si fullName commence par "OLD-"
      if (realToken['totalTokens'] != null && realToken['totalTokens'] > 0 &&
          realToken['fullName'] != null && !realToken['fullName'].startsWith('OLD-')) {
        allTokensList.add({
          'shortName': realToken['shortName'],
          'fullName': realToken['fullName'],
          'imageLink': realToken['imageLink'],
          'lat': realToken['coordinate']['lat'],
          'lng': realToken['coordinate']['lng'],
          'totalTokens': realToken['totalTokens'],
          'tokenPrice': realToken['tokenPrice'],
          'totalValue': realToken['totalInvestment'],
          'annualPercentageYield': realToken['annualPercentageYield'],
          'dailyIncome': realToken['netRentDayPerToken'] * realToken['totalTokens'],
          'monthlyIncome': realToken['netRentMonthPerToken'] * realToken['totalTokens'],
          'yearlyIncome': realToken['netRentYearPerToken'] * realToken['totalTokens'],
          'initialLaunchDate': realToken['initialLaunchDate']?['date'],
          'totalInvestment': realToken['totalInvestment'],
          'underlyingAssetPrice': realToken['underlyingAssetPrice'],
          'initialMaintenanceReserve': realToken['initialMaintenanceReserve'],
          'rentalType': realToken['rentalType'],
          'rentStartDate': realToken['rentStartDate']?['date'],
          'rentedUnits': realToken['rentedUnits'],
          'totalUnits': realToken['totalUnits'],
          'grossRentMonth': realToken['grossRentMonth'],
          'netRentMonth': realToken['netRentMonth'],
          'constructionYear': realToken['constructionYear'],
          'propertyStories': realToken['propertyStories'],
          'lotSize': realToken['lotSize'],
          'squareFeet': realToken['squareFeet'],
          'marketplaceLink': realToken['marketplaceLink'],
          'propertyType': realToken['propertyType'],
          'historic': realToken['historic'],
          'ethereumContract': realToken['ethereumContract'],
          'gnosisContract': realToken['gnosisContract'],
          'totalRentReceived': 0.0, // Ajout du loyer total reçu
        });
      }
    }
  }

  // Mettre à jour la liste des tokens
  _allTokens = allTokensList;
  logger.i("Tokens récupérés: ${allTokensList.length}"); // Vérifiez que vous obtenez bien des tokens

  // Notifie les widgets que les données ont changé
  notifyListeners();
}



  // Méthode pour récupérer et calculer les données pour le Dashboard et Portfolio
  Future<void> fetchAndCalculateData({bool forceFetch = false}) async {
   logger.i("Début de la récupération des données de tokens...");

  var box = Hive.box('realTokens');

  // Charger les données en cache si disponibles
  final cachedGnosisTokens = box.get('cachedTokenData_gnosis');
  if (cachedGnosisTokens != null) {
    walletTokensGnosis = List<Map<String, dynamic>>.from(json.decode(cachedGnosisTokens));
    logger.i("Données Gnosis en cache utilisées.");
  }

  final cachedEtherumTokens = box.get('cachedTokenData_ethereum');
  if (cachedEtherumTokens != null) {
    walletTokensEtherum = List<Map<String, dynamic>>.from(json.decode(cachedEtherumTokens));
    logger.i("Données Etherum en cache utilisées.");
  }

  final cachedRMMTokens = box.get('cachedRMMData');
  if (cachedRMMTokens != null) {
    rmmTokens = List<Map<String, dynamic>>.from(json.decode(cachedRMMTokens));
    logger.i("Données RMM en cache utilisées.");
  }

  final cachedRealTokens = box.get('cachedRealTokens');
  if (cachedRealTokens != null) {
    realTokens = List<Map<String, dynamic>>.from(json.decode(cachedRealTokens));
    logger.i("Données RealTokens en cache utilisées.");
  }

  final cachedDetailedRentData = box.get('detailedRentData');
  if (cachedDetailedRentData != null) {
    detailedRentData = List<Map<String, dynamic>>.from(json.decode(cachedDetailedRentData));
    logger.i("Données Rent en cache utilisées.");
  }

    // Fusionner les tokens de Gnosis et d'Etherum
    final walletTokens = [...walletTokensGnosis, ...walletTokensEtherum];

    // Vérifier les données récupérées et loguer si elles sont vides
    if (walletTokensGnosis.isEmpty) {
      logger.i("Aucun wallet récupéré depuis Gnosis.");
    } else {
      logger.i("Nombre de wallets récupérés depuis Gnosis: ${walletTokensGnosis.length}");
    }

    if (walletTokensEtherum.isEmpty) {
      logger.i("Aucun wallet récupéré depuis Etherum.");
    } else {
      logger.i("Nombre de wallets récupérés depuis Etherum: ${walletTokensEtherum.length}");
    }

    if (rmmTokens.isEmpty) {
      logger.i("Aucun token dans le RMM.");
    } else {
      logger.i("Nombre de tokens dans le RMM récupérés: ${rmmTokens.length}");
    }

    if (realTokens.isEmpty) {
      logger.i("Aucun RealToken trouvé.");
    } else {
      logger.i("Nombre de RealTokens récupérés: ${realTokens.length}");
    }

    // Variables temporaires pour calculer les valeurs
    double walletValueSum = 0;
    double rmmValueSum = 0;
    double rwaValue = 0;
    double walletTokensSum = 0;
    double rmmTokensSum = 0;
    double annualYieldSum = 0;
    double dailyRentSum = 0;
    double monthlyRentSum = 0;
    double yearlyRentSum = 0;
    int yieldCount = 0;
    List<Map<String, dynamic>> newPortfolio = [];

    // Réinitialisation des compteurs de tokens et unités
    walletTokenCount = 0;
    rmmTokenCount = 0;
    rentedUnits = 0;
    totalUnits = 0;

    // Utilisation des ensembles pour stocker les adresses uniques
    Set<String> uniqueWalletTokens = {};
    Set<String> uniqueRmmTokens = {};
    Set<String> globalUniqueTokens = {}; // Pour stocker les tokens uniques globaux
    Set<String> uniqueRentedUnitAddresses = {}; // Pour stocker les adresses uniques avec unités louées
    Set<String> uniqueTotalUnitAddresses ={}; // Pour stocker les adresses uniques avec unités totales

    // **Itérer sur chaque wallet** pour récupérer tous les tokens
    for (var wallet in walletTokens) {
      final walletBalances = wallet['balances'];

      // Process wallet tokens (pour Dashboard et Portfolio)
      for (var walletToken in walletBalances) {
        final tokenAddress = walletToken['token']['address'].toLowerCase();
        uniqueWalletTokens
            .add(tokenAddress); // Ajouter à l'ensemble des tokens uniques

        final matchingRealToken =
            realTokens.cast<Map<String, dynamic>>().firstWhere(
                  (realToken) =>
                      realToken['uuid'].toLowerCase() == tokenAddress,
                  orElse: () => <String, dynamic>{},
                );

        if (matchingRealToken.isNotEmpty) {
          final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
          final double tokenValue = (double.parse(walletToken['amount']) * tokenPrice) ?? 0.0;

          // Compter les unités louées et totales si elles n'ont pas déjà été comptées
          if (!uniqueRentedUnitAddresses.contains(tokenAddress)) {
            rentedUnits += (matchingRealToken['rentedUnits'] ?? 0) as int;
            uniqueRentedUnitAddresses.add(tokenAddress); // Marquer cette adresse comme comptée pour les unités louées
          }
          if (!uniqueTotalUnitAddresses.contains(tokenAddress)) {
            totalUnits += (matchingRealToken['totalUnits'] ?? 0) as int;
            uniqueTotalUnitAddresses.add(tokenAddress); // Marquer cette adresse comme comptée pour les unités totales
          }

          if (tokenAddress == rwaTokenAddress.toLowerCase()) {
            rwaValue += tokenValue;
          } else {
            walletValueSum += tokenValue;
            walletTokensSum += double.parse(walletToken['amount']);

            // Récupérer la date d'aujourd'hui
            final today = DateTime.now();

            // Convertir la chaîne de date 'initialLaunchDate' en objet DateTime
            final launchDateString = matchingRealToken['rentStartDate']?['date'];
            if (launchDateString != null) {
              final launchDate = DateTime.tryParse(launchDateString);

              // Comparer la date de lancement avec aujourd'hui
              if (launchDate != null && launchDate.isBefore(today)) {
                // Ajouter uniquement si la date de lancement est dans le passé
                annualYieldSum += matchingRealToken['annualPercentageYield'];
                yieldCount++;
                dailyRentSum += matchingRealToken['netRentDayPerToken'] * double.parse(walletToken['amount']);
                monthlyRentSum += matchingRealToken['netRentMonthPerToken'] * double.parse(walletToken['amount']);
                yearlyRentSum += matchingRealToken['netRentYearPerToken'] * double.parse(walletToken['amount']);
              }
            }

          
          }
           double totalRentReceived = 0.0;
        final tokenContractAddress = matchingRealToken['uuid'] ?? ''; // Utiliser l'adresse du contrat du token
       
          // Ajouter au Portfolio
          newPortfolio.add({
            'id': matchingRealToken['id'],
            'shortName': matchingRealToken['shortName'],
            'fullName': matchingRealToken['fullName'],
            'imageLink': matchingRealToken['imageLink'],
            'lat': matchingRealToken['coordinate']['lat'],
            'lng': matchingRealToken['coordinate']['lng'],
            'amount': walletToken['amount'],
            'totalTokens': matchingRealToken['totalTokens'],
            'source': 'Wallet',
            'tokenPrice': tokenPrice,
            'totalValue': tokenValue,
            'annualPercentageYield': matchingRealToken['annualPercentageYield'],
            'dailyIncome': matchingRealToken['netRentDayPerToken'] * double.parse(walletToken['amount']),
            'monthlyIncome': matchingRealToken['netRentMonthPerToken'] * double.parse(walletToken['amount']),
            'yearlyIncome': matchingRealToken['netRentYearPerToken'] * double.parse(walletToken['amount']),
            'initialLaunchDate': matchingRealToken['initialLaunchDate'] ?['date'],
            'totalInvestment': matchingRealToken['totalInvestment'],
            'underlyingAssetPrice': matchingRealToken['underlyingAssetPrice'],
            'initialMaintenanceReserve': matchingRealToken['initialMaintenanceReserve'],
            'rentalType': matchingRealToken['rentalType'],
            'rentStartDate': matchingRealToken['rentStartDate']?['date'],
            'rentedUnits': matchingRealToken['rentedUnits'],
            'totalUnits': matchingRealToken['totalUnits'],
            'grossRentMonth': matchingRealToken['grossRentMonth'],
            'netRentMonth': matchingRealToken['netRentMonth'],
            'constructionYear': matchingRealToken['constructionYear'],
            'propertyStories': matchingRealToken['propertyStories'],
            'lotSize': matchingRealToken['lotSize'],
            'squareFeet': matchingRealToken['squareFeet'],
            'marketplaceLink': matchingRealToken['marketplaceLink'],
            'propertyType': matchingRealToken['propertyType'],
            'historic': matchingRealToken['historic'],
            'ethereumContract': matchingRealToken['ethereumContract'],
            'gnosisContract': matchingRealToken['gnosisContract'],
            'totalRentReceived': totalRentReceived, // Ajout du loyer total reçu
          });

         if (tokenContractAddress.isNotEmpty) {
           // Récupérer les informations de loyer pour ce token
        double? rentDetails = getRentDetailsForToken(tokenContractAddress);

        double totalRentReceived = rentDetails;

        // Une fois les données récupérées, mettre à jour l'élément du portfolio correspondant
        final portfolioItem = newPortfolio.firstWhere(
          (item) => item['shortName'] == matchingRealToken['shortName'], 
          orElse: () => {},
        );

        portfolioItem['totalRentReceived'] = totalRentReceived;
              
        // Notifiez les listeners après avoir mis à jour le portfolio
        notifyListeners();
      }


        }
      }
    }

    // Process tokens dans le RMM (similaire au processus wallet)
    for (var rmmToken in rmmTokens) {
      final tokenAddress = rmmToken['token']['id'].toLowerCase();
      uniqueRmmTokens.add(tokenAddress); // Ajouter à l'ensemble des tokens uniques

      final matchingRealToken =
          realTokens.cast<Map<String, dynamic>>().firstWhere(
                (realToken) => realToken['uuid'].toLowerCase() == tokenAddress,
                orElse: () => <String, dynamic>{},
              );

      if (matchingRealToken.isNotEmpty) {
        final BigInt rawAmount = BigInt.parse(rmmToken['amount']);
        final int decimals = matchingRealToken['decimals'] ?? 18;
        final double amount = rawAmount / BigInt.from(10).pow(decimals);
        final double tokenPrice = matchingRealToken['tokenPrice'];
        rmmValueSum += amount * tokenPrice;
        rmmTokensSum += amount;

        // Compter les unités louées et totales si elles n'ont pas déjà été comptées
        if (!uniqueRentedUnitAddresses.contains(tokenAddress)) {
          rentedUnits += (matchingRealToken['rentedUnits'] ?? 0) as int;
          uniqueRentedUnitAddresses.add(tokenAddress); // Marquer cette adresse comme comptée pour les unités louées
        }
        if (!uniqueTotalUnitAddresses.contains(tokenAddress)) {
          totalUnits += (matchingRealToken['totalUnits'] ?? 0) as int;
          uniqueTotalUnitAddresses.add(tokenAddress); // Marquer cette adresse comme comptée pour les unités totales
        }

        // Récupérer la date d'aujourd'hui
        final today = DateTime.now();

        // Convertir la chaîne de date 'initialLaunchDate' en objet DateTime
        final launchDateString = matchingRealToken['initialLaunchDate']?['date'];
        if (launchDateString != null) {
          final launchDate = DateTime.tryParse(launchDateString);

          // Comparer la date de lancement avec aujourd'hui
          if (launchDate != null && launchDate.isBefore(today)) {
            // Ajouter uniquement si la date de lancement est dans le passé
            annualYieldSum += matchingRealToken['annualPercentageYield'];
            yieldCount++;
            dailyRentSum += matchingRealToken['netRentDayPerToken'] * amount;
            monthlyRentSum += matchingRealToken['netRentMonthPerToken'] * amount;
            yearlyRentSum += matchingRealToken['netRentYearPerToken'] * amount;
          }
        }

        double totalRentReceived = 0.0;
        final tokenContractAddress = matchingRealToken['uuid'] ?? ''; // Utiliser l'adresse du contrat du token

        // Ajouter au Portfolio
        newPortfolio.add({
          'id': matchingRealToken['id'],
          'shortName': matchingRealToken['shortName'],
          'fullName': matchingRealToken['fullName'],
          'imageLink': matchingRealToken['imageLink'],
          'lat': matchingRealToken['coordinate']['lat'],
          'lng': matchingRealToken['coordinate']['lng'],
          'amount': amount,
          'totalTokens': matchingRealToken['totalTokens'],
          'walletTokensSum': matchingRealToken['walletTokensSum'],
          'source': 'RMM',
          'tokenPrice': tokenPrice,
          'totalValue': amount * tokenPrice,
          'annualPercentageYield': matchingRealToken['annualPercentageYield'],
          'dailyIncome': matchingRealToken['netRentDayPerToken'] * amount,
          'monthlyIncome': matchingRealToken['netRentMonthPerToken'] * amount,
          'yearlyIncome': matchingRealToken['netRentYearPerToken'] * amount,
          'initialLaunchDate': matchingRealToken['initialLaunchDate']?['date'],
          'totalInvestment': matchingRealToken['totalInvestment'],
          'underlyingAssetPrice': matchingRealToken['underlyingAssetPrice'],
          'initialMaintenanceReserve': matchingRealToken['initialMaintenanceReserve'],
          'rentalType': matchingRealToken['rentalType'],
          'rentStartDate': matchingRealToken['rentStartDate']?['date'],
          'rentedUnits': matchingRealToken['rentedUnits'],
          'totalUnits': matchingRealToken['totalUnits'],
          'grossRentMonth': matchingRealToken['grossRentMonth'],
          'netRentMonth': matchingRealToken['netRentMonth'],
          'constructionYear': matchingRealToken['constructionYear'],
          'propertyStories': matchingRealToken['propertyStories'],
          'lotSize': matchingRealToken['lotSize'],
          'squareFeet': matchingRealToken['squareFeet'],
          'marketplaceLink': matchingRealToken['marketplaceLink'],
          'propertyType': matchingRealToken['propertyType'],
          'historic': matchingRealToken['historic'],
          'ethereumContract': matchingRealToken['ethereumContract'],
          'gnosisContract': matchingRealToken['gnosisContract'],
          'totalRentReceived': totalRentReceived, // Ajout du loyer total reçu
        });
        
         if (tokenContractAddress.isNotEmpty) {
           // Récupérer les informations de loyer pour ce token
        double? rentDetails = getRentDetailsForToken(tokenContractAddress);

        double totalRentReceived = rentDetails;

        // Une fois les données récupérées, mettre à jour l'élément du portfolio correspondant
        final portfolioItem = newPortfolio.firstWhere(
          (item) => item['shortName'] == matchingRealToken['shortName'], 
          orElse: () => {},
        );

        portfolioItem['totalRentReceived'] = totalRentReceived;
              
        // Notifiez les listeners après avoir mis à jour le portfolio
        notifyListeners();
      }

      }
    }

    // Mise à jour des variables pour le Dashboard
    totalValue = walletValueSum +
        rmmValueSum +
        rwaValue +
        totalUsdcDepositBalance +
        totalXdaiDepositBalance -
        totalUsdcBorrowBalance -
        totalXdaiBorrowBalance;
    walletValue = walletValueSum;
    rmmValue = rmmValueSum;
    rwaHoldingsValue = rwaValue;
    walletTokensSums = walletTokensSum;
    rmmTokensSums = rmmTokensSum;
    totalTokens = (walletTokensSum + rmmTokensSum);
    averageAnnualYield = yieldCount > 0 ? annualYieldSum / yieldCount : 0;
    dailyRent = dailyRentSum;
    weeklyRent = dailyRentSum * 7;
    monthlyRent = monthlyRentSum;
    yearlyRent = yearlyRentSum;

   // Compter les tokens uniques pour wallet et RMM
    walletTokenCount = uniqueWalletTokens.length;
    rmmTokenCount = uniqueRmmTokens.length;

    // Crée des sets pour contenir les tokens uniques
    final Set<String> walletTokensSet = uniqueWalletTokens.toSet();
    final Set<String> rmmTokensSet = uniqueRmmTokens.toSet();
    final Set<String> allUniqueTokens = {...walletTokensSet, ...rmmTokensSet};

    // Comptabilise le nombre de tokens uniques
    totalTokenCount = allUniqueTokens.length;

    // Trouve l'intersection des deux ensembles (tokens présents dans les deux sets)
    final Set<String> duplicateTokens = walletTokensSet.intersection(rmmTokensSet);

    // Comptabilise le nombre de tokens en doublons
    duplicateTokenCount = duplicateTokens.length;



    // Mise à jour des données pour le Portfolio
    _portfolio = newPortfolio;

    logger.i("Portfolio mis à jour avec ${_portfolio.length} éléments.");
    logger.i("Unité louées uniques: $rentedUnits, Unités totales uniques: $totalUnits");

    // Notify listeners that data has changed
    notifyListeners();
  

  }
  
// Méthode pour afficher l'évolution des loyers cumulés jusqu'à chaque 'rentStartDate'
List<Map<String, dynamic>> getCumulativeRentEvolution() {
  List<Map<String, dynamic>> cumulativeRentList = [];
  double cumulativeRent = 0.0;

  // Trier les données de `_portfolio` par 'rentStartDate'
  _portfolio.sort((a, b) {
    DateTime dateA = a['rentStartDate'] != null
        ? DateTime.parse(a['rentStartDate'])
        : DateTime.now(); // Utiliser DateTime.now() ou une autre valeur par défaut si null
    DateTime dateB = b['rentStartDate'] != null
        ? DateTime.parse(b['rentStartDate'])
        : DateTime.now(); // Utiliser DateTime.now() ou une autre valeur par défaut si null
    return dateA.compareTo(dateB);
  });

  // Parcourir chaque élément de `_portfolio` et accumuler les loyers
  for (var portfolioEntry in _portfolio) {
    if (portfolioEntry['rentStartDate'] != null) {
      DateTime rentStartDate = DateTime.parse(portfolioEntry['rentStartDate']);

      // Ajoutez la valeur de loyer au cumul jusqu'à cette date
      cumulativeRent += (portfolioEntry['dailyIncome'] * 7) ?? 0.0;

      // Ajoutez cette entrée à la liste des loyers cumulés (peu importe la date)
      cumulativeRentList.add({
        'rentStartDate': rentStartDate,
        'cumulativeRent': cumulativeRent,
      });
    }
  }

  return cumulativeRentList;
}

  // Méthode pour extraire les mises à jour récentes sur les 30 derniers jours

  List<Map<String, dynamic>> _extractRecentUpdates(
      List<dynamic> realTokensRaw) {
    final List<Map<String, dynamic>> realTokens =
        realTokensRaw.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> recentUpdates = [];

    for (var token in realTokens) {
      // Vérification si update30 existe, est une liste et est non vide
      if (token.containsKey('update30') &&
          token['update30'] is List &&
          token['update30'].isNotEmpty) {
        logger.i(
            "Processing updates for token: ${token['shortName'] ?? 'Nom inconnu'}");

        // Récupérer les informations de base du token
        final String shortName = token['shortName'] ?? 'Nom inconnu';
        final String imageLink =
            (token['imageLink'] != null && token['imageLink'].isNotEmpty)
                ? token['imageLink'][0]
                : 'Lien d\'image non disponible';

        // Filtrer et formater les mises à jour pertinentes
        List<Map<String, dynamic>> updatesWithDetails =
            List<Map<String, dynamic>>.from(token['update30'])
                .where((update) =>
                    update.containsKey('key') &&
                    _isRelevantKey(update['key'])) // Vérifier que 'key' existe
                .map((update) => _formatUpdateDetails(
                    update, shortName, imageLink)) // Formater les détails
                .toList();

        // Ajouter les mises à jour extraites dans recentUpdates
        recentUpdates.addAll(updatesWithDetails);
      } else {
        logger.i(
            'Aucune mise à jour pour le token : ${token['shortName'] ?? 'Nom inconnu'}');
      }
    }

    // Trier les mises à jour par date
    recentUpdates.sort((a, b) =>
        DateTime.parse(b['timsync']).compareTo(DateTime.parse(a['timsync'])));
    return recentUpdates;
  }

// Vérifier les clés pertinentes
  bool _isRelevantKey(String key) {
    return key == 'netRentYearPerToken' || key == 'annualPercentageYield';
  }

// Formater les détails des mises à jour
  Map<String, dynamic> _formatUpdateDetails(
      Map<String, dynamic> update, String shortName, String imageLink) {
    String formattedKey = 'Donnée inconnue';
    String formattedOldValue = 'Valeur inconnue';
    String formattedNewValue = 'Valeur inconnue';

    // Vérifiez que les clés existent avant de les utiliser
    if (update['key'] == 'netRentYearPerToken') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Net Rent Per Token (Annuel)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)} USD";
      formattedNewValue = "${newValue.toStringAsFixed(2)} USD";
    } else if (update['key'] == 'annualPercentageYield') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Rendement Annuel (%)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)}%";
      formattedNewValue = "${newValue.toStringAsFixed(2)}%";
    }

    return {
      'shortName': shortName,
      'formattedKey': formattedKey,
      'formattedOldValue': formattedOldValue,
      'formattedNewValue': formattedNewValue,
      'timsync': update['timsync'] ?? '', // Assurez-vous que 'timsync' existe
      'imageLink': imageLink,
    };
  }

  // Méthode pour récupérer les données des loyers
Future<void> fetchRentData({bool forceFetch = false}) async {
  var box = Hive.box('realTokens');

  // Charger les données en cache si disponibles
  final cachedRentData = box.get('cachedRentData');
  if (cachedRentData != null) {
    rentData = List<Map<String, dynamic>>.from(json.decode(cachedRentData));
    logger.i("Données rentData en cache utilisées.");
  }
  Future(() async {
    try {
      // Exécuter l'appel d'API pour récupérer les données de loyer

      // Vérifier si les résultats ne sont pas vides avant de mettre à jour les variables
      if (tempRentData.isNotEmpty) {
        logger.i("Mise à jour des données de rentData avec de nouvelles valeurs.");
        rentData = tempRentData;  // Mise à jour de la variable locale
        box.put('cachedRentData', json.encode(tempRentData));

      } else {
        logger.d("Les résultats des données de rentData sont vides, pas de mise à jour.");
      }

    } catch (e) {
      logger.e("Erreur lors de la récupération des données de loyer: $e");
    }
  }).then((_) {
  notifyListeners();  // Notifier les listeners une fois les données mises à jour
});
}


  // Méthode pour récupérer les données des propriétés
  Future<void> fetchPropertyData({bool forceFetch = false}) async {
          List<Map<String, dynamic>> tempPropertyData = [];

      // Fusionner les tokens de Gnosis et d'Etherum
      final walletTokens = [...walletTokensGnosis, ...walletTokensEtherum];

      // Fusionner les tokens du portefeuille (Gnosis, Ethereum) et du RMM
      List<dynamic> allTokens = [];
      for (var wallet in walletTokens) {
        allTokens.addAll(wallet['balances']); // Ajouter tous les balances des wallets
      }
      allTokens.addAll(rmmTokens); // Ajouter les tokens du RMM

      // Parcourir chaque token du portefeuille et du RMM
      for (var token in allTokens) {
        if (token != null &&
            token['token'] != null &&
            token['token']['address'] != null) {
          final tokenAddress = token['token']['address'].toLowerCase();

          // Correspondre avec les RealTokens
          final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
            (realToken) => realToken['uuid'].toLowerCase() == tokenAddress.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          if (matchingRealToken.isNotEmpty && matchingRealToken['propertyType'] != null) {
            final propertyType = matchingRealToken['propertyType'];

            // Vérifiez si le type de propriété existe déjà dans propertyData
            final existingPropertyType = tempPropertyData.firstWhere(
              (data) => data['propertyType'] == propertyType,
              orElse: () => <String, dynamic>{}, // Renvoie un map vide si aucune correspondance n'est trouvée
            );

            if (existingPropertyType.isNotEmpty) {
              // Incrémenter le compte si la propriété existe déjà
              existingPropertyType['count'] += 1;
            } else {
              // Ajouter une nouvelle entrée si la propriété n'existe pas encore
              tempPropertyData.add({'propertyType': propertyType, 'count': 1});
            }
          }
        } else {
          //logger.i('Invalid token or missing address for token: $token');
        }
      }

      propertyData = tempPropertyData;
   
    notifyListeners();
  }
  
  // Méthode pour réinitialiser toutes les données
  Future<void> resetData() async {
    // Remettre toutes les variables à leurs valeurs initiales
    totalValue = 0;
    walletValue = 0;
    rmmValue = 0;
    rwaHoldingsValue = 0;
    rentedUnits = 0;
    totalUnits = 0;
    totalTokens = 0;
    walletTokensSums = 0.0;
    rmmTokensSums = 0.0;
    averageAnnualYield = 0;
    dailyRent = 0;
    weeklyRent = 0;
    monthlyRent = 0;
    yearlyRent = 0;

    // Vider les listes de données
    rentData = [];
    propertyData = [];
    _portfolio = [];
    _recentUpdates = [];

    // Réinitialiser les compteurs
    walletTokenCount = 0;
    rmmTokenCount = 0;
    totalTokenCount = 0;
    duplicateTokenCount = 0;

    // Notifier les observateurs que les données ont été réinitialisées
    notifyListeners();

    // Supprimer également les préférences sauvegardées si nécessaire
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Si vous voulez vider toutes les préférences
  }

// Méthode pour mettre à jour le taux de conversion et le symbole
Future<void> updateConversionRate(
  String currency, 
  String selectedCurrency, 
  Map<String, dynamic> currencies,
) async {
  selectedCurrency = currency; // Mettez à jour la devise sélectionnée

  if (selectedCurrency == "usd") {
    conversionRate = 1.0; // Forcer le taux à 1 pour USD
  } else if (currencies.containsKey(selectedCurrency)) {
    // Récupérez le taux de conversion, ou 1.0 si absent
    conversionRate = currencies[selectedCurrency] is double 
        ? currencies[selectedCurrency] 
        : 1.0;
  } else {
    conversionRate = 1.0; // Par défaut, utiliser 1.0 (si devise inconnue)
  }

  // Mettre à jour le symbole de la devise, ou utiliser les 3 lettres si le symbole est absent
  currencySymbol = _currencySymbols[selectedCurrency] ?? 
      selectedCurrency.toUpperCase(); // Utiliser les lettres de la devise si le symbole est absent

  notifyListeners(); // Notifiez les écouteurs que quelque chose a changé
}


  Future<void> loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';

    final currencies = await ApiService.fetchCurrencies();

    // Appeler updateConversionRate avec les trois paramètres nécessaires
    await updateConversionRate(selectedCurrency, selectedCurrency, currencies);
  }

  // Exemple de conversion
  double convert(double valueInUsd) {
    return valueInUsd * conversionRate;
  }

// Nouvelle méthode pour récupérer les balances RMM
  Future<void> fetchRmmBalances() async {
    try {
      // Récupérer les balances de l'API

      double usdcDepositSum = 0;
      double usdcBorrowSum = 0;
      double xdaiDepositSum = 0;
      double xdaiBorrowSum = 0;

      for (var balance in rmmBalances) {
        // Vérifier si les valeurs existent avant de les traiter
        double usdcDepositBalance = balance['usdcDepositBalance'] != null
            ? double.parse(balance['usdcDepositBalance']) / (1e6)
            : 0;

        double usdcBorrowBalance = balance['usdcBorrowBalance'] != null
            ? double.parse(balance['usdcBorrowBalance']) / (1e6)
            : 0;

        double xdaiDepositBalance = balance['xdaiDepositBalance'] != null
            ? double.parse(balance['xdaiDepositBalance']) / (1e18)
            : 0;

        double xdaiBorrowBalance = balance['xdaiBorrowBalance'] != null
            ? double.parse(balance['xdaiBorrowBalance']) / (1e18)
            : 0;

        // Ajouter les balances à la somme totale
        usdcDepositSum += usdcDepositBalance;
        usdcBorrowSum += usdcBorrowBalance;
        xdaiDepositSum += xdaiDepositBalance;
        xdaiBorrowSum += xdaiBorrowBalance;
      }

      // Stocker les balances agrégées dans les variables
      totalUsdcDepositBalance = usdcDepositSum;
      totalUsdcBorrowBalance = usdcBorrowSum;
      totalXdaiDepositBalance = xdaiDepositSum;
      totalXdaiBorrowBalance = xdaiBorrowSum;

      notifyListeners(); // Notifier l'interface que les données ont été mises à jour
    } catch (e) {
      logger.i('Error fetching RMM balances: $e');
    }
  }

  double getTotalRentReceived() {
      return rentData.fold(0.0, (total, rentEntry) => total + rentEntry['rent']);
  }

double getRentDetailsForToken(String token) {
    double totalRent = 0.0;

    // Parcourir chaque entrée de la liste detailedRentData
    for (var entry in detailedRentData) {
      // Vérifie si l'entrée contient une liste de 'rents'
      if (entry.containsKey('rents') && entry['rents'] is List) {
        List rents = entry['rents'];

        // Parcourir chaque élément de la liste des loyers
        for (var rentEntry in rents) {
          if (rentEntry['token'] != null && rentEntry['token'].toLowerCase() == token.toLowerCase()) {
            // Ajoute le rent à totalRent si le token correspond
            totalRent += (rentEntry['rent'] ?? 0.0).toDouble();
          }
        }
      }
    }

    return totalRent;
  }
}
