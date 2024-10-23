import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import pour les coordonnées géographiques
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import 'package:realtokens_apps/api/data_manager.dart'; // Import de DataManager
import 'package:realtokens_apps/generated/l10n.dart'; // Import pour les traductions
import 'package:carousel_slider/carousel_slider.dart';
import 'portfolio/FullScreenCarousel.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:realtokens_apps/app_state.dart';

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
          body: Stack(
            children: [
              FlutterMap(
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
                        point: LatLng(latitude, longitude), // Coordonnées du marqueur
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
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    // Lancer Google Street View
                    final googleStreetViewUrl =
                        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
                    Utils.launchURL(googleStreetViewUrl);
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(
                    Icons.streetview,
                    color: Colors.white,
                  ),
                ),
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
Future<void> showTokenDetails( BuildContext context, Map<String, dynamic> token) async {
  final prefs = await SharedPreferences.getInstance();
  bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
  final appState = Provider.of<AppState>(context, listen: false);

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
                      fontSize: 15 + appState.getTextSizeOffset(),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // TabBar pour les différents onglets
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset(),fontWeight: FontWeight.bold), // Taille du texte des onglets sélectionnés
                  unselectedLabelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset() ), // Taille du texte des onglets non sélectionnés
                  labelPadding: EdgeInsets.symmetric(horizontal: 2.0), // Ajustez cette valeur selon vos besoins
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
                            Row(
                              children: [
                                // Pastille de couleur en fonction du statut de location
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Utils.getRentalStatusColor(
                                      token['rentedUnits'] ??
                                          0, // Nombre de logements loués
                                      token['totalUnits'] ??
                                          1, // Nombre total de logements
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${S.of(context).rentedUnits} : ${token['rentedUnits'] ?? S.of(context).notSpecified} / ${token['totalUnits'] ?? S.of(context).notSpecified}',
                                  style: TextStyle(
                                      fontSize: 13 + appState.getTextSizeOffset()), // Réduction de la taille du texte pour Android
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              S.of(context).characteristics,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(context,
                                S.of(context).constructionYear,
                                token['constructionYear']?.toString() ??
                                    S.of(context).notSpecified),
                            _buildDetailRow(context,
                                S.of(context).rentalType,
                                token['rentalType']?.toString() ??
                                    S.of(context).notSpecified),
                            _buildDetailRow(context,
                                S.of(context).totalUnits,
                                token['totalUnits']?.toString() ??
                                    S.of(context).notSpecified),
                            _buildDetailRow(context,
                              S.of(context).lotSize,
                              _formatSquareFeet(
                                token['lotSize']?.toDouble() ?? 0,
                                convertToSquareMeters,
                              ),
                            ),
                            _buildDetailRow(context,
                              S.of(context).squareFeet,
                              _formatSquareFeet(
                                token['squareFeet']?.toDouble() ?? 0,
                                convertToSquareMeters,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              S.of(context).rents,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(context,
                                S.of(context).rentStartDate,
                                Utils.formatReadableDate(
                                    token['rentStartDate']))
                          ],
                        ),
                      ),

                      // Onglet Finances
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailRow(context,
                                S.of(context).totalInvestment,
                                formatCurrency(context, token['totalInvestment'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).underlyingAssetPrice,
                                formatCurrency(context,token['underlyingAssetPrice'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).initialMaintenanceReserve,
                                formatCurrency(context,token['initialMaintenanceReserve'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).grossRentMonth,
                                formatCurrency(context, token['grossRentMonth'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).netRentMonth,
                                formatCurrency(context, token['netRentMonth'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).annualPercentageYield,'${token['annualPercentageYield']?.toStringAsFixed(2) ?? S.of(context).notSpecified} %'),
                            _buildDetailRow(context,
                                S.of(context).totalRentReceived,
                                formatCurrency(context, token['totalRentReceived'] ?? 0)),
                            _buildDetailRow(context,
                                S.of(context).roiPerProperties,
                                "${(token['totalRentReceived'] / token['totalValue'] * 100 ).toStringAsFixed(2)} %"),
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
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Ethereum Contract avec icône de lien
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).ethereumContract,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13 + appState.getTextSizeOffset(), // Rendre TextStyle non const
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.link),
                                  onPressed: () {
                                    final ethereumAddress =
                                        token['ethereumContract'] ?? '';
                                    if (ethereumAddress.isNotEmpty) {
                                      Utils.launchURL(
                                          'https://etherscan.io/address/$ethereumAddress');
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                S.of(context).notSpecified)),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              token['ethereumContract'] ??
                                  S.of(context).notSpecified,
                              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                            ),

                            const SizedBox(height: 10),

                            // Gnosis Contract avec icône de lien
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).gnosisContract,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13 + appState.getTextSizeOffset()),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.link),
                                  onPressed: () {
                                    final gnosisAddress =
                                        token['gnosisContract'] ?? '';
                                    if (gnosisAddress.isNotEmpty) {
                                      Utils.launchURL(
                                          'https://gnosisscan.io/address/$gnosisAddress');
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                S.of(context).notSpecified)),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              token['gnosisContract'] ??
                                  S.of(context).notSpecified,
                              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                            ),
                          ],
                        ),
                      ),

                      // Onglet Insights
                     SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Graphique du rendement (Yield)
      Text(
        S.of(context).yieldEvolution, // Utilisation de la traduction
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15 + appState.getTextSizeOffset(), // Réduction de la taille du texte pour Android
        ),
      ),
      const SizedBox(height: 10),
      _buildYieldChartOrMessage(
          context,
          token['historic']?['yields'] ?? [],
          token['historic']?['init_yield']),

      const SizedBox(height: 20),

      // Jauge verticale du ROI de la propriété
      Row(
  children: [
    Text(
      S.of(context).roiPerProperties, // Titre de la jauge
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15 + appState.getTextSizeOffset(),
      ),
    ),
    const SizedBox(width: 8), // Espace entre le texte et l'icône
    GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).roiPerProperties), // Titre du popup
              content: Text(S.of(context).roiAlertInfo), // Texte du popup
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer le popup
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
      child: Icon(
        Icons.help_outline, // Icône "?"
        color: Colors.grey,
        size: 20 + appState.getTextSizeOffset(), // Ajustez la taille en fonction du texte
      ),
    ),
  ],
),

      const SizedBox(height: 10),
      _buildGaugeForROI(
        token['totalRentReceived'] / token['totalValue'] * 100, // Calcul du ROI
        context,
      ),

      const SizedBox(height: 20),

      // Graphique des prix
      Text(
        S.of(context).priceEvolution, // Utilisation de la traduction
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15 + appState.getTextSizeOffset(), // Réduction de la taille du texte pour Android
        ),
      ),
      const SizedBox(height: 10),
      _buildPriceChartOrMessage(
          context,
          token['historic']?['prices'] ?? [],
          token['historic']?['init_price']),
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
                            onPressed: () => Utils.launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue, // Bouton bleu pour RealT
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              textStyle: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(), // Rendre TextStyle non const
                              ),
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
                                  textStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),                            
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

