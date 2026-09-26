#!/usr/bin/env python3
"""Upload feature graphics to App Store Connect for all locales."""

import json, time, os, sys, hashlib
import jwt, httpx

KEY_ID = "83RP2C955C"
ISSUER_ID = "00f77d2c-067d-40f9-a27a-42325d6b760f"
KEY_PATH = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_83RP2C955C.p8")
APP_ID = "6753213525"
VERSION_ID = "7cd34420-8192-45b6-9de1-88898151a252"
EXPORT_DIR = os.path.join(os.path.dirname(__file__), "export")

# Map our locale dirs to App Store Connect locale codes
LOCALE_MAP = {
    "en": "en-US",
    "ja": "ja",
    "zh-Hans": "zh-Hans",
    "zh-Hant": "zh-Hant",
    "ko": "ko",
    "fr": "fr-FR",
    "de": "de-DE",
    "es": "es-ES",
    "pt-BR": "pt-BR",
    "th": "th",
    "vi": "vi",
    "id": "id",
    "it": "it",
    "pl": "pl",
    "tr": "tr",
    "ru": "ru",
    "ms": "ms",
    "nl": "nl-NL",
    "sv": "sv",
    "da": "da",
    "nb": "nb-NO",
    "fi": "fi",
    "ar-SA": "ar-SA",
    "ca": "ca",
    "cs": "cs",
    "el": "el",
    "en-AU": "en-AU",
    "en-CA": "en-CA",
    "en-GB": "en-GB",
    "es-MX": "es-MX",
    "fr-CA": "fr-CA",
    "he": "he",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "no": "no",
    "pt-PT": "pt-PT",
    "ro": "ro",
    "sk": "sk",
    "uk": "uk",
}

# macOS screenshot display type
DISPLAY_TYPE = "APP_DESKTOP"

def get_token():
    with open(KEY_PATH) as f:
        key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, token, json_data=None, **kwargs):
    url = f"https://api.appstoreconnect.apple.com/v1/{path}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    r = httpx.request(method, url, headers=headers, json=json_data, timeout=60, **kwargs)
    if r.status_code >= 400:
        print(f"  ERROR {r.status_code}: {r.text[:500]}")
    return r

def get_version_localizations(token):
    r = api("GET", f"appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations?limit=50", token)
    data = r.json().get("data", [])
    return {item["attributes"]["locale"]: item["id"] for item in data}

def create_localization(token, locale):
    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "attributes": {"locale": locale},
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": VERSION_ID}
                }
            }
        }
    }
    r = api("POST", "appStoreVersionLocalizations", token, body)
    if r.status_code < 300:
        return r.json()["data"]["id"]
    return None

def get_screenshot_sets(token, loc_id):
    r = api("GET", f"appStoreVersionLocalizations/{loc_id}/appScreenshotSets?filter[screenshotDisplayType]={DISPLAY_TYPE}", token)
    data = r.json().get("data", [])
    return data[0]["id"] if data else None

def create_screenshot_set(token, loc_id):
    body = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            }
        }
    }
    r = api("POST", "appScreenshotSets", token, body)
    if r.status_code < 300:
        return r.json()["data"]["id"]
    return None

def upload_screenshot(token, set_id, filepath):
    filename = os.path.basename(filepath)
    filesize = os.path.getsize(filepath)

    # Step 1: Reserve screenshot
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {
                "fileName": filename,
                "fileSize": filesize,
            },
            "relationships": {
                "appScreenshotSet": {
                    "data": {"type": "appScreenshotSets", "id": set_id}
                }
            }
        }
    }
    r = api("POST", "appScreenshots", token, body)
    if r.status_code >= 400:
        return False

    screenshot_data = r.json()["data"]
    screenshot_id = screenshot_data["id"]
    upload_ops = screenshot_data["attributes"]["uploadOperations"]

    # Step 2: Upload binary parts
    with open(filepath, "rb") as f:
        file_bytes = f.read()

    for op in upload_ops:
        offset = op["offset"]
        length = op["length"]
        chunk = file_bytes[offset:offset + length]
        upload_headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        r2 = httpx.put(op["url"], content=chunk, headers=upload_headers, timeout=60)
        if r2.status_code >= 400:
            print(f"    Upload chunk failed: {r2.status_code}")
            return False

    # Step 3: Commit
    md5 = hashlib.md5(file_bytes).hexdigest()
    commit_body = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {
                "uploaded": True,
                "sourceFileChecksum": md5,
            }
        }
    }
    r3 = api("PATCH", f"appScreenshots/{screenshot_id}", token, commit_body)
    return r3.status_code < 400

def delete_existing_screenshots(token, set_id):
    """Delete all screenshots in a set."""
    r = api("GET", f"appScreenshotSets/{set_id}/appScreenshots?limit=10", token)
    if r.status_code >= 400:
        return
    for ss in r.json().get("data", []):
        api("DELETE", f"appScreenshots/{ss['id']}", token)

def main():
    token = get_token()

    # Get existing localizations
    print("Fetching version localizations...")
    locs = get_version_localizations(token)
    print(f"  Found {len(locs)} existing localizations")

    slides = ["slide-1.png", "slide-2.png", "slide-3.png", "slide-4.png"]
    total = 0
    errors = 0

    for our_locale, asc_locale in LOCALE_MAP.items():
        locale_dir = os.path.join(EXPORT_DIR, our_locale)
        if not os.path.isdir(locale_dir):
            print(f"  SKIP {our_locale}: no export directory")
            continue

        # Get or create localization
        loc_id = locs.get(asc_locale)
        if not loc_id:
            print(f"  Creating localization for {asc_locale}...")
            loc_id = create_localization(token, asc_locale)
            if not loc_id:
                print(f"  FAILED to create localization for {asc_locale}")
                errors += 1
                continue

        # Get or create screenshot set, delete existing screenshots
        set_id = get_screenshot_sets(token, loc_id)
        if set_id:
            delete_existing_screenshots(token, set_id)
        else:
            set_id = create_screenshot_set(token, loc_id)
            if not set_id:
                print(f"  FAILED to create screenshot set for {asc_locale}")
                errors += 1
                continue

        # Upload each slide
        for slide in slides:
            filepath = os.path.join(locale_dir, slide)
            if not os.path.isfile(filepath):
                continue
            ok = upload_screenshot(token, set_id, filepath)
            if ok:
                total += 1
            else:
                errors += 1

        # Refresh token periodically
        token = get_token()
        print(f"✓ {asc_locale} ({our_locale})")

    print(f"\nDone! Uploaded {total} screenshots, {errors} errors.")

if __name__ == "__main__":
    main()
