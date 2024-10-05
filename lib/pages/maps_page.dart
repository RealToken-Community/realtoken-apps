import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../api/data_manager.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  // Create a PopupController to manage the popups
  final PopupController _popupController = PopupController();

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    // Vérification si le portefeuille contient des données
    if (dataManager.portfolio.isEmpty) {
      return const Center(child: Text('No portfolio data available'));
    }

    final List<Marker> markers = [];

    // Helper function to create markers
    Marker createMarker({
      required dynamic matchingToken,
      required Color color,
    }) {
      final lat = double.tryParse(matchingToken['lat']);
      final lng = double.tryParse(matchingToken['lng']);

      if (lat != null && lng != null) {
        return Marker(
          point: LatLng(lat, lng),
          width: 80.0,
          height: 80.0,
          child: Icon(
            Icons.location_on,
            color: color,
            size: 40.0,
          ),
          key: ValueKey(matchingToken), // Use key to store data
        );
      } else {
        return Marker(
          point: LatLng(0, 0),
          width: 0,
          height: 0,
          child: const SizedBox.shrink(),
        );
      }
    }

    // Ajouter les tokens du portefeuille à la carte
    for (var token in dataManager.portfolio) {
      if (token['lat'] != null) {
        markers.add(
          createMarker(
            matchingToken: token,
            color: token['source'] == 'Wallet' ? Colors.green : Colors.blue, // Différencier par la source
          ),
        );
      }
    }

    if (markers.isEmpty) {
      return const Center(child: Text('No tokens with valid coordinates found on the map'));
    }

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(42.367476, -83.130921),
          initialZoom: 10.0,
          onTap: (_, __) => _popupController.hideAllPopups(),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PopupScope(
            child: MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 70,
                disableClusteringAtZoom: 15,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, markers) {
                  return CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(markers.length.toString()),
                  );
                },
                popupOptions: PopupOptions(
                  popupController: _popupController,
                  popupBuilder: (BuildContext context, Marker marker) {
                    final matchingToken = marker.key is ValueKey
                        ? (marker.key as ValueKey).value
                        : null;

                    if (matchingToken != null) {
                      return Card(
                        child: Container(
                          width: 200,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                matchingToken['imageLink'][0],
                                width: 200,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  matchingToken['shortName'],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const Text('No data available for this marker');
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
