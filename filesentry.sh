#!/bin/bash
#
# FileSentry - A simple file integrity monitoring tool.
#
# Usage:
#   To generate an initial baseline of file hashes:
#       ./filesentry.sh --init
#
#   To run an integrity check (compare current state vs. baseline):
#       ./filesentry.sh
#

# Load configuration
source ./config.ini

# Check for help/usage flags
if [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [--init]"
    echo "  --init   Generate baseline of file hashes for monitored directories"
    exit 0
fi

# Create log file if it doesn't exist
touch "$LOG_FILE"

# If --init is specified, generate the baseline
if [[ "$1" == "--init" ]]; then
    echo "[*] Generating baseline at $(date)" | tee -a "$LOG_FILE"
    > "$BASELINE"  # Clear baseline file
    for DIR in $MONITOR_DIRS; do
        # Find all regular files in the directory (suppress permission errors)
        find "$DIR" -type f 2>/dev/null | while read -r file; do
            if [[ -r "$file" ]]; then
                hash=$(sha256sum "$file" | awk '{print $1}')
                echo "$file $hash" >> "$BASELINE"
            fi
        done
    done
    echo "[*] Baseline generated in $BASELINE" | tee -a "$LOG_FILE"
    exit 0
fi

# === Monitoring Mode ===
echo "[*] Running FileSentry integrity check at $(date)" | tee -a "$LOG_FILE"

# Temporary file for current hashes
TEMP_HASHES=$(mktemp)

# Build current hash list from monitored directories
for DIR in $MONITOR_DIRS; do
    find "$DIR" -type f 2>/dev/null | while read -r file; do
        if [[ -r "$file" ]]; then
            hash=$(sha256sum "$file" | awk '{print $1}')
            echo "$file $hash" >> "$TEMP_HASHES"
        fi
    done
done

echo "[*] Comparing current file hashes with baseline..." | tee -a "$LOG_FILE"

# Load baseline into an associative array
declare -A baseline_hashes
while read -r file basehash; do
    baseline_hashes["$file"]="$basehash"
done < "$BASELINE"

DIFF_FOUND=0

# Check for new or modified files
while read -r file currhash; do
    basehash="${baseline_hashes["$file"]}"
    if [[ -z "$basehash" ]]; then
        echo "[ALERT] New file detected: $file" | tee -a "$LOG_FILE"
        DIFF_FOUND=1
    elif [[ "$currhash" != "$basehash" ]]; then
        echo "[ALERT] File modified: $file" | tee -a "$LOG_FILE"
        DIFF_FOUND=1
    fi
done < "$TEMP_HASHES"

# Check for deleted files
while read -r file basehash; do
    if ! grep -q "^$file " "$TEMP_HASHES"; then
        echo "[ALERT] File deleted: $file" | tee -a "$LOG_FILE"
        DIFF_FOUND=1
    fi
done < "$BASELINE"

# Remove the temporary file
rm "$TEMP_HASHES"

if [[ "$DIFF_FOUND" -eq 1 ]]; then
    ALERT_MSG="FileSentry Alert: Integrity issues detected at $(date).\nCheck the log at: $LOG_FILE"
    echo -e "$ALERT_MSG" | tee -a "$LOG_FILE"
    # Send an email alert
    ./notify.sh "FileSentry Alert" "$ALERT_MSG"
else
    echo "[*] No differences detected. System integrity intact." | tee -a "$LOG_FILE"
fi
