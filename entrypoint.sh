#!/usr/bin/env bash

set -euo pipefail

response=$(curl -s "${API_URL}" )


echo "$response" | jq '.' > data.json
echo "Project is working"
# https://pulse-api-xrla.onrender.com/monitors/2/checks&limit=30

