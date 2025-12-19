#!/usr/bin/env python3
"""
Upload New Localization Keys to Google Sheets

This script reads new localization keys from Localizable.strings files
and appends them to the Google Sheet.

Requirements:
- gspread
- google-auth
- google-auth-oauthlib
- google-auth-httplib2

Install: pip install gspread google-auth google-auth-oauthlib google-auth-httplib2
"""

import os
import sys
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Set

try:
    import gspread
    import google.auth
    from google.oauth2.service_account import Credentials
except ImportError:
    print("Error: Required packages not installed.")
    print("Please run: pip install gspread google-auth google-auth-oauthlib google-auth-httplib2")
    sys.exit(1)


# Configuration
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent
LOCALIZATIONS_DIR = PROJECT_ROOT / "DMateResource" / "Resources" / "Localizations"

# Google Sheets API Scopes - READ & WRITE
SCOPES = [
    'https://www.googleapis.com/auth/spreadsheets',  # Read and write
    'https://www.googleapis.com/auth/drive'
]

# Language mapping (column order in sheet)
LANGUAGES = ['ko', 'en', 'ja', 'id', 'zh-Hans', 'de', 'fr', 'es', 'ar']

# Key prefixes to extract (newly added keys)
NEW_KEY_PREFIXES = [
    'widget.',
    'onboarding.',
    'medication.',
    'medication_detail.',
    'date_format.',
    'time_unit.'
]


def parse_strings_file(file_path: Path) -> Dict[str, str]:
    """Parse a Localizable.strings file and extract key-value pairs"""
    translations = {}

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match pattern: "key" = "value";
    pattern = r'"([^"]+)"\s*=\s*"([^"]+)";'
    matches = re.findall(pattern, content, re.MULTILINE)

    for key, value in matches:
        # Unescape the value
        value = value.replace('\\"', '"').replace('\\n', '\n')
        translations[key] = value

    return translations


def extract_new_keys() -> Dict[str, Dict[str, str]]:
    """Extract all new keys from all language files"""
    all_keys = {}

    for lang_code in LANGUAGES:
        lproj_folder = f"{lang_code}.lproj"
        strings_file = LOCALIZATIONS_DIR / lproj_folder / "Localizable.strings"

        if not strings_file.exists():
            print(f"Warning: {strings_file} not found")
            continue

        translations = parse_strings_file(strings_file)

        # Filter only new keys
        for key, value in translations.items():
            if any(key.startswith(prefix) for prefix in NEW_KEY_PREFIXES):
                if key not in all_keys:
                    all_keys[key] = {}
                all_keys[key][lang_code] = value

    return all_keys


class SheetsUploader:
    """Upload new localization keys to Google Sheets"""

    def __init__(self, sheet_id: str, credentials_path: Optional[Path], worksheet_name: str):
        self.sheet_id = sheet_id
        self.credentials_path = credentials_path
        self.worksheet_name = worksheet_name
        self.client = None
        self.worksheet = None

    def authenticate(self) -> None:
        """Authenticate with Google Sheets API"""
        try:
            credentials = None

            if self.credentials_path and self.credentials_path.exists():
                print(f"Auth: Using service account file: {self.credentials_path.name}")
                credentials = Credentials.from_service_account_file(
                    str(self.credentials_path),
                    scopes=SCOPES
                )
            else:
                print("Auth: Using default credentials...")
                credentials, project = google.auth.default(scopes=SCOPES)

            self.client = gspread.authorize(credentials)
            print("✓ Successfully authenticated with Google Sheets API")

        except Exception as e:
            print(f"Error: Authentication failed: {e}")
            sys.exit(1)

    def open_worksheet(self) -> None:
        """Open the target worksheet"""
        try:
            spreadsheet = self.client.open_by_key(self.sheet_id)
            self.worksheet = spreadsheet.worksheet(self.worksheet_name)
            print(f"✓ Opened worksheet: '{self.worksheet.title}'")
        except Exception as e:
            print(f"Error: Failed to open worksheet: {e}")
            sys.exit(1)

    def get_existing_keys(self) -> Set[str]:
        """Get all existing keys from column A"""
        try:
            keys_column = self.worksheet.col_values(1)  # Column A
            # Skip header
            existing_keys = set(keys_column[1:]) if len(keys_column) > 1 else set()
            print(f"✓ Found {len(existing_keys)} existing keys in sheet")
            return existing_keys
        except Exception as e:
            print(f"Error: Failed to get existing keys: {e}")
            return set()

    def append_new_keys(self, new_keys: Dict[str, Dict[str, str]]) -> None:
        """Append new keys to the sheet"""
        try:
            existing_keys = self.get_existing_keys()

            # Filter out keys that already exist
            keys_to_add = {k: v for k, v in new_keys.items() if k not in existing_keys}

            if not keys_to_add:
                print("No new keys to add. All keys already exist in the sheet.")
                return

            # Prepare rows to append
            rows_to_append = []
            for key in sorted(keys_to_add.keys()):
                translations = keys_to_add[key]
                row = [key]  # First column is the key

                # Add translations in order: ko, en, ja, id, zh-Hans, de, fr, es, ar
                for lang in LANGUAGES:
                    row.append(translations.get(lang, ''))

                rows_to_append.append(row)

            # Append all rows at once
            self.worksheet.append_rows(rows_to_append, value_input_option='RAW')

            print(f"✓ Successfully added {len(rows_to_append)} new keys to the sheet:")
            for row in rows_to_append[:5]:  # Show first 5
                print(f"  - {row[0]}")
            if len(rows_to_append) > 5:
                print(f"  ... and {len(rows_to_append) - 5} more")

        except Exception as e:
            print(f"Error: Failed to append keys: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


def resolve_credentials_path(config: Dict) -> Optional[Path]:
    """Resolve credentials file path from config"""
    priority_keys = ['credentials_primary', 'credentials_secondary']

    for key in priority_keys:
        filename = config.get(key)
        if filename:
            candidate_path = SCRIPT_DIR / filename
            if candidate_path.exists():
                print(f"Config: Found credentials file ({key}): '{filename}'")
                return candidate_path
            else:
                print(f"Config: File '{filename}' not found. Skipping...")

    return None


if __name__ == "__main__":
    print("=" * 60)
    print("Upload New Localization Keys to Google Sheets")
    print("=" * 60)
    print()

    # 1. Load configuration
    config_path = SCRIPT_DIR / "config.json"
    if not config_path.exists():
        print("Error: config.json not found")
        sys.exit(1)

    with open(config_path, 'r') as f:
        config = json.load(f)

    sheet_id = config.get('sheet_id')
    worksheet_name = config.get('worksheet_name', 'ios')

    if not sheet_id:
        print("Error: 'sheet_id' not found in config.json")
        sys.exit(1)

    # 2. Extract new keys from Localizable.strings files
    print("Step 1: Extracting new keys from Localizable.strings files...")
    new_keys = extract_new_keys()
    print(f"✓ Extracted {len(new_keys)} new keys")
    print()

    if not new_keys:
        print("No new keys found to upload.")
        sys.exit(0)

    # 3. Authenticate and upload
    print("Step 2: Uploading to Google Sheets...")
    creds_path = resolve_credentials_path(config)

    uploader = SheetsUploader(
        sheet_id=sheet_id,
        credentials_path=creds_path,
        worksheet_name=worksheet_name
    )

    uploader.authenticate()
    uploader.open_worksheet()
    uploader.append_new_keys(new_keys)

    print()
    print("=" * 60)
    print("✓ Upload completed successfully!")
    print("=" * 60)
