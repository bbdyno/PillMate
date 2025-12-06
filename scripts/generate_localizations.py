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
from typing import Dict, List, Optional
from datetime import datetime

try:
    import gspread
    from google.oauth2.service_account import Credentials
except ImportError:
    print("Error: Required packages not installed.")
    print("Please run: pip install gspread google-auth google-auth-oauthlib google-auth-httplib2")
    sys.exit(1)


# Configuration
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent
LOCALIZATIONS_DIR = PROJECT_ROOT / "DoseMate" / "Resources" / "Localizations"
CREDENTIALS_FILE = SCRIPT_DIR / "google-sheet-api.json"

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
}


def extract_sheet_id(input_str: str) -> str:
    """
    Extract Google Sheets ID from URL or return as-is if already an ID

    Args:
        input_str: Google Sheets URL or ID

    Returns:
        Sheet ID
    """
    # Check if it's a URL
    url_pattern = r'/spreadsheets/d/([a-zA-Z0-9-_]+)'
    match = re.search(url_pattern, input_str)

    if match:
        return match.group(1)

    # Assume it's already an ID
    return input_str


class LocalizationGenerator:
    """Generates iOS Localizable.strings files from Google Sheets"""

    def __init__(self, credentials_path: Path, sheet_id: str, worksheet_name: Optional[str] = None):
        """
        Initialize the generator

        Args:
            credentials_path: Path to Google service account JSON file
            sheet_id: Google Sheets document ID
            worksheet_name: Name of the worksheet (default: first sheet)
        """
        self.credentials_path = credentials_path
        self.sheet_id = sheet_id
        self.worksheet_name = worksheet_name
        self.client = None

    def authenticate(self) -> None:
        """Authenticate with Google Sheets API"""
        try:
            credentials = Credentials.from_service_account_file(
                str(self.credentials_path),
                scopes=SCOPES
            )
            self.client = gspread.authorize(credentials)
            print(f"✓ Successfully authenticated with Google Sheets API")
        except FileNotFoundError:
            print(f"Error: Credentials file not found: {self.credentials_path}")
            sys.exit(1)
        except Exception as e:
            print(f"Error: Authentication failed: {e}")
            sys.exit(1)

    def fetch_data(self) -> List[List[str]]:
        """
        Fetch all data from the Google Sheet

        Returns:
            2D list of sheet data
        """
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
            print(f"\nDetailed error:")
            traceback.print_exc()

            # Provide helpful hints
            print("\nPossible causes:")
            print("1. The worksheet name 'ios' might not exist in the spreadsheet")
            print("2. The service account might not have access to the spreadsheet")
            print("3. Check if you've shared the spreadsheet with the service account email")
            sys.exit(1)

    def parse_data(self, raw_data: List[List[str]]) -> Dict[str, Dict[str, str]]:
        """
        Parse raw sheet data into structured format

        Expected format:
        Row 1: [Key, en, ko, ja, zh-Hans, id, ...]
        Row 2+: [key_name, "English", "한국어", "日本語", "中文", "Bahasa", ...]

        Args:
            raw_data: Raw 2D list from Google Sheets

        Returns:
            Dictionary mapping language codes to key-value pairs
        """
        if not raw_data or len(raw_data) < 2:
            print("Error: Sheet is empty or has insufficient data")
            sys.exit(1)

        headers = raw_data[0]
        if len(headers) < 2:
            print("Error: Sheet must have at least 2 columns (Key + at least 1 language)")
            sys.exit(1)

        # First column is the key, rest are language codes
        language_codes = [h.strip() for h in headers[1:] if h.strip()]

        # Initialize result dictionary
        result: Dict[str, Dict[str, str]] = {lang: {} for lang in language_codes}

        # Process each row
        for row_idx, row in enumerate(raw_data[1:], start=2):
            if not row or not row[0].strip():
                continue  # Skip empty rows

            key = row[0].strip()

            # Process each language column
            for lang_idx, lang_code in enumerate(language_codes, start=1):
                if lang_idx < len(row):
                    value = row[lang_idx].strip()
                    if value:  # Only add non-empty values
                        result[lang_code][key] = value

        print(f"✓ Parsed data for {len(language_codes)} languages:")
        for lang in language_codes:
            print(f"  - {lang}: {len(result[lang])} keys")

        return result

    def generate_strings_file(self, data: Dict[str, str], output_path: Path) -> None:
        """
        Generate an iOS Localizable.strings file

        Args:
            data: Dictionary of key-value pairs
            output_path: Output file path
        """
        # Create parent directory if it doesn't exist
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Backup existing file if it exists
        if output_path.exists():
            backup_path = output_path.with_suffix('.strings.backup')
            import shutil
            shutil.copy2(output_path, backup_path)
            print(f"  → Backed up existing file to {backup_path.name}")

        # Generate content
        lines = []
        lines.append(f"/* Generated from Google Sheets */")
        lines.append(f"/* Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} */")
        lines.append(f"/* Total keys: {len(data)} */")
        lines.append("")

        # Sort keys for consistent output
        for key in sorted(data.keys()):
            value = data[key]
            # Escape quotes in value
            escaped_value = value.replace('"', '\\"').replace('\n', '\\n')
            lines.append(f'"{key}" = "{escaped_value}";')

        # Write to file
        content = '\n'.join(lines) + '\n'
        output_path.write_text(content, encoding='utf-8')

        print(f"✓ Generated: {output_path.relative_to(PROJECT_ROOT)}")

    def generate_all(self, localization_data: Dict[str, Dict[str, str]]) -> None:
        """
        Generate all Localizable.strings files

        Args:
            localization_data: Dictionary mapping language codes to key-value pairs
        """
        print(f"\nGenerating Localizable.strings files...")

        for lang_code, data in localization_data.items():
            # Determine the .lproj folder name
            lproj_folder = LANGUAGE_MAPPING.get(lang_code, f"{lang_code}.lproj")

            # Construct output path
            output_path = LOCALIZATIONS_DIR / lproj_folder / "Localizable.strings"

            # Generate the file
            self.generate_strings_file(data, output_path)

        print(f"\n✓ Successfully generated {len(localization_data)} localization files")

    def run(self) -> None:
        """Run the complete localization generation process"""
        print("=" * 60)
        print("iOS Localizations Generator")
        print("=" * 60)
        print()

        # Step 1: Authenticate
        print("Step 1: Authenticating with Google Sheets...")
        self.authenticate()
        print()

        # Step 2: Fetch data
        print("Step 2: Fetching data from Google Sheets...")
        raw_data = self.fetch_data()
        print()

        # Step 3: Parse data
        print("Step 3: Parsing localization data...")
        localization_data = self.parse_data(raw_data)
        print()

        # Step 4: Generate files
        print("Step 4: Generating Localizable.strings files...")
        self.generate_all(localization_data)
        print()

        print("=" * 60)
        print("✓ All done!")
        print("=" * 60)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Generate iOS Localizable.strings files from Google Sheets',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example:
  %(prog)s --sheet-id 1ABC123...xyz --worksheet "Localizations"
  %(prog)s -s 1ABC123...xyz -w "Sheet1"
        """
    )

    parser.add_argument(
        '-s', '--sheet-id',
        required=True,
        help='Google Sheets document ID or full URL'
    )

    parser.add_argument(
        '-w', '--worksheet',
        help='Worksheet name (default: first sheet)'
    )

    parser.add_argument(
        '-c', '--credentials',
        default=str(CREDENTIALS_FILE),
        help=f'Path to Google service account credentials JSON (default: {CREDENTIALS_FILE})'
    )

    args = parser.parse_args()

    # Validate credentials file
    credentials_path = Path(args.credentials)
    if not credentials_path.exists():
        print(f"Error: Credentials file not found: {credentials_path}")
        print(f"\nPlease ensure '{credentials_path.name}' is in the scripts directory")
        sys.exit(1)

    # Extract sheet ID from URL if needed
    sheet_id = extract_sheet_id(args.sheet_id)

    # Create and run generator
    generator = LocalizationGenerator(
        credentials_path=credentials_path,
        sheet_id=sheet_id,
        worksheet_name=args.worksheet
    )

    generator.run()


if __name__ == '__main__':
    main()
