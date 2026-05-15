#!/bin/bash

# =========================================================
# 1. Hardcoded URL
# =========================================================
BASE_URL="https://ftp.mozilla.org/pub/thunderbird/candidates/"

# Ensure the base URL always ends with a trailing slash
BASE_URL="${BASE_URL%/}/"

# The prefix is the first argument
PREFIX="$1" 

# ---------------------------------------------------------
# Step 1: Find the latest candidate directory
# ---------------------------------------------------------
echo "Searching for the latest candidate directory in $BASE_URL..."

LATEST_CANDIDATE=$(curl -s "$BASE_URL" | \
  grep -oE "href=\"[^\"]*${PREFIX}[^\"]+-candidates/\"" | \
  sed -E 's/href="([^"]+)"/\1/' | \
  awk -F'/' '{print $(NF-1)"/"}' | \
  sort -V | \
  tail -n 1)

if [ -z "$LATEST_CANDIDATE" ]; then
  echo "Error: No matching candidate directories found."
  exit 1
fi

echo "-> Found latest candidate: $LATEST_CANDIDATE"
CANDIDATE_URL="${BASE_URL}${LATEST_CANDIDATE}"

# ---------------------------------------------------------
# Step 2: Find the latest build directory inside the candidate
# ---------------------------------------------------------
echo "Searching for the latest build in $CANDIDATE_URL..."

LATEST_BUILD=$(curl -s "$CANDIDATE_URL" | \
  grep -oE "href=\"[^\"]*build[0-9]+/?\"" | \
  sed -E 's/href="([^"]+)"/\1/' | \
  awk -F'/' '{print $(NF-1)"/"}' | \
  sort -V | \
  tail -n 1)

if [ -z "$LATEST_BUILD" ]; then
  echo "Error: No build directories found inside $CANDIDATE_URL"
  exit 1
fi

echo "-> Found latest build: $LATEST_BUILD"

# ---------------------------------------------------------
# Step 3: Find the .dmg file in mac/en-US/
# ---------------------------------------------------------
MAC_DIR_URL="${CANDIDATE_URL}${LATEST_BUILD}mac/en-US/"

echo "Searching for the .dmg file in $MAC_DIR_URL..."

DMG_FILE=$(curl -s "$MAC_DIR_URL" | \
  grep -oE "href=\"[^\"]+\.dmg\"" | \
  sed -E 's/href="([^"]+)"/\1/' | \
  awk -F'/' '{print $NF}' | \
  head -n 1)

if [ -z "$DMG_FILE" ]; then
  echo "Error: No .dmg file found in $MAC_DIR_URL"
  exit 1
fi

ENCODED_DMG_FILE=$(echo "$DMG_FILE" | sed 's/ /%20/g')

DOWNLOAD_URL="${MAC_DIR_URL}${ENCODED_DMG_FILE}"
echo "---------------------------------------------------------"
echo "File ready to download: $DMG_FILE"
echo "From: $DOWNLOAD_URL"
echo "---------------------------------------------------------"

# ---------------------------------------------------------
# Step 4: Ask for confirmation
# ---------------------------------------------------------
read -p "Do you want to proceed with the download? (y/n) " -n 1 -r
echo    # Move to a new line after user input

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Starting download..."
    # Changed from -O to -o "$DMG_FILE" to save it cleanly with the spaces locally
    curl -o "$DMG_FILE" "$DOWNLOAD_URL"
    echo "Download complete! Saved to your current directory."
else
    echo "Download cancelled by user."
    exit 0
fi
