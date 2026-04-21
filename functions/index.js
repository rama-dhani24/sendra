/**
 * Sendra — Exchange Rate Cloud Function
 *
 * Runs on a schedule (every 30 min) and on HTTP request.
 * Fetches live rates from two sources:
 *   • ExchangeRate-API  → fiat rates (GBP, EUR, USD → USD base)
 *   • CoinGecko free API → USDT/TZS price + crypto prices
 *
 * Writes result to Firestore: /config/exchange_rates
 *
 * Flutter reads ONLY from Firestore — never calls these APIs directly.
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

// ─── Config ────────────────────────────────────────────────────────────────
const SPREAD = 0.015;          // 1.5% applied on sender-side conversions
const FEE_RATE = 0.01;         // 1.0% transaction fee

// Fiat symbols to pull from ExchangeRate-API (USD base)
const FIAT_SYMBOLS = ["GBP", "EUR", "TZS"];

// Crypto coins to pull from CoinGecko
// key = CoinGecko id, value = our symbol
const CRYPTO_IDS = {
  tether: "USDT",
  bitcoin: "BTC",
  ethereum: "ETH",
  solana: "SOL",
  binancecoin: "BNB",
  ripple: "XRP",
  cardano: "ADA",
  dogecoin: "DOGE",
};

// ─── Main logic ─────────────────────────────────────────────────────────────
async function fetchAndStoreRates() {
  logger.info("Sendra: fetching exchange rates...");

  const [fiatRates, cryptoRates] = await Promise.all([
    fetchFiatRates(),
    fetchCryptoRates(),
  ]);

  // USDT→TZS comes from CoinGecko (USDT price in TZS)
  // CoinGecko returns USDT price in USD (~1.0), then we use TZS/USD rate
  const usdToTzs = fiatRates["TZS"] ?? 2650;
  const usdtPriceUsd = cryptoRates["USDT"]?.usd ?? 1.0;
  const usdtToTzs = usdtPriceUsd * usdToTzs;

  const payload = {
    // Fiat → USDT mid-market rates (1 unit of currency = X USDT)
    fiat: {
      GBP: fiatRates["GBP"] ? (1 / fiatRates["GBP"]) * usdtPriceUsd : 1.27,
      EUR: fiatRates["EUR"] ? (1 / fiatRates["EUR"]) * usdtPriceUsd : 1.08,
      USD: usdtPriceUsd,
      USDT: 1.0,
    },

    // Receiving side: 1 USDT = X TZS
    usdtToTzs,

    // Crypto prices in USD (for ExchangePage crypto tab)
    crypto: {
      BTC: cryptoRates["BTC"]?.usd ?? 65000,
      ETH: cryptoRates["ETH"]?.usd ?? 3200,
      SOL: cryptoRates["SOL"]?.usd ?? 140,
      BNB: cryptoRates["BNB"]?.usd ?? 600,
      XRP: cryptoRates["XRP"]?.usd ?? 0.60,
      ADA: cryptoRates["ADA"]?.usd ?? 0.45,
      DOGE: cryptoRates["DOGE"]?.usd ?? 0.16,
    },

    // Sendra business config (editable without redeploying)
    config: {
      spread: SPREAD,
      feeRate: FEE_RATE,
    },

    updatedAt: FieldValue.serverTimestamp(),
    source: "ExchangeRate-API + CoinGecko",
  };

  await db.collection("config").doc("exchange_rates").set(payload);
  logger.info("Sendra: rates stored successfully", { usdtToTzs });
  return payload;
}

// ─── ExchangeRate-API (free tier, USD base) ─────────────────────────────────
async function fetchFiatRates() {
  try {
    // Free tier: https://open.er-api.com/v6/latest/USD
    // Returns { rates: { GBP: 0.78, EUR: 0.92, TZS: 2650, ... } }
    const res = await fetch("https://open.er-api.com/v6/latest/USD");
    if (!res.ok) throw new Error(`ExchangeRate-API HTTP ${res.status}`);
    const data = await res.json();
    if (data.result !== "success") throw new Error("ExchangeRate-API error");

    return {
      GBP: data.rates.GBP,   // USD per 1 GBP  (e.g. 0.788)
      EUR: data.rates.EUR,   // USD per 1 EUR  (e.g. 0.926)
      TZS: data.rates.TZS,   // TZS per 1 USD  (e.g. 2650)
    };
  } catch (err) {
    logger.error("Fiat rate fetch failed, using fallback", err);
    return { GBP: 0.788, EUR: 0.926, TZS: 2650 };
  }
}

// ─── CoinGecko (free, no key required) ──────────────────────────────────────
async function fetchCryptoRates() {
  try {
    const ids = Object.keys(CRYPTO_IDS).join(",");
    const url = `https://api.coingecko.com/api/v3/simple/price?ids=${ids}&vs_currencies=usd`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`CoinGecko HTTP ${res.status}`);
    const data = await res.json();

    // Remap CoinGecko ids → our symbols
    const result = {};
    for (const [geckoId, symbol] of Object.entries(CRYPTO_IDS)) {
      if (data[geckoId]) result[symbol] = data[geckoId];
    }
    return result;
  } catch (err) {
    logger.error("Crypto rate fetch failed, using fallback", err);
    return {
      USDT: { usd: 1.0 },
      BTC: { usd: 65000 },
      ETH: { usd: 3200 },
      SOL: { usd: 140 },
      BNB: { usd: 600 },
      XRP: { usd: 0.60 },
      ADA: { usd: 0.45 },
      DOGE: { usd: 0.16 },
    };
  }
}

// ─── Exports ────────────────────────────────────────────────────────────────

// Scheduled: every 30 minutes
exports.refreshExchangeRates = onSchedule("every 30 minutes", async () => {
  await fetchAndStoreRates();
});

// HTTP: call manually to force a refresh (useful during dev)
// GET https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/refreshRatesHttp
exports.refreshRatesHttp = onRequest(async (req, res) => {
  try {
    const payload = await fetchAndStoreRates();
    res.json({ success: true, rates: payload });
  } catch (err) {
    logger.error("Manual refresh failed", err);
    res.status(500).json({ success: false, error: err.message });
  }
});