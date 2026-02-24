#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# finnhub-cli.sh — CLI tool for the Finnhub Stock API
###############################################################################

# === Constants ===============================================================

BASE_URL="https://finnhub.io/api/v1"
DEFAULT_TOKEN="d6ef26hr01qloir6btc0d6ef26hr01qloir6btcg"
VERSION="0.1.0"

# === Core Helper Functions ===================================================

# Print message to stderr and exit 1.
_err() {
    printf "finnhub-cli.sh: %s\n" "$*" >&2
    exit 1
}

# Check that a variable is non-empty, otherwise call _err with a usage hint.
#   $1 — variable name (for the error message)
#   $2 — value to check
#   $3 — usage hint
_require() {
    local var_name="$1"
    local value="$2"
    local usage_hint="$3"
    if [[ -z "$value" ]]; then
        _err "missing required argument: $var_name -- $usage_hint"
    fi
}

# Convert YYYY-MM-DD to Unix timestamp. If input is already numeric, pass
# through unchanged. Works on both macOS (BSD date) and Linux (GNU date).
_date_to_ts() {
    local input="$1"
    # If already a unix timestamp (all digits), pass through
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        printf "%s" "$input"
        return
    fi
    # Try GNU date first (Linux), then BSD date (macOS)
    if date -d "$input" +%s >/dev/null 2>&1; then
        date -d "$input" +%s
    elif date -j -f "%Y-%m-%d" "$input" +%s >/dev/null 2>&1; then
        date -j -f "%Y-%m-%d" "$input" +%s
    else
        _err "unable to parse date: $input (expected YYYY-MM-DD or Unix timestamp)"
    fi
}

# Return a date N days ago in YYYY-MM-DD format. Works on macOS and Linux.
#   $1 — number of days ago
_default_from() {
    local days="$1"
    if date -d "-${days} days" +%Y-%m-%d >/dev/null 2>&1; then
        date -d "-${days} days" +%Y-%m-%d
    elif date -j -v "-${days}d" +%Y-%m-%d >/dev/null 2>&1; then
        date -j -v "-${days}d" +%Y-%m-%d
    else
        _err "unable to compute date ${days} days ago"
    fi
}

# Return today's date in YYYY-MM-DD format.
_default_to() {
    date +%Y-%m-%d
}

# Return a date N days from now in YYYY-MM-DD format. Works on macOS and Linux.
#   $1 — number of days forward
_date_forward() {
    local days="$1"
    if date -d "+${days} days" +%Y-%m-%d >/dev/null 2>&1; then
        date -d "+${days} days" +%Y-%m-%d
    elif date -j -v "+${days}d" +%Y-%m-%d >/dev/null 2>&1; then
        date -j -v "+${days}d" +%Y-%m-%d
    else
        _err "unable to compute date ${days} days from now"
    fi
}

# Main API caller.
#   $1        — endpoint path (e.g. "/quote")
#   $2..$N    — key=value query parameter pairs
#
# Builds the full URL with query params (including the auth token), calls curl,
# checks the HTTP status, and outputs the JSON body to stdout. On error, the
# response body is printed to stderr and the function exits 1.
_api() {
    local endpoint="$1"; shift

    # Start building query string with token
    local query="token=${TOKEN}"

    # Append each key=value pair
    local pair
    for pair in "$@"; do
        query="${query}&${pair}"
    done

    local url="${BASE_URL}${endpoint}?${query}"

    # Call curl: silent, no -f (we handle errors ourselves), 30s timeout,
    # append HTTP status code on a separate line.
    local response
    response=$(curl -s -w $'\n%{http_code}' --max-time 30 "$url") || {
        _err "curl failed for ${BASE_URL}${endpoint} (network error or timeout)"
    }

    # Split response into body and HTTP status code.
    local http_code body
    http_code=$(printf "%s" "$response" | tail -n1)
    body=$(printf "%s" "$response" | sed '$d')

    # Check for 2xx status
    if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        printf "finnhub-cli.sh: HTTP %s from %s\n%s\n" "$http_code" "${BASE_URL}${endpoint}" "$body" >&2
        exit 1
    fi

    printf "%s\n" "$body"
}

