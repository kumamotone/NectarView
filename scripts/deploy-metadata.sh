#!/bin/zsh
# Deploy App Store Connect metadata from metadata/ directory
# Usage: ./scripts/deploy-metadata.sh <version-id>
#
# Prerequisites:
#   - asc-cli authenticated (asc auth login)
#   - Version already created on App Store Connect
#
# To find version-id:
#   asc versions list --app-id 6753213525

set -euo pipefail

VERSION_ID="${1:?Usage: $0 <version-id>}"
APP_INFO_ID="55f6f7ff-911c-4c7c-9990-f714988fade2"
METADATA_DIR="$(cd "$(dirname "$0")/../metadata" && pwd)"

# Locale mapping: directory name -> App Store Connect locale
# version-localizations use these IDs (fetched once, update if needed)
declare -A VERSION_LOC_IDS
declare -A APP_INFO_LOC_IDS

echo "==> Fetching version localization IDs..."
while IFS='|' read -r locale id; do
    VERSION_LOC_IDS["$locale"]="$id"
    echo "    $locale -> $id"
done < <(asc version-localizations list --version-id "$VERSION_ID" 2>/dev/null | \
    python3 -c "import sys,json; [print(f'{x[\"locale\"]}|{x[\"id\"]}') for x in json.load(sys.stdin)['data']]")

echo ""
echo "==> Fetching app info localization IDs..."
while IFS='|' read -r locale id; do
    APP_INFO_LOC_IDS["$locale"]="$id"
    echo "    $locale -> $id"
done < <(asc app-info-localizations list --app-info-id "$APP_INFO_ID" 2>/dev/null | \
    python3 -c "import sys,json; [print(f'{x[\"locale\"]}|{x[\"id\"]}') for x in json.load(sys.stdin)['data']]")

echo ""

# Map directory names to ASC locale codes
declare -A DIR_TO_LOCALE=(
    ["en-US"]="en-US"
    ["ja"]="ja"
    ["zh-Hans"]="zh-Hans"
    ["zh-Hant"]="zh-Hant"
    ["ko"]="ko"
    ["fr"]="fr-FR"
    ["de"]="de-DE"
    ["es"]="es-ES"
)

for dir in "$METADATA_DIR"/*/; do
    dir_name=$(basename "$dir")
    locale="${DIR_TO_LOCALE[$dir_name]:-$dir_name}"

    echo "==> Processing $dir_name (locale: $locale)"

    # Update version localizations (description, keywords, whats_new)
    loc_id="${VERSION_LOC_IDS[$locale]:-}"
    if [ -z "$loc_id" ]; then
        echo "    Creating version localization for $locale..."
        result=$(asc version-localizations create --version-id "$VERSION_ID" --locale "$locale" 2>&1 || true)
        loc_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])" 2>/dev/null || true)
        if [ -z "$loc_id" ]; then
            echo "    SKIP: Could not create localization for $locale"
            continue
        fi
    fi

    if [ -f "$dir/description.txt" ]; then
        echo "    Updating description..."
        asc version-localizations update --localization-id "$loc_id" \
            --description "$(cat "$dir/description.txt")" >/dev/null 2>&1 && echo "    OK" || echo "    FAILED"
    fi

    if [ -f "$dir/keywords.txt" ]; then
        echo "    Updating keywords..."
        asc version-localizations update --localization-id "$loc_id" \
            --keywords "$(cat "$dir/keywords.txt")" >/dev/null 2>&1 && echo "    OK" || echo "    FAILED"
    fi

    if [ -f "$dir/whats_new.txt" ]; then
        echo "    Updating whats_new..."
        asc version-localizations update --localization-id "$loc_id" \
            --whats-new "$(cat "$dir/whats_new.txt")" >/dev/null 2>&1 && echo "    OK" || echo "    FAILED"
    fi

    # Update app info localizations (subtitle)
    info_loc_id="${APP_INFO_LOC_IDS[$locale]:-}"
    if [ -n "$info_loc_id" ] && [ -f "$dir/subtitle.txt" ]; then
        echo "    Updating subtitle..."
        asc app-info-localizations update --localization-id "$info_loc_id" \
            --subtitle "$(cat "$dir/subtitle.txt")" >/dev/null 2>&1 && echo "    OK" || echo "    FAILED"
    fi

    echo ""
done

echo "==> Done! Verify at: https://appstoreconnect.apple.com/apps/6753213525"
