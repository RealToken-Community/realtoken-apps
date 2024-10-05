import 'dart:io'; // Pour détecter la plateforme
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/data_manager.dart';

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

  Future<void> _saveAddress(String address) async {
    if (!ethAddresses.contains(address)) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        ethAddresses.add(address.toLowerCase());
      });
      await prefs.setStringList('evmAddresses', ethAddresses);

       // Appeler les méthodes du DataManager après avoir ajouté une adresse
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.fetchAndCalculateData(forceFetch: true); // Forcer le fetch
    dataManager.fetchRentData(forceFetch: true);         // Forcer le fetch des données de loyer
    dataManager.fetchPropertyData(forceFetch: true);     // Forcer le fetch des données de propriété
  
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
        body: MobileScanner(
          onDetect: (BarcodeCapture barcodeCapture) {
            if (!isAddressSaved) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final String code = barcode.rawValue!;
                  if (_validateEVMAddress(code) == null) {
                    _saveAddress(code);
                    isAddressSaved = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Wallet saved: $code')),
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
          },
        ),
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
                    style: TextStyle(
                      fontSize: Platform.isAndroid ? 14.0 : 15.0, // Taille de texte ajustée pour Android
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Icône blanche
                  ),
                  onPressed: _scanQRCode, 
                  child: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Texte blanc
                textStyle: TextStyle(
                  fontSize: Platform.isAndroid ? 14.0 : 15.0, // Taille ajustée pour Android
                ),
              ),
              onPressed: () {
                String enteredAddress = _ethAddressController.text;
                if (_validateEVMAddress(enteredAddress) == null) {
                  _saveAddress(enteredAddress);
                  _ethAddressController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Address saved: $enteredAddress')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid wallet address')),
                  );
                }
              },
              child: const Text('Save Address'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ethAddresses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      ethAddresses[index],
                      style: TextStyle(
                        fontSize: Platform.isAndroid ? 14.0 : 15.0, // Taille ajustée pour Android
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteAddress(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Address deleted')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
