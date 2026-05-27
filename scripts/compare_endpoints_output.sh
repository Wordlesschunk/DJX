#!/bin/bash

# Compare API responses between two environments
# Usage: ./compare_endpoints_output.sh
#
# Just paste full URLs as pairs (env1 env2) in the COMPARISONS array below.
# Grab the cURL from Postman's code snippet view for each request.

# --- Auth tokens (one per environment, leave empty if not needed) ---
ENV1_TOKEN="COOL_KEY"
ENV2_TOKEN="COOL_KEY"

# --- Define URL pairs to compare ---
# Each line is: "FULL_URL_ENV1 FULL_URL_ENV2"
COMPARISONS=(
  # Add more pairs:
  # "https://api.company.com/api/v2/users https://api.company.com/api/v2/users"
)

# --- Script ---
PASS=0
FAIL=0
TMPDIR=$(mktemp -d)

for pair in "${COMPARISONS[@]}"; do
  url1=$(echo "$pair" | awk '{print $1}')
  url2=$(echo "$pair" | awk '{print $2}')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "URL1: $url1"
  echo "URL2: $url2"
  echo ""

  resp1="$TMPDIR/env1_response.json"
  resp2="$TMPDIR/env2_response.json"

  # Fetch from both
  http_code1=$(curl -s -L -o "$resp1" -w "%{http_code}" \
    -H "Authorization: Bearer $ENV1_TOKEN" \
    "$url1")

  http_code2=$(curl -s -L -o "$resp2" -w "%{http_code}" \
    -H "Authorization: Bearer $ENV2_TOKEN" \
    "$url2")

  echo "  ENV1: HTTP $http_code1"
  echo "  ENV2: HTTP $http_code2"

  # Compare status codes
  if [ "$http_code1" != "$http_code2" ]; then
    echo "  ❌ Status codes differ: $http_code1 vs $http_code2"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Normalize JSON (sort keys) and compare
  if command -v jq &> /dev/null; then
    diff_output=$(diff <(jq -S . "$resp1" 2>/dev/null || cat "$resp1") \
                       <(jq -S . "$resp2" 2>/dev/null || cat "$resp2"))
  else
    diff_output=$(diff "$resp1" "$resp2")
  fi

  if [ -z "$diff_output" ]; then
    echo "  ✅ Responses match"
    PASS=$((PASS + 1))
  else
    echo "  ❌ Responses differ:"
    echo "$diff_output" | head -40 | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
done

# Cleanup
rm -rf "$TMPDIR"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed ($(( PASS + FAIL )) total)"
[ $FAIL -eq 0 ] && exit 0 || exit 1
