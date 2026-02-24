---
name: finn
description: "Query Finnhub financial market data — real-time quotes, company fundamentals, analyst estimates, insider trading, earnings, technical indicators, economic calendars, ESG, congressional trading. Use when the user asks about stock data, company analysis, market reports, insider activity, price targets, earnings surprises, technical analysis, economic events, or needs data for financial advisory reports."
allowed-tools: Bash
argument-hint: "[command] [args...]"
---

# finnhub-cli.sh — Finnhub Financial Market Data CLI

Query real-time and historical financial market data from the Finnhub API. Designed for a financial advisor building market reports and client advisory content.

## Base Command

> **IMPORTANT:** Update the path below to match where you cloned the repo.

```bash
/path/to/finnhub-skill/finnhub-cli.sh <command> [args...]
```

Shorthand in this doc:
```
finnhub-cli.sh <command>   # means the full path above
```

## Important Notes

1. API key is pre-configured. No setup needed.
2. All output is **raw JSON** to stdout. Errors go to stderr.
3. Some endpoints require premium Finnhub plan (noted below). Free tier covers most commands.
4. Rate limit: 30 calls/sec on free tier. Space out bulk queries.
5. All dates use `YYYY-MM-DD` format. Smart defaults are applied when dates are omitted.

## Command Shorthand

| User says | Command |
|-----------|---------|
| AAPL price, quote AAPL | `finnhub-cli.sh quote AAPL` |
| AAPL profile, tell me about AAPL | `finnhub-cli.sh profile AAPL` |
| AAPL news | `finnhub-cli.sh company-news AAPL` |
| market news, headlines | `finnhub-cli.sh market-news` |
| AAPL metrics, AAPL ratios, PE ratio | `finnhub-cli.sh metrics AAPL` |
| AAPL earnings | `finnhub-cli.sh earnings AAPL` |
| AAPL analyst, recommendations | `finnhub-cli.sh recommendation AAPL` |
| AAPL price target | `finnhub-cli.sh price-target AAPL` |
| AAPL EPS estimate | `finnhub-cli.sh eps-estimate AAPL` |
| AAPL insiders, insider buying | `finnhub-cli.sh insider-transactions AAPL` |
| AAPL insider sentiment | `finnhub-cli.sh insider-sentiment AAPL` |
| who owns AAPL | `finnhub-cli.sh ownership AAPL` |
| AAPL peers, competitors | `finnhub-cli.sh peers AAPL` |
| AAPL financials, income statement | `finnhub-cli.sh financials AAPL` |
| AAPL balance sheet | `finnhub-cli.sh financials AAPL --statement bs` |
| AAPL cash flow | `finnhub-cli.sh financials AAPL --statement cf` |
| AAPL revenue breakdown | `finnhub-cli.sh revenue-breakdown AAPL` |
| AAPL executives | `finnhub-cli.sh executives AAPL` |
| AAPL candle, AAPL chart data | `finnhub-cli.sh candle AAPL` |
| AAPL RSI | `finnhub-cli.sh indicator AAPL --indicator rsi` |
| AAPL SMA 50 | `finnhub-cli.sh indicator AAPL --indicator sma --timeperiod 50` |
| AAPL support resistance | `finnhub-cli.sh support-resistance AAPL` |
| AAPL pattern | `finnhub-cli.sh pattern AAPL` |
| search apple | `finnhub-cli.sh search apple` |
| S&P 500 members | `finnhub-cli.sh index-constituents ^GSPC` |
| SPY holdings | `finnhub-cli.sh etf-holdings SPY` |
| earnings this week | `finnhub-cli.sh earnings-calendar` |
| upcoming IPOs | `finnhub-cli.sh ipo-calendar` |
| economic calendar | `finnhub-cli.sh economic-calendar` |
| sector performance | `finnhub-cli.sh sector-metrics` |
| AAPL ESG score | `finnhub-cli.sh esg AAPL` |
| AAPL congressional trading | `finnhub-cli.sh congressional-trading AAPL` |
| AAPL supply chain | `finnhub-cli.sh supply-chain AAPL` |
| forex rates, USD rates | `finnhub-cli.sh forex-rates` |
| country risk data | `finnhub-cli.sh country` |
| upgrade downgrade AAPL | `finnhub-cli.sh upgrade-downgrade AAPL` |

## Quick Reference

