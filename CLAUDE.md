# Finnhub CLI Tool (`finnhub-cli.sh`)

A lightweight CLI for querying financial market data from the Finnhub API. Used by a financial advisor to build market reports and advise clients on market movements.

## Quick Start

The CLI is at `/home/ubuntu/tinyclaw-workspace/finn/finnhub-cli.sh`. API key is pre-configured.

```bash
finnhub-cli.sh quote AAPL                    # Real-time price
finnhub-cli.sh profile AAPL                  # Company overview
finnhub-cli.sh recommendation AAPL          # Analyst consensus
finnhub-cli.sh company-news AAPL --from 2025-01-01 --to 2025-01-31
```

## Output

All output is JSON to stdout. Errors go to stderr. Pipe output directly or parse with jq.

## Command Reference

### Market Data & Quotes

| Command | Usage | Description |
|---------|-------|-------------|
| `quote` | `finnhub-cli.sh quote <symbol>` | Real-time price, change %, high/low, prev close |
| `candle` | `finnhub-cli.sh candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Historical OHLCV price data. Resolution: 1,5,15,30,60,D,W,M. Dates default to last year |
| `search` | `finnhub-cli.sh search <query>` | Find ticker symbols by company name |
| `symbols` | `finnhub-cli.sh symbols <exchange>` | List all symbols on an exchange (e.g., US, L, T) |
| `market-status` | `finnhub-cli.sh market-status <exchange>` | Is the market open or closed? |
| `market-news` | `finnhub-cli.sh market-news [--category general]` | Latest market news headlines. Categories: general, forex, crypto, merger |
| `company-news` | `finnhub-cli.sh company-news <symbol> [--from DATE] [--to DATE]` | Company-specific news. Defaults to last 30 days |
| `forex-rates` | `finnhub-cli.sh forex-rates [--base USD]` | Real-time FX exchange rates |
| `forex-candle` | `finnhub-cli.sh forex-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Forex OHLCV (e.g., OANDA:EUR_USD) |
| `crypto-candle` | `finnhub-cli.sh crypto-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Crypto OHLCV (e.g., BINANCE:BTCUSDT) |

### Company Fundamentals

| Command | Usage | Description |
|---------|-------|-------------|
| `profile` | `finnhub-cli.sh profile <symbol>` | Company overview: name, sector, market cap, IPO date, logo, website |
| `peers` | `finnhub-cli.sh peers <symbol>` | List of comparable/peer companies |
| `metrics` | `finnhub-cli.sh metrics <symbol> [--metric all]` | Financial ratios: PE, EPS, margins, beta, 52w high/low, dividend yield |
| `financials` | `finnhub-cli.sh financials <symbol> [--statement bs\|ic\|cf] [--freq annual\|quarterly]` | Financial statements (balance sheet, income, cash flow) |
| `financials-reported` | `finnhub-cli.sh financials-reported <symbol> [--freq annual\|quarterly]` | As-reported SEC filing data |
| `revenue-breakdown` | `finnhub-cli.sh revenue-breakdown <symbol>` | Revenue split by segment and geography |
| `executives` | `finnhub-cli.sh executives <symbol>` | C-suite and board member details |
| `insider-transactions` | `finnhub-cli.sh insider-transactions <symbol> [--from DATE] [--to DATE]` | Insider buying/selling activity. Defaults to last 90 days |
| `insider-sentiment` | `finnhub-cli.sh insider-sentiment <symbol> [--from DATE] [--to DATE]` | Net insider sentiment (bullish/bearish). Defaults to last 90 days |
| `ownership` | `finnhub-cli.sh ownership <symbol>` | Institutional holders and their positions |

### Estimates & Analyst Data

| Command | Usage | Description |
|---------|-------|-------------|
| `recommendation` | `finnhub-cli.sh recommendation <symbol>` | Analyst consensus: strongBuy, buy, hold, sell, strongSell counts by month |
| `price-target` | `finnhub-cli.sh price-target <symbol>` | Analyst price targets: high, low, mean, median |
| `eps-estimate` | `finnhub-cli.sh eps-estimate <symbol> [--freq quarterly]` | Forward EPS estimates |
| `revenue-estimate` | `finnhub-cli.sh revenue-estimate <symbol> [--freq quarterly]` | Forward revenue estimates |
| `earnings` | `finnhub-cli.sh earnings <symbol> [--limit 4]` | Historical EPS: actual vs estimate, surprise % |
| `earnings-calendar` | `finnhub-cli.sh earnings-calendar [--from DATE] [--to DATE] [--symbol SYM]` | Upcoming earnings dates. Defaults to next 7 days |
| `upgrade-downgrade` | `finnhub-cli.sh upgrade-downgrade <symbol> [--from DATE] [--to DATE]` | Rating changes from analysts. Defaults to last 90 days |
| `ipo-calendar` | `finnhub-cli.sh ipo-calendar [--from DATE] [--to DATE]` | Upcoming IPOs. Defaults to next 30 days |

### Sentiment & Alternative Data

| Command | Usage | Description |
|---------|-------|-------------|
| `news-sentiment` | `finnhub-cli.sh news-sentiment <symbol>` | News sentiment scores and buzz metrics (premium) |
| `social-sentiment` | `finnhub-cli.sh social-sentiment <symbol> [--from DATE] [--to DATE]` | Reddit/Twitter sentiment. Defaults to last 30 days (premium) |
| `congressional-trading` | `finnhub-cli.sh congressional-trading <symbol> [--from DATE] [--to DATE]` | Politician stock trades. Defaults to last 90 days |
| `supply-chain` | `finnhub-cli.sh supply-chain <symbol>` | Key customers and suppliers |
| `sector-metrics` | `finnhub-cli.sh sector-metrics [--region NA]` | Sector performance metrics |
| `esg` | `finnhub-cli.sh esg <symbol>` | Environmental, Social, Governance scores |

### Technical Analysis & Indices

| Command | Usage | Description |
|---------|-------|-------------|
| `indicator` | `finnhub-cli.sh indicator <symbol> --indicator sma [--resolution D] [--from DATE] [--to DATE] [--timeperiod 14]` | Technical indicators: sma, ema, rsi, macd, bbands, stoch, adx, atr, cci, obv, wma |
| `pattern` | `finnhub-cli.sh pattern <symbol> [--resolution D]` | Candlestick pattern recognition |
| `support-resistance` | `finnhub-cli.sh support-resistance <symbol> [--resolution D]` | Support and resistance price levels |
| `index-constituents` | `finnhub-cli.sh index-constituents <symbol>` | Index members (e.g., ^GSPC for S&P 500, ^DJI for Dow) |
| `etf-holdings` | `finnhub-cli.sh etf-holdings <symbol>` | ETF portfolio holdings breakdown (e.g., SPY, QQQ) |

### Economic & Calendar

| Command | Usage | Description |
|---------|-------|-------------|
| `economic-calendar` | `finnhub-cli.sh economic-calendar [--from DATE] [--to DATE]` | Upcoming economic events (CPI, FOMC, jobs). Defaults to next 7 days |
| `economic-codes` | `finnhub-cli.sh economic-codes` | List all available economic indicator codes |
| `economic` | `finnhub-cli.sh economic <code>` | Historical data for an economic indicator |
| `country` | `finnhub-cli.sh country` | Country metadata with risk premiums and ratings |

## Date Format

All dates use `YYYY-MM-DD` format. The tool auto-converts to Unix timestamps where the API requires them. Smart defaults are applied when dates are omitted.

## Common Workflows for Financial Advisory

### Daily Market Briefing
```bash
finnhub-cli.sh quote AAPL                    # Current price
finnhub-cli.sh quote MSFT
finnhub-cli.sh quote GOOGL
finnhub-cli.sh market-news                   # Headlines
finnhub-cli.sh economic-calendar             # What's coming this week
finnhub-cli.sh sector-metrics                # Sector performance
```

### Company Deep Dive for Client
```bash
finnhub-cli.sh profile AAPL                  # Overview
finnhub-cli.sh metrics AAPL                  # Key ratios (PE, margins, beta)
finnhub-cli.sh recommendation AAPL          # Analyst consensus
finnhub-cli.sh price-target AAPL            # Where analysts think it's going
finnhub-cli.sh earnings AAPL                 # Recent earnings beats/misses
finnhub-cli.sh eps-estimate AAPL            # Forward estimates
finnhub-cli.sh revenue-estimate AAPL        # Revenue outlook
finnhub-cli.sh insider-transactions AAPL    # Are insiders buying or selling?
finnhub-cli.sh company-news AAPL --from 2025-02-01 --to 2025-02-24
```

### Competitor Analysis
```bash
finnhub-cli.sh peers AAPL                    # Find peers
finnhub-cli.sh quote AAPL && finnhub-cli.sh quote MSFT && finnhub-cli.sh quote GOOGL  # Compare prices
finnhub-cli.sh metrics AAPL && finnhub-cli.sh metrics MSFT                   # Compare ratios
finnhub-cli.sh recommendation AAPL && finnhub-cli.sh recommendation MSFT     # Compare sentiment
```

### Portfolio Review
```bash
finnhub-cli.sh quote AAPL                    # Check each holding
finnhub-cli.sh candle AAPL --from 2025-01-01 --to 2025-02-24      # YTD chart data
finnhub-cli.sh indicator AAPL --indicator rsi                       # Is it overbought?
finnhub-cli.sh indicator AAPL --indicator sma --timeperiod 50       # 50-day moving avg
finnhub-cli.sh support-resistance AAPL                              # Key price levels
```

### IPO & Earnings Watch
```bash
finnhub-cli.sh earnings-calendar             # Who reports this week
finnhub-cli.sh ipo-calendar                  # Upcoming IPOs
finnhub-cli.sh upgrade-downgrade AAPL        # Recent rating changes
```

### Macro Overview
```bash
finnhub-cli.sh economic-calendar             # CPI, FOMC, jobs data
finnhub-cli.sh forex-rates                   # USD strength
finnhub-cli.sh sector-metrics                # Which sectors are leading
finnhub-cli.sh country                       # Country risk data
```

## Notes

- Some endpoints (news-sentiment, social-sentiment, candle) require a premium Finnhub plan
- Free tier supports: quote, profile, peers, metrics, recommendation, price-target, earnings, search, company-news, market-news, index-constituents, executives, ownership, insider-transactions, insider-sentiment, upgrade-downgrade, earnings-calendar, ipo-calendar, economic-calendar, country, economic-codes
- Rate limits apply (30 calls/sec for free tier)
- All output is raw JSON — use jq for filtering or let Claude parse it directly
