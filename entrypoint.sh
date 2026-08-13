#!/usr/bin/env bash

set -euo pipefail

WEBHOOK_URL="https://discord.com/api/webhooks/1537389677626003526/hWC8JYFTpz0dYMFOtY_l5ToRYock7mPaG_jk9Kb5KTJH5QvwDx600ZBLDiEKvBveJbk3"

response=$(curl -s "https://pulse-api-xrla.onrender.com/monitors/2/checks?limit=30" | jq -r)


echo "$response" | jq '.' > ./data.json
echo "Project is working"
# https://pulse-api-xrla.onrender.com/monitors/2/checks&limit=30