# === Help Text ===============================================================

_usage() {
    cat <<'HELPTEXT'
finnhub-cli.sh -- CLI tool for the Finnhub Stock API

USAGE
    finnhub-cli.sh <command> [options]

GLOBAL OPTIONS
    --token <key>    API token (overrides FINNHUB_TOKEN env var)
    --help, -h       Show help (use after a command for command-specific help)
    --version        Show version

COMMANDS

  Market Data & Quotes
    quote                 Get real-time quote for a stock symbol
    candle                Get candlestick (OHLCV) data for a symbol
    search                Search for symbols by query string
    symbols               List supported symbols for an exchange
    market-status         Get current market status for all exchanges
    market-news           Get latest general market news
    company-news          Get news articles for a specific company
    forex-rates           Get real-time forex rates
    forex-candle          Get forex candlestick data
    crypto-candle         Get crypto candlestick data

  Company Fundamentals
    profile               Get company profile / overview
    peers                 Get company peers (similar companies)
    metrics               Get basic financial metrics
    financials            Get standardized financial statements
    financials-reported   Get as-reported financial statements
    revenue-breakdown     Get revenue breakdown by segment/geo
    executives            Get list of company executives
    insider-transactions  Get insider transactions
    insider-sentiment     Get insider sentiment data
    ownership             Get institutional ownership data

  Estimates & Analyst Data
    recommendation        Get analyst recommendation trends
    price-target          Get analyst price target consensus
    eps-estimate          Get EPS estimates
    revenue-estimate      Get revenue estimates
    earnings              Get company earnings (actual vs estimate)
    earnings-calendar     Get upcoming earnings calendar
    upgrade-downgrade     Get upgrade/downgrade history
    ipo-calendar          Get upcoming IPO calendar

  Sentiment & Alternative Data
    news-sentiment        Get news sentiment for a symbol
    social-sentiment      Get social media sentiment
    congressional-trading Get congressional trading activity
    supply-chain          Get supply chain relationships
    sector-metrics        Get sector-level performance metrics
    esg                   Get ESG (environmental/social/governance) scores

  Technical Analysis & Indices
    indicator             Run a technical indicator on candle data
    pattern               Detect candlestick patterns
    support-resistance    Get support and resistance levels
    index-constituents    Get constituents of a stock index
    etf-holdings          Get ETF holdings breakdown

  Economic & Calendar
    economic-calendar     Get economic event calendar
    economic-codes        List available economic indicator codes
    economic              Get economic indicator data
    country               List available country metadata

EXAMPLES
    finnhub-cli.sh quote AAPL
    finnhub-cli.sh candle MSFT --from 2024-01-01 --to 2024-06-01
    finnhub-cli.sh profile TSLA
    finnhub-cli.sh search "apple"
    finnhub-cli.sh --token sk-xxxxx quote GOOG

ENVIRONMENT
    FINNHUB_TOKEN    API token (can also use --token flag)

HELPTEXT
}

_version() {
    printf "finnhub-cli.sh %s\n" "$VERSION"
}

# === Global Argument Pre-Processing ==========================================

TOKEN=""
SHOW_HELP=0
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token)
            if [[ $# -lt 2 ]]; then
                _err "--token requires a value"
            fi
            TOKEN="$2"
            shift 2
            ;;
        --help|-h)
            SHOW_HELP=1
            shift
            ;;
        --version)
            _version
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Resolve token: flag > env var > default
if [[ -z "$TOKEN" ]]; then
    TOKEN="${FINNHUB_TOKEN:-$DEFAULT_TOKEN}"
fi

# Extract command and remaining args
COMMAND="${ARGS[0]:-""}"
COMMAND_ARGS=("${ARGS[@]:1}")

