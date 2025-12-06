# Localization Scripts

This directory contains scripts for managing iOS app localizations.

## generate_localizations.py

Python script that fetches localization data from Google Sheets and generates `Localizable.strings` files for iOS.

### Prerequisites

1. **Python 3.7+** installed on your system

2. **Install required packages:**
   ```bash
   pip install gspread google-auth google-auth-oauthlib google-auth-httplib2
   ```

3. **Google Service Account credentials:**
   - Create a Google Cloud project
   - Enable Google Sheets API
   - Create a Service Account and download the JSON credentials
   - Save the credentials as `google-sheet-api.json` in this `scripts` directory
   - Share your Google Sheet with the service account email

### Google Sheets Format

Your Google Sheet should be structured as follows:

| Key | en | ko | ja | zh-Hans | id |
|-----|----|----|----|---------|----|
| common.ok | OK | 확인 | OK | 确定 | OK |
| common.cancel | Cancel | 취소 | キャンセル | 取消 | Batal |
| ... | ... | ... | ... | ... | ... |

- **First column:** Localization keys (e.g., `common.ok`)
- **Subsequent columns:** Language codes as headers (e.g., `en`, `ko`, `ja`)
- **Data rows:** Translated strings for each language

### Quick Start

The easiest way to update localizations:

```bash
# Simply run the update script
./update_localizations.sh
```

This script uses the configuration in `config.json` which already contains your Google Sheet ID.

### Manual Usage

You can also run the Python script directly:

```bash
# Using full Google Sheets URL
./generate_localizations.py --sheet-id "https://docs.google.com/spreadsheets/d/1XS4kIJdJUmzHwE59PG68iIvBiKh6ksEXhMXfKn-AfvA/edit"

# Using just the Sheet ID
./generate_localizations.py --sheet-id 1XS4kIJdJUmzHwE59PG68iIvBiKh6ksEXhMXfKn-AfvA

# Specify a specific worksheet
./generate_localizations.py --sheet-id 1XS4kIJdJUmzHwE59PG68iIvBiKh6ksEXhMXfKn-AfvA --worksheet "Localizations"

# Use custom credentials file
./generate_localizations.py --sheet-id YOUR_SHEET_ID --credentials /path/to/credentials.json
```

### Configuration

Edit `config.json` to change the default settings:

```json
{
  "sheet_id": "1XS4kIJdJUmzHwE59PG68iIvBiKh6ksEXhMXfKn-AfvA",
  "worksheet_name": null,
  "credentials_file": "google-sheet-api.json"
}
```

- **sheet_id**: Your Google Sheets document ID
- **worksheet_name**: Specific worksheet name (null = use first sheet)
- **credentials_file**: Name of your credentials JSON file

### What It Does

1. Authenticates with Google Sheets API using service account credentials
2. Fetches all data from the specified worksheet
3. Parses the data into language-specific key-value pairs
4. Backs up existing `Localizable.strings` files (creates `.backup` files)
5. Generates new `Localizable.strings` files in:
   - `DoseMate/Resources/Localizations/en.lproj/Localizable.strings`
   - `DoseMate/Resources/Localizations/ko.lproj/Localizable.strings`
   - `DoseMate/Resources/Localizations/ja.lproj/Localizable.strings`
   - `DoseMate/Resources/Localizations/zh-Hans.lproj/Localizable.strings`
   - `DoseMate/Resources/Localizations/id.lproj/Localizable.strings`

### Supported Languages

The script currently supports:
- `en` → en.lproj (English)
- `ko` → ko.lproj (Korean)
- `ja` → ja.lproj (Japanese)
- `zh-Hans` → zh-Hans.lproj (Simplified Chinese)
- `id` → id.lproj (Indonesian)

To add more languages, update the `LANGUAGE_MAPPING` dictionary in the script.

### Troubleshooting

**Error: Credentials file not found**
- Ensure `google-sheet-api.json` exists in the `scripts` directory
- Check the file path and permissions

**Error: Failed to fetch data**
- Verify the Sheet ID is correct
- Ensure the service account email has access to the Google Sheet
- Check that the worksheet name is correct (if specified)

**Error: Required packages not installed**
- Run: `pip install gspread google-auth google-auth-oauthlib google-auth-httplib2`

### Security Note

⚠️ **Important:** The `google-sheet-api.json` file contains sensitive credentials and is already added to `.gitignore`. Never commit this file to version control.

### File Structure

```
scripts/
├── README.md                      # This file
├── config.json                    # Configuration file with Sheet ID
├── update_localizations.sh        # Quick update script
├── generate_localizations.py      # Main Python script
├── google-sheet-api.json          # Google API credentials (gitignored)
└── swiftgen.sh                    # SwiftGen script
```

### Workflow

1. **Edit localizations** in Google Sheets:
   https://docs.google.com/spreadsheets/d/1XS4kIJdJUmzHwE59PG68iIvBiKh6ksEXhMXfKn-AfvA/edit

2. **Run the update script**:
   ```bash
   cd scripts
   ./update_localizations.sh
   ```

3. **Commit the changes**:
   ```bash
   git add DoseMate/Resources/Localizations/
   git commit -m "update: localization strings"
   ```
