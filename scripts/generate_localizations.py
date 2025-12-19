#!/usr/bin/env python3
"""
Google Sheets to iOS Localizations Generator

This script fetches localization data from Google Sheets and generates
Localizable.strings files for iOS app localization.

Requirements:
- google-auth
- google-auth-oauthlib
- google-auth-httplib2
- gspread

Install: pip install gspread google-auth google-auth-oauthlib google-auth-httplib2
"""

import os
import sys
import json
import re
import argparse
import traceback
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

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

# Google Sheets API Scopes
SCOPES = [
    'https://www.googleapis.com/auth/spreadsheets.readonly',
    'https://www.googleapis.com/auth/drive.readonly'
]

# Language code to .lproj folder mapping
LANGUAGE_MAPPING = {
    'en': 'en.lproj',
    'ko': 'ko.lproj',
    'ja': 'ja.lproj',
    'zh-Hans': 'zh-Hans.lproj',
    'id': 'id.lproj',
    'de': 'de.lproj',
    'es': 'es.lproj',
    'fr': 'fr.lproj',
    'ar': 'ar.lproj',
}


def extract_sheet_id(input_str: str) -> str:
    """
    Extract Google Sheets ID from URL or return as-is if already an ID
    """
    url_pattern = r'/spreadsheets/d/([a-zA-Z0-9-_]+)'
    match = re.search(url_pattern, input_str)

    if match:
        return match.group(1)
    return input_str


class LocalizationGenerator:
    """Generates iOS Localizable.strings files from Google Sheets"""

    def __init__(self, sheet_id: str, credentials_path: Optional[Path] = None, worksheet_name: Optional[str] = None):
        """
        Initialize the generator

        Args:
            sheet_id: Google Sheets document ID
            credentials_path: Path to service account JSON (Optional if using WIF/Env Vars)
            worksheet_name: Name of the worksheet (default: first sheet)
        """
        self.sheet_id = sheet_id
        self.credentials_path = credentials_path
        self.worksheet_name = worksheet_name
        self.client = None

    def authenticate(self) -> None:
        """Authenticate with Google Sheets API using WIF or Service Account"""
        try:
            credentials = None
            
            # 1. Explicit Service Account File (Legacy/Direct Path)
            if self.credentials_path and self.credentials_path.exists():
                print(f"Auth: Using provided service account file: {self.credentials_path.name}")
                credentials = Credentials.from_service_account_file(
                    str(self.credentials_path),
                    scopes=SCOPES
                )
            
            # 2. Workload Identity Federation / Standard Environment Variable
            else:
                print("Auth: Attempting to use Default Credentials (WIF/Env Vars)...")
                # google.auth.default() checks GOOGLE_APPLICATION_CREDENTIALS automatically
                credentials, project = google.auth.default(scopes=SCOPES)
            
            # Authorize gspread
            self.client = gspread.authorize(credentials)
            print(f"✓ Successfully authenticated with Google Sheets API")

        except Exception as e:
            print(f"Error: Authentication failed: {e}")
            print("\nTroubleshooting for Workload Identity Federation:")
            print("1. Ensure 'GOOGLE_APPLICATION_CREDENTIALS' env var points to your configuration JSON.")
            print("2. Ensure the underlying service account has access to the Spreadsheet.")
            sys.exit(1)

    def fetch_data(self) -> List[List[str]]:
        """Fetch all data from the Google Sheet"""
        try:
            spreadsheet = self.client.open_by_key(self.sheet_id)

            if self.worksheet_name:
                worksheet = spreadsheet.worksheet(self.worksheet_name)
            else:
                worksheet = spreadsheet.get_worksheet(0)  # First sheet

            data = worksheet.get_all_values()
            print(f"✓ Fetched {len(data)} rows from '{worksheet.title}'")
            return data

        except Exception as e:
            print(f"Error: Failed to fetch data: {e}")
            sys.exit(1)

    def parse_data(self, raw_data: List[List[str]]) -> Dict[str, Dict[str, str]]:
        """Parse raw sheet data into structured format"""
        if not raw_data or len(raw_data) < 2:
            print("Error: Sheet is empty or has insufficient data")
            sys.exit(1)

        headers = raw_data[0]
        if len(headers) < 2:
            print("Error: Sheet must have at least 2 columns (Key + at least 1 language)")
            sys.exit(1)

        language_codes = [h.strip() for h in headers[1:] if h.strip()]
        result: Dict[str, Dict[str, str]] = {lang: {} for lang in language_codes}

        for row in raw_data[1:]:
            if not row or not row[0].strip():
                continue

            key = row[0].strip()
            for lang_idx, lang_code in enumerate(language_codes, start=1):
                if lang_idx < len(row):
                    value = row[lang_idx].strip()
                    if value:
                        result[lang_code][key] = value

        print(f"✓ Parsed data for {len(language_codes)} languages")
        return result

    def generate_strings_file(self, data: Dict[str, str], output_path: Path) -> None:
        """Generate an iOS Localizable.strings file"""
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Backup logic removed to keep directories clean.
        # It will simply overwrite the existing file.

        lines = [
            f"/* Generated from Google Sheets */",
            ""
        ]

        # Sort keys strictly to minimize git diff noise
        for key in sorted(data.keys()):
            val = data[key]
            # Escape double quotes and newlines for .strings format
            val_escaped = val.replace('"', '\\"').replace('\n', '\\n')
            lines.append(f'"{key}" = "{val_escaped}";')

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        
        print(f"✓ Created: {output_path.name}")


def resolve_credentials_path(config: Dict[str, Any]) -> Optional[Path]:
    """
    Resolve the path to the credentials JSON file based on config priority:
    1. credentials_primary
    2. credentials_secondary
    """
    priority_keys = ['credentials_primary', 'credentials_secondary']
    
    for key in priority_keys:
        filename = config.get(key)
        if filename:
            candidate_path = SCRIPT_DIR / filename
            if candidate_path.exists():
                print(f"Config: Found credentials file ({key}): '{filename}'")
                return candidate_path
            else:
                print(f"Config: File defined in '{key}' ('{filename}') not found. Skipping...")

    return None


if __name__ == "__main__":
    # 1. Load Configuration
    config_path = SCRIPT_DIR / "config.json"
    config = {}
    
    if config_path.exists():
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load config.json: {e}")
    
    # 2. Determine Sheet ID
    sheet_id = config.get('sheet_id')
    if not sheet_id:
        print("Error: 'sheet_id' not found in config.json")
        sys.exit(1)
        
    sheet_id = extract_sheet_id(sheet_id)
    worksheet_name = config.get('worksheet_name')

    # 3. Resolve Credentials
    creds_path = resolve_credentials_path(config)

    # 4. Run Generator
    generator = LocalizationGenerator(
        sheet_id=sheet_id,
        credentials_path=creds_path,
        worksheet_name=worksheet_name
    )
    
    generator.authenticate()
    raw_data = generator.fetch_data()
    parsed_data = generator.parse_data(raw_data)

    # 5. Export Files
    print(f"\nTarget Directory: {LOCALIZATIONS_DIR}")
    
    for lang_code, translations in parsed_data.items():
        if not translations:
            continue
            
        mapped_folder = LANGUAGE_MAPPING.get(lang_code)
        if not mapped_folder:
            print(f"Skipping unknown language code: {lang_code}")
            continue
            
        output_file = LOCALIZATIONS_DIR / mapped_folder / "Localizable.strings"
        generator.generate_strings_file(translations, output_file)

    print("\n✓ Localization update completed successfully.")
