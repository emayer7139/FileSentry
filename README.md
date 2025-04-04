# FileSentry - File Integrity Monitoring Tool

FileSentry is a lightweight Bash tool that monitors the integrity of critical system files by comparing their current SHA‑256 hashes with a previously generated baseline. It helps you detect unauthorized modifications, new files, or deletions in your monitored directories and can alert you via email when discrepancies are found.

---

## Features

- **Baseline Generation:**  
  Create an initial hash database for all files in specified directories.
  
- **Integrity Monitoring:**  
  Recursively scans monitored directories and compares current file hashes against the baseline.
  
- **Alerting & Logging:**  
  Logs scan results and sends email alerts when changes are detected.
  
- **Automation Ready:**  
  Easily schedule periodic scans using systemd timers (or cron).

---

## Requirements

- **OS:** Linux (e.g., Kali, Ubuntu, Debian)
- **Dependencies:**
  - Bash, find, sha256sum
  - msmtp (with your SMTP settings configured in `~/.msmtprc`)
- **Privileges:**  
  Some monitored directories may require root privileges. FileSentry uses `sudo` for commands like `arp-scan` and `nmap` when necessary.

---

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/FileSentry.git
   cd FileSentry
2. Configure msmtp:

Create ~/.msmtprc with your SMTP settings. For example (for Gmail):

ini
Copy
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your.email@gmail.com
user           your.email@gmail.com
password       your_app_password_here

account default : gmail
Secure the file:

    chmod 600 ~/.msmtprc

3. Edit config.ini as needed.

Usage
- Generate Baseline
  Create an initial baseline of file hashes (this scans all files in the directories specified in MONITOR_DIRS):


      ./filesentry.sh --init
  This will generate (or overwrite) the baseline.db file.

- Run Integrity Check
  To check for unauthorized changes:

      ./filesentry.sh
  If changes are detected (new, modified, or deleted files), FileSentry logs the details in filesentry.log and sends an email alert.

- Automation with systemd
  To run FileSentry automatically (e.g., every 30 minutes), follow these steps:

  Copy the Unit Files:

      sudo cp filesentry.service /etc/systemd/system/
      sudo cp filesentry.timer /etc/systemd/system/

  Reload systemd:

      sudo systemctl daemon-reload
  Enable and Start the Timer:

      sudo systemctl enable --now filesentry.timer

  Verify the Timer:

      systemctl list-timers | grep filesentry
  Note: Ensure your filesentry.service sets the correct HOME environment variable so that msmtp can locate your ~/.msmtprc. For example, the service file should include:
  
      Environment=HOME=/home/yourusername

## Troubleshooting
- Email Alerts Not Sending:
  Check your ~/.msmtp.log for errors and verify your ~/.msmtprc configuration.

- Frequent Alerts:
  If dynamic files (e.g., log files) trigger too many alerts, consider refining MONITOR_DIRS to exclude them.

- Temporary Files:
  The script creates temporary files (scan_result.tmp, parsed_scan.txt, etc.) during execution, which are automatically cleaned up at the end.

