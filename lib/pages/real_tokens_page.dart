import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importer provider
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../api/data_manager.dart';
import 'token_bottom_sheet.dart'; // Import du modal bottom sheet

String formatCurrency(double value) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '\$',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

class RealTokensPage extends StatefulWidget {
  const RealTokensPage({super.key});

  @override
  _RealTokensPageState createState() => _RealTokensPageState();
}

class _RealTokensPageState extends State<RealTokensPage> {
  String _searchQuery = '';
  String _sortOption = 'recentlyAdded';
  bool _isAscending = true;
  String? _selectedCity;
  final String _rentalStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  // Méthode pour filtrer et trier la liste des tokens
  List<Map<String, dynamic>> _filterAndSortTokens(DataManager dataManager) {
    List<Map<String, dynamic>> filteredTokens = dataManager.allTokens.where((token) {
      final matchesSearchQuery = token['fullName']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCity = _selectedCity == null ||
          token['fullName'].contains(_selectedCity!);
      return matchesSearchQuery && matchesCity;
    }).toList();

    // Tri des tokens
    if (_sortOption == 'name') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['shortName'].compareTo(b['shortName'])
          : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == 'price') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['tokenPrice'].compareTo(b['tokenPrice'])
          : b['tokenPrice'].compareTo(a['tokenPrice']));
    } else if (_sortOption == 'recentlyAdded') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['initialLaunchDate'].compareTo(b['initialLaunchDate'])
          : b['initialLaunchDate'].compareTo(a['initialLaunchDate']));
    }

    return filteredTokens;
  }

  // Méthode pour obtenir la liste unique des villes à partir des noms complets (fullName)
  List<String> _getUniqueCities(List<Map<String, dynamic>> tokens) {
    final cities = tokens
        .map((token) {
          List<String> parts = token['fullName'].split(',');
          return parts.length >= 2 ? parts[1].trim() : 'Unknown City';
        })
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RealTokens'),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.allTokens.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredAndSortedTokens = _filterAndSortTokens(dataManager);
          final uniqueCities = _getUniqueCities(dataManager.allTokens);

          return Column(
            children: [
              // Ligne avec tous les éléments de filtre et recherche
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search tokens...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          if (value == 'asc' || value == 'desc') {
                            _isAscending = value == 'asc';
                          } else {
                            _sortOption = value;
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: const Text('Sort by Name'),
                        ),
                        PopupMenuItem(
                          value: 'price',
                          child: const Text('Sort by Price'),
                        ),
                        PopupMenuItem(
                          value: 'recentlyAdded',
                          child: const Text('Sort by Recently Added'),
                        ),
                        const PopupMenuDivider(),
                        CheckedPopupMenuItem(
                          value: 'asc',
                          checked: _isAscending,
                          child: const Text('Ascending'),
                        ),
                        CheckedPopupMenuItem(
                          value: 'desc',
                          checked: !_isAscending,
                          child: const Text('Descending'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8.0),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.location_city),
                      onSelected: (String value) {
                        setState(() {
                          _selectedCity = value == 'All Cities' ? null : value;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'All Cities',
                            child: Text('All Cities'),
                          ),
                          ...uniqueCities.map((city) => PopupMenuItem(
                                value: city,
                                child: Text(city),
                              )),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 20),
                  itemCount: filteredAndSortedTokens.length,
                  itemBuilder: (context, index) {
                    final token = filteredAndSortedTokens[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => showTokenDetails(context, token),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: token['imageLink'][0] ?? '',
                                      width: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  Expanded(
                                    child: Card(
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      color: Theme.of(context).cardColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  token['shortName'] ??
                                                      'Nom indisponible',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Asset price: ${formatCurrency(token['totalInvestment'] ?? 0)}',
                                            ),
                                            Text(
                                              'Token price: ${token['tokenPrice']}',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Expected Yield: ${token['annualPercentageYield'].toStringAsFixed(2)} %',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
