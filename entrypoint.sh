#!/usr/bin/env bash

set -euo pipefail

source ./env.sh

if [ -z "$WEBHOOK_URL" ]; then 
  echo "Error: WEBHOOK_URL is not set. Run 'source env.sh' first."
  exit 1
fi

echo " WEBHOOK_URL: $WEBHOOK_URL"
# https://pulse-api-xrla.onrender.com/