Widget _buildGaugeForROI(double roiValue, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Aligner la jauge à gauche
    children: [
      const SizedBox(height: 5),
      // Utilisation de LayoutBuilder pour occuper toute la largeur disponible
      LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth; // Largeur disponible

          return Stack(
            children: [
              // Fond gris
              Container(
                height: 20,
                width: maxWidth, // Largeur maximale disponible
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, // Couleur du fond grisé
                  borderRadius: BorderRadius.circular(5), // Bordure arrondie
                ),
              ),
              // Barre bleue représentant le ROI
              Container(
                height: 20,
                width: roiValue.clamp(0, 100) / 100 * maxWidth, // Largeur de la barre bleue en fonction du ROI
                decoration: BoxDecoration(
                  color: Colors.blue, // Couleur de la barre
                  borderRadius: BorderRadius.circular(5), // Bordure arrondie
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 5),
      // Afficher la valeur du ROI
      Text(
        "${roiValue.toStringAsFixed(1)} %", // Afficher avec 1 chiffre après la virgule
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    ],
  );
}

// Méthode pour construire les lignes de détails
Widget _buildDetailRow(BuildContext context, String label, String value) {
    final appState = Provider.of<AppState>(context, listen: false);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13 + appState.getTextSizeOffset())), // Réduction pour Android
        Text(value,
            style: TextStyle(
                fontSize: 13 + appState.getTextSizeOffset())), // Réduction pour Android
      ],
    ),
  );
}

