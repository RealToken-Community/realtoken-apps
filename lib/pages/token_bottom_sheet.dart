import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importer le fichier utils
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import pour les coordonnées géographiques
import 'package:fl_chart/fl_chart.dart';
import 'dart:io'; // Import pour vérifier la plateforme
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import '../api/data_manager.dart'; // Import de DataManager
import '../generated/l10n.dart'; // Import pour les traductions
import 'package:carousel_slider/carousel_slider.dart';
import 'portfolio/FullScreenCarousel.dart';

// Fonction modifiée pour formater la monnaie avec le taux de conversion et le symbole
String formatCurrency(BuildContext context, double value) {
  final dataManager =
      Provider.of<DataManager>(context, listen: false); // Récupérer DataManager
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR', // Vous pouvez adapter la locale selon vos besoins
    symbol: dataManager.currencySymbol, // Utilise le symbole de la devise
    decimalDigits: 2,
  );
  return formatter.format(
      dataManager.convert(value)); // Conversion selon la devise sélectionnée
}

void _openMapModal(BuildContext context, dynamic lat, dynamic lng) {
  // Convertir les valeurs lat et lng en double
  final double? latitude = double.tryParse(lat.toString());
  final double? longitude = double.tryParse(lng.toString());

  if (latitude == null || longitude == null) {
    // Afficher un message d'erreur si les coordonnées ne sont pas valides
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid coordinates for the property')),
    );
    return;
  }


  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.7, // Ajuste la hauteur de la modale
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).viewOnMap), // Titre de la carte
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter:
                  LatLng(latitude, longitude), // Utilise les valeurs converties
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point:
                        LatLng(latitude, longitude), // Coordonnées du marqueur
                    width: 50, // Largeur du marqueur
                    height: 50, // Hauteur du marqueur
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40, // Taille de l'icône de localisation
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // Fonction pour convertir les sqft en m²
String _formatSquareFeet(double sqft, bool convertToSquareMeters) {
  if (convertToSquareMeters) {
    double squareMeters = sqft * 0.092903; // Conversion des pieds carrés en m²
    return '${squareMeters.toStringAsFixed(2)} m²';
  } else {
    return '${sqft.toStringAsFixed(2)} sqft';
  }
}
  
