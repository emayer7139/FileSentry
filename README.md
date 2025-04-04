# FileSentry - File Integrity Monitoring Tool

FileSentry is a lightweight Bash-based tool designed to monitor the integrity of critical system files by comparing their current cryptographic hashes against a previously generated baseline. It helps you detect unauthorized modifications, new files, or deletions in monitored directories and can alert you via email if any discrepancies are found.

---

## Features

- **Baseline Generation:**  
  Generate an initial SHA‑256 hash database for all files in specified directories.
  
- **Integrity Monitoring:**  
  Recursively scans monitored directories and compares current file hashes against the baseline.
  
- **Alerting & Logging:**  
  Logs all scan results and discrepancies. Sends email alerts when changes are detected.
  
- **Automation Ready:**  
  Easily schedule periodic scans using systemd timers or cron.
  
- **Configurable:**  
  Customize which directories to monitor and the email address for alerts via a simple `config.ini` file.

---

## Project Structure

FileSentry/ ├── filesentry.sh # Main script for baseline generation and integrity checking ├── notify.sh # Script to send email alerts via msmtp ├── config.ini # Configuration for monitored directories, email, log file, and baseline file paths ├── baseline.db # Baseline file containing file hashes (auto-created with --init) ├── filesentry.log # Log file for recording scan results and alerts ├── filesentry.service # systemd service unit for automated runs ├── filesentry.timer # systemd timer unit to schedule periodic scans └── README.md # This documentation file

yaml
Copy

---

## Requirements

- **Operating System:** Linux (e.g., Kali, Ubuntu, Debian)
- **Dependencies:**
  - Bash
  - `find`, `sha256sum`
  - `msmtp` (with a correctly configured `~/.msmtprc`)
- **Privileges:**  
  Some directories (like `/etc` or `/var/log`) may require root privileges to read. Run the script with appropriate permissions or use sudo for specific commands as needed.

---

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/FileSentry.git
   cd FileSentry
Install Dependencies (Debian-based systems):

bash
Copy
sudo apt update
sudo apt install msmtp msmtp-mta -y
Configure msmtp:

Create a file named ~/.msmtprc with your SMTP settings. For example, for Gmail:

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
Then secure the configuration:

bash
Copy
chmod 600 ~/.msmtprc
Configure FileSentry:

Edit config.ini to customize your settings. For example:

ini
Copy
# === FileSentry Config ===
MONITOR_DIRS="/etc /var/log"
ALERT_EMAIL="your.email@example.com"
LOG_FILE="./filesentry.log"
BASELINE="baseline.db"
Make the Scripts Executable:

bash
Copy
chmod +x filesentry.sh notify.sh
Usage
Baseline Generation
Before running integrity checks, generate an initial baseline of file hashes. This will scan all directories specified in MONITOR_DIRS and create (or overwrite) the baseline.db file:

bash
Copy
./filesentry.sh --init
Integrity Check
Run the script to perform an integrity check against the baseline:

bash
Copy
./filesentry.sh
If discrepancies are found (new, modified, or deleted files), alerts will be logged in filesentry.log and an email will be sent to the address specified in ALERT_EMAIL.

Note: FileSentry monitors all regular files in the specified directories. Some files (especially log files in /var/log) are dynamic and may trigger frequent alerts. You may want to adjust MONITOR_DIRS if certain directories generate too many false positives.

Automation with systemd
To run FileSentry automatically (e.g., every 30 minutes), use systemd timers:

Copy Unit Files to the System Directory

The project includes filesentry.service and filesentry.timer. Copy these files to /etc/systemd/system/:

bash
Copy
sudo cp filesentry.service /etc/systemd/system/
sudo cp filesentry.timer /etc/systemd/system/
Reload the Systemd Daemon

bash
Copy
sudo systemctl daemon-reload
Enable and Start the Timer

bash
Copy
sudo systemctl enable --now filesentry.timer
Verify the Timer

Check that the timer is active:

bash
Copy
systemctl list-timers | grep filesentry
msmtp Environment Configuration and Workaround
When FileSentry is run as a systemd service or timer, it may not inherit the full user environment (especially the HOME variable). Without this, msmtp might not locate your ~/.msmtprc file, resulting in errors like:

pgsql
Copy
/home/yourusername/.msmtprc: line 11: user: command not found
Solution:
Ensure that the HOME environment variable is set in your service unit. In filesentry.service, include:

ini
Copy
Environment=HOME=/home/yourusername
Replace /home/yourusername with your actual home directory. This setting ensures that when FileSentry runs automatically, msmtp correctly loads your SMTP configuration from ~/.msmtprc.

Troubleshooting
No Email Alerts?

Verify your SMTP configuration in ~/.msmtprc.

Check the msmtp log at ~/.msmtprc or ~/.msmtp.log for error messages.

Ensure that FileSentry detects discrepancies to trigger the alert.

Frequent Alerts from Log Files:
Files in /var/log often change. Consider excluding these directories from MONITOR_DIRS if false positives are a concern.

Temporary Files:
FileSentry creates temporary files (scan_result.tmp, parsed_scan.txt, unknown_devices.tmp) during execution. These files are automatically removed at the end of the run.

