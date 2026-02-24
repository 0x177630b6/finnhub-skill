# finnhub-cli.sh

A lightweight CLI for querying the [Finnhub](https://finnhub.io/) financial market API. Built for financial advisors who need fast access to market data for client reports and advisory.

**43 commands. Pure bash + curl. Zero dependencies.**

Works on macOS and Linux out of the box.

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/0x177630b6/finnhub-skill.git
cd finnhub-skill
```

### 2. Verify it works

```bash
./finnhub-cli.sh --version
./finnhub-cli.sh --help
```

### 3. (Optional) Add to PATH

```bash
ln -s "$(pwd)/finnhub-cli.sh" /usr/local/bin/finnhub-cli.sh
```

### 4. API Key

A default Finnhub API key is included for quick testing. Replace it with your own for production use:

```bash
# Option 1: Environment variable (recommended)
export FINNHUB_TOKEN="your-api-key"

# Option 2: Per-command flag
finnhub-cli.sh --token your-api-key quote AAPL
```

Get a free key at [finnhub.io](https://finnhub.io/).

## Claude Code Skill Installation

This repo is designed to work as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. The `skill/` folder contains the skill definition file.

### Setup

1. **Create the skill directory:**

```bash
mkdir -p ~/.claude/skills/finnhub
```

2. **Copy the skill file:**

```bash
cp skill/SKILL.md ~/.claude/skills/finnhub/SKILL.md
```

3. **Update the path** in `~/.claude/skills/finnhub/SKILL.md` to point to where you cloned the repo. Open the file and find the `Base Command` section:

```bash
# Change this line to match YOUR install path:
/your/path/to/finnhub-skill/finnhub-cli.sh <command> [args...]
```

For example, if you cloned to `~/projects/finnhub-skill`:
```bash
~/projects/finnhub-skill/finnhub-cli.sh <command> [args...]
```

4. **Restart Claude Code.** The skill will now appear and Claude can invoke `finnhub-cli.sh` to pull market data, build reports, and answer financial questions.

## Quick Start

```bash
finnhub-cli.sh quote AAPL                    # Real-time price
finnhub-cli.sh profile AAPL                  # Company overview
finnhub-cli.sh metrics AAPL                  # PE, EPS, margins, beta
finnhub-cli.sh recommendation AAPL           # Analyst buy/hold/sell
finnhub-cli.sh earnings AAPL                 # Actual vs estimate
finnhub-cli.sh company-news AAPL             # Recent news
finnhub-cli.sh insider-transactions AAPL     # Insider buying/selling
finnhub-cli.sh economic-calendar             # Upcoming economic events
```

All output is raw JSON to stdout. Errors go to stderr. Pipe to `jq` for filtering:

```bash
finnhub-cli.sh quote AAPL | jq '.c'         # Just the current price
finnhub-cli.sh peers AAPL | jq '.[]'        # One peer per line
```

## Commands

### Market Data & Quotes

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh quote <symbol>` | Real-time price, change %, high/low, prev close |
| `finnhub-cli.sh candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Historical OHLCV price data |
| `finnhub-cli.sh search <query>` | Find ticker symbols by company name |
| `finnhub-cli.sh symbols <exchange>` | List all symbols on an exchange (e.g., US, L, T) |
| `finnhub-cli.sh market-status <exchange>` | Is the market open or closed? |
| `finnhub-cli.sh market-news [--category general]` | Latest headlines (general, forex, crypto, merger) |
| `finnhub-cli.sh company-news <symbol> [--from DATE] [--to DATE]` | Company-specific news (default: last 30 days) |
| `finnhub-cli.sh forex-rates [--base USD]` | Real-time FX exchange rates |
| `finnhub-cli.sh forex-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Forex OHLCV (e.g., OANDA:EUR_USD) |
| `finnhub-cli.sh crypto-candle <symbol> [--resolution D] [--from DATE] [--to DATE]` | Crypto OHLCV (e.g., BINANCE:BTCUSDT) |

### Company Fundamentals

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh profile <symbol>` | Company overview: sector, market cap, IPO date |
| `finnhub-cli.sh peers <symbol>` | Comparable/peer companies |
| `finnhub-cli.sh metrics <symbol> [--metric all]` | Financial ratios: PE, EPS, margins, beta, 52w high/low |
| `finnhub-cli.sh financials <symbol> [--statement bs\|ic\|cf] [--freq annual\|quarterly]` | Financial statements |
| `finnhub-cli.sh financials-reported <symbol> [--freq annual\|quarterly]` | As-reported SEC filing data |
| `finnhub-cli.sh revenue-breakdown <symbol>` | Revenue split by segment and geography |
| `finnhub-cli.sh executives <symbol>` | C-suite and board member details |
| `finnhub-cli.sh insider-transactions <symbol> [--from DATE] [--to DATE]` | Insider buying/selling (default: 90 days) |
| `finnhub-cli.sh insider-sentiment <symbol> [--from DATE] [--to DATE]` | Net insider sentiment (default: 90 days) |
| `finnhub-cli.sh ownership <symbol>` | Institutional holders and positions |

### Estimates & Analyst Data

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh recommendation <symbol>` | Analyst consensus: strongBuy, buy, hold, sell counts |
| `finnhub-cli.sh price-target <symbol>` | Price targets: high, low, mean, median |
| `finnhub-cli.sh eps-estimate <symbol> [--freq quarterly]` | Forward EPS estimates |
| `finnhub-cli.sh revenue-estimate <symbol> [--freq quarterly]` | Forward revenue estimates |
| `finnhub-cli.sh earnings <symbol> [--limit 4]` | Historical EPS: actual vs estimate, surprise % |
| `finnhub-cli.sh earnings-calendar [--from DATE] [--to DATE] [--symbol SYM]` | Upcoming earnings (default: next 7 days) |
| `finnhub-cli.sh upgrade-downgrade <symbol> [--from DATE] [--to DATE]` | Analyst rating changes (default: 90 days) |
| `finnhub-cli.sh ipo-calendar [--from DATE] [--to DATE]` | Upcoming IPOs (default: next 30 days) |

### Sentiment & Alternative Data

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh news-sentiment <symbol>` | News sentiment scores (premium) |
| `finnhub-cli.sh social-sentiment <symbol> [--from DATE] [--to DATE]` | Reddit/Twitter sentiment (premium) |
| `finnhub-cli.sh congressional-trading <symbol> [--from DATE] [--to DATE]` | Politician stock trades (default: 90 days) |
| `finnhub-cli.sh supply-chain <symbol>` | Key customers and suppliers |
| `finnhub-cli.sh sector-metrics [--region NA]` | Sector performance metrics |
| `finnhub-cli.sh esg <symbol>` | ESG scores |

### Technical Analysis & Indices

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh indicator <symbol> --indicator sma [--resolution D] [--timeperiod 14]` | Technical indicators (sma, ema, rsi, macd, bbands, etc.) |
| `finnhub-cli.sh pattern <symbol> [--resolution D]` | Candlestick pattern recognition |
| `finnhub-cli.sh support-resistance <symbol> [--resolution D]` | Support/resistance levels |
| `finnhub-cli.sh index-constituents <symbol>` | Index members (^GSPC for S&P 500, ^DJI for Dow) |
| `finnhub-cli.sh etf-holdings <symbol>` | ETF portfolio holdings (SPY, QQQ, etc.) |

### Economic & Calendar

| Command | Description |
|---------|-------------|
| `finnhub-cli.sh economic-calendar [--from DATE] [--to DATE]` | Economic events (CPI, FOMC, jobs, default: next 7 days) |
| `finnhub-cli.sh economic-codes` | List available economic indicator codes |
| `finnhub-cli.sh economic <code>` | Historical data for an economic indicator |
| `finnhub-cli.sh country` | Country metadata with risk premiums and ratings |

## Date Format

All dates use `YYYY-MM-DD`. The tool handles Unix timestamp conversion internally. When dates are omitted, smart defaults apply (e.g., last 30 days for news, last 90 days for insider data, last year for candles).

## Free vs Premium Endpoints

Most commands work on the free Finnhub tier. These require a premium plan:

- `news-sentiment`, `social-sentiment` — sentiment analysis
- `candle`, `forex-candle`, `crypto-candle` — some symbols
- `forex-rates` — real-time FX
- `upgrade-downgrade`, `price-target` — analyst data
- `indicator` — technical indicators

Free tier rate limit: 30 calls/second.

## Repo Structure

```
finnhub-skill/
├── finnhub-cli.sh    # CLI executable (single bash script, ~1450 lines)
├── CLAUDE.md         # Project instructions for Claude Code
├── README.md         # This file
├── LICENSE           # MIT License
└── skill/
    └── SKILL.md      # Claude Code skill definition (copy to ~/.claude/skills/finnhub/)
```

## License

MIT — see [LICENSE](LICENSE).
