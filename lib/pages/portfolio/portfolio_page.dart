import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../api/data_manager.dart'; 
import 'portfolio_display_1.dart';
import 'portfolio_display_2.dart';
import '../../generated/l10n.dart'; // Import pour les traductions

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  bool _isDisplay1 = true; 
  String _searchQuery = ''; 
  String _sortOption = 'Name'; 
  bool _isAscending = true;
  String? _selectedCity; 
  String _rentalStatusFilter = 'All'; // Nouveau filtre pour le statut de location

  @override
  void initState() {
    super.initState();
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.fetchAndCalculateData(); 
    _loadDisplayPreference(); 
  }

  Future<void> _loadDisplayPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDisplay1 = prefs.getBool('isDisplay1') ?? true; 
    });
  }

  Future<void> _saveDisplayPreference(bool isDisplay1) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDisplay1', isDisplay1);
  }

  void _toggleDisplay() {
    setState(() {
      _isDisplay1 = !_isDisplay1;
    });
    _saveDisplayPreference(_isDisplay1); 
  }

  // Modifier la méthode pour appliquer le filtre sur le statut de location
  List<Map<String, dynamic>> _filterAndSortPortfolio(List<Map<String, dynamic>> portfolio) {
    List<Map<String, dynamic>> filteredPortfolio = portfolio
        .where((token) =>
            token['fullName'].toLowerCase().contains(_searchQuery.toLowerCase()) &&
            (_selectedCity == null || token['fullName'].contains(_selectedCity!)) &&
            (_rentalStatusFilter == S.of(context).rentalStatusAll || _filterByRentalStatus(token)))
        .toList();

    if (_sortOption == S.of(context).sortByName) {
      filteredPortfolio.sort((a, b) =>
          _isAscending ? a['shortName'].compareTo(b['shortName']) : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == S.of(context).sortByValue) {
      filteredPortfolio.sort((a, b) => _isAscending
          ? a['totalValue'].compareTo(b['totalValue'])
          : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == S.of(context).sortByAPY) {
      filteredPortfolio.sort((a, b) => _isAscending
          ? a['annualPercentageYield'].compareTo(b['annualPercentageYield'])
          : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    }

    return filteredPortfolio;
  }

  // Nouvelle méthode pour filtrer par statut de location
  bool _filterByRentalStatus(Map<String, dynamic> token) {
    int rentedUnits = token['rentedUnits'] ?? 0;
    int totalUnits = token['totalUnits'] ?? 1;

    if (_rentalStatusFilter == S.of(context).rentalStatusRented) {
      return rentedUnits == totalUnits;
    } else if (_rentalStatusFilter == S.of(context).rentalStatusPartiallyRented) {
      return rentedUnits > 0 && rentedUnits < totalUnits;
    } else if (_rentalStatusFilter == S.of(context).rentalStatusNotRented) {
      return rentedUnits == 0;
    }
    return true;
  }

  // Méthode pour obtenir la liste unique des villes à partir des noms complets (fullName)
  List<String> _getUniqueCities(List<Map<String, dynamic>> portfolio) {
    final cities = portfolio.map((token) {
      List<String> parts = token['fullName'].split(',');
      return parts.length >= 2 ? parts[1].trim() : S.of(context).unknownCity;
    }).toSet().toList();
    cities.sort(); 
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final sortedFilteredPortfolio = _filterAndSortPortfolio(dataManager.portfolio);
          final uniqueCities = _getUniqueCities(dataManager.portfolio); 

          return Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 40),
            child: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    primary: false,
                    floating: true,
                    snap: true,
                    title: Row(
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
                              hintText: S.of(context).searchHint, // "Search..."
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          icon: Icon(_isDisplay1 ? Icons.view_module : Icons.view_list),
                          onPressed: _toggleDisplay,
                        ),
                        const SizedBox(width: 8.0),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.location_city),
                          onSelected: (String value) {
                            setState(() {
                              _selectedCity = value == S.of(context).allCities ? null : value;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                value: S.of(context).allCities,
                                child: Text(S.of(context).allCities),
                              ),
                              ...uniqueCities.map((city) => PopupMenuItem(
                                    value: city,
                                    child: Text(city),
                                  )),
                            ];
                          },
                        ),
                        const SizedBox(width: 8.0),
                        
                        // Nouveau PopupMenuButton pour le filtre sur le statut de location
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_alt),
                          onSelected: (String value) {
                            setState(() {
                              _rentalStatusFilter = value;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                value: S.of(context).rentalStatusAll,
                                child: Text(S.of(context).rentalStatusAll),
                              ),
                              PopupMenuItem(
                                value: S.of(context).rentalStatusRented,
                                child: Text(S.of(context).rentalStatusRented),
                              ),
                              PopupMenuItem(
                                value: S.of(context).rentalStatusPartiallyRented,
                                child: Text(S.of(context).rentalStatusPartiallyRented),
                              ),
                              PopupMenuItem(
                                value: S.of(context).rentalStatusNotRented,
                                child: Text(S.of(context).rentalStatusNotRented),
                              ),
                            ];
                          },
                        ),
                        
                        const SizedBox(width: 8.0),
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            setState(() {
                              if (value == 'asc' || value == 'desc') {
                                _isAscending = (value == 'asc');
                              } else {
                                _sortOption = value;
                              }
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                value: S.of(context).sortByName,
                                child: Text(S.of(context).sortByName),
                              ),
                              PopupMenuItem(
                                value: S.of(context).sortByValue,
                                child: Text(S.of(context).sortByValue),
                              ),
                              PopupMenuItem(
                                value: S.of(context).sortByAPY,
                                child: Text(S.of(context).sortByAPY),
                              ),
                              const PopupMenuDivider(),
                              CheckedPopupMenuItem(
                                value: 'asc',
                                checked: _isAscending,
                                child: Text(S.of(context).ascending),
                              ),
                              CheckedPopupMenuItem(
                                value: 'desc',
                                checked: !_isAscending,
                                child: Text(S.of(context).descending),
                              ),
                            ];
                          },
                        ),
                        
                      ],
                    ),
                  ),
                ];
              },
              body: _isDisplay1
                  ? PortfolioDisplay1(portfolio: sortedFilteredPortfolio)
                  : PortfolioDisplay2(portfolio: sortedFilteredPortfolio),
            ),
          );
        },
      ),
    );
  }
}
