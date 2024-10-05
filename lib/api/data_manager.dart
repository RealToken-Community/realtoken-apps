import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class DataManager extends ChangeNotifier {
  // Variables partagées pour le Dashboard et Portfolio
  double totalValue = 0;
  double walletValue = 0;
  double rmmValue = 0;
  double rwaHoldingsValue = 0;
  int rentedUnits = 0;
  int totalUnits = 0;
  int totalTokens = 0;
  double walletTokensSums = 0;
  double rmmTokensSums = 0;
  double averageAnnualYield = 0;
  double dailyRent = 0;
  double weeklyRent = 0;
  double monthlyRent = 0;
  double yearlyRent = 0;
  double conversionRate = 1.0; // Taux de conversion par défaut (USD)
  String currencySymbol = '\$'; // Symbole par défaut (USD)
  String selectedCurrency = 'usd'; // Devise par défaut

  // Dictionnaire des symboles de devises
  final Map<String, String> _currencySymbols = {
    'usd': '\$', 'eur': '€', 'gbp': '£', 'jpy': '¥', 'inr': '₹', 
    'btc': '₿', 'eth': 'Ξ', // Ajouter plus de devises selon vos besoins
  };

  // Variables pour stocker les données de loyers et de propriétés
  List<Map<String, dynamic>> rentData = [];
  List<Map<String, dynamic>> propertyData = [];

  // Ajout des variables pour compter les tokens dans le wallet et RMM
  int walletTokenCount = 0;
  int rmmTokenCount = 0;

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

  final String rwaTokenAddress = '0x0675e8f4a52ea6c845cb6427af03616a2af42170';

Future<void> fetchAndStoreAllTokens() async {
  final realTokens = await ApiService.fetchRealTokens(); // Garder realTokens en List<dynamic>

  List<Map<String, dynamic>> allTokensList = [];

  // Si des tokens existent, les ajouter à la liste des tokens
  if (realTokens.isNotEmpty) {
    for (var realToken in realTokens.cast<Map<String, dynamic>>()) {
      allTokensList.add({
        'shortName': realToken['shortName'],
        'fullName': realToken['fullName'],
        'imageLink': realToken['imageLink'][0],
        'amount': realToken['totalTokens'].toString(),  // Affiche le total des tokens disponibles
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
      });
    }
  }

  // Mettre à jour la liste des tokens
  _allTokens = allTokensList;

  // Notifie les widgets que les données ont changé
  notifyListeners();
}

  // Méthode pour récupérer et calculer les données pour le Dashboard et Portfolio
Future<void> fetchAndCalculateData({bool forceFetch = false}) async {
  print("Début de la récupération des données de tokens...");

  final walletTokensGnosis = await ApiService.fetchTokensFromGnosis(forceFetch: forceFetch);
  final walletTokensEtherum = await ApiService.fetchTokensFromEtherum(forceFetch: forceFetch);
  final rmmTokens = await ApiService.fetchRMMTokens(forceFetch: forceFetch);
  final realTokens = await ApiService.fetchRealTokens(forceFetch: forceFetch);

// Fusionner les tokens de Gnosis et d'Etherum
  final walletTokens = [...walletTokensGnosis, ...walletTokensEtherum];

  // Vérifier les données récupérées et loguer si elles sont vides
  if (walletTokensGnosis.isEmpty) {
    print("Aucun wallet récupéré depuis Gnosis.");
  } else {
    print("Nombre de wallets récupérés depuis Gnosis: ${walletTokensGnosis.length}");
  }

  if (walletTokensEtherum.isEmpty) {
    print("Aucun wallet récupéré depuis Etherum.");
  } else {
    print("Nombre de wallets récupérés depuis Etherum: ${walletTokensEtherum.length}");
  }

  if (rmmTokens.isEmpty) {
    print("Aucun token dans le RMM.");
  } else {
    print("Nombre de tokens dans le RMM récupérés: ${rmmTokens.length}");
  }

  if (realTokens.isEmpty) {
    print("Aucun RealToken trouvé.");
  } else {
    print("Nombre de RealTokens récupérés: ${realTokens.length}");
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
  Set<String> uniqueRentedUnitAddresses = {}; // Pour stocker les adresses uniques avec unités louées
  Set<String> uniqueTotalUnitAddresses = {}; // Pour stocker les adresses uniques avec unités totales

  // **Itérer sur chaque wallet** pour récupérer tous les tokens
  for (var wallet in walletTokens) {
    final walletBalances = wallet['balances'];

    // Process wallet tokens (pour Dashboard et Portfolio)
    for (var walletToken in walletBalances) {
      final tokenAddress = walletToken['token']['address'].toLowerCase();
      uniqueWalletTokens.add(tokenAddress); // Ajouter à l'ensemble des tokens uniques

      final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
        (realToken) => realToken['uuid'].toLowerCase() == tokenAddress,
        orElse: () => <String, dynamic>{},
      );

      if (matchingRealToken.isNotEmpty) {
        final double tokenPrice = matchingRealToken['tokenPrice'];
        final double tokenValue = double.parse(walletToken['amount']) * tokenPrice;

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

          annualYieldSum += matchingRealToken['annualPercentageYield'];
          yieldCount++;
          dailyRentSum += matchingRealToken['netRentDayPerToken'] * double.parse(walletToken['amount']);
          monthlyRentSum += matchingRealToken['netRentMonthPerToken'] * double.parse(walletToken['amount']);
          yearlyRentSum += matchingRealToken['netRentYearPerToken'] * double.parse(walletToken['amount']);
        }

        // Ajouter au Portfolio
        newPortfolio.add({
                    'shortName': matchingRealToken['shortName'],
          'fullName': matchingRealToken['fullName'],
          'imageLink': matchingRealToken['imageLink'][0],
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
        });
      }
    }
  }

  // Process tokens dans le RMM (similaire au processus wallet)
  for (var rmmToken in rmmTokens) {
    final tokenAddress = rmmToken['token']['id'].toLowerCase();
    uniqueRmmTokens.add(tokenAddress); // Ajouter à l'ensemble des tokens uniques

    final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
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

      annualYieldSum += matchingRealToken['annualPercentageYield'];
      yieldCount++;
      dailyRentSum += matchingRealToken['netRentDayPerToken'] * amount;
      monthlyRentSum += matchingRealToken['netRentMonthPerToken'] * amount;
      yearlyRentSum += matchingRealToken['netRentYearPerToken'] * amount;

      // Ajouter au Portfolio
      newPortfolio.add({
          'shortName': matchingRealToken['shortName'],
          'fullName': matchingRealToken['fullName'],
          'imageLink': matchingRealToken['imageLink'][0],
          'lat': matchingRealToken['coordinate']['lat'],
          'lng': matchingRealToken['coordinate']['lng'],
          'amount': amount.toString(),
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
      });
    }
  }

  // Mise à jour des variables pour le Dashboard
  totalValue = walletValueSum + rmmValueSum + rwaValue;
  walletValue = walletValueSum;
  rmmValue = rmmValueSum;
  rwaHoldingsValue = rwaValue;
  walletTokensSums = walletTokensSum;
  rmmTokensSums = rmmTokensSum;
  totalTokens = (walletTokensSum + rmmTokensSum).toInt();
  averageAnnualYield = yieldCount > 0 ? annualYieldSum / yieldCount : 0;
  dailyRent = dailyRentSum;
  weeklyRent = dailyRentSum * 7;
  monthlyRent = monthlyRentSum;
  yearlyRent = yearlyRentSum;

  // Compter les tokens uniques pour wallet et RMM
  walletTokenCount = uniqueWalletTokens.length;
  rmmTokenCount = uniqueRmmTokens.length;

  // Mise à jour des données pour le Portfolio
  _portfolio = newPortfolio;

  print("Portfolio mis à jour avec ${_portfolio.length} éléments.");
  print("Unité louées uniques: $rentedUnits, Unités totales uniques: $totalUnits");

  // Notify listeners that data has changed
  notifyListeners();
}

  // Méthode pour extraire les mises à jour récentes sur les 30 derniers jours
  List<Map<String, dynamic>> _extractRecentUpdates(List<dynamic> realTokensRaw) {
  final List<Map<String, dynamic>> realTokens = realTokensRaw.cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> recentUpdates = [];

  for (var token in realTokens) {
    if (token.containsKey('update30')) {
      final String shortName = token['shortName'] ?? 'Nom inconnu';
      final String imageLink = token['imageLink'] != null && token['imageLink'].isNotEmpty 
          ? token['imageLink'][0] // Prendre la première image si disponible
          : 'Lien d\'image non disponible';

      List<Map<String, dynamic>> updatesWithDetails = List<Map<String, dynamic>>.from(token['update30']).where((update) {
        return update['key'] == 'netRentYearPerToken' || update['key'] == 'annualPercentageYield';
      }).map((update) {
        // Initialiser les variables avec des valeurs par défaut
        String formattedKey = 'Donnée inconnue';
        String formattedOldValue = 'Valeur inconnue';
        String formattedNewValue = 'Valeur inconnue';

        if (update['key'] == 'netRentYearPerToken') {
          // Arrondir la valeur à deux chiffres après la virgule
          double newValue = double.tryParse(update['new_value']) ?? 0.0;
          double oldValue = double.tryParse(update['old_value']) ?? 0.0;
          formattedKey = 'Net Rent Per Token (Annuel)';
          formattedOldValue = "${oldValue.toStringAsFixed(2)} USD";
          formattedNewValue = "${newValue.toStringAsFixed(2)} USD";
        } else if (update['key'] == 'annualPercentageYield') {
          // Arrondir la valeur à deux chiffres après la virgule
          double newValue = double.tryParse(update['new_value']) ?? 0.0;
          double oldValue = double.tryParse(update['old_value']) ?? 0.0;
          formattedKey = 'Rendement Annuel (%)';
          formattedOldValue = "${oldValue.toStringAsFixed(2)}%";
          formattedNewValue = "${newValue.toStringAsFixed(2)}%";
        }

        return {
          'shortName': shortName,
          'formattedKey': formattedKey,
          'formattedOldValue': formattedOldValue,
          'formattedNewValue': formattedNewValue,
          'timsync': update['timsync'],
          'imageLink': imageLink, // Ajout de l'image du token
        };
      }).toList();

      recentUpdates.addAll(updatesWithDetails);
    }
  }

  // Trier les mises à jour par date
  recentUpdates.sort((a, b) => DateTime.parse(b['timsync']).compareTo(DateTime.parse(a['timsync'])));

  return recentUpdates;
}



  // Méthode pour récupérer les données des loyers
  Future<void> fetchRentData({bool forceFetch = false}) async {
    try {
      List<Map<String, dynamic>> rentData = await ApiService.fetchRentData(forceFetch: forceFetch);
      this.rentData = rentData;
    } catch (e) {
      print("Error fetching rent data: $e");
    }
    notifyListeners();
  }

  // Méthode pour récupérer les données des propriétés