# If no command given, or top-level --help, show usage
if [[ -z "$COMMAND" ]] || { [[ "$SHOW_HELP" -eq 1 ]] && [[ -z "$COMMAND" ]]; }; then
    _usage
    exit 0
fi

# === Command Dispatch ========================================================

case "$COMMAND" in

    # --- help ----------------------------------------------------------------
    help)
        _usage
        exit 0
        ;;

    # === PHASE 1: Market Data & Quotes =======================================
    quote)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh quote <symbol>

Get real-time quote data for a stock symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT, GOOG)

EXAMPLES
    finnhub-cli.sh quote AAPL
    finnhub-cli.sh quote MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh quote <symbol>"
        _api "/quote" "symbol=${symbol}"
        ;;
    candle)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh candle <symbol> [options]

Get candlestick (OHLCV) data for a stock symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT)

OPTIONS
    --resolution R    Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)
    --from DATE       Start date in YYYY-MM-DD format (default: 365 days ago)
    --to DATE         End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh candle AAPL
    finnhub-cli.sh candle MSFT --resolution 60 --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" resolution="D" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh candle <symbol> [--resolution D] [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 365)
        [[ -z "$to" ]] && to=$(_default_to)
        from_ts=""; to_ts=""
        from_ts=$(_date_to_ts "$from")
        to_ts=$(_date_to_ts "$to")
        _api "/stock/candle" "symbol=${symbol}" "resolution=${resolution}" "from=${from_ts}" "to=${to_ts}"
        ;;
    search)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh search <query>

Search for stock symbols by name or keyword.

ARGUMENTS
    <query>    Search query string (e.g. "apple", "tesla")

EXAMPLES
    finnhub-cli.sh search apple
    finnhub-cli.sh search "microsoft corp"
EOF
            exit 0
        fi
        query="${COMMAND_ARGS[0]:-""}"
        _require "query" "$query" "usage: finnhub-cli.sh search <query>"
        _api "/search" "q=${query}"
        ;;
    symbols)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh symbols <exchange>

List supported stock symbols for an exchange.

ARGUMENTS
    <exchange>    Exchange code (e.g. US, L, T, HK)

EXAMPLES
    finnhub-cli.sh symbols US
    finnhub-cli.sh symbols L
EOF
            exit 0
        fi
        exchange="${COMMAND_ARGS[0]:-""}"
        _require "exchange" "$exchange" "usage: finnhub-cli.sh symbols <exchange>"
        _api "/stock/symbol" "exchange=${exchange}"
        ;;
    market-status)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh market-status <exchange>

Get current market trading status for an exchange.

ARGUMENTS
    <exchange>    Exchange code (e.g. US, L, T, HK)

EXAMPLES
    finnhub-cli.sh market-status US
    finnhub-cli.sh market-status L
EOF
            exit 0
        fi
        exchange="${COMMAND_ARGS[0]:-""}"
        _require "exchange" "$exchange" "usage: finnhub-cli.sh market-status <exchange>"
        _api "/stock/market-status" "exchange=${exchange}"
        ;;
    market-news)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh market-news [options]

Get latest general market news.

OPTIONS
    --category CAT    News category: general, forex, crypto, merger (default: general)

EXAMPLES
    finnhub-cli.sh market-news
    finnhub-cli.sh market-news --category crypto
EOF
            exit 0
        fi
        category="general"
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --category) category="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _api "/news" "category=${category}"
        ;;
    company-news)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh company-news <symbol> [options]

Get news articles for a specific company.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT)

OPTIONS
    --from DATE    Start date in YYYY-MM-DD format (default: 30 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh company-news AAPL
    finnhub-cli.sh company-news TSLA --from 2024-01-01 --to 2024-03-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh company-news <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 30)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/company-news" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    forex-rates)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh forex-rates [options]

Get real-time forex exchange rates.

OPTIONS
    --base CUR    Base currency code (default: USD)

EXAMPLES
    finnhub-cli.sh forex-rates
    finnhub-cli.sh forex-rates --base EUR