// Méthode pour afficher soit le graphique du yield, soit un message, avec % évolution
Widget _buildYieldChartOrMessage(BuildContext context, List<dynamic> yields, double? initYield) {
    final appState = Provider.of<AppState>(context, listen: false);

  if (yields.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return Text(
      "${S.of(context).noYieldEvolution} ${yields.isNotEmpty ? yields.first['yield'].toStringAsFixed(2) : S.of(context).notSpecified} %",
      style: TextStyle(
          fontSize: 13 + appState.getTextSizeOffset()), // Réduction pour Android
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastYield = yields.last['yield']?.toDouble() ?? 0;
    double percentageChange = ((lastYield - (initYield ?? lastYield)) / (initYield ?? lastYield)) * 100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYieldChart(context,yields),
        const SizedBox(height: 10),
        Text(
          "${S.of(context).yieldEvolutionPercentage} ${percentageChange.toStringAsFixed(2)} %",
          style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset()), // Réduction pour Android
        ),
      ],
    );
  }
}

// Méthode pour afficher soit le graphique des prix, soit un message, avec % évolution
Widget _buildPriceChartOrMessage(BuildContext context, List<dynamic> prices, double? initPrice) {
    final appState = Provider.of<AppState>(context, listen: false);

  if (prices.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return Text(
      "${S.of(context).noPriceEvolution} ${prices.isNotEmpty ? prices.first['price'].toStringAsFixed(2) : S.of(context).notSpecified} \$",
      style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()), // Réduction pour Android
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastPrice = prices.last['price']?.toDouble() ?? 0;
    double percentageChange = ((lastPrice - (initPrice ?? lastPrice)) / (initPrice ?? lastPrice)) * 100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceChart(context, prices),
        const SizedBox(height: 10),
        Text(
          "${S.of(context).priceEvolutionPercentage} ${percentageChange.toStringAsFixed(2)} %",
          style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset()), // Réduction pour Android
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique du yield
Widget _buildYieldChart(BuildContext context, List<dynamic> yields) {
  final appState = Provider.of<AppState>(context, listen: false);

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
      dateLabels.add(DateFormat('MM/yyyy').format(date)); // Ajouter la date formatée en mois/année
    }
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
      : 0;
  double maxYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
      : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.2; // Marge pour l'axe X
  const double marginY = 0.5; // Marge pour l'axe Y

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                    ),
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
                    fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: minXValue - marginX,
        maxX: maxXValue + marginX,
        minY: minYValue - marginY,
        maxY: maxYValue + marginY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.blue,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

// Méthode pour construire le graphique des prix
Widget _buildPriceChart(BuildContext context, List<dynamic> prices) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < prices.length; i++) {
    DateTime date = DateTime.parse(prices[i]['timsync']);
    double x = i.toDouble(); // Utiliser un indice pour l'axe X
    double y = prices[i]['price']?.toDouble() ?? 0;

    spots.add(FlSpot(x, y));
    dateLabels.add(DateFormat('MM/yyyy').format(date)); // Ajouter la date formatée en mois/année
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
      : 0;
  double maxYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
      : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.1; // Marge pour l'axe X
  const double marginY = 0.2; // Marge pour l'axe Y

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                    ),
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
                    fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: minXValue - marginX,
        maxX: maxXValue + marginX,
        minY: minYValue - marginY,
        maxY: maxYValue + marginY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.blue,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

