#!/bin/bash

# This script updates the clock and collects usage Data of 
# Samsung SCX , possibly also other models of the SCX-5x30 Series
# So this compensates the lack of NTP client functionality of this device.
#
# This script relies problably on the following firmware versions on the device:
## Main Firmware Version: OS 1.01.05.06 08-08-2007
## Network Firmware Version: V4.03.02(SCX-5x30) 07-04-2007
## Engine Firmware Version: 1.00.43
## PCL5E Firmware Version: PCL5e 5.60 06-27-2007	
## PCLXL Firmware Version: PCL6 5.47 05-21-2007	
## PS3 Firmware Version: PS3 V1.62.16 06-12-2007	
## SPL Firmware Version: SPL 5.24 03-27-2006	
## PDF Firmware Version: PDF V1.00.32 02-25-2006
#
# Example for invocation via /etc/crontab
#  */5   *     * * *  root   /opt/mfcupdate.sh
#
# (c) Cornelis Denhart 2016, Licensed as GNU GPLv3
# Visit https://github.com/CornelisDenhart/SamsungMFCTool for updates and more information 

# IP Address (or hostname) of Samsung MFC device
MFCIP=192.168.24.52

# Set to "1" if a CSV file should be written, indicating if the device is responding or not
writeUptimeLog=1

# Set to "1" if a CSV file should be written, containing usage counter data
writeUsageDataLog=1

# Locations of logfiles
uptimelLogFile="/opt/mfcUpLog.txt"
dataLogFile="/opt/mfcData.txt"

# CSV field separator; either Tab \t or ; are suggested
CSVSeparator="\t"
CSVSeparator=";"

#------------------------------------------------------------------------------------------

dateURL="http://$MFCIP/SaveChanges.cgi"
counterURL="http://$MFCIP/Information/billing_counters.htm"
tonerURL="http://$MFCIP/Information/supplies_status.htm"

headerData="Content-Type: application/x-www-form-urlencoded"
cookieData="FALSE=TRUE; xuser=webclient; SelectedTab=2; InfoMenu=1; InfoSubMenu=0; SelectedMenu=1; SelectedSubMenu=0; SettingsMenu=1; SettingsSubMenu=0"
currentDate=$(date "+%Y-%m-%d")
currentHr=$(date "+%H")
currentMin=$(date "+%M")
currentStamp=$(date "+%Y-%m-%d %H:%M:%S")
postData="GSI_CLOCK_MODE=2&GSI_DATE_TIME=$currentDate+$currentHr%3A$currentMin&"
successIdentificator="Your Selections have been modified successfully"

result=$(curl --cookie "$cookieData" --header "$headerData" --data $postData $dateURL 2>&1 | grep -c "$successIdentificator")
if [ "$writeUptimeLog" = "1" ]; then
	if [ ! -f $uptimelLogFile ]; then
		echo -e "Date/Time""$CSVSeparator""Up=1 / Down=0" >> $uptimelLogFile
	fi
	echo -e $currentStamp"$CSVSeparator"$result >> $uptimelLogFile
fi

if [ "$writeUsageDataLog" = "1" ]; then
	if [ ! -f $dataLogFile ]; then
		echo -e "Date/Time""$CSVSeparator""PwrOnCnt""$CSVSeparator""TonerLevel""$CSVSeparator""TotalPgCnt""$CSVSeparator""TonerPgCnt""$CSVSeparator""ADFScanPgCnt""$CSVSeparator""FlatScanPgCnt" >> $dataLogFile
	fi
	tonerLevelIdentificator="&nbsp;%"
	TotalPgCntIdentificator="Total Page Count"
	PwrOnCntIdentificator="Power On Page Count"
	TonerPgCntIdentificator="Toner Page Count"
	ADFScanPgCntIdentificator="ADF Scan Page Count"
	FlatScanPgCntIdentificator="Platen Scan Page Count"

	if [ "$result" -gt "0" ]; then
		resultTonerLevel=$(curl $tonerURL 2>&1 | grep -m 1 "$tonerLevelIdentificator" | cut -f 5 | cut -d ' ' -f 5 | cut -d '&' -f 1)
		dataCounters=$(curl $counterURL 2>&1 )

		resultTotalPgCnt=$(echo "$dataCounters" | grep -m 1 -A 3 "$TotalPgCntIdentificator" | cut -d$'\n' -f 4 | cut -f 8 | cut -d ' ' -f 1)
		resultPwrOnCnt=$(echo "$dataCounters" | grep -m 1 -A 3 "$PwrOnCntIdentificator" | cut -d$'\n' -f 4 | cut -f 8 | cut -d ' ' -f 1)
		resultTonerPgCnt=$(echo "$dataCounters" | grep -m 1 -A 3 "$TonerPgCntIdentificator" | cut -d$'\n' -f 4 | cut -f 9 | cut -d ' ' -f 1)
		resultADFScanPgCnt=$(echo "$dataCounters" | grep -m 1 -A 1 "$ADFScanPgCntIdentificator" | cut -d$'\n' -f 2 | cut -d ' ' -f 3 | cut -d '>' -f 2)
		resultFlatScanPgCnt=$(echo "$dataCounters" | grep -m 1 -A 3 "$FlatScanPgCntIdentificator" | cut -d$'\n' -f 4 | cut -f 6 | cut -d ' ' -f 1)

		echo -e $currentStamp"$CSVSeparator"$resultPwrOnCnt"$CSVSeparator"$resultTonerLevel"$CSVSeparator"$resultTotalPgCnt"$CSVSeparator"$resultTonerPgCnt"$CSVSeparator"$resultADFScanPgCnt"$CSVSeparator"$resultFlatScanPgCnt >> $dataLogFile
	fi
fi