EOF
            exit 0
        fi
        base="USD"
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --base) base="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _api "/forex/rates" "base=${base}"
        ;;
    forex-candle)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh forex-candle <symbol> [options]

Get forex candlestick (OHLCV) data.

ARGUMENTS
    <symbol>    Forex pair symbol (e.g. OANDA:EUR_USD)

OPTIONS
    --resolution R    Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)
    --from DATE       Start date in YYYY-MM-DD format (default: 365 days ago)
    --to DATE         End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh forex-candle OANDA:EUR_USD
    finnhub-cli.sh forex-candle OANDA:GBP_USD --resolution 60 --from 2024-01-01
EOF
            exit 0
        fi
        symbol="" resolution="D" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh forex-candle <symbol> [--resolution D] [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 365)
        [[ -z "$to" ]] && to=$(_default_to)
        from_ts=""; to_ts=""
        from_ts=$(_date_to_ts "$from")
        to_ts=$(_date_to_ts "$to")
        _api "/forex/candle" "symbol=${symbol}" "resolution=${resolution}" "from=${from_ts}" "to=${to_ts}"
        ;;
    crypto-candle)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh crypto-candle <symbol> [options]

Get crypto candlestick (OHLCV) data.

ARGUMENTS
    <symbol>    Crypto pair symbol (e.g. BINANCE:BTCUSDT)

OPTIONS
    --resolution R    Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)
    --from DATE       Start date in YYYY-MM-DD format (default: 365 days ago)
    --to DATE         End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh crypto-candle BINANCE:BTCUSDT
    finnhub-cli.sh crypto-candle BINANCE:ETHUSDT --resolution 60 --from 2024-01-01
EOF
            exit 0
        fi
        symbol="" resolution="D" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh crypto-candle <symbol> [--resolution D] [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 365)
        [[ -z "$to" ]] && to=$(_default_to)
        from_ts=""; to_ts=""
        from_ts=$(_date_to_ts "$from")
        to_ts=$(_date_to_ts "$to")
        _api "/crypto/candle" "symbol=${symbol}" "resolution=${resolution}" "from=${from_ts}" "to=${to_ts}"
        ;;

    # === PHASE 2: Company Fundamentals =======================================
    profile)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh profile <symbol>

Get company profile and overview.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Examples:
    finnhub-cli.sh profile AAPL
    finnhub-cli.sh profile TSLA
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh profile <symbol>"
        _api "/stock/profile2" "symbol=${symbol}"
        ;;
    peers)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh peers <symbol>

Get company peers (similar companies).

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Examples:
    finnhub-cli.sh peers AAPL
    finnhub-cli.sh peers MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh peers <symbol>"
        _api "/stock/peers" "symbol=${symbol}"
        ;;
    metrics)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh metrics <symbol> [options]

Get basic financial metrics for a company.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Options:
    --metric METRIC    Metric type (default: all)

Examples:
    finnhub-cli.sh metrics AAPL
    finnhub-cli.sh metrics MSFT --metric all
EOF
            exit 0
        fi
        symbol="" metric="all"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --metric) metric="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh metrics <symbol> [--metric all]"
        _api "/stock/metric" "symbol=${symbol}" "metric=${metric}"
        ;;
    financials)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh financials <symbol> [options]

Get standardized financial statements.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Options:
    --statement TYPE    Statement type: bs, ic, cf (default: ic)
    --freq FREQ         Frequency: annual, quarterly (default: annual)

Examples:
    finnhub-cli.sh financials AAPL
    finnhub-cli.sh financials MSFT --statement bs --freq quarterly
EOF
            exit 0
        fi
        symbol="" statement="ic" freq="annual"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --statement) statement="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --freq) freq="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh financials <symbol> [--statement bs|ic|cf] [--freq annual|quarterly]"
        _api "/stock/financials" "symbol=${symbol}" "statement=${statement}" "freq=${freq}"
        ;;
    financials-reported)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh financials-reported <symbol> [options]

