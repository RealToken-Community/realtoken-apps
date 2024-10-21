import 'package:RealToken/settings/service_status.dart';
import 'package:RealToken/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/settings_page.dart'; // Importer la page des paramètres
import '../pages/real_tokens_page.dart'; // Importer la page des RealTokens
import '../about.dart'; // Importer la page About
import '../pages/updates_page.dart'; // Importer la page des mises à jour
import '../pages/realt_page.dart'; // Importer la page TokenSummaryPage
// Pour détecter la plateforme
import '../generated/l10n.dart'; // Importer les traductions
import '../settings/manage_evm_addresses_page.dart'; // Ajouter cet import si ce n'est pas déjà le cas
import '../app_state.dart'; // Importer AppState

class CustomDrawer extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const CustomDrawer({required this.onThemeChanged, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
       return Drawer(
  child: SingleChildScrollView(  // Ajoute SingleChildScrollView pour permettre le défilement
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
                      fontSize: 23 + appState.getTextSizeOffset(),
                    ),
                  ),
                  Text(
                    S.of(context).appDescription,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15 + appState.getTextSizeOffset(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.wallet, size: 24 + appState.getTextSizeOffset()),
          title: Text(
            S.of(context).manageEvmAddresses,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
            S.of(context).realTokensList,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
            S.of(context).recentChanges,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
        ListTile(
          leading: const Icon(Icons.show_chart),
          title: Text(
            'RealT stats',
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RealtPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.monitor),
          title: Text(
            'Service Status',
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceStatusPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.book),
          title: Text(
            'Wiki',
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
          ),
          onTap: () {
            Utils.launchURL('https://community-realt.gitbook.io/tuto-community');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(
            S.of(context).settings,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: Text(
            S.of(context).about,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
            S.of(context).feedback,
            style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
          ),
          onTap: () {
            Utils.launchURL('https://github.com/RealToken-Community/realtoken-apps/issues');
          },
        ),
        const SizedBox(height: 20),
      ],
    ),
  ),
);
},
    );
  }
}
