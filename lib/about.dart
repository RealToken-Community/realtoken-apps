import 'package:RealToken/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importer pour le copier dans le presse-papiers
import 'dart:io'; // Importer pour détecter la plateforme
import 'package:provider/provider.dart'; // Pour accéder à AppState
import '../generated/l10n.dart'; // Importer pour les traductions
import '../../app_state.dart'; // Importer pour accéder à l'offset de texte

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à AppState

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).about), // Traduction pour "About"
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            // Section Nom et Version de l'application
            SectionHeader(
              title: S.of(context).application, // Traduction pour "Application"
              textSizeOffset: appState.getTextSizeOffset(),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                S.of(context).appName, // Traduction pour "Nom de l'application"
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
              ),
              subtitle: const Text('RealToken App'),
            ),
            ListTile(
              leading: const Icon(Icons.verified),
              title: Text(
                S.of(context).version, // Traduction pour "Version"
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
              ),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                S.of(context).author, // Traduction pour "Auteur"
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
              ),
              subtitle: const Text('Byackee'),
            ),

            // Padding pour décaler les liens
            Padding(
              padding: const EdgeInsets.only(left: 32.0), // Décalage des ListTile pour LinkedIn et GitHub
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      'LinkedIn',
                      style: TextStyle(
                          fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
                    ),
                    onTap: () => Utils.launchURL('https://www.linkedin.com/in/vincent-fresnel/'),
                    visualDensity: const VisualDensity(vertical: -4), // Réduction de l'espace vertical
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: Text(
                      'GitHub',
                      style: TextStyle(
                          fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
                    ),
                    onTap: () => Utils.launchURL('https://github.com/byackee'),
                    visualDensity: const VisualDensity(vertical: -4), // Réduction de l'espace vertical
                  ),
                ],
              ),
            ),

            const Divider(),

            // Section Remerciements
            SectionHeader(
              title: S.of(context).thanks, // Traduction pour "Remerciements"
              textSizeOffset: appState.getTextSizeOffset(),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(
                S.of(context).thankYouMessage, // Traduction pour "Merci à tous ceux qui ont contribué à ce projet"
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
              ),
              subtitle: Text(
                S.of(context).specialThanks, // Traduction pour "Remerciements particuliers à..."
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 13 : 14) + appState.getTextSizeOffset()),
              ),
            ),
            const Divider(),

            // Section Donation
            SectionHeader(
              title: S.of(context).donate, // Traduction pour "Faire un don"
              textSizeOffset: appState.getTextSizeOffset(),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: Text(
                S.of(context).supportProject, // Traduction pour "Soutenez le projet"
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 14 : 15) + appState.getTextSizeOffset()),
              ),
              subtitle: Text(
                S.of(context).donationMessage, // Traduction pour "Si vous aimez cette application..."
                style: TextStyle(
                    fontSize: (Platform.isAndroid ? 13 : 14) + appState.getTextSizeOffset()),
              ),
            ),

            // Boutons pour les donations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton PayPal
                ElevatedButton.icon(
                  onPressed: () {
                    Utils.launchURL('https://paypal.me/byackee?country.x=FR&locale.x=fr_FR');
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    S.of(context).paypal, // Traduction pour "PayPal"
                    style: TextStyle(
                        fontSize: (Platform.isAndroid ? 13 : 14) + appState.getTextSizeOffset(),
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                // Bouton Donation en Crypto
                ElevatedButton.icon(
                  onPressed: () {
                    _showCryptoAddressDialog(context, appState.getTextSizeOffset());
                  },
                  icon: const Icon(Icons.currency_bitcoin, color: Colors.white),
                  label: Text(
                    S.of(context).crypto, // Traduction pour "Crypto"
                    style: TextStyle(
                        fontSize: (Platform.isAndroid ? 13 : 14) + appState.getTextSizeOffset(),
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoAddressDialog(BuildContext context, double textSizeOffset) {
    const cryptoAddress = '0x2cb49d04890a98eb89f4f43af96ad01b98b64165'; // Remplacez par votre adresse Ethereum

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).cryptoDonationAddress, // Traduction pour "Adresse de Donation Crypto"
              style: TextStyle(fontSize: (Platform.isAndroid ? 13 : 14) + textSizeOffset)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).sendDonations, // Traduction pour "Envoyez vos donations à l'adresse suivante"
                  style: TextStyle(fontSize: (Platform.isAndroid ? 13 : 14) + textSizeOffset)),
              const SizedBox(height: 10),
              SelectableText(
                cryptoAddress,
                style: TextStyle(fontSize: (Platform.isAndroid ? 13 : 14) + textSizeOffset, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: cryptoAddress)); // Copier l'adresse dans le presse-papiers
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).addressCopied)), // Traduction pour "Adresse copiée dans le presse-papiers"
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(
                      S.of(context).copy, // Traduction pour "Copier"
                      style: TextStyle(fontSize: (Platform.isAndroid ? 13 : 14) + textSizeOffset),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                S.of(context).close, // Traduction pour "Fermer"
                style: TextStyle(fontSize: (Platform.isAndroid ? 13 : 14) + textSizeOffset),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final double textSizeOffset;

  const SectionHeader({required this.title, required this.textSizeOffset, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: (Platform.isAndroid ? 17 : 18) + textSizeOffset, // Ajustement pour Android avec offset
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