Get as-reported financial statements.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Options:
    --freq FREQ    Frequency: annual, quarterly (default: annual)

Examples:
    finnhub-cli.sh financials-reported AAPL
    finnhub-cli.sh financials-reported MSFT --freq quarterly
EOF
            exit 0
        fi
        symbol="" freq="annual"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --freq) freq="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh financials-reported <symbol> [--freq annual|quarterly]"
        _api "/stock/financials-reported" "symbol=${symbol}" "freq=${freq}"
        ;;
    revenue-breakdown)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh revenue-breakdown <symbol>

Get revenue breakdown by segment/geography.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Examples:
    finnhub-cli.sh revenue-breakdown AAPL
    finnhub-cli.sh revenue-breakdown MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh revenue-breakdown <symbol>"
        _api "/stock/revenue-breakdown" "symbol=${symbol}"
        ;;
    executives)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh executives <symbol>

Get list of company executives.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Examples:
    finnhub-cli.sh executives AAPL
    finnhub-cli.sh executives MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh executives <symbol>"
        _api "/stock/executive" "symbol=${symbol}"
        ;;
    insider-transactions)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh insider-transactions <symbol> [options]

Get insider transactions for a company.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Options:
    --from DATE    Start date in YYYY-MM-DD format (default: 90 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

Examples:
    finnhub-cli.sh insider-transactions AAPL
    finnhub-cli.sh insider-transactions MSFT --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh insider-transactions <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 90)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/stock/insider-transactions" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    insider-sentiment)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh insider-sentiment <symbol> [options]

Get insider sentiment data for a company.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Options:
    --from DATE    Start date in YYYY-MM-DD format (default: 90 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

Examples:
    finnhub-cli.sh insider-sentiment AAPL
    finnhub-cli.sh insider-sentiment MSFT --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh insider-sentiment <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 90)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/stock/insider-sentiment" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    ownership)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh ownership <symbol>

Get institutional ownership data for a company.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL, MSFT)

Examples:
    finnhub-cli.sh ownership AAPL
    finnhub-cli.sh ownership MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh ownership <symbol>"
        _api "/stock/ownership" "symbol=${symbol}"
        ;;

    # === PHASE 3: Estimates & Analyst Data ====================================
    recommendation)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh recommendation <symbol>

Get analyst recommendation trends (buy/hold/sell).

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Examples:
    finnhub-cli.sh recommendation AAPL
    finnhub-cli.sh recommendation MSFT
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh recommendation <symbol>"
        _api "/stock/recommendation" "symbol=${symbol}"
        ;;
    price-target)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh price-target <symbol>

Get analyst price target consensus.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Examples:
    finnhub-cli.sh price-target AAPL
    finnhub-cli.sh price-target TSLA
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh price-target <symbol>"
        _api "/stock/price-target" "symbol=${symbol}"
        ;;
    eps-estimate)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh eps-estimate <symbol> [options]

Get EPS (earnings per share) estimates.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Options:
    --freq F    Frequency: annual or quarterly (default: quarterly)

Examples:
    finnhub-cli.sh eps-estimate AAPL
    finnhub-cli.sh eps-estimate MSFT --freq annual
EOF
            exit 0
        fi
        symbol="" freq="quarterly"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --freq) freq="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh eps-estimate <symbol> [--freq quarterly|annual]"
        _api "/stock/eps-estimate" "symbol=${symbol}" "freq=${freq}"
        ;;
    revenue-estimate)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh revenue-estimate <symbol> [options]

Get revenue estimates.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Options:
    --freq F    Frequency: annual or quarterly (default: quarterly)

Examples:
    finnhub-cli.sh revenue-estimate AAPL
    finnhub-cli.sh revenue-estimate MSFT --freq annual
EOF
            exit 0
        fi
        symbol="" freq="quarterly"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --freq) freq="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh revenue-estimate <symbol> [--freq quarterly|annual]"
        _api "/stock/revenue-estimate" "symbol=${symbol}" "freq=${freq}"
        ;;
    earnings)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh earnings <symbol> [options]

