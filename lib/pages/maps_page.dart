import 'package:RealToken/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/data_manager.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
  
}

class _MapsPageState extends State<MapsPage> {
  final PopupController _popupController = PopupController();
  bool _showAllTokens = false;
  final String _searchQuery = '';
  final String _sortOption = 'Name';
  final bool _isAscending = true;
  bool _isDarkTheme = false; // Variable pour suivre le thème sélectionné

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Charger la préférence du thème à l'initialisation
     WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  // Charger la préférence du thème à partir de SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  // Méthode pour filtrer et trier les tokens (même approche que PortfolioPage)
  List<Map<String, dynamic>> _filterAndSortTokens(
      List<Map<String, dynamic>> tokens) {
    List<Map<String, dynamic>> filteredTokens = tokens
        .where((token) => token['fullName']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    if (_sortOption == 'Name') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['shortName'].compareTo(b['shortName'])
          : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == 'Value') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['totalValue'].compareTo(b['totalValue'])
          : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == 'APY') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['annualPercentageYield'].compareTo(b['annualPercentageYield'])
          : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    }

    return filteredTokens;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    final tokensToShow = _showAllTokens
        ? _filterAndSortTokens(dataManager.allTokens)
        : _filterAndSortTokens(dataManager.portfolio);

    if (tokensToShow.isEmpty) {
      return const Center(child: Text('No tokens available'));
    }

    final List<Marker> markers = [];

    // Helper function to create markers
    Marker createMarker({
      required dynamic matchingToken,
      required Color color,
    }) {
      final lat = double.tryParse(matchingToken['lat']);
      final lng = double.tryParse(matchingToken['lng']);
      final rentedUnits = matchingToken['rentedUnits'] ?? 0;
      final totalUnits = matchingToken['totalUnits'] ?? 1;

      if (lat != null && lng != null) {
        return Marker(
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () => _showMarkerPopup(context, matchingToken),
            child: Icon(
              Icons.location_on,
              color: getRentalStatusColor(rentedUnits, totalUnits),
              size: 40.0,
            ),
          ),
          key: ValueKey(matchingToken),
        );
      } else {
        return Marker(
          point: LatLng(0, 0),
          child: const SizedBox.shrink(),
        );
      }
    }

    for (var token in tokensToShow) {
      final isWallet = token['source'] == 'Wallet';
      final isRMM = token['source'] == 'RMM';

      if (token['lat'] != null) {
        markers.add(
          createMarker(
            matchingToken: token,
            color: isWallet
                ? Colors.green
                : isRMM
                    ? Colors.blue
                    : Colors.grey,
          ),
        );
      }
    }

    if (markers.isEmpty) {
      return const Center(
          child: Text('No tokens with valid coordinates found on the map'));
    }

return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  body: Stack(
    children: [
      Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Définit la couleur de fond pour la carte
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(42.367476, -83.130921),
            initialZoom: 10.0,
            onTap: (_, __) => _popupController.hideAllPopups(),
          ),
          children: [
            TileLayer(
              // Utilisation de tuiles différentes selon le thème sélectionné
              urlTemplate: _isDarkTheme
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.byackee.app',
              retinaMode: true,
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 70,
                disableClusteringAtZoom: 15,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, clusterMarkers) {
                  Color clusterColor = _getClusterColor(clusterMarkers);
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          clusterColor.withOpacity(0.9),
                          clusterColor.withOpacity(0.2),
                        ],
                        stops: [0.4, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        clusterMarkers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Switch en haut à gauche pour basculer entre les tokens du portefeuille et tous les tokens
      Positioned(
        top: 90, // Positionner juste en dessous de l'AppBar
        left: 16,
        child: Row(
          children: [
            Text(_showAllTokens ? 'All Tokens' : 'Portfolio'),
            Switch(
              value: _showAllTokens,
              onChanged: (value) {
                setState(() {
                  _showAllTokens = value;
                });
              },
            ),
          ],
        ),
      ),
      // Légende en bas à gauche
      Positioned(
        bottom: 90, // Remonter la légende pour la placer au-dessus de la BottomBar
        left: 16,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children:  [
                  Icon(Icons.location_on, color: Colors.green),
                  SizedBox(width: 4),
                  Text("Fully Rented", style: TextStyle(
                  fontSize: 13, // Taille du texte ajustée
              ),
              ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 4),
                  Text("Partially Rented", style: TextStyle(
                  fontSize: 13, // Taille du texte ajustée
              ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 4),
                  Text("Not Rented", style: TextStyle(
                  fontSize: 13, // Taille du texte ajustée
              ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

  }

  // Fonction pour déterminer la couleur du cluster en fonction des marqueurs qu'il contient
  Color _getClusterColor(List<Marker> markers) {
    int fullyRented = 0;
    // ignore: unused_local_variable
    int partiallyRented = 0;
    int notRented = 0;

    for (var marker in markers) {
      if (marker.key is ValueKey) {
        final token = (marker.key as ValueKey).value as Map<String, dynamic>;

        final rentedUnits = token['rentedUnits'] ?? 0;
        final totalUnits = token['totalUnits'] ?? 1;

        if (rentedUnits == 0) {
          notRented++;
        } else if (rentedUnits == totalUnits) {
          fullyRented++;
        } else {
          partiallyRented++;
        }
      }
    }

    if (fullyRented == markers.length) {
      return Colors.green;
    } else if (notRented == markers.length) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

void _showMarkerPopup(BuildContext context, dynamic matchingToken) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final rentedUnits = matchingToken['rentedUnits'] ?? 0;
      final totalUnits = matchingToken['totalUnits'] ?? 1;
      final lat = double.tryParse(matchingToken['lat']) ?? 0.0;
      final lng = double.tryParse(matchingToken['lng']) ?? 0.0;

      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (matchingToken['imageLink'] != null)
              Image.network(
                matchingToken['imageLink'][0],
                width: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                matchingToken['shortName'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Token Price: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${matchingToken['tokenPrice'] ?? 'N/A'}'),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Token Yield: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    '${matchingToken['annualPercentageYield'] != null ? matchingToken['annualPercentageYield'].toStringAsFixed(2) : 'N/A'}'),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Units Rented: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('$rentedUnits / $totalUnits'),
              ],
            ),
            const SizedBox(height: 16.0),
            IconButton(
              icon: const Icon(Icons.streetview, color: Colors.blue),
              onPressed: () {
                final googleStreetViewUrl =
                    'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat,$lng';
                Utils.launchURL(googleStreetViewUrl);
              },
            ),
            const Text('View in Street View'),
          ],
        ),
      );
    },
  );
}
  Color getRentalStatusColor(int rentedUnits, int totalUnits) {
    if (rentedUnits == 0) {
      return Colors.red;
    } else if (rentedUnits == totalUnits) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}