### Market Data & Quotes
```bash
finnhub-cli.sh quote AAPL                          # Real-time price, change, high/low
finnhub-cli.sh candle AAPL                         # OHLCV (default: daily, last year)
finnhub-cli.sh candle AAPL --resolution 60 --from 2025-01-01 --to 2025-06-01
finnhub-cli.sh search "apple"                      # Find ticker symbols
finnhub-cli.sh symbols US                          # All symbols on an exchange
finnhub-cli.sh market-status US                    # Is the market open?
finnhub-cli.sh market-news                         # General market headlines
finnhub-cli.sh market-news --category crypto       # Categories: general, forex, crypto, merger
finnhub-cli.sh company-news AAPL                   # Company news (default: last 30 days)
finnhub-cli.sh company-news AAPL --from 2025-01-01 --to 2025-02-01
finnhub-cli.sh forex-rates                         # FX rates (default: USD base)
finnhub-cli.sh forex-rates --base EUR
finnhub-cli.sh forex-candle OANDA:EUR_USD          # Forex OHLCV
finnhub-cli.sh crypto-candle BINANCE:BTCUSDT       # Crypto OHLCV
```

### Company Fundamentals
```bash
finnhub-cli.sh profile AAPL                        # Name, sector, market cap, IPO date
finnhub-cli.sh peers AAPL                          # Comparable companies
finnhub-cli.sh metrics AAPL                        # PE, EPS, margins, beta, 52w high/low
finnhub-cli.sh financials AAPL                     # Income statement (annual)
finnhub-cli.sh financials AAPL --statement bs      # Balance sheet
finnhub-cli.sh financials AAPL --statement cf      # Cash flow
finnhub-cli.sh financials AAPL --freq quarterly    # Quarterly
finnhub-cli.sh financials-reported AAPL            # As-reported SEC filing data
finnhub-cli.sh revenue-breakdown AAPL              # Revenue by segment/geography
finnhub-cli.sh executives AAPL                     # C-suite and board members
finnhub-cli.sh insider-transactions AAPL           # Insider buying/selling (default: 90 days)
finnhub-cli.sh insider-sentiment AAPL              # Net insider sentiment
finnhub-cli.sh ownership AAPL                      # Institutional holders
```

### Estimates & Analyst Data
```bash
finnhub-cli.sh recommendation AAPL                 # Buy/hold/sell consensus by month
finnhub-cli.sh price-target AAPL                   # Analyst targets: high, low, mean, median
finnhub-cli.sh eps-estimate AAPL                   # Forward EPS estimates (default: quarterly)
finnhub-cli.sh eps-estimate AAPL --freq annual
finnhub-cli.sh revenue-estimate AAPL               # Forward revenue estimates
finnhub-cli.sh earnings AAPL                       # EPS actual vs estimate (default: 4 quarters)
finnhub-cli.sh earnings AAPL --limit 8
finnhub-cli.sh earnings-calendar                   # Upcoming earnings (default: next 7 days)
finnhub-cli.sh earnings-calendar --symbol AAPL     # Filter to one company
finnhub-cli.sh upgrade-downgrade AAPL              # Analyst rating changes (default: 90 days)
finnhub-cli.sh ipo-calendar                        # Upcoming IPOs (default: next 30 days)
```

### Sentiment & Alternative Data
```bash
finnhub-cli.sh news-sentiment AAPL                 # News sentiment scores (premium)
finnhub-cli.sh social-sentiment AAPL               # Reddit/Twitter sentiment (premium)
finnhub-cli.sh congressional-trading AAPL          # Politician stock trades (90 days)
finnhub-cli.sh supply-chain AAPL                   # Key customers and suppliers
finnhub-cli.sh sector-metrics                      # Sector performance (default: NA region)
finnhub-cli.sh sector-metrics --region EU
finnhub-cli.sh esg AAPL                            # ESG scores
```

### Technical Analysis & Indices
```bash
finnhub-cli.sh indicator AAPL --indicator sma      # 14-period SMA (default)
finnhub-cli.sh indicator AAPL --indicator rsi      # RSI
finnhub-cli.sh indicator AAPL --indicator macd     # MACD
finnhub-cli.sh indicator AAPL --indicator sma --timeperiod 50   # 50-day SMA
finnhub-cli.sh indicator AAPL --indicator bbands   # Bollinger Bands
# Available: sma, ema, rsi, macd, bbands, stoch, adx, atr, cci, obv, wma
finnhub-cli.sh pattern AAPL                        # Candlestick pattern recognition
finnhub-cli.sh support-resistance AAPL             # Support/resistance levels
finnhub-cli.sh index-constituents ^GSPC            # S&P 500 members
finnhub-cli.sh index-constituents ^DJI             # Dow Jones members
finnhub-cli.sh etf-holdings SPY                    # ETF portfolio breakdown
finnhub-cli.sh etf-holdings QQQ
```

