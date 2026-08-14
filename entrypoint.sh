#!/usr/bin/env bash

set -euo pipefail

if [ -z "${API_URL:-}" ]; then
    echo "❌ Error: API_URL environment variable is not set." >&2
    exit 1
fi

if [ -z "${WEBHOOK_URL:-}" ]; then
    echo "❌ Error: WEBHOOK_URL environment variable is not set." >&2
    exit 1
fi

response=$(curl -s "${API_URL}" )


echo "$response" | jq '.' > data.json


report=$(jq -r '.checks[] | "\(.id) \(.ok) \(.status_code)"' data.json |
awk '
{
    total++

    if ($2 == "true" && $3 == 200)
        success++
    else
        failed++
}
END {
    printf "%d %d %d", total, success, failed
}')

read -r total success failed <<< "$report"

echo "Total Monitors: $total"
echo "🚨 ALERT: $failed"
echo "Sucess: $success"

if [ -n "${WEBHOOK_URL:-}" ]; then
    curl -s -X POST "${WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "{\"content\":\"🚨 ALERT: ${failed} check(s) failed out of ${total}.\\n✅ Successful: ${success}.\"}"
fi