Future<void> fetchPropertyData({bool forceFetch = false}) async {
    try {
      // Récupérer les tokens depuis l'API
      final walletTokensGnosis = await ApiService.fetchTokensFromGnosis(forceFetch: forceFetch);
      final walletTokensEtherum = await ApiService.fetchTokensFromEtherum(forceFetch: forceFetch);
      final rmmTokens = await ApiService.fetchRMMTokens(forceFetch: forceFetch);
      final realTokens = await ApiService.fetchRealTokens(forceFetch: forceFetch);

      // Fusionner les tokens de Gnosis et d'Etherum
      final walletTokens = [...walletTokensGnosis, ...walletTokensEtherum];

      final List<Map<String, dynamic>> realTokensCasted = realTokens.cast<Map<String, dynamic>>();

      // Fusionner les tokens du portefeuille (Gnosis, Ethereum) et du RMM
      List<dynamic> allTokens = [];
      for (var wallet in walletTokens) {
        allTokens.addAll(wallet['balances']); // Ajouter tous les balances des wallets
      }
      allTokens.addAll(rmmTokens); // Ajouter les tokens du RMM

      List<Map<String, dynamic>> propertyData = [];

      // Parcourir chaque token du portefeuille et du RMM
      for (var token in allTokens) {
        if (token != null && token['token'] != null && token['token']['address'] != null) {
          final tokenAddress = token['token']['address'].toLowerCase();

          // Correspondre avec les RealTokens
          final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
            (realToken) => realToken['uuid'].toLowerCase() == tokenAddress.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          if (matchingRealToken.isNotEmpty && matchingRealToken['propertyType'] != null) {
            final propertyType = matchingRealToken['propertyType'];

            // Vérifiez si le type de propriété existe déjà dans propertyData
            final existingPropertyType = propertyData.firstWhere(
              (data) => data['propertyType'] == propertyType,
              orElse: () => <String, dynamic>{}, // Renvoie un map vide si aucune correspondance n'est trouvée
            );

            if (existingPropertyType.isNotEmpty) {
              // Incrémenter le compte si la propriété existe déjà
              existingPropertyType['count'] += 1;
            } else {
              // Ajouter une nouvelle entrée si la propriété n'existe pas encore
              propertyData.add({'propertyType': propertyType, 'count': 1});
            }
          }
        } else {
          print('Invalid token or missing address for token: $token');
        }
      }

      this.propertyData = propertyData;
    } catch (e) {
      print("Error fetching property data: $e");
    }
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
  walletTokensSums = 0;
  rmmTokensSums = 0;
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

  // Notifier les observateurs que les données ont été réinitialisées
  notifyListeners();
  
  // Supprimer également les préférences sauvegardées si nécessaire
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Si vous voulez vider toutes les préférences
}

// Méthode pour mettre à jour le taux de conversion et le symbole
  Future<void> updateConversionRate(String currency, String selectedCurrency, Map<String, dynamic> currencies) async {
    selectedCurrency = currency;
    if (currencies.containsKey(selectedCurrency)) {
      conversionRate = currencies[selectedCurrency] ?? 1.0;
    } else {
      conversionRate = 1.0; // Par défaut, rester en USD
    }

    // Mettre à jour le symbole de la devise, ou utiliser les 3 lettres si absent
    currencySymbol = _currencySymbols[selectedCurrency] ?? selectedCurrency.toUpperCase(); // Si absent, utiliser les 3 lettres
    notifyListeners();
  }

  Future<void> loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';

    // Utilisez ApiService pour récupérer les devises
    final apiService = ApiService();
    final currencies = await apiService.fetchCurrencies();

    // Appeler updateConversionRate avec les trois paramètres nécessaires
    await updateConversionRate(selectedCurrency, selectedCurrency, currencies);
  }

  // Exemple de conversion
  double convert(double valueInUsd) {
    return valueInUsd * conversionRate;
  }
}

