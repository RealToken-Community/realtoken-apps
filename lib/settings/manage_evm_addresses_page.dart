import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Pour copier dans le presse-papiers
import '../api/data_manager.dart';
import '../api/api_service.dart';
import '../../app_state.dart'; // Import pour accéder à AppState

class ManageEvmAddressesPage extends StatefulWidget {
  const ManageEvmAddressesPage({super.key});

  @override
  _ManageEthAddressesPageState createState() => _ManageEthAddressesPageState();
}

class _ManageEthAddressesPageState extends State<ManageEvmAddressesPage> {
  final TextEditingController _ethAddressController = TextEditingController();
  List<String> ethAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses(); // Charger les adresses sauvegardées
  }

  @override
  void dispose() {
    _ethAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ethAddresses = prefs.getStringList('evmAddresses') ?? [];
    });
  }

  String? _extractEthereumAddress(String scannedData) {
    // Vérifiez si le code scanné contient une adresse Ethereum valide
    RegExp ethAddressRegExp = RegExp(r'(0x[a-fA-F0-9]{40})');
    final match = ethAddressRegExp.firstMatch(scannedData);
    if (match != null) {
      return match.group(0); // Retourne la première adresse valide
    }
    return null; // Aucune adresse trouvée
  }

  Future<void> _saveAddress(String address) async {
    if (!ethAddresses.contains(address)) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        ethAddresses.add(address.toLowerCase());
      });
      await prefs.setStringList('evmAddresses', ethAddresses);

      final dataManager = Provider.of<DataManager>(context, listen: false);

      // Récupérer le userId associé à l'adresse via ApiService
      final userId = await ApiService.fetchUserIdFromAddress(address);
      if (userId != null) {
        // Récupérer les autres adresses associées au userId
        final associatedAddresses = await ApiService.fetchAddressesForUserId(userId);
        dataManager.addAddressesForUserId(userId, associatedAddresses);

        setState(() {
          ethAddresses.addAll(associatedAddresses.where((addr) => !ethAddresses.contains(addr)));
        });

        await prefs.setStringList('evmAddresses', ethAddresses);
      }
      await dataManager.updateGlobalVariables(forceFetch: true);
      dataManager.fetchRentData(forceFetch: true); // Forcer le fetch des données de loyer
      dataManager.fetchAndCalculateData(forceFetch: true); // Forcer le fetch
    }
  }

  String? _validateEVMAddress(String address) {
    if (address.startsWith('0x') && address.length == 42) {
      return null; // Adresse valide
    }
    return 'Invalid Wallet address';
  }

  Future<void> _scanQRCode() async {
    bool isAddressSaved = false; // Pour éviter l'ajout multiple
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: MobileScanner(onDetect: (BarcodeCapture barcodeCapture) {
          if (!isAddressSaved) {
            final List<Barcode> barcodes = barcodeCapture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final String code = barcode.rawValue!;
                final String? extractedAddress = _extractEthereumAddress(code);
                if (extractedAddress != null) {
                  _saveAddress(extractedAddress);
                  isAddressSaved = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Wallet saved: $extractedAddress')),
                  );
                  Navigator.of(context).pop(); // Fermer le scanner
                  break;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid wallet in QR Code')),
                  );
                }
              }
            }
          }
        }),
      ),
    ));
  }

  Future<void> _deleteAddress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ethAddresses.removeAt(index);
    });
    await prefs.setStringList('evmAddresses', ethAddresses);
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context); // Récupérer AppState pour le texte

    // Récupérer toutes les adresses liées à un userId
    final List linkedAddresses = dataManager
        .getAllUserIds()
        .expand((userId) => dataManager.getAddressesForUserId(userId) ?? [])
        .toList();

    // Filtrer les adresses non liées
    final unlinkedAddresses =
        ethAddresses.where((address) => !linkedAddresses.contains(address)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Wallets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ethAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _scanQRCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Fond bleu
                    foregroundColor: Colors.white, // Icône blanche
                  ),
                  child: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String enteredAddress = _ethAddressController.text;
                if (_validateEVMAddress(enteredAddress) == null) {
                  _saveAddress(enteredAddress);
                  _ethAddressController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid wallet address')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Fond bleu
                foregroundColor: Colors.white, // Texte blanc
              ),
              child: Text(
                'Save Address',
                style: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
              ),
            ),
            const SizedBox(height: 20),

            if (unlinkedAddresses.isNotEmpty) ...[
              Text(
                'Unlinked Wallet Addresses',
                style: TextStyle(
                  fontSize: 18 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: unlinkedAddresses.length,
                  itemBuilder: (context, index) {
                    final address = unlinkedAddresses[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: address));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Address copied: $address')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteAddress(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (dataManager.getAllUserIds().isNotEmpty) ...[
              Text(
                'User Linked Wallet Addresses',
                style: TextStyle(
                  fontSize: 18 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: dataManager.getAllUserIds().length,
                  itemBuilder: (context, index) {
                    final userId = dataManager.getAllUserIds()[index];
                    final addresses = dataManager.getAddressesForUserId(userId);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'User ID: $userId',
                                style: TextStyle(
                                  fontSize: 18 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  dataManager.removeUserId(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User ID $userId deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...addresses!.map((address) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, color: Colors.blue),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: address));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Address copied: $address')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      dataManager.removeAddressForUserId(userId, address);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Address $address deleted')),
                                      );
                                    },
                                  ),
                                ],
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
