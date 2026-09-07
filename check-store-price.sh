#!/bin/zsh
# Has the App Store price actually changed yet?
#
# Reads the live product page rather than trusting a schedule. Apple's own
# listing is the only thing that can say what a coach will be charged, and a
# website that disagrees with it sends someone to a checkout for a different
# number than they were quoted.
#
# Exit 0 = the expected price is live. Exit 1 = not yet. Exit 2 = could not tell,
# which is NOT the same as "not yet" and must never be treated as one.
set -uo pipefail
WANT="${1:-\$50.00}"
URL="https://apps.apple.com/us/app/sideline-sidekick-tracker/id6798818893"

BODY=$(curl -s -L --max-time 30 -A "Mozilla/5.0" "$URL") || BODY=""
if [[ -z "$BODY" ]]; then
  echo "UNKNOWN: could not fetch the listing"
  exit 2
fi

# The listing embeds the IAP name and price as an adjacent pair. Anchor on the
# plan name so a price elsewhere on the page cannot be mistaken for it.
FOUND=$(printf '%s' "$BODY" \
  | grep -oE 'Annual Team Plan"[^0-9]{0,12}"\$[0-9]+\.[0-9]{2}"' \
  | grep -oE '\$[0-9]+\.[0-9]{2}' | head -1)

if [[ -z "$FOUND" ]]; then
  # Fetched fine but the shape changed — say so rather than reporting "not yet",
  # which would look identical to a price that simply has not moved.
  echo "UNKNOWN: fetched the page but could not find the Annual Team Plan price"
  exit 2
fi

echo "live price: $FOUND (want $WANT)"
[[ "$FOUND" == "$WANT" ]] && exit 0 || exit 1
