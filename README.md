# RealToken_apss

RealToken apps is a mobile application built using Flutter, available on both iOS and Android, allowing users to access and see their fractional ownership of tokenized real estate. Leveraging blockchain technology, the app provides a seamless interface for users to view their RealToken portfolios, and access property details.

## Features

- **Real Estate Tokenization**: View your fractional ownership of properties and track real-time token values.
- **Portfolio Management**: Manage multiple real estate tokens directly from your mobile device.
- **Real-Time Updates**: Access live data about your tokens, rental income, and property details.

## Technology Stack

- **Framework**: Flutter (iOS & Android)
- **Backend**: Integrated with The Graph and Ethereum for real-time property and transaction data.
- **Storage**: Persistent storage of Ethereum addresses and portfolio data using Hive and Shared Preferences.
- **APIs**: 
  - [The Graph API](https://gateway-arbitrum.network.thegraph.com) for fetching token-related data.
  - [PitsBi API](https://pitswap-api.herokuapp.com) for accessing RealToken properties and details.
  - [ehpst API](https://ehpst.duckdns.org) for accessing RealToken rent tracker.


## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio/Xcode
- A valid Ethereum wallet address for testing
- configure TheGraph API key (theGraphApiKey) in api_service.dart

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/RealToken-Community/App-iOS.git
2. Navigate to the project directory:
    ```bash
    cd realtoken_app
3. Install dependencies:
    ```bash
    flutter pub get
4. Setup iOS with CocoaPods (for macOS):
    ```bash
### Running the app
To run on Android:
    ```bash
    flutter run
To run on Android:
    ```bash
    flutter run --release

### Configuration
Ajoutez vos adresses de portefeuille Ethereum directement dans le menu **Settings** de l'application. Ces adresses seront enregistrées pour une utilisation future. Il est possible d'ajouter plusieurs portefeuilles, et l'application prend en charge la persistance des données d'une session à l'autre.

### Contributing

Nous accueillons les contributions ! Veuillez cloner le dépôt, puis soumettre une pull request. Pour les changements majeurs, merci d'ouvrir une issue pour discuter de ce que vous aimeriez modifier.

### License

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

### About RealToken

RealToken permet aux investisseurs de posséder des parts fractionnées de biens immobiliers via des jetons basés sur la blockchain. En achetant des jetons, les investisseurs peuvent accéder à des revenus locatifs, à l'appréciation des biens immobiliers et à d'autres avantages financiers. Pour en savoir plus sur la plateforme RealToken, visitez [realt.co](https://realt.co).