### Economic & Calendar
```bash
finnhub-cli.sh economic-calendar                   # Economic events (default: next 7 days)
finnhub-cli.sh economic-codes                      # List economic indicator codes
finnhub-cli.sh economic MA-USA-656880              # Historical economic data by code
finnhub-cli.sh country                             # Country metadata with risk premiums
```

## Common Workflows for Financial Advisory

### Daily Market Briefing
```bash
finnhub-cli.sh quote AAPL && finnhub-cli.sh quote MSFT && finnhub-cli.sh quote GOOGL
finnhub-cli.sh market-news
finnhub-cli.sh economic-calendar
finnhub-cli.sh sector-metrics
```

### Company Deep Dive for Client
```bash
finnhub-cli.sh profile AAPL
finnhub-cli.sh metrics AAPL
finnhub-cli.sh recommendation AAPL
finnhub-cli.sh price-target AAPL
finnhub-cli.sh earnings AAPL
finnhub-cli.sh eps-estimate AAPL
finnhub-cli.sh revenue-estimate AAPL
finnhub-cli.sh insider-transactions AAPL
finnhub-cli.sh company-news AAPL --from 2025-02-01 --to 2025-02-24
```

### Competitor Analysis
```bash
finnhub-cli.sh peers AAPL
finnhub-cli.sh quote AAPL && finnhub-cli.sh quote MSFT && finnhub-cli.sh quote GOOGL
finnhub-cli.sh metrics AAPL && finnhub-cli.sh metrics MSFT
finnhub-cli.sh recommendation AAPL && finnhub-cli.sh recommendation MSFT
```

### Portfolio Review / Technical Check
```bash
finnhub-cli.sh quote AAPL
finnhub-cli.sh candle AAPL --from 2025-01-01 --to 2025-02-24
finnhub-cli.sh indicator AAPL --indicator rsi
finnhub-cli.sh indicator AAPL --indicator sma --timeperiod 50
finnhub-cli.sh support-resistance AAPL
```

### IPO & Earnings Watch
```bash
finnhub-cli.sh earnings-calendar
finnhub-cli.sh ipo-calendar
finnhub-cli.sh upgrade-downgrade AAPL
```

### Macro Overview
```bash
finnhub-cli.sh economic-calendar
finnhub-cli.sh forex-rates
finnhub-cli.sh sector-metrics
finnhub-cli.sh country
```

## Error Handling

- **HTTP 403**: Endpoint requires premium Finnhub plan. Known premium endpoints: news-sentiment, social-sentiment, candle (some symbols), forex-rates, crypto-candle, upgrade-downgrade, price-target.
- **HTTP 429**: Rate limited. Wait a few seconds and retry.
- **Empty JSON / `{}`**: Symbol may be invalid or data not available. Verify with `finnhub-cli.sh search`.
- **Network timeout**: Transient issue. Retry the command.

## Free vs Premium Endpoints

**Free tier** (working): quote, profile, peers, metrics, recommendation, earnings, search, company-news, market-news, index-constituents, executives, ownership, insider-transactions, insider-sentiment, earnings-calendar, ipo-calendar, economic-calendar, country, economic-codes, sector-metrics, esg, congressional-trading, supply-chain, financials-reported, pattern, support-resistance.

**Premium** (returns 403 on free plan): news-sentiment, social-sentiment, candle (some), forex-rates, forex-candle, crypto-candle, upgrade-downgrade, price-target, indicator.

## Complementary Use with yfinance

This skill pairs well with the `yfinance` skill. Use **finnhub-cli.sh** for:
- Insider transactions & sentiment
- Congressional trading
- Supply chain relationships
- ESG scores
- Sector metrics
- Economic calendars & indicators
- Earnings calendar with broad date ranges
- Index constituents

Use **yfinance** for:
- Price targets (free on Yahoo)
- Options chains
- Detailed holder breakdowns
- Screeners (day gainers, most active)
- Macro overview (indices, bonds, commodities in one call)
- Historical price data (free)
- Dividend history
