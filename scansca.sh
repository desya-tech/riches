#!/bin/bash

# =========================
# Config
# =========================
APP_ID="riches_test"
IQ_URL="https://sonatype.kikoichi.dev/"
AUTH="lLUNFJfN:eh7FRouBEjNgY5DnhkQGCG5Kg9PwwgosBcYkkMRdAYhp"
TARGET_FILE="/opt/integration/sca/requirements.txt"
CLI_JAR="/opt/integration/sca/nexus-cli.jar"

CRITICAL_THRESHOLD=10

# =========================
# Temp directory (IMPORTANT)
# =========================
TMP_DIR="/opt/integration/sca/tmp"

mkdir -p "$TMP_DIR"
chmod 777 "$TMP_DIR"

echo "Using TMP_DIR=$TMP_DIR"

# =========================
# Run Scan
# =========================
echo "Starting SCA Scan..."

SCAN_OUTPUT=$(java -Djava.io.tmpdir="$TMP_DIR" -jar "$CLI_JAR" \
    -i "$APP_ID" \
    -s "$IQ_URL" \
    -a "$AUTH" \
    "$TARGET_FILE" 2>&1)

echo "$SCAN_OUTPUT"

# =========================
# Extract Metrics
# =========================
AFFECTED_LINE=$(echo "$SCAN_OUTPUT" | grep "Number of components affected")

CRITICAL=$(echo "$AFFECTED_LINE" | grep -oP '\d+(?= critical)')
SEVERE=$(echo "$AFFECTED_LINE" | grep -oP '\d+(?= severe)')
MODERATE=$(echo "$AFFECTED_LINE" | grep -oP '\d+(?= moderate)')

CRITICAL=${CRITICAL:-0}
SEVERE=${SEVERE:-0}
MODERATE=${MODERATE:-0}

echo "-----------------------------------"
echo "Scan Summary:"
echo "Critical : $CRITICAL"
echo "Severe   : $SEVERE"
echo "Moderate : $MODERATE"
echo "-----------------------------------"

# =========================
# Threshold Check
# =========================
if [ "$CRITICAL" -gt "$CRITICAL_THRESHOLD" ]; then
    echo "Scan FAILED — Critical findings above threshold ($CRITICAL > $CRITICAL_THRESHOLD)"
    exit 1
else
    echo "Scan PASSED — Within acceptable threshold"
    exit 0
fi
