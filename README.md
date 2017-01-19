# SamsungMFCTool
Real Time Clock (RTC / pseudo NTP) Update and usage data collection for Samsung SCX-5x30 MFC Series, i. e. SCX-5530FN.

As this device can send and receive fax and can put pdf files on a SMB server or USB stick, a correct time is really useful. When powering the device down, the clock does not run on and eventually gets lost. Usage data collection is an additional benefit to predict toner lowage.

Designed to run on Linux i. e. Raspbian. Requires curl. Tested with Raspbian GNU/Linux 8.0 (jessie).

Example for invocation via /etc/crontab: `*/15   *     * * *  root   /opt/mfcupdate.sh`
