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

response=$(curl -fsS --max-time 15 --retry 3  "${API_URL}" )


echo "$response" | jq '.' > data.json

jq -e '.checks[]' data.json > /dev/null || {
    echo "❌ Error: 'checks'array missing or null in API response." >&2
    exit 1
}

report=$(jq -r '.checks[] | "\(.id) \(.ok) \(.status_code)"' data.json |
awk '
BEGIN {
    total=0
    success=0
    failed=0
}
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
echo "✅  Success: $success"

if [ "$failed" -gt 0 ]; then
  if [ -n "${WEBHOOK_URL:-}" ]; then
PAYLOAD=$(cat <<EOF
{ "content": "🚨 ALERT: ${failed} check(s) failed out of ${total}.\n✅ Successful: ${success}."}
EOF
)

    curl --fail-with-body \
        --silent \
        --show-error \
        --max-time 15 \
        --retry 3 \
        --retry-delay 2 \
        -X POST "${WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "$PAYLOAD"
  fi
fi