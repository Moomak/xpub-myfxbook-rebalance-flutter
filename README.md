# Portfolio Rebalancer Flutter App

A Flutter application designed to act as a portfolio dashboard and rebalancing tool. It helps users track their Bitcoin (derived from a zPub key) and Myfxbook account balances, calculates their total value in a target currency (e.g., USDT), and suggests rebalancing actions based on a user-defined target ratio.

This project is inspired by the PHP-based [xpub-myfxbook-rebalance](https://github.com/Moomak/xpub-myfxbook-rebalance).

## Features

*   Fetches Bitcoin balance from a zPub key using the Blockchain.info API.
*   Fetches Myfxbook account balance using the Myfxbook API.
*   Fetches cryptocurrency exchange rates (e.g., BTC/TARGET_CURRENCY, USDT/TARGET_CURRENCY) from the CoinGecko API.
*   Calculates and displays the total portfolio value in the chosen target currency.
*   Shows the current allocation of assets in the portfolio.
*   Allows users to set a target allocation ratio for Bitcoin vs. Myfxbook holdings.
*   Calculates and suggests adjustments needed to achieve the target allocation.

## Getting Started

This project is a starting point for a Flutter application.

To get started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Prerequisites

*   Flutter SDK: Ensure you have Flutter installed. For installation instructions, see the [Flutter documentation](https://docs.flutter.dev/get-started/install).
*   An IDE like Android Studio (with Flutter plugin) or Visual Studio Code (with Flutter extension).

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Moomak/xpub-myfxbook-rebalance-flutter
    cd rebalance_portfolio_flutter
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configuration:**
    The application will require API keys and user credentials to function. These will likely be managed via a configuration file or secure storage within the app. Details to be provided include:
    *   `ZPUB_KEY`: Your Bitcoin zPub key (Native SegWit - BIP84).
    *   `COINGECKO_API_KEY`: (Optional) Your CoinGecko API key.
    *   `TARGET_CURRENCY`: Target currency for display and conversions (e.g., 'usd', 'usdt').
    *   `MYFXBOOK_EMAIL`: Your Myfxbook login email.
    *   `MYFXBOOK_PASSWORD`: Your Myfxbook login password.
    *   `MYFXBOOK_TARGET_ACCOUNT_NAME`: The exact name of your Myfxbook account.

    *Note: Securely managing these credentials is crucial. Do not hardcode them directly into version-controlled files.*

4.  **Run the application:**
    ```bash
    flutter run
    ```

## How Balances & Rates Are Fetched (Planned)

*   **Bitcoin (zPub):** The app will utilize libraries to derive addresses from the zPub key and fetch balances via the Blockchain.info API.
*   **Myfxbook:** The app will interact with the Myfxbook API (likely JSON-based) to retrieve account balances, handling login and session management as needed.
*   **Exchange Rates:** The app will fetch exchange rates from the CoinGecko API.

## Disclaimer

*   This application is for informational and personal use. Use at your own risk.
*   You are responsible for the security of your API keys, zPub, and Myfxbook credentials.
*   Data accuracy depends on external APIs (Blockchain.info, CoinGecko, Myfxbook).
*   The application is intended to perform read-only operations on your accounts where possible.