// Fonction réutilisable pour afficher la BottomModalSheet avec les détails du token
Future<void> showTokenDetails(BuildContext context, Map<String, dynamic> token) async {
  final prefs = await SharedPreferences.getInstance();
  bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;

  showModalBottomSheet(
    backgroundColor: Theme.of(context).cardColor,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DefaultTabController(
        length: 4, // Quatre onglets
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du token
                token['imageLink'] != null && token['imageLink'].isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          // Vérifier si c'est une chaîne ou une liste
                          final List<String> imageLinks = token['imageLink']
                                  is String
                              ? [
                                  token['imageLink']
                                ] // Convertir en liste si c'est une chaîne
                              : List<String>.from(token[
                                  'imageLink']); // Garder la liste si c'est déjà une liste

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullScreenCarousel(
                                imageLinks: imageLinks,
                              ),
                            ),
                          );
                        },
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: MediaQuery.of(context).size.height * 0.22,
                            enableInfiniteScroll: true,
                            enlargeCenterPage: true,
                          ),
                          items: (token['imageLink'] is String
                                  ? [
                                      token['imageLink']
                                    ] // Convertir en liste si c'est une chaîne
                                  : List<String>.from(token[
                                      'imageLink'])) // Utiliser la liste directement
                              .map<Widget>((imageUrl) {
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey,
                        child: const Center(
                          child: Text("No image available"),
                        ),
                      ),
                const SizedBox(height: 10),

                // Titre du token
                Center(
                  child: Text(
                    token['fullName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Platform.isAndroid ? 14 : 15,
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // TabBar pour les différents onglets
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: S.of(context).properties),
                    Tab(text: S.of(context).finances),
                    Tab(text: S.of(context).others),
                    Tab(text: S.of(context).insights),
                  ],
                ),

                const SizedBox(height: 10),

                // TabBarView pour le contenu de chaque onglet
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: TabBarView(
                    children: [
                      // Onglet Propriétés
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).characteristics,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Platform.isAndroid ? 14 : 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                                S.of(context).constructionYear,
                                token['constructionYear']?.toString() ??
                                    S.of(context).notSpecified),
                            _buildDetailRow(
                                S.of(context).propertyStories,
                                token['propertyStories']?.toString() ??
                                    S.of(context).notSpecified),
                            _buildDetailRow(
                                S.of(context).totalUnits,
                                token['totalUnits']?.toString() ??
                                    S.of(context).notSpecified),
                             _buildDetailRow(
                              S.of(context).squareFeet,
                              _formatSquareFeet(token['lotSize']?.toDouble() ?? 0, convertToSquareMeters,),
                            ),
                            _buildDetailRow(
                              S.of(context).squareFeet,
                              _formatSquareFeet(token['squareFeet']?.toDouble() ?? 0, convertToSquareMeters,),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      // Onglet Finances
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailRow(
                                S.of(context).totalInvestment,
                                formatCurrency(
                                    context, token['totalInvestment'] ?? 0)),
                            _buildDetailRow(
                                S.of(context).underlyingAssetPrice,
                                formatCurrency(context,
                                    token['underlyingAssetPrice'] ?? 0)),
                            _buildDetailRow(
                                S.of(context).initialMaintenanceReserve,
                                formatCurrency(context,
                                    token['initialMaintenanceReserve'] ?? 0)),
                            _buildDetailRow(
                                S.of(context).grossRentMonth,
                                formatCurrency(
                                    context, token['grossRentMonth'] ?? 0)),
                            _buildDetailRow(
                                S.of(context).netRentMonth,
                                formatCurrency(
                                    context, token['netRentMonth'] ?? 0)),
                            _buildDetailRow(S.of(context).annualPercentageYield,
                                '${token['annualPercentageYield']?.toStringAsFixed(2) ?? S.of(context).notSpecified}%'),
                          ],
                        ),
                      ),

                      // Onglet Autres avec section Blockchain uniquement
                      SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        S.of(context).blockchain,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Platform.isAndroid ? 14 : 15,
        ),
      ),
      const SizedBox(height: 10),

      // Ethereum Contract avec icône de lien
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context).ethereumContract,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              final ethereumAddress = token['ethereumContract'] ?? '';
              if (ethereumAddress.isNotEmpty) {
                _launchURL('https://etherscan.io/address/$ethereumAddress');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).notSpecified)),
                );
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        token['ethereumContract'] ?? S.of(context).notSpecified,
        style: const TextStyle(fontSize: 13),
      ),

      const SizedBox(height: 10),

      // Gnosis Contract avec icône de lien
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context).gnosisContract,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              final gnosisAddress = token['gnosisContract'] ?? '';
              if (gnosisAddress.isNotEmpty) {
                _launchURL('https://gnosisscan.io/address/$gnosisAddress');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).notSpecified)),
                );
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        token['gnosisContract'] ?? S.of(context).notSpecified,
        style: const TextStyle(fontSize: 13),
      ),
    ],
  ),
),

                      // Onglet Insights
                       SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Pastille de couleur en fonction du statut de location
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: getRentalStatusColor(
                                      token['rentedUnits'] ?? 0, // Nombre de logements loués
                                      token['totalUnits'] ?? 1,  // Nombre total de logements
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  S.of(context).rentalStatus, // Utilisation de la traduction
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Platform.isAndroid ? 14 : 15,  // Réduction de la taille du texte pour Android
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // Ajout du texte pour indiquer le pourcentage des logements loués
                            Text(
                              '${S.of(context).rentedUnits} : ${token['rentedUnits'] ?? S.of(context).notSpecified} / ${token['totalUnits'] ?? S.of(context).notSpecified}',
                              style: TextStyle(fontSize: Platform.isAndroid ? 12 : 13),  // Réduction de la taille du texte pour Android
                            ),

                            const SizedBox(height: 10),

                            // Graphique du rendement (Yield)
                            Text(
                              S.of(context).yieldEvolution, // Utilisation de la traduction
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Platform.isAndroid ? 14 : 15,  // Réduction de la taille du texte pour Android
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildYieldChartOrMessage(context, token['historic']?['yields'] ?? [], token['historic']?['init_yield']),
                            
                            const SizedBox(height: 20),

                            // Graphique des prix
                            Text(
                              S.of(context).priceEvolution, // Utilisation de la traduction
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Platform.isAndroid ? 14 : 15,  // Réduction de la taille du texte pour Android
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPriceChartOrMessage(context, token['historic']?['prices'] ?? [], token['historic']?['init_price']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton pour voir sur RealT
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Ajoute un padding de 16 pixels autour des boutons
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centre les boutons
                      children: [
                        // Bouton pour voir sur RealT
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () =>
                                _launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Colors.blue, // Bouton bleu pour RealT
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child: Text(S.of(context).viewOnRealT),
                          ),
                        ),
                        const SizedBox(
                            width: 10), // Espacement entre les deux boutons
                        // Bouton pour voir sur la carte
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _openMapModal(
                                context, token['lat'], token['lng']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Colors.green, // Bouton vert pour la carte
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child: Text(S.of(context).viewOnMap),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Méthode pour construire les lignes de détails
Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:
                    Platform.isAndroid ? 12 : 13)), // Réduction pour Android
        Text(value,
            style: TextStyle(
                fontSize:
                    Platform.isAndroid ? 12 : 13)), // Réduction pour Android
      ],
    ),
  );
}

