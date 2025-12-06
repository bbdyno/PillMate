#!/bin/bash

# Update iOS Localizations from Google Sheets
# This script reads configuration from config.json and runs the Python generator

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=================================="
echo "Update DoseMate Localizations"
echo "=================================="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    echo "Please install Python 3 to continue"
    exit 1
fi

# Check if required packages are installed
echo "Checking Python dependencies..."
python3 -c "import gspread; import google.oauth2.service_account" 2>/dev/null || {
    echo ""
    echo "Error: Required Python packages not installed"
    echo "Please run: pip install gspread google-auth google-auth-oauthlib google-auth-httplib2"
    exit 1
}

# Check if credentials file exists
if [ ! -f "google-sheet-api.json" ]; then
    echo ""
    echo "Error: google-sheet-api.json not found"
    echo "Please place your Google Service Account credentials in the scripts directory"
    exit 1
fi

# Check if config file exists
if [ ! -f "config.json" ]; then
    echo ""
    echo "Error: config.json not found"
    exit 1
fi

# Read configuration
SHEET_ID=$(python3 -c "import json; print(json.load(open('config.json'))['sheet_id'])")
WORKSHEET=$(python3 -c "import json; w=json.load(open('config.json')).get('worksheet_name'); print(w if w else '')")

echo "✓ Dependencies OK"
echo "✓ Credentials found"
echo "✓ Configuration loaded"
echo ""

# Build command
CMD="python3 generate_localizations.py --sheet-id $SHEET_ID"

if [ ! -z "$WORKSHEET" ]; then
    CMD="$CMD --worksheet \"$WORKSHEET\""
fi

# Run the generator
echo "Running localization generator..."
echo ""
eval $CMD

echo ""
echo "=================================="
echo "Update Complete!"
echo "=================================="
