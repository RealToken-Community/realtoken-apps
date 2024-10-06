import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';  // Importer url_launcher pour ouvrir des liens externes
import '../settings/settings_page.dart';  // Importer la page des paramètres
import '../pages/real_tokens_page.dart';  // Importer la page des RealTokens
import '../about.dart';  // Importer la page About
import '../updates_page.dart';  // Importer la page des mises à jour
import 'dart:io'; // Pour détecter la plateforme
import '../generated/l10n.dart';  // Importer les traductions
import '../settings/manage_evm_addresses_page.dart';  // Ajouter cet import si ce n'est pas déjà le cas

class CustomDrawer extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const CustomDrawer({required this.onThemeChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RealToken',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Platform.isAndroid ? 23 : 24, // Réduction pour Android
                      ),
                    ),
                    Text(
                      S.of(context).appDescription, // Utilisation de la traduction
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: Platform.isAndroid ? 15 : 16, // Réduction pour Android
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
           ListTile(
            leading: const Icon(Icons.wallet),
            title: Text(
              S.of(context).manageEvmAddresses,  // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16),  // Réduction pour Android
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageEvmAddressesPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list),
            title: Text(
              S.of(context).realTokensList, // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16), // Réduction pour Android
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RealTokensPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: Text(
              S.of(context).recentChanges, // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16), // Réduction pour Android
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdatesPage(),
                ),
              );
            },
          ),
         
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(
              S.of(context).settings, // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16), // Réduction pour Android
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(onThemeChanged: onThemeChanged),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(
              S.of(context).about, // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16), // Réduction pour Android
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(
              S.of(context).feedback, // Utilisation de la traduction
              style: TextStyle(fontSize: Platform.isAndroid ? 15 : 16), // Réduction pour Android
            ),
            onTap: () {
              _launchFeedbackURL();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _launchFeedbackURL() async {
    const url = 'https://github.com/RealToken-Community/realtoken-apps/issues';
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      throw 'Impossible d\'ouvrir le lien $url';
    }
  }
}
