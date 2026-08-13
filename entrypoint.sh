#!/usr/bin/env bash

set -euo pipefail

if [ -f "./env.sh" ]; then
    source ./env.sh
fi

if [ -z "$WEBHOOK_URL" ]; then 
  echo "Error: WEBHOOK_URL is not set. Run 'source env.sh' first."
  exit 1
fi

response=$(curl -s "https://pulse-api-xrla.onrender.com/monitors/2/checks?limit=30" | jq -r)


echo "$response" | jq '.' > ./data.json
# https://pulse-api-xrla.onrender.com/monitors/2/checks&limit=30