// Méthode pour afficher soit le graphique du yield, soit un message, avec % évolution
Widget _buildYieldChartOrMessage(
    BuildContext context, List<dynamic> yields, double? initYield) {
  if (yields.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return Text(
      "${S.of(context).noYieldEvolution} ${yields.isNotEmpty ? yields.first['yield'].toStringAsFixed(2) : S.of(context).notSpecified}",
      style: TextStyle(
          fontSize: Platform.isAndroid ? 12 : 13), // Réduction pour Android
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastYield = yields.last['yield']?.toDouble() ?? 0;
    double percentageChange =
        ((lastYield - (initYield ?? lastYield)) / (initYield ?? lastYield)) *
            100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYieldChart(yields),
        const SizedBox(height: 10),
        Text(
          "${S.of(context).yieldEvolutionPercentage} ${percentageChange.toStringAsFixed(2)}%",
          style: TextStyle(
              fontSize: Platform.isAndroid ? 12 : 13), // Réduction pour Android
        ),
      ],
    );
  }
}

// Méthode pour afficher soit le graphique des prix, soit un message, avec % évolution
Widget _buildPriceChartOrMessage(
    BuildContext context, List<dynamic> prices, double? initPrice) {
  if (prices.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return Text(
      "${S.of(context).noPriceEvolution} ${prices.isNotEmpty ? prices.first['price'].toStringAsFixed(2) : S.of(context).notSpecified}",
      style: TextStyle(
          fontSize: Platform.isAndroid ? 12 : 13), // Réduction pour Android
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastPrice = prices.last['price']?.toDouble() ?? 0;
    double percentageChange =
        ((lastPrice - (initPrice ?? lastPrice)) / (initPrice ?? lastPrice)) *
            100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceChart(prices),
        const SizedBox(height: 10),
        Text(
          "${S.of(context).priceEvolutionPercentage} ${percentageChange.toStringAsFixed(2)}%",
          style: TextStyle(
              fontSize: Platform.isAndroid ? 12 : 13), // Réduction pour Android
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique du yield
Widget _buildYieldChart(List<dynamic> yields) {
  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < yields.length; i++) {
    if (yields[i]['timsync'] != null && yields[i]['timsync'] is String) {
      DateTime date = DateTime.parse(yields[i]['timsync']);
      double x = i.toDouble(); // Utiliser un indice pour l'axe X
      double y = yields[i]['yield'] != null
          ? double.tryParse(yields[i]['yield'].toString()) ?? 0
          : 0;
      y = double.parse(
          y.toStringAsFixed(2)); // Limiter la valeur de `y` à 2 décimales

      spots.add(FlSpot(x, y));
      dateLabels.add(DateFormat('MM/yyyy')
          .format(date)); // Ajouter la date formatée en mois/année
    }
  }

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles:
                SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                        fontSize: Platform.isAndroid
                            ? 9
                            : 10), // Réduction de la taille pour Android
                  );
                }
                return const Text('');
              },
              interval: 1, // Afficher une date à chaque intervalle
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: Platform.isAndroid
                          ? 9
                          : 10), // Réduction de la taille pour Android
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles:
                SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: spots.isNotEmpty ? spots.first.x : 0,
        maxX: spots.isNotEmpty ? spots.last.x : 0,
        minY: spots.isNotEmpty
            ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
            : 0,
        maxY: spots.isNotEmpty
            ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
            : 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

// Méthode pour construire le graphique des prix
Widget _buildPriceChart(List<dynamic> prices) {
  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < prices.length; i++) {
    DateTime date = DateTime.parse(prices[i]['timsync']);
    double x = i.toDouble(); // Utiliser un indice pour l'axe X
    double y = prices[i]['price']?.toDouble() ?? 0;

    spots.add(FlSpot(x, y));
    dateLabels.add(DateFormat('MM/yyyy')
        .format(date)); // Ajouter la date formatée en mois/année
  }

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles:
                SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                        fontSize: Platform.isAndroid
                            ? 9
                            : 10), // Réduction de la taille pour Android
                  );
                }
                return const Text('');
              },
              interval: 1, // Afficher une date à chaque intervalle
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: Platform.isAndroid
                          ? 9
                          : 10), // Réduction de la taille pour Android
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles:
                SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: spots.isNotEmpty ? spots.first.x : 0,
        maxX: spots.isNotEmpty ? spots.last.x : 0,
        minY: spots.isNotEmpty
            ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
            : 0,
        maxY: spots.isNotEmpty
            ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
            : 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

// Méthode pour déterminer la couleur de la pastille en fonction du taux de location
Color getRentalStatusColor(int rentedUnits, int totalUnits) {
  if (rentedUnits == 0) {
    return Colors.red; // Aucun logement loué
  } else if (rentedUnits == totalUnits) {
    return Colors.green; // Tous les logements sont loués
  } else {
    return Colors.orange; // Partiellement loué
  }
}

// Méthode pour ouvrir une URL dans le navigateur externe
Future<void> _launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Impossible d\'ouvrir l\'URL: $url';
  }
}
