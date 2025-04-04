#!/bin/bash
#
# notify.sh - Sends an email alert using msmtp.
#
# Usage: ./notify.sh "Subject" "Body message"
#

SUBJECT="$1"
BODY="$2"
EMAIL=$(grep ALERT_EMAIL config.ini | cut -d '=' -f2 | tr -d '"')

echo -e "$BODY" | msmtp "$EMAIL"
echo "[DEBUG] Alert sent with subject: $SUBJECT" >> filesentry.log
