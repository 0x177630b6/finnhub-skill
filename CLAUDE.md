# Finnhub CLI Tool (`finn`)

A lightweight CLI for querying financial market data from the Finnhub API. Used by a financial advisor to build market reports and advise clients on market movements.

## Quick Start

The CLI is at `/home/ubuntu/tinyclaw-workspace/finn/finn`. API key is pre-configured.

```bash
finn quote AAPL                    # Real-time price
finn profile AAPL                  # Company overview
finn recommendation AAPL          # Analyst consensus
finn company-news AAPL --from 2025-01-01 --to 2025-01-31
```

## Output

All output is JSON to stdout. Errors go to stderr. Pipe output directly or parse with jq.

## Command Reference

### Market Data & Quotes

| Command | Usage | Description |
|---------|-------|-------------|
| `quote` | `finn quote <symbol>` | Real-time price, change %, high/low, prev close |
| `candle` | `finn candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Historical OHLCV price data. Resolution: 1,5,15,30,60,D,W,M. Dates default to last year |
| `search` | `finn search <query>` | Find ticker symbols by company name |
| `symbols` | `finn symbols <exchange>` | List all symbols on an exchange (e.g., US, L, T) |
| `market-status` | `finn market-status <exchange>` | Is the market open or closed? |
| `market-news` | `finn market-news [--category general]` | Latest market news headlines. Categories: general, forex, crypto, merger |
| `company-news` | `finn company-news <symbol> [--from DATE] [--to DATE]` | Company-specific news. Defaults to last 30 days |
| `forex-rates` | `finn forex-rates [--base USD]` | Real-time FX exchange rates |
| `forex-candle` | `finn forex-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Forex OHLCV (e.g., OANDA:EUR_USD) |
| `crypto-candle` | `finn crypto-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Crypto OHLCV (e.g., BINANCE:BTCUSDT) |

### Company Fundamentals

| Command | Usage | Description |
|---------|-------|-------------|
| `profile` | `finn profile <symbol>` | Company overview: name, sector, market cap, IPO date, logo, website |
| `peers` | `finn peers <symbol>` | List of comparable/peer companies |
| `metrics` | `finn metrics <symbol> [--metric all]` | Financial ratios: PE, EPS, margins, beta, 52w high/low, dividend yield |
| `financials` | `finn financials <symbol> [--statement bs\|ic\|cf] [--freq annual\|quarterly]` | Financial statements (balance sheet, income, cash flow) |
| `financials-reported` | `finn financials-reported <symbol> [--freq annual\|quarterly]` | As-reported SEC filing data |
| `revenue-breakdown` | `finn revenue-breakdown <symbol>` | Revenue split by segment and geography |
| `executives` | `finn executives <symbol>` | C-suite and board member details |
| `insider-transactions` | `finn insider-transactions <symbol> [--from DATE] [--to DATE]` | Insider buying/selling activity. Defaults to last 90 days |
| `insider-sentiment` | `finn insider-sentiment <symbol> [--from DATE] [--to DATE]` | Net insider sentiment (bullish/bearish). Defaults to last 90 days |
| `ownership` | `finn ownership <symbol>` | Institutional holders and their positions |

### Estimates & Analyst Data

| Command | Usage | Description |
|---------|-------|-------------|
| `recommendation` | `finn recommendation <symbol>` | Analyst consensus: strongBuy, buy, hold, sell, strongSell counts by month |
| `price-target` | `finn price-target <symbol>` | Analyst price targets: high, low, mean, median |
| `eps-estimate` | `finn eps-estimate <symbol> [--freq quarterly]` | Forward EPS estimates |
| `revenue-estimate` | `finn revenue-estimate <symbol> [--freq quarterly]` | Forward revenue estimates |
| `earnings` | `finn earnings <symbol> [--limit 4]` | Historical EPS: actual vs estimate, surprise % |
| `earnings-calendar` | `finn earnings-calendar [--from DATE] [--to DATE] [--symbol SYM]` | Upcoming earnings dates. Defaults to next 7 days |
| `upgrade-downgrade` | `finn upgrade-downgrade <symbol> [--from DATE] [--to DATE]` | Rating changes from analysts. Defaults to last 90 days |
| `ipo-calendar` | `finn ipo-calendar [--from DATE] [--to DATE]` | Upcoming IPOs. Defaults to next 30 days |

### Sentiment & Alternative Data

| Command | Usage | Description |
|---------|-------|-------------|
| `news-sentiment` | `finn news-sentiment <symbol>` | News sentiment scores and buzz metrics (premium) |
| `social-sentiment` | `finn social-sentiment <symbol> [--from DATE] [--to DATE]` | Reddit/Twitter sentiment. Defaults to last 30 days (premium) |
| `congressional-trading` | `finn congressional-trading <symbol> [--from DATE] [--to DATE]` | Politician stock trades. Defaults to last 90 days |
| `supply-chain` | `finn supply-chain <symbol>` | Key customers and suppliers |
| `sector-metrics` | `finn sector-metrics [--region NA]` | Sector performance metrics |
| `esg` | `finn esg <symbol>` | Environmental, Social, Governance scores |

### Technical Analysis & Indices

| Command | Usage | Description |
|---------|-------|-------------|
| `indicator` | `finn indicator <symbol> --indicator sma [--resolution D] [--from DATE] [--to DATE] [--timeperiod 14]` | Technical indicators: sma, ema, rsi, macd, bbands, stoch, adx, atr, cci, obv, wma |
| `pattern` | `finn pattern <symbol> [--resolution D]` | Candlestick pattern recognition |
| `support-resistance` | `finn support-resistance <symbol> [--resolution D]` | Support and resistance price levels |
| `index-constituents` | `finn index-constituents <symbol>` | Index members (e.g., ^GSPC for S&P 500, ^DJI for Dow) |
| `etf-holdings` | `finn etf-holdings <symbol>` | ETF portfolio holdings breakdown (e.g., SPY, QQQ) |

### Economic & Calendar

| Command | Usage | Description |
|---------|-------|-------------|
| `economic-calendar` | `finn economic-calendar [--from DATE] [--to DATE]` | Upcoming economic events (CPI, FOMC, jobs). Defaults to next 7 days |
| `economic-codes` | `finn economic-codes` | List all available economic indicator codes |
| `economic` | `finn economic <code>` | Historical data for an economic indicator |
| `country` | `finn country` | Country metadata with risk premiums and ratings |

## Date Format

All dates use `YYYY-MM-DD` format. The tool auto-converts to Unix timestamps where the API requires them. Smart defaults are applied when dates are omitted.

## Common Workflows for Financial Advisory

### Daily Market Briefing
```bash
finn quote AAPL                    # Current price
finn quote MSFT
finn quote GOOGL
finn market-news                   # Headlines
finn economic-calendar             # What's coming this week
finn sector-metrics                # Sector performance
```

### Company Deep Dive for Client
```bash
finn profile AAPL                  # Overview
finn metrics AAPL                  # Key ratios (PE, margins, beta)
finn recommendation AAPL          # Analyst consensus
finn price-target AAPL            # Where analysts think it's going
finn earnings AAPL                 # Recent earnings beats/misses
finn eps-estimate AAPL            # Forward estimates
finn revenue-estimate AAPL        # Revenue outlook
finn insider-transactions AAPL    # Are insiders buying or selling?
finn company-news AAPL --from 2025-02-01 --to 2025-02-24
```

### Competitor Analysis
```bash
finn peers AAPL                    # Find peers
finn quote AAPL && finn quote MSFT && finn quote GOOGL  # Compare prices
finn metrics AAPL && finn metrics MSFT                   # Compare ratios
finn recommendation AAPL && finn recommendation MSFT     # Compare sentiment
```

### Portfolio Review
```bash
finn quote AAPL                    # Check each holding
finn candle AAPL --from 2025-01-01 --to 2025-02-24      # YTD chart data
finn indicator AAPL --indicator rsi                       # Is it overbought?
finn indicator AAPL --indicator sma --timeperiod 50       # 50-day moving avg
finn support-resistance AAPL                              # Key price levels
```

### IPO & Earnings Watch
```bash
finn earnings-calendar             # Who reports this week
finn ipo-calendar                  # Upcoming IPOs
finn upgrade-downgrade AAPL        # Recent rating changes
```

### Macro Overview
```bash
finn economic-calendar             # CPI, FOMC, jobs data
finn forex-rates                   # USD strength
finn sector-metrics                # Which sectors are leading
finn country                       # Country risk data
```

## Notes

- Some endpoints (news-sentiment, social-sentiment, candle) require a premium Finnhub plan
- Free tier supports: quote, profile, peers, metrics, recommendation, price-target, earnings, search, company-news, market-news, index-constituents, executives, ownership, insider-transactions, insider-sentiment, upgrade-downgrade, earnings-calendar, ipo-calendar, economic-calendar, country, economic-codes
- Rate limits apply (30 calls/sec for free tier)
- All output is raw JSON — use jq for filtering or let Claude parse it directly