Get company earnings (actual vs estimate).

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Options:
    --limit N    Number of quarterly results to return (default: 4)

Examples:
    finnhub-cli.sh earnings AAPL
    finnhub-cli.sh earnings MSFT --limit 8
EOF
            exit 0
        fi
        symbol="" limit="4"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --limit) limit="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh earnings <symbol> [--limit 4]"
        _api "/stock/earnings" "symbol=${symbol}" "limit=${limit}"
        ;;
    earnings-calendar)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh earnings-calendar [options]

Get upcoming earnings calendar.

Options:
    --from DATE      Start date in YYYY-MM-DD format (default: today)
    --to DATE        End date in YYYY-MM-DD format (default: 7 days from now)
    --symbol SYMBOL  Filter to a specific stock symbol (optional)

Examples:
    finnhub-cli.sh earnings-calendar
    finnhub-cli.sh earnings-calendar --from 2024-01-01 --to 2024-01-31
    finnhub-cli.sh earnings-calendar --symbol AAPL
EOF
            exit 0
        fi
        from="" to="" symbol=""
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --symbol) symbol="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        [[ -z "$from" ]] && from=$(_default_from 0)
        [[ -z "$to" ]] && to=$(_date_forward 7)
        params=("from=${from}" "to=${to}")
        [[ -n "$symbol" ]] && params+=("symbol=${symbol}")
        _api "/calendar/earnings" "${params[@]}"
        ;;
    upgrade-downgrade)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh upgrade-downgrade <symbol> [options]

Get upgrade/downgrade history for a stock.

Arguments:
    symbol    Stock ticker symbol (e.g., AAPL)

Options:
    --from DATE    Start date in YYYY-MM-DD format (default: 90 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

Examples:
    finnhub-cli.sh upgrade-downgrade AAPL
    finnhub-cli.sh upgrade-downgrade MSFT --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh upgrade-downgrade <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 90)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/stock/upgrade-downgrade" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    ipo-calendar)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh ipo-calendar [options]

Get upcoming IPO calendar.

Options:
    --from DATE    Start date in YYYY-MM-DD format (default: today)
    --to DATE      End date in YYYY-MM-DD format (default: 30 days from now)

Examples:
    finnhub-cli.sh ipo-calendar
    finnhub-cli.sh ipo-calendar --from 2024-01-01 --to 2024-03-01
EOF
            exit 0
        fi
        from="" to=""
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        [[ -z "$from" ]] && from=$(_default_from 0)
        [[ -z "$to" ]] && to=$(_date_forward 30)
        _api "/calendar/ipo" "from=${from}" "to=${to}"
        ;;

    # === PHASE 4: Sentiment & Alternative Data ================================
    news-sentiment)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh news-sentiment <symbol>

Get news sentiment analysis for a symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g., AAPL)

EXAMPLES
    finnhub-cli.sh news-sentiment AAPL
    finnhub-cli.sh news-sentiment TSLA
EOF
            exit 0
        fi
        symbol=""
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh news-sentiment <symbol>"
        _api "/news-sentiment" "symbol=${symbol}"
        ;;
    social-sentiment)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh social-sentiment <symbol> [options]

Get social media sentiment data for a symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g., AAPL)

OPTIONS
    --from DATE    Start date in YYYY-MM-DD format (default: 30 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh social-sentiment AAPL
    finnhub-cli.sh social-sentiment TSLA --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh social-sentiment <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 30)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/stock/social-sentiment" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    congressional-trading)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh congressional-trading <symbol> [options]

Get congressional trading activity for a symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g., AAPL)

OPTIONS
    --from DATE    Start date in YYYY-MM-DD format (default: 90 days ago)
    --to DATE      End date in YYYY-MM-DD format (default: today)

EXAMPLES
    finnhub-cli.sh congressional-trading AAPL
    finnhub-cli.sh congressional-trading TSLA --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" from="" to=""
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh congressional-trading <symbol> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"
        [[ -z "$from" ]] && from=$(_default_from 90)
        [[ -z "$to" ]] && to=$(_default_to)
        _api "/stock/congressional-trading" "symbol=${symbol}" "from=${from}" "to=${to}"
        ;;
    supply-chain)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh supply-chain <symbol>

Get supply chain relationships for a symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g., AAPL)

EXAMPLES
    finnhub-cli.sh supply-chain AAPL
    finnhub-cli.sh supply-chain TSLA
EOF
            exit 0
        fi
        symbol=""
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh supply-chain <symbol>"
        _api "/stock/supply-chain" "symbol=${symbol}"
        ;;
    sector-metrics)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh sector-metrics [options]

Get sector-level performance metrics.

OPTIONS
    --region REGION    Region code (default: NA)

EXAMPLES
    finnhub-cli.sh sector-metrics
    finnhub-cli.sh sector-metrics --region EU
EOF
            exit 0
        fi
        region="NA"
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --region) region="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _api "/sector/metrics" "region=${region}"
        ;;
    esg)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh esg <symbol>

Get ESG (environmental, social, governance) scores for a symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g., AAPL)

EXAMPLES
    finnhub-cli.sh esg AAPL
    finnhub-cli.sh esg MSFT
EOF
            exit 0
        fi
        symbol=""
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh esg <symbol>"
        _api "/stock/esg" "symbol=${symbol}"
        ;;

    # === PHASE 5: Technical Analysis & Indices ================================
    indicator)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh indicator <symbol> --indicator <name> [options]

Run a technical indicator calculation on candle data.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT)

OPTIONS
    --indicator NAME   Indicator name: sma, ema, rsi, macd, bbands, stoch,
                       adx, atr, cci, obv, wma (required)
    --resolution R     Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)
    --from DATE        Start date in YYYY-MM-DD format (default: 1 year ago)
    --to DATE          End date in YYYY-MM-DD format (default: today)
    --timeperiod N     Time period for the indicator (default: 14)

EXAMPLES
    finnhub-cli.sh indicator AAPL --indicator sma
    finnhub-cli.sh indicator MSFT --indicator rsi --timeperiod 21
    finnhub-cli.sh indicator TSLA --indicator macd --from 2024-01-01 --to 2024-06-01
EOF
            exit 0
        fi
        symbol="" resolution="D" from="" to="" ind="" timeperiod="14"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --indicator) ind="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --timeperiod) timeperiod="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh indicator <symbol> --indicator <name> [--resolution D] [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--timeperiod 14]"
        _require "indicator" "$ind" "usage: finnhub-cli.sh indicator <symbol> --indicator <name> (e.g. sma, ema, rsi, macd, bbands)"
        [[ -z "$from" ]] && from=$(_default_from 365)
        [[ -z "$to" ]] && to=$(_default_to)
        from_ts=""; to_ts=""
        from_ts=$(_date_to_ts "$from")
        to_ts=$(_date_to_ts "$to")
        _api "/indicator" "symbol=${symbol}" "resolution=${resolution}" "from=${from_ts}" "to=${to_ts}" "indicator=${ind}" "timeperiod=${timeperiod}"
        ;;
    pattern)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh pattern <symbol> [options]

Detect candlestick patterns for a stock symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT)

OPTIONS
    --resolution R    Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)

EXAMPLES
    finnhub-cli.sh pattern AAPL
    finnhub-cli.sh pattern MSFT --resolution W
EOF
            exit 0
        fi
        symbol="" resolution="D"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh pattern <symbol> [--resolution D]"
        _api "/scan/pattern" "symbol=${symbol}" "resolution=${resolution}"
        ;;
    support-resistance)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh support-resistance <symbol> [options]

Get support and resistance levels for a stock symbol.

ARGUMENTS
    <symbol>    Stock ticker symbol (e.g. AAPL, MSFT)

OPTIONS
    --resolution R    Candle resolution: 1, 5, 15, 30, 60, D, W, M (default: D)

EXAMPLES
    finnhub-cli.sh support-resistance AAPL
    finnhub-cli.sh support-resistance MSFT --resolution W
EOF
            exit 0
        fi
        symbol="" resolution="D"
        symbol="${COMMAND_ARGS[0]:-""}"
        i=1
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --resolution) resolution="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        _require "symbol" "$symbol" "usage: finnhub-cli.sh support-resistance <symbol> [--resolution D]"
        _api "/scan/support-resistance" "symbol=${symbol}" "resolution=${resolution}"
        ;;
    index-constituents)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh index-constituents <symbol>

Get the constituents (member stocks) of a stock index.

ARGUMENTS
    <symbol>    Index symbol (e.g. ^GSPC for S&P 500, ^DJI for Dow Jones)

EXAMPLES
    finnhub-cli.sh index-constituents ^GSPC
    finnhub-cli.sh index-constituents ^DJI
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh index-constituents <symbol> (e.g. ^GSPC, ^DJI)"
        _api "/index/constituents" "symbol=${symbol}"
        ;;
    etf-holdings)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh etf-holdings <symbol>

Get ETF holdings breakdown.

ARGUMENTS
    <symbol>    ETF ticker symbol (e.g. SPY, QQQ, IWM)

EXAMPLES
    finnhub-cli.sh etf-holdings SPY
    finnhub-cli.sh etf-holdings QQQ
EOF
            exit 0
        fi
        symbol="${COMMAND_ARGS[0]:-""}"
        _require "symbol" "$symbol" "usage: finnhub-cli.sh etf-holdings <symbol> (e.g. SPY, QQQ)"
        _api "/etf/holdings" "symbol=${symbol}"
        ;;

    # === PHASE 6: Economic & Calendar =========================================
    economic-calendar)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh economic-calendar [options]

Get upcoming economic events calendar.

Options:
    --from    Start date YYYY-MM-DD (default: today)
    --to      End date YYYY-MM-DD (default: 7 days from now)

Examples:
    finnhub-cli.sh economic-calendar
    finnhub-cli.sh economic-calendar --from 2024-01-01 --to 2024-01-31
EOF
            exit 0
        fi
        from="" to=""
        i=0
        while [[ $i -lt ${#COMMAND_ARGS[@]} ]]; do
            case "${COMMAND_ARGS[$i]}" in
                --from) from="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                --to) to="${COMMAND_ARGS[$((i+1))]:-""}"; ((i+=2)) ;;
                *) ((i+=1)) ;;
            esac
        done
        [[ -z "$from" ]] && from=$(_default_to)
        [[ -z "$to" ]] && to=$(_date_forward 7)
        _api "/calendar/economic" "from=${from}" "to=${to}"
        ;;
    economic-codes)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh economic-codes

List available economic indicator codes.

Examples:
    finnhub-cli.sh economic-codes
EOF
            exit 0
        fi
        _api "/economic/code"
        ;;
    economic)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh economic <code>

Get economic indicator data by code.

Arguments:
    <code>    Economic indicator code (e.g. MA-USA-656880)

Examples:
    finnhub-cli.sh economic MA-USA-656880
EOF
            exit 0
        fi
        code="${COMMAND_ARGS[0]:-""}"
        _require "code" "$code" "usage: finnhub-cli.sh economic <code>"
        _api "/economic" "code=${code}"
        ;;
    country)
        if [[ "$SHOW_HELP" -eq 1 ]]; then
            cat <<'EOF'
Usage: finnhub-cli.sh country

List available country metadata.

Examples:
    finnhub-cli.sh country
EOF
            exit 0
        fi
        _api "/country"
        ;;

    # --- Unknown command ------------------------------------------------------
    *)
        printf "finnhub-cli.sh: unknown command '%s'\n\n" "$COMMAND" >&2
        _usage >&2
        exit 1
        ;;
esac
