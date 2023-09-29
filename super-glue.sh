#!/bin/sh
# The next line disables specific ShellCheck codes for the entire script.
# https://github.com/koalaman/shellcheck
# shellcheck disable=SC2001,SC2009,SC2207,SC2024

# Super-Glue by John Lockwood
# https://github.com/jelockwood/Super-Glue
#
# This script is based on -
# S.U.P.E.R.M.A.N.
# Software Update/Upgrade Policy Enforcement (with) Recursive Messaging And Notification
# https://github.com/Macjutsu/super
# by Kevin M. White
# 
# This is modified version that installs the full copy of Super and adds support for LAPS based admin authentication
# It strips out a lot of the original code but retains enough to do the same parameter processing and adds support for 
# for reading extension attributes containing the local admin credentials. These are then passed directly to the real
# Super script
#
# This script as provided is intended for use with the LAPS solution written by Perry Driscol
# https://github.com/PezzaD84/macOSLAPS
#
# It should however be easily adaptable either to using an identical but encrypted local admin password or
# an alternative LAPS solution
# 
# Due to needing to use some command paramters for its own functionality this reduces the number of command parameters
# that can be passed to the actual Super script. I have worked to keep this overhead a low as possible and I believe only
# two extra parameters are required for this script

#superVERSION="4.0"
#superDATE="2023/10/01"

# MARK: *** Documentation ***
################################################################################

# Show usage documentation. 
showUsage() {
echo "
  super-glue
  Script for adding LAPS capability to Super
  
  Version $superVERSION
  $superDATE
  https://github.com/jelockwood/Super-Glue
  
  Usage:
  sudo ./super-glue
  
  Deferment Timer Options:
  [--default-defer=seconds] [--focus-defer=seconds]
  [--menu-defer=seconds,seconds,etc...] [--error-defer=seconds]
  [--recheck-defer=seconds] [--delete-deferrals]
  
  Deferment Count Deadline Options:
  [--focus-count=number] [--soft-count=number] [--hard-count=number]
  [--restart-counts] [--delete-counts]
  
  Deferment Days Deadline Options:
  [--focus-days=number] [--soft-days=number] [--hard-days=number]
  [--zero-day=YYYY-MM-DD:hh:mm] [--restart-days] [--delete-days]
  
  Deferment Date Deadline Options:
  [--focus-date=YYYY-MM-DD:hh:mm] [--soft-date=YYYY-MM-DD:hh:mm]
  [--hard-date=YYYY-MM-DD:hh:mm] [--delete-dates]
  
  User Interface Options:
  [--defer-dialog-timeout=seconds] [--soft-dialog-timeout=seconds]
  [--display-redraw=seconds] [--display-icon=/local/path or URL]
  [--icon-size-ibm=pixels] [--icon-size-jamf=pixels ]
  [--display-accessory-type=TEXTBOX|HTMLBOX|HTML|IMAGE|VIDEO|VIDEOAUTO]
  [--display-accessory-default=/local/path or URL]
  [--display-accessory-update=/local/path or URL]
  [--display-accessory-upgrade=/local/path or URL]
  [--display-accessory-user-auth=/local/path or URL]
  [--help-button=plain text or URL] [--warning-button=plain text or URL]
  [--display-silently] [--display-silently-off]
  [--prefer-jamf-helper] [--prefer-jamf-helper-off]
  
  Apple Silicon Credential Options:
  [--local-account=AccountName] [--local-password=Password]
  [--admin-account=AccountName] [--admin-password=lapssecret-name or --admin-password=Password]
  [--admin-crypt-key=lapscryptkey-name or --admin-crypt-key=Key]
  [--super-account=AccountName] [--super-password=Password]
  [--jamf-account=AccountName] [--jamf-password=Password]
  [--lapsapicredentials=encryptedcredentials]
  [--delete-accounts] [--user-auth-timeout=seconds]
  [--user-auth-mdm-failover=ALWAYS,NOSERVICE,SOFT,HARD,INSTALLNOW,BOOTSTRAP]
  
  Update, Upgrade, and Restart Options:
  [--allow-upgrade] [--allow-upgrade-off] [--target-upgrade=version]
  [--allow-rsr-updates] [--allow-rsr-updates-off]
  [--enforce-non-system-updates] [--enforce-non-system-updates-off]
  [--only-download] [--only-download-off]
  [--install-now] [--install-now-off]
  [--policy-triggers=PolicyTrigger,PolicyTrigger,etc...]
  [--skip-updates] [--skip-updates-off]
  [--restart-without-updates] [--restart-without-updates-off]
  
  macOS Update/Upgrade Validation Options:
  [--free-space-update=gigabytes] [--free-space-upgrade=gigabytes]
  [--free-space-timeout=seconds] [--battery-level=percentage]
  [--battery-timeout=seconds]
  
  Testing, Validation, and Documentation:
  [--test-mode] [--test-mode-off] [--test-mode-timeout=seconds]
  [--verbose-mode] [--verbose-mode-off] [--open-logs] [--reset-super]
  [--usage] [--help]
  
  * Managed preferences override local options via domain: com.macjutsu.super
  <key>DefaultDefer</key> <string>seconds</string>
  <key>FocusDefer</key> <string>seconds</string>
  <key>MenuDefer</key> <string>seconds,seconds,etc...</string>
  <key>RecheckDefer</key> <string>seconds</string>
  <key>ErrorDefer</key> <string>seconds</string>
  <key>FocusCount</key> <string>number</string>
  <key>SoftCount</key> <string>number</string>
  <key>HardCount</key> <string>number</string>
  <key>FocusDays</key> <string>number</string>
  <key>SoftDays</key> <string>number</string>
  <key>HardDays</key> <string>number</string>
  <key>ZeroDay</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>FocusDate</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>SoftDate</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>HardDate</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>DeferDialogTimeout</key> <string>seconds</string>
  <key>SoftDialogTimeout</key> <string>seconds</string>
  <key>DisplayRedraw</key> <string>seconds</string>
  <key>DisplayIcon</key> <string>path</string>
  <key>IconSizeIbm</key> <string>pixels</string>
  <key>IconSizeJamf</key> <string>pixels</string>
  <key>DisplayAccessoryType</key>
  <string>TEXTBOX|HTMLBOX|HTML|IMAGE|VIDEO|VIDEOAUTO</string>
  <key>DisplayAccessoryDefault</key> <string>path or URL</string>
  <key>DisplayAccessoryUpdate</key> <string>path or URL</string>
  <key>DisplayAccessoryUpgrade</key> <string>path or URL</string>
  <key>DisplayAccessoryUserAuth</key> <string>path or URL</string>
  <key>HelpButton</key> <string>plain text or URL</string>
  <key>WarningButton</key> <string>plain text or URL</string>
  <key>DisplaySilently</key> <true/> | <false/>
  <key>PreferJamfHelper</key> <true/> | <false/>
  <key>UserAuthTimeout</key> <string>seconds</string>
  <key>UserAuthMDMFailover</key>
  <string>ALWAYS,NOSERVICE,SOFT,HARD,INSTALLNOW,BOOTSTRAP</string>
  <key>AllowUpgrade</key> <true/> | <false/>
  <key>TargetUpgrade</key> <string>version</string>
  <key>AllowRSRUpdates</key> <true/> | <false/>
  <key>EnforceNonSystemUpdates</key> <true/> | <false/>
  <key>OnlyDownload</key> <true/> | <false/>
  <key>InstallNow</key> <true/> | <false/>
  <key>PolicyTriggers</key> <string>PolicyTrigger,PolicyTrigger,etc...</string>
  <key>SkipUpdates</key> <true/> | <false/>
  <key>RestartWithoutUpdates</key> <true/> | <false/>
  <key>FreeSpaceUpdate</key> <string>gigabytes</string>
  <key>FreeSpaceUpgrade</key> <string>gigabytes</string>
  <key>FreeSpaceTimeout</key> <string>seconds</string>
  <key>BatteryLevel</key> <string>percentage</string>
  <key>BatteryTimeout</key> <string>seconds</string>
  <key>TestMode</key> <true/> | <false/>
  <key>TestModeTimeout</key> <string>seconds</string>
  <key>VerboseMode</key> <true/> | <false/>
  
  ** For detailed documentation visit: https://github.com/Macjutsu/super/wiki
  ** Or use --help to automatically open the S.U.P.E.R.M.A.N. Wiki.
"

# Error log any unrecognized options.
if [[ -n ${unrecognizedOptionsARRAY[*]} ]]; then
	sendToLog  "Error: Unrecognized Options: ${unrecognizedOptionsARRAY[*]}"; parameterERROR="TRUE"
	[[ "$jamfPARENT" == "TRUE" ]] && sendToLog  "Error: Note that each Jamf Pro Policy Parameter can only contain a single option."
	sendToStatus "Inactive Error: Unrecognized Options: ${unrecognizedOptionsARRAY[*]}"
fi
sendToLog "**** S.U.P.E.R.M.A.N. $superVERSION USAGE EXIT ****"
exit 0
}

# If there is a real current user then open the S.U.P.E.R.M.A.N. Wiki, otherwise run the showUsage() function.
showHelp() {
checkCurrentUser
if [[ "$currentUserNAME" != "FALSE" ]]; then
	sendToLog "Startup: Opening S.U.P.E.R.M.A.N. Wiki for user \"$currentUserNAME\"."
	sudo -u "$currentUserNAME" open "https://github.com/Macjutsu/super/wiki" &
else
	showUsage
fi
sendToLog "**** S.U.P.E.R.M.A.N. $superVERSION HELP EXIT ****"
exit 0
}

# MARK: *** Parameters ***
################################################################################

# Set default parameters that are used throughout the script.
setDefaults() {
# Installation folder:
superFOLDER="/Library/Management/super"

# Symbolic link in default path for super.
superLINK="/usr/local/bin/super"

# Path to a PID file:
# superPIDFILE="/var/run/super.pid"

# Path to a local property list file:
superPLIST="$superFOLDER/com.macjutsu.super" # No trailing ".plist"

# Path to a managed property list file:
superMANAGEDPLIST="/Library/Managed Preferences/com.macjutsu.super" # No trailing ".plist"

# Path to the log for the main super workflow:
superLOG="$superFOLDER/super.log"

# Path to the log for the current softwareupdate --list command result:
asuListLOG="$superFOLDER/asuList.log"

# Path to the log for the current erase-install.sh --list command result:
installerListLOG="$superFOLDER/installerList.log"

# Path to the log for all softwareupdate download/install workflows:
asuLOG="$superFOLDER/asu.log"

# Path to the log for all macOS installer application download/install workflows:
installerLOG="$superFOLDER/installer.log"

# Path to the log for filtered MDM client command progress:
mdmCommandLOG="$superFOLDER/mdmCommand.log"

# Path to the log for debug MDM client command progress:
mdmCommandDebugLOG="$superFOLDER/mdmCommandDebug.log"

# Path to the log for filtered MDM update/upgrade workflow progress:
mdmWorkflowLOG="$superFOLDER/mdmWorkflow.log"

# Path to the log for debug MDM update/upgrade workflow progress:
mdmWorkflowDebugLOG="$superFOLDER/mdmWorkflowDebug.log"

# Path to the "hidden" file that triggers a macOS update/upgrade restart validation workflow:
restartValidateFilePATH="$superFOLDER/.RestartValidate"

# This is the name for the LaunchDaemon.
launchDaemonNAME="com.macjutsu.super" # No trailing ".plist"

# Path to the jamf binary:
jamfBINARY="/usr/local/bin/jamf"

# Path to the jamfHELPER binary:
jamfHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# URL to the IBM Notifier.app download:
ibmNotifierURL="https://github.com/IBM/mac-ibm-notifications/releases/download/v-2.9.1-b-96/IBM.Notifier.zip"

# Target version for IBM Notifier.app:
ibmNotifierVERSION="2.9.1"

# Path to the local IBM Notifier.app:
ibmNotifierAPP="$superFOLDER/IBM Notifier.app"

# Path to the local IBM Notifier.app binary:
ibmNotifierBINARY="$ibmNotifierAPP/Contents/MacOS/IBM Notifier"

# URL to the erase-install package installer:
eraseInstallURL="https://github.com/grahampugh/erase-install/releases/download/v27.3/erase-install-27.3.pkg"

# Target version for erase-install.sh:
eraseInstallVERSION="27.3"

# Target checksum for erase-install.sh:
eraseInstallCHECKSUM="890f3ec8fe0e2efa7b33d407eee96358d8a44ca4"

# Path to the local erase-install folder:
eraseInstallFOLDER="/Library/Management/erase-install"
# IMPORTANT DETAIL: super does NOT move the default erase-install folder content to another custom location.
# Changing this folder path to anything besides "/Library/Management/erase-install" requires that you must also deploy the erase-install folder to the custom location prior to using super.

# Path to the local copy of erase-install.sh:
eraseInstallSCRIPT="$eraseInstallFOLDER/erase-install.sh"

# Path to the local copy of installinstallmacOS.py:
installInstallMacOS="$eraseInstallFOLDER/installinstallmacOS.py"

# Path to the local copy of movable Python.framework:
pythonFRAMEWORK="$eraseInstallFOLDER/Python.framework"

# Path to a local softwareupdate property list file:
asuPLIST="/Library/Preferences/com.apple.SoftwareUpdate" # No trailing ".plist"

# Path to for the local cached display icon:
cachedICON="$superFOLDER/icon.png"

# The default icon in the if no $displayIconOPTION is specified or found.
defaultICON="/System/Library/PrivateFrameworks/SoftwareUpdate.framework/Versions/A/Resources/SoftwareUpdate.icns"

# Default icon size for IBM Notifier.app.
ibmNotifierIconSIZE=96

# Default icon size for jamfHelper.
jamfHelperIconSIZE=96

# Deadline date display format.
dateFORMAT="+%B %d, %Y" # Formatting options can be found in the man page for the date command.

# Deadline time display format.
timeFORMAT="+%l:%M %p" # Formatting options can be found in the man page for the date command.

# The default number of seconds to defer if a user choses not to restart now.
defaultDeferSECONDS=3600

# The default number of seconds to defer if there is a workflow error.
errorDeferSECONDS=3600

# The default user authentication dialog timeout.
userAuthTimeoutSECONDS=3600

# The default minium free storage space in gigabytes required for a macOS update.
freeSpaceUpdateGB=15

# The default minium free storage space in gigabytes required for a macOS upgrade.
freeSpaceUpgradeGB=35

# The default macOS upgrade installer estimated size (macOS update sizes are automatically collected via softwareupdate).
macOSInstallerGB=13

# The number of seconds between storage checks when displaying the insufficient free space notification via the notifyStorage() function.
storageRecheckSECONDS=5

# The default insufficient available free space notification timeout.
freeSpaceTimeoutSECONDS=3600

# The default battery level percentage required for a macOS software update/upgrade.
batteryLevelPERCENT=50

# The number of seconds between AC power checks when displaying the insufficient battery notification via the notifyStorage() function.
powerRecheckSECONDS=1

# The default AC Power required for low battery notification timeout.
batteryTimeoutSECONDS=3600

# The number of seconds to timeout various workflow startup processes if no progress is reported.
initialStartTimeoutSECONDS=120

# The number of seconds to timeout the macOS 11+ softwareupdate download/prepare workflow if no progress is reported.
softwareUpdateTimeoutSECONDS=1200

# The number of seconds to timeout the macOS 10.x softwareupdate download/prepare workflow if no progress is reported.
softwareUpdateLegacyTimeoutSECONDS=3600

# The number of seconds to timeout the softwareupdate recommended (non-system) update workflow if no progress is reported.
softwareUpdateRecommendedTimeoutSECONDS=600

# The number of seconds to timeout the macOS installer download workflow if no progress is reported.
macOSInstallerDownloadTimeoutSECONDS=300

# The number of seconds to timeout the macOS installation workflow if no progress is reported.
macOSInstallerTimeoutSECONDS=600

# The number of seconds to timeout MDM commands if no response is reported.
mdmTimeoutSECONDS=300

# The number of seconds to timeout the MDM download/prepare workflow if no progress is reported.
mdmWorkflowTimeoutSECONDS=600

# The default amount of time in seconds to leave test notifications and dialogs open before moving on with the test mode workflow.
testModeTimeoutSECONDS=10

# These parameters identify the relevant system information.
macOSMAJOR=$(sw_vers -productVersion | cut -d'.' -f1) # Expected output: 10, 11, 12
macOSMINOR=$(sw_vers -productVersion | cut -d'.' -f2) # Expected output: 14, 15, 06, 01
macOSVERSION=${macOSMAJOR}$(printf "%02d" "$macOSMINOR") # Expected output: 1014, 1015, 1106, 1203
[[ "$macOSMAJOR" -ge 13 ]] && macOSEXTRA=$(sw_vers -productVersionExtra | cut -d'.' -f2) # Expected output: (a), (b), (c)
macOSBUILD=$(sw_vers -buildVersion) # Expected output: 22D68
macOSNAME="macOS $(awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | awk -F 'macOS ' '{print $NF}' | awk '{print substr($0, 0, length($0)-1)}')" # Expected output: macOS Ventura
macOSARCH=$(arch) # Expected output: i386, arm64
macModelID="$(system_profiler SPHardwareDataType | grep 'Model Identifier' | awk -F ': ' '{print $2}')" # Expected output: MacBookPro18,2
[[ $(echo "$macModelID" | grep -c 'Book') -gt 0 ]] && macBOOK="TRUE" # Expected output: TRUE
lastREBOOT="$(last reboot | head -1 | sed -e 's/reboot    ~                         //' | xargs)" # Expected output: Sat Feb 18 11:45
}

# Collect input options and set associated parameters.
getOptions() {
# If super is running via Jamf Policy installation then the first 3 input parameters are skipped.
if [[ $1 == "/" ]]; then
	shift 3
	jamfPARENT="TRUE"
fi

# getOptions debug mode.
# sendToLog "Debug Mode: Function ${FUNCNAME[0]}: @ is:\n$@"

# This is a standard while/case loop to collect all the input parameters.
commandPARAMS=""
while [[ -n $1 ]]; do
	case "$1" in
		--default-defer* )
			defaultDeferOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --default-defer=$defaultDeferOPTION"
		;;
		--focus-defer* )
			focusDeferOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --focus-defer=$focusDeferOPTION"
		;;
		--menu-defer* )
			menuDeferOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --menu-defer=$menuDeferOPTION"
		;;
		--recheck-defer* )
			recheckDeferOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --recheck-defer=$recheckDeferOPTION"
		;;
		--error-defer* )
			errorDeferOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --error-defer=$errorDeferOPTION"
		;;
		--delete-deferrals )
			deleteDEFFERALS="TRUE"
            commandPARAMS="$commandPARAMS --delete-deferrals=$deleteDEFFERALS"
		;;
		--focus-count* )
			focusCountOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --focus-count=$focusCountOPTION"
		;;
		--soft-count* )
			softCountOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --soft-count=$softCountOPTION"
		;;
		--hard-count* )
			hardCountOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --hard-count=$hardCountOPTION"
		;;
		--restart-counts )
			restartCOUNTS="TRUE"
            commandPARAMS="$commandPARAMS --restart-counts"
		;;
		--delete-counts )
			deleteCOUNTS="TRUE"
            commandPARAMS="$commandPARAMS --delete-counts"
		;;
		--focus-days* )
			focusDaysOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --focus-days=$focusDaysOPTION"
		;;
		--soft-days* )
			softDaysOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --soft-days=$softDaysOPTION"
		;;
		--hard-days* )
			hardDaysOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --hard-days=$hardDaysOPTION"
		;;
		--zero-day* )
			zeroDayOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --zero-day=$zeroDayOPTION"
		;;
		--restart-days )
			restartDAYS="TRUE"
            commandPARAMS="$commandPARAMS --restart-days"
		;;
		--delete-days )
			deleteDAYS="TRUE"
            commandPARAMS="$commandPARAMS --delete-days"
		;;
		--focus-date* )
			focusDateOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --focus-date=$focusDateOPTION"
		;;
		--soft-date* )
			softDateOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --soft-date=$softDateOPTION"
		;;
		--hard-date* )
			hardDateOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --hard-date=$hardDateOPTION"
		;;
		--delete-dates )
			deleteDATES="TRUE"
            commandPARAMS="$commandPARAMS --delete-dates"
		;;
		--defer-dialog-timeout* )
			deferDialogTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --defer-dialog-timeout=$deferDialogTimeoutOPTION"
		;;
		--soft-dialog-timeout* )
			softDialogTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --soft-dialog-timeout=$softDialogTimeoutOPTION"
		;;
		--display-redraw* )
			displayRedrawOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-redraw=$displayRedrawOPTION"
		;;
		--display-icon* )
			displayIconOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-icon=$dislayIconOPTION"
		;;
		--icon-size-ibm* )
			iconSizeIbmOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --icon-size-ibm=$iconSizeIbmOPTION"
		;;
		--icon-size-jamf* )
			iconSizeJamfOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --icon-size-jamf=$iconSizeJamfOPTION"
		;;
		--display-accessory-type* )
			displayAccessoryTypeOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-accessory-type=$dislayAccessoryTypeOPTION"
		;;
		--display-accessory-default* )
			displayAccessoryDefaultOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-accessory-default=$dislayAccessoryDefaultOPTION"
		;;
		--display-accessory-update* )
			displayAccessoryUpdateOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-accessory-update=$dislayAccessoryUpdateOPTION"
		;;
		--display-accessory-upgrade* )
			displayAccessoryUpgradeOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-accessory-upgrade=$dislayAccessoryUpgradeOPTION"
		;;
		--display-accessory-user-auth* )
			displayAccessoryUserAuthOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --display-accessory-user-auth=$dislayAccessoryUserAuthOPTION"
		;;
		--help-button* )
			helpButtonOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --help-button=$helpButtonOPTION"
		;;
		--warning-button* )
			warningButtonOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --warning-button=$warningButtonOPTION"
		;;
		-Q|--display-silently|--display-silently-on )
			displaySilentlyOPTION="TRUE"
            commandPARAMS="$commandPARAMS --display-silently"
		;;
		-q|--display-silently-off|--no-display-silently )
			displaySilentlyOPTION="FALSE"
            commandPARAMS="$commandPARAMS --display-silently-off"
		;;
		-J|--prefer-jamf-helper|--prefer-jamf-helper-on )
			preferJamfHelperOPTION="TRUE"
            commandPARAMS="$commandPARAMS --prefer-jamf-helper"
		;;
		-j|--prefer-jamf-helper-off|--no-prefer-jamf-helper )
			preferJamfHelperOPTION="FALSE"
            commandPARAMS="$commandPARAMS --prefer-jamf-helper-off"
		;;
		--local-account* )
			localOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --local-account=$localOPTION"
		;;
		--local-password* )
			localPASSWORD=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --local-password=$localPASSWORD"
		;;
		--admin-account* )
			adminACCOUNT=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --admin-account=$adminACCOUNT"
		;;
		--admin-password* )
			adminPASSWORD=$(echo "$1" | sed -e 's|^[^=]*=||g')
		;;
		--admin-crypt-key* )
			adminCryptKEY=$(echo "$1" | sed -e 's|^[^=]*=||g')
		;;
		--super-account* )
			superOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --super-account=$superOPTION"
		;;
		--super-password* )
			superPASSWORD=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --super-password=$superPASSWORD"
		;;
		--jamf-account* )
			jamfOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --jamf-account=$jamfOPTION"
		;;
		--jamf-password* )
			jamfPASSWORD=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --jamf-password=$jamfPASSWORD"
		;;
		--lapsapicredentials* )
			lapsCREDENTIALS=$(echo "$1" | sed -e 's|^[^=]*=||g' | base64 -D)
		;;
		-d|-D|--delete-accounts )
			deleteACCOUNTS="TRUE"
            commandPARAMS="$commandPARAMS --delete-accounts"
		;;
		-M|--allow-upgrade|--allow-upgrade-on )
			allowUpgradeOPTION="TRUE"
            commandPARAMS="$commandPARAMS --allow-upgrade"
		;;
		-m|--allow-upgrade-off|--no-allow-upgrade )
			allowUpgradeOPTION="FALSE"
            commandPARAMS="$commandPARAMS --allow-upgrade-off"
		;;
		--user-auth-timeout* )
			userAuthTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --user-auth-timeout=$userAuthTimeoutOPTION"
		;;
		--user-auth-mdm-failover* )
			userAuthMDMFailoverOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --user-auth-mdm-failover=$userAuthMDMFailoverOPTION"
		;;
		--target-upgrade* )
			targetUpgradeOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --target-upgrade=$targetUpgradeOPTION"
		;;
		-N|--enforce-non-system-updates|--enforce-non-system-updates-on )
			enforceNonSystemUpdatesOPTION="TRUE"
            commandPARAMS="$commandPARAMS --enforce-non-system-updates"
		;;
		-n|--enforce-non-system-updates-off|--no-enforce-non-system-updates )
			enforceNonSystemUpdatesOPTION="FALSE"
            commandPARAMS="$commandPARAMS --enforce-non-system-updates-off"
		;;
		-R|--allow-rsr-updates|--allow-rsr-updates-on )
			allowRSRUpdatesOPTION="TRUE"
            commandPARAMS="$commandPARAMS --allow-rsr-updates"
		;;
		-r|--allow-rsr-updates-off|--no-allow-rsr-updates )
			allowRSRUpdatesOPTION="FALSE"
            commandPARAMS="$commandPARAMS --allow-rsr-updates-off"
		;;
		-O|--only-download|--only-download-on )
			onlyDownloadOPTION="TRUE"
            commandPARAMS="$commandPARAMS --only-download"
		;;
		-o|--only-download-off|--no-only-download )
			onlyDownloadOPTION="FALSE"
            commandPARAMS="$commandPARAMS --only-download-off"
		;;
		-I|--install-now|--install-now-on )
			installNowOPTION="TRUE"
            commandPARAMS="$commandPARAMS --install-now"
		;;
		-i|--install-now-off|--no-update-now )
			installNowOPTION="FALSE"
            commandPARAMS="$commandPARAMS --install-now-off"
		;;
		--policy-triggers* )
			policyTriggersOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --policy-triggers=$policyTriggersOPTION"
		;;
		-S|--skip-updates|--skip-updates-on )
			skipUpdatesOPTION="TRUE"
            commandPARAMS="$commandPARAMS --skip-updates"
		;;
		-s|--skip-updates-off|--no-skip-updates )
			skipUpdatesOPTION="FALSE"
            commandPARAMS="$commandPARAMS --skip-updates-off"
		;;
		-W|--restart-without-updates|--restart-without-updates-on )
			restartWithoutUpdatesOPTION="TRUE"
            commandPARAMS="$commandPARAMS --restart-without-updates"
		;;
		-w|--restart-without-updates-off|--no-restart-without-updates )
			restartWithoutUpdatesOPTION="FALSE"
            commandPARAMS="$commandPARAMS --restart-without-updates-off"
		;;
		--free-space-update* )
			freeSpaceUpdateOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --free-space-update=$freeSpaceUpdateOPTION"
		;;
		--free-space-upgrade* )
			freeSpaceUpgradeOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --free-space-upgrade=$freeSpaceUpgradeOPTION"
		;;
		--free-space-timeout* )
			freeSpaceTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --free-space-timeout=$freeSpaceTimeoutOPTION"
		;;
		--battery-level* )
			batteryLevelOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --battery-level=$batteryLevelOPTION"
		;;
		--battery-timeout* )
			batteryTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --battery-timeout=$batteryTimeoutOPTION"
		;;
		-T|--test-mode|--test-mode-on )
			testModeOPTION="TRUE"
            commandPARAMS="$commandPARAMS --test-mode"
		;;
		-t|--test-mode-off|--no-test-mode )
			testModeOPTION="FALSE"
            commandPARAMS="$commandPARAMS --test-mode-off"
		;;
		--test-mode-timeout* )
			testModeTimeoutOPTION=$(echo "$1" | sed -e 's|^[^=]*=||g')
            commandPARAMS="$commandPARAMS --test-mode-timeout=$testModeTimeoutOPTION"
		;;
		-V|--verbose-mode|--verbose-mode-on )
			verboseModeOPTION="TRUE"
            commandPARAMS="$commandPARAMS --verbose-mode"
		;;
		-v|--verbose-mode-off|--no-verbose-mode )
			verboseModeOPTION="FALSE"
            commandPARAMS="$commandPARAMS --verbose-mode-off"
		;;
		-l|-L|--open-logs )
			openLOGS="TRUE"
            commandPARAMS="$commandPARAMS --open-logs"
		;;
		-x|-X|--reset-super )
			resetLocalPROPERTIES="TRUE"
            commandPARAMS="$commandPARAMS --reset-super"
		;;
		-u|-U|--usage )
			showUsage
            commandPARAMS="$commandPARAMS --usage"
		;;
		-h|-H|--help )
			showHelp
            commandPARAMS="$commandPARAMS --help"
		;;
		*)
			unrecognizedOptionsARRAY+=("$1")
		;;
	esac
	shift
done

# Error log any unrecognized options.
[[ -n ${unrecognizedOptionsARRAY[*]} ]] && showUsage

if [[ -n "$adminPASSWORD" ]]; then
	extensionNAME=""
	getJamfProComputerID
    if [ -z "$jamfProID" ]; then
    	jamfProID=$(/usr/bin/defaults read "/Library/Managed Preferences/com.macjutsu.super.plist" JamfProID)
    fi
#   commandRESULT=$(curl -X POST -u "$jamfOPTION:$jamfPASSWORD" -s "${jamfSERVER}api/v1/auth/token")
    commandRESULT=$(curl -X POST -u "$lapsCREDENTIALS" -s "${jamfSERVER}api/v1/auth/token")
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: commandRESULT is:\n$commandRESULT"
	if [[ $(echo "$commandRESULT" | grep -c 'token') -gt 0 ]]; then
		if [[ $macOSMAJOR -ge 12 ]]; then
			jamfProTOKEN=$(echo "$commandRESULT" | plutil -extract token raw -)
		else
			jamfProTOKEN=$(echo "$commandRESULT" | grep 'token' | tr -d '"',',' | sed -e 's#token :##' | xargs)
		fi
	else
		sendToLog "Error: Response from Jamf Pro API token request did not contain a token."; jamfERROR="TRUE"
	fi
 	# Check adminPASSWORD and adminCryptKEY, if value of adminPASSWORD starts with 'lapssecret-' then the content points to an extension attribute being used as part of a LAPS implementation and we need to retrieve it and store it in adminPASSWORD, if adminCryptKEY is set to a value then it needs to be used to decrypt the adminPASSWORD.
	#
	# first checking if adminPASSWORD is pointing to an extension attribute and if true reading its value and storing it in adminPASSWORD
	if [[ "$adminPASSWORD" == "lapssecret-"* ]]; then
		# adminPASSWD is pointing to an extension attribute
		# remove "lapssecret-" prefix to get extension attribute name
		extensionNAME=${adminPASSWORD#"lapssecret-"}

		# replace content of adminPASSWORD with content of extension attribute
		extensionVALUE=$(curl -s -H "Accept: application/xml" $jamfSERVER/JSSResource/computers/id/$jamfProID/subset/extension_attributes -H "Authorization:Bearer $jamfProTOKEN" | xpath -e "//extension_attribute[name=normalize-space('$extensionNAME')]" 2>&1 | awk -F'<value>|</value>' '{print $2}' | tail -n +1)
     	if [[ -n "$extensionVALUE" ]]; then
			adminPASSWORD="$extensionVALUE"
		else
			sendToLog "Credential Error: LAPS extension attribute $extensionNAME did not return a value."; credentialERROR="TRUE"
		fi
	fi

	extensionNAME=""
	# now checking if adminCryptKEY is set and if so then using it to decrypt the content of adminPASSWORD
	# note: this works even if an extension attribute is not used allowing an encrypted adminPASSWORD and decryption key to be passed directly as script parameters
	if [[ -n "$adminCryptKEY" ]]; then
		# adminCryptKEY contains value checking to see if it is pointing to an extension attribute
		if [[ "$adminCryptKEY" == "lapscryptkey-"* ]]; then
			# adminCryptKEY is pointing to an extension attribute
			# remove "lapscryptkey-" prefix to get extension attribute name
			extensionNAME=${adminCryptKEY#"lapscryptkey-"}

			# replace content of adminCryptKEY with content of extension attribute
			extensionVALUE=$(curl -s -H "Accept: application/xml" $jamfSERVER/JSSResource/computers/id/$jamfProID/subset/extension_attributes -H "Authorization:Bearer $jamfProTOKEN" | xpath -e "//extension_attribute[name=normalize-space('$extensionNAME')]" 2>&1 | awk -F'<value>|</value>' '{print $2}' | tail -n +1)
			echo "Crypt2 = $extensionVALUE"
            if [[ -n "$extensionVALUE" ]]; then
				adminCryptKEY="$extensionVALUE"
			else
				sendToLog "Credential Error: LAPS extension attribute $extensionNAME did not return a value."; credentialERROR="TRUE"
			fi
		fi
		# decrypt content of adminPASSWORD
		# note: this is using the same encryption method as https://github.com/PezzaD84/macOSLAPS
    	adminPASSWORD=$(echo "$adminCryptKEY" | openssl enc -aes-256-cbc -md sha512 -a -d -salt -pass pass:"$adminPASSWORD")
	fi

	# now add adminPASSWORD (decrypted if needed) to commandPARAMS
    commandPARAMS="$commandPARAMS --admin-password=$adminPASSWORD"
fi
# we can now pass all the script command parameters including the retrieved/decrypted admin password to the real Super script
# we do not need to pass --admin-crypt-key as the whole point of this script is to if needed decrypt the admin password on behalf of the real Super script


}

# Collect any parameters stored in $superMANAGEDPLIST and/or $superPLIST.
getPreferences() {

# Collect any managed preferences from $superMANAGEDPLIST.
if [[ -f "$superMANAGEDPLIST.plist" ]]; then
	jamfProIdMANAGED=$(defaults read "$superMANAGEDPLIST" JamfProID 2> /dev/null)
    # this script only needs the Jamf Pro ID, the real Super script will itself read this and all the other preferences
fi

# Collect any local preferences from $superPLIST.
if [[ -f "$superPLIST.plist" ]]; then
    echo
    # this script does not need any of the values of the local preferences, the real Super script will those itself
fi

}

# Validate non-credential parameters and manage $superPLIST. Any errors set $parameterERROR.
manageParameters() {
parameterERROR="FALSE"

# Various regular expressions used for parameter validation.
regexNUMBER="^[0-9]+$"
regexMENU="^[0-9*,]+$"
regexDATE="^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$"
regexTIME="^(2[0-3]|[01][0-9]):[0-5][0-9]$"
regexDATETIME="^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]):(2[0-3]|[01][0-9]):[0-5][0-9]$"
regexMACOSMAJORVERSION="^([1][1-9])$"

# Removed all validation steps as the real Super script will still do this

}

# For Apple Silicon computers this function manages update/upgrade credentials given $deleteACCOUNTS, $localACCOUNT, $adminACCOUNT, $superACCOUNT, or $jamfACCOUNT. Any errors set $credentialERROR.
manageUpdateCredentials () {
# Validate that the account $jamfOPTION and $jamfPASSWORD are valid.
if [[ -n $jamfOPTION ]] && [[ "$credentialERROR" != "TRUE" ]]; then
	jamfACCOUNT="$jamfOPTION"
	jamfKEYCHAIN="$jamfPASSWORD"
	if [[ "$jamfSERVER" != "FALSE" ]]; then
		getJamfProAccount
		[[ "$jamfERROR" == "TRUE" ]] && credentialERROR="TRUE"
	else
		sendToLog "Credential Error: Unable to connect to Jamf Pro to validate user account."; credentialERROR="TRUE"
	fi
	unset jamfACCOUNT
	unset jamfKEYCHAIN
fi
    
    echo "skip manageUpdateCredentials as real Super script will do this"
}

# This function determines what $updateWORKFLOW, $upgradeWORKFLOW, and betaWORKFLOW modes are possible given the architecture and authentication options.
manageWorkflowOptions() {
workflowERROR="FALSE"
# Update/upgrade workflow modes: FALSE, JAMF, LOCAL, or USER
updateWORKFLOW="FALSE"
upgradeWORKFLOW="FALSE"
betaWORKFLOW="FALSE"
}

# MARK: *** Installation & Startup ***
################################################################################

# Install and validate helper items that may be used by super.
manageHelpers() {
helperERROR="FALSE"

# Validate $jamfBINARY if installed and set $jamfVERSION and $jamfSERVER accordingly.
jamfVERSION="FALSE"
if [[ -e "$jamfBINARY" ]]; then
	getJamfProServer
	jamfMAJOR=$("$jamfBINARY" -version | cut -c 9- | cut -d'.' -f1) # Expected output: 10
	jamfMINOR=$("$jamfBINARY" -version | cut -c 9- | cut -d'.' -f2) # Expected output: 30, 31, 32, etc.
	jamfVERSION=${jamfMAJOR}$(printf "%02d" "$jamfMINOR") # Expected output: 1030, 1031, 1032, etc.
	if [[ $macOSVERSION -ge 1103 ]] && [[ $jamfVERSION -lt 1038 ]]; then
		sendToLog "Helper Error: super requires Jamf Pro version 10.38 or later, the currently installed version of Jamf Pro $jamfVERSION is not supported."; helperERROR="TRUE"
	elif [[ "$jamfVERSION" -lt 1000 ]]; then
		sendToLog "Helper Error: super requires Jamf Pro version 10.00 or later, the currently installed version of Jamf Pro $jamfVERSION is not supported."; helperERROR="TRUE"
	else
		sendToLog "Startup: Computer is currently managed by Jamf Pro version $jamfMAJOR.$jamfMINOR."
	fi
else
	sendToLog "Startup: Unable to locate jamf binary at: $jamfBINARY"
fi

}

# Install items required by super.
superInstallation() {
# Download real Super script and then run it with command parameters original passed to this script
echo "installation"

# Work around for apparent bug, the way this script runs the real SUPER install script seems to result 
# in the directory permissions being set incorrectly as drwx------ when they should be drwxr-xr-x
# This in turn results in the real SUPER install script failing to install IBM Notifier.app
# This workaround therefore pre-creates these directories and sets the correct permissions
if [ ! -d "/Library/Management" ]; then
	/bin/mkdir "/Library/Management"
fi
/bin/chmod 755 "/Library/Management"
if [ ! -d "/Library/Management/super" ]; then
	/bin/mkdir "/Library/Management/super"
fi
/bin/chmod 755 "/Library/Management/super"


if [[ -f "/Library/LaunchDaemons/com.macjutsu.super.plist" ]]; then
	/bin/launchctl unload -w "/Library/LaunchDaemons/com.macjutsu.super.plist"
fi
/usr/bin/curl --silent -o /tmp/super -L -O https://github.com/Macjutsu/super/raw/main/super
/bin/chmod +x /tmp/super
#echo "params = $commandPARAMS"
array=($commandPARAMS)
#echo "array ${array[@]}"
mycmd=(/tmp/super "${array[@]}")
"${mycmd[@]}"
/bin/launchctl load -w "/Library/LaunchDaemons/com.macjutsu.super.plist"
}

# Prepare super by cleaning after previous super runs, record various maintenance modes, validate parameters, and liberate super from Jamf Policy runs.
superStartup() {
sendToLog "**** S.U.P.E.R.M.A.N. $superVERSION STARTUP ****"
sendToStatus "Running: Startup workflow."
sendToPending "Currently running."

# Collect any locally cached or managed preferences.
#getPreferences



# Main parameter validation and management.
checkCurrentUser
manageParameters

# Workflow for for $openLOGS.
if [[ "$openLOGS" == "TRUE" ]]; then
	if [[ "$currentUserNAME" != "FALSE" ]]; then
		sendToLog "Startup: Opening logs for user \"$currentUserNAME\"."
		if [[ "$macOSARCH" == "arm64" ]]; then
			sudo -u "$currentUserNAME" open "$mdmWorkflowLOG"
			sudo -u "$currentUserNAME" open "$mdmCommandLOG"
		fi
		sudo -u "$currentUserNAME" open "$installerLOG"
		sudo -u "$currentUserNAME" open "$asuLOG"
		sudo -u "$currentUserNAME" open "$installerListLOG"
		sudo -u "$currentUserNAME" open "$asuListLOG"
		sudo -u "$currentUserNAME" open "$superLOG"
	else
		sendToLog "Startup: Open logs request denied because there is currently no local user logged into the GUI."
	fi
fi

# Additional validation and management.
[[ "$macOSARCH" == "arm64" ]] && manageUpdateCredentials
manageWorkflowOptions
manageHelpers
[[ "$verboseModeOPTION" == "TRUE" ]] && logParameters
if [[ "$parameterERROR" == "TRUE" ]] || [[ "$credentialERROR" == "TRUE" ]] || [[ "$workflowERROR" == "TRUE" ]] || [[ "$helperERROR" == "TRUE" ]]; then
	sendToLog "Exit: Startup validation failed."
	sendToStatus "Inactive Error: Startup validation failed."
	errorExit
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: Local preference file after all validations $superPLIST is:\n$(defaults read "$superPLIST" 2> /dev/null)"

# Wait for a valid network connection. If there is still no network after two minutes, an automatic deferral is started.
networkTIMEOUT=0
while [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]] && [[ $networkTIMEOUT -lt 120 ]]; do
	sendToLog "Startup: Waiting for network..."
	sleep 5
	networkTIMEOUT=$((networkTIMEOUT + 5))
done
if [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]]; then
	if [[ "$installNowOPTION" == "TRUE" ]]; then
		sendToLog "Error: Network unavailable, install now workflow can not continue."
		sendToStatus "Inactive Error: Network unavailable, install now workflow can not continue."
		notifyInstallNowFailure
		errorExit
	else
		deferSECONDS="$errorDeferSECONDS"
		sendToLog "Error: Network unavailable, trying again in $deferSECONDS seconds."
		sendToStatus "Pending: Network unavailable, trying again in $deferSECONDS seconds."
		makeLaunchDaemonCalendar
	fi
fi

}

# This function is used when the super workflow exits with no errors.
cleanExit() {
[[ -n "$jamfProTOKEN" ]] && deleteJamfProServerToken
defaults delete "$superPLIST" InstallNow 2> /dev/null
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: Local preference file $superPLIST is:\n$(defaults read "$superPLIST" 2> /dev/null)"
sendToLog "**** S.U.P.E.R.M.A.N. $superVERSION EXIT ****"
rm -f "$superPIDFILE"
exit 0
}

# This function is used when the super workflow must exit due to an unrecoverable error.
errorExit() {
[[ -n "$jamfProTOKEN" ]] && deleteJamfProServerToken
defaults delete "$superPLIST" InstallNow 2> /dev/null
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: Local preference file $superPLIST is:\n$(defaults read "$superPLIST" 2> /dev/null)"
sendToLog "**** S.U.P.E.R.M.A.N. $superVERSION ERROR EXIT ****"
sendToPending "Inactive."
rm -f "$superPIDFILE"
exit 1
}

# MARK: *** Logging ***
################################################################################

# Append input to the command line and log located at $superLOG.
sendToLog() {
echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" | tee -a "$superLOG"
}

# Send input to the command line only, so as not to save secrets to the $superLOG.
sendToEcho() {
echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: Not Logged: $*"
}

# Send input to the command line only replacing the current line, so as not to save save interactive progress updates to the $superLOG.
sendToEchoReplaceLine() {
echo -ne "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: Not Logged: $*\r"
}

# Append input to a log located at $asuLOG.
sendToASULog() {
echo -e "\n$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >> "$asuLOG"
}

# Append input to a log located at $installerLOG.
sendToInstallerLog() {
echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >> "$installerLOG"
}

# Append input to a log located at $mdmCommandLOG.
sendToMDMCommandLog() {
echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >> "$mdmCommandLOG"
}

# Append input to a log located at $mdmWorkflowLOG.
sendToMDMWorkflowLog() {
echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >> "$mdmWorkflowLOG"
}

# Update the SuperStatus key in the $superPLIST.
sendToStatus() {
defaults write "$superPLIST" SuperStatus -string "$(date +"%a %b %d %T"): $*"
}

# Update the SuperPending key in the $superPLIST.
sendToPending() {
defaults write "$superPLIST" SuperPending -string "$*"
}

# Log any parameters that have values.
logParameters() {
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: superVERSION is: $superVERSION"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: superDATE is: $superDATE"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSMAJOR is: $macOSMAJOR"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSMINOR is: $macOSMINOR"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSVERSION is: $macOSVERSION"
[[ "$macOSMAJOR" -ge 13 ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSEXTRA is: $macOSEXTRA"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSARCH is: $macOSARCH"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macModelID is: $macModelID"
[[ -n $macBOOK ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macBOOK is: $macBOOK"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: lastREBOOT is: $lastREBOOT"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: parameterERROR is: $parameterERROR"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: credentialERROR is: $credentialERROR"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: workflowERROR is: $workflowERROR"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: helperERROR is: $helperERROR"
[[ -n $jamfVERSION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfVERSION is: $jamfVERSION"
[[ -n $jamfSERVER ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfSERVER is: $jamfSERVER"
[[ -n $ibmNotifierVALID ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: ibmNotifierVALID is: $ibmNotifierVALID"
[[ -n $eraseInstallVALID ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: eraseInstallVALID is: $eraseInstallVALID"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: defaultDeferSECONDS is: $defaultDeferSECONDS"
[[ -n $focusDeferSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: focusDeferSECONDS is: $focusDeferSECONDS"
[[ -n $menuDeferSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: menuDeferSECONDS is: $menuDeferSECONDS"
[[ -n $recheckDeferSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: recheckDeferSECONDS is: $recheckDeferSECONDS"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: errorDeferSECONDS is: $errorDeferSECONDS"
[[ -n $focusCountMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: focusCountMAX is: $focusCountMAX"
[[ -n $softCountMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: softCountMAX is: $softCountMAX"
[[ -n $hardCountMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: hardCountMAX is: $hardCountMAX"
[[ -n $focusDaysMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: focusDaysMAX is: $focusDaysMAX"
[[ -n $softDaysMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: softDaysMAX is: $softDaysMAX"
[[ -n $hardDaysMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: hardDaysMAX is: $hardDaysMAX"
[[ -n $zeroDayOVERRIDE ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: zeroDayOVERRIDE is: $zeroDayOVERRIDE"
[[ -n $focusDateMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: focusDateMAX is: $focusDateMAX"
[[ -n $softDateMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: softDateMAX is: $softDateMAX"
[[ -n $hardDateMAX ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: hardDateMAX is: $hardDateMAX"
[[ -n $deferDialogTimeoutSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: deferDialogTimeoutSECONDS is: $deferDialogTimeoutSECONDS"
[[ -n $softDialogTimeoutSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: softDialogTimeoutSECONDS is: $softDialogTimeoutSECONDS"
[[ -n $displayRedrawSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayRedrawSECONDS is: $displayRedrawSECONDS"
[[ -n $ibmNotifierIconSIZE ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: ibmNotifierIconSIZE is: $ibmNotifierIconSIZE"
[[ -n $jamfHelperIconSIZE ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfHelperIconSIZE is: $jamfHelperIconSIZE"
[[ -n $displayAccessoryTYPE ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayAccessoryTYPE is: $displayAccessoryTYPE"
[[ -n $displayAccessoryDefaultCONTENT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayAccessoryDefaultCONTENT is: $displayAccessoryDefaultCONTENT"
[[ -n $displayAccessoryUpdateCONTENT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayAccessoryUpdateCONTENT is: $displayAccessoryUpdateCONTENT"
[[ -n $displayAccessoryUpgradeCONTENT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayAccessoryUpgradeCONTENT is: $displayAccessoryUpgradeCONTENT"
[[ -n $displayAccessoryUserAuthCONTENT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displayAccessoryUserAuthCONTENT is: $displayAccessoryUserAuthCONTENT"
[[ -n $helpBUTTON ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: helpBUTTON is: $helpBUTTON"
[[ -n $warningBUTTON ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: warningBUTTON is: $warningBUTTON"
[[ -n $displaySilentlyOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: displaySilentlyOPTION is: $displaySilentlyOPTION"
[[ -n $preferJamfHelperOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: preferJamfHelperOPTION is: $preferJamfHelperOPTION"
[[ -n $localOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: localOPTION is: $localOPTION"
[[ -n $localPASSWORD ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: localPASSWORD is: $localPASSWORD"
[[ -n $localACCOUNT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: localACCOUNT is: $localACCOUNT"
[[ -n $localKEYCHAIN ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: localKEYCHAIN is: $localKEYCHAIN"
[[ -n $localCREDENTIAL ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: localCREDENTIAL is: $localCREDENTIAL"
[[ -n $adminACCOUNT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: adminACCOUNT is: $adminACCOUNT"
[[ -n $adminPASSWORD ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: adminPASSWORD is: $adminPASSWORD"
[[ -n $superOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: superOPTION is: $superOPTION"
[[ -n $superPASSWORD ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: superPASSWORD is: $superPASSWORD"
[[ -n $superACCOUNT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: superACCOUNT is: $superACCOUNT"
[[ -n $superKEYCHAIN ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: superKEYCHAIN is: $superKEYCHAIN"
[[ -n $superCREDENTIAL ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: superCREDENTIAL is: $superCREDENTIAL"
[[ -n $JamfProID ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: JamfProID is: $JamfProID"
[[ -n $jamfOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfOPTION is: $jamfOPTION"
[[ -n $jamfPASSWORD ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: jamfPASSWORD is: $jamfPASSWORD"
[[ -n $jamfACCOUNT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfACCOUNT is: $jamfACCOUNT"
[[ -n $jamfKEYCHAIN ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: jamfKEYCHAIN is: $jamfKEYCHAIN"
[[ -n $jamfCREDENTIAL ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfCREDENTIAL is: $jamfCREDENTIAL"
[[ -n $deleteACCOUNTS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: deleteACCOUNTS is: $deleteACCOUNTS"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthTimeoutSECONDS is: $userAuthTimeoutSECONDS"
[[ -n $userAuthMDMFailoverOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFailoverOPTION is: $userAuthMDMFailoverOPTION"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFAILOVER is: $userAuthMDMFAILOVER"
[[ -n $userAuthMDMFailoverSOFT ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFailoverSOFT is: $userAuthMDMFailoverSOFT"
[[ -n $userAuthMDMFailoverHARD ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFailoverHARD is: $userAuthMDMFailoverHARD"
[[ -n $userAuthMDMFailoverINSTALLNOW ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFailoverINSTALLNOW is: $userAuthMDMFailoverINSTALLNOW"
[[ -n $userAuthMDMFailoverBOOTSTRAP ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: userAuthMDMFailoverBOOTSTRAP is: $userAuthMDMFailoverBOOTSTRAP"
[[ -n $allowUpgradeOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: allowUpgradeOPTION is: $allowUpgradeOPTION"
[[ -n $targetUpgradeVERSION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: targetUpgradeVERSION is: $targetUpgradeVERSION"
[[ -n $allowRSRUpdatesOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: allowRSRUpdatesOPTION is: $allowRSRUpdatesOPTION"
[[ -n $enforceNonSystemUpdatesOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: enforceNonSystemUpdatesOPTION is: $enforceNonSystemUpdatesOPTION"
[[ -n $onlyDownloadOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: onlyDownloadOPTION is: $onlyDownloadOPTION"
[[ -n $installNowOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: installNowOPTION is: $installNowOPTION"
[[ -n $policyTRIGGERS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: policyTRIGGERS is: $policyTRIGGERS"
[[ -n $skipUpdatesOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: skipUpdatesOPTION is: $skipUpdatesOPTION"
[[ -n $restartWithoutUpdatesOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: restartWithoutUpdatesOPTION is: $restartWithoutUpdatesOPTION"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: freeSpaceUpdateGB is: $freeSpaceUpdateGB"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: freeSpaceUpgradeGB is: $freeSpaceUpgradeGB"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: freeSpaceTimeoutSECONDS is: $freeSpaceTimeoutSECONDS"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: batteryLevelPERCENT is: $batteryLevelPERCENT"
sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: batteryTimeoutSECONDS is: $batteryTimeoutSECONDS"
[[ -n $testModeOPTION ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: testModeOPTION is: $testModeOPTION"
[[ -n $testModeTimeoutSECONDS ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: testModeTimeoutSECONDS is: $testModeTimeoutSECONDS"
}

# MARK: *** Jamf Pro API ***
################################################################################

# Validate the connection to a managed computer's Jamf Pro service and set $jamfSERVER accordingly.
getJamfProServer() {
jamfSTATUS=$("$jamfBINARY" checkJSSConnection -retry 1 2>/dev/null)
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfSTATUS is: $jamfSTATUS"
if [[ $(echo "$jamfSTATUS" | grep -c 'available') -gt 0 ]]; then
	jamfSERVER=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
	sendToLog "Warning: Jamf Pro service unavailable."; jamfSERVER="FALSE"; jamfERROR="TRUE"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfSTATUS is: $jamfSTATUS"
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfSERVER is: $jamfSERVER"
}

# Attempt to acquire a Jamf Pro $jamfProTOKEN via $jamfACCOUNT and $jamfKEYCHAIN credentials.
getJamfProToken() {
getJamfProServer
if [[ "$jamfSERVER" != "FALSE" ]]; then
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfACCOUNT is: $jamfACCOUNT"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToEcho "Verbose Mode: Function ${FUNCNAME[0]}: jamfKEYCHAIN is: $jamfKEYCHAIN"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfSERVER is: $jamfSERVER"
	commandRESULT=$(curl -X POST -u "$jamfACCOUNT:$jamfKEYCHAIN" -s "${jamfSERVER}api/v1/auth/token")
    echo "token commandRESULT = $commandRESULT"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: commandRESULT is:\n$commandRESULT"
	if [[ $(echo "$commandRESULT" | grep -c 'token') -gt 0 ]]; then
		if [[ $macOSMAJOR -ge 12 ]]; then
			jamfProTOKEN=$(echo "$commandRESULT" | plutil -extract token raw -)
		else
			jamfProTOKEN=$(echo "$commandRESULT" | python -c 'import sys, json; print json.load(sys.stdin)["token"]')
		fi
	else
		sendToLog "Error: Response from Jamf Pro API token request did not contain a token."; jamfERROR="TRUE"
	fi
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfProTOKEN is:\n$jamfProTOKEN"
fi
}

# Validate that the account $jamfACCOUNT and $jamfKEYCHAIN are valid credentials and has appropriate permissions to send MDM push commands. If not set $jamfERROR.
getJamfProAccount() {
getJamfProToken
if [[ -n $jamfProTOKEN ]]; then
	getJamfProComputerID
	if [[ -n $jamfProID ]]; then
		sendBlankPush
			if [[ $commandRESULT != 201 ]]; then
				sendToLog "Error: Unable to request Blank Push via Jamf Pro API user account \"$jamfACCOUNT\". Verify this account has has the privileges \"Jamf Pro Server Objects > Computers > Create & Read\"."; jamfERROR="TRUE"
			fi
	else
		sendToLog "Error: Unable to acquire Jamf Pro ID for computer with UDID \"$computerUDID\". Verify that this computer is enrolled in Jamf Pro."
		sendToLog "Error: Also verify that the Jamf Pro API account \"$jamfACCOUNT\" has the privileges \"Jamf Pro Server Objects > Computers > Create & Read\"."; jamfERROR="TRUE"
	fi
else
	sendToLog "Error: Unable to acquire authentication token via Jamf Pro API user account \"$jamfACCOUNT\". Verify account name and password."; jamfERROR="TRUE"
fi
}

# Use $jamfProIdMANAGED or $jamfProTOKEN to find the computer's Jamf Pro ID and set $jamfProID.
getJamfProComputerID() {
computerUDID=$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: computerUDID is: $computerUDID"
if [[ -n $jamfProIdMANAGED ]]; then
	jamfProID="$jamfProIdMANAGED"
else
	sendToLog "Warning: Using a Jamf Pro API account with \"Computers > Read\" privileges to collect the computer ID is a security risk. Instead use a custom Configuration Profile with the following; Preference Domain \"com.macjutsu.super\", Key \"JamfProID\", String \"\$JSSID\"."
	jamfProID=$(curl --header "Authorization: Bearer ${jamfProTOKEN}" --header "Accept: application/xml" --request GET --url "${jamfSERVER}JSSResource/computers/udid/${computerUDID}/subset/General" 2> /dev/null | xpath -e /computer/general/id 2>&1 | awk -F '<id>|</id>' '{print $2}' | xargs)
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: jamfProID is: $jamfProID"
}

# Attempt to send a Blank Push to Jamf Pro.
sendBlankPush() {
commandRESULT=$(curl --header "Authorization: Bearer ${jamfProTOKEN}" --write-out "%{http_code}" --silent --output /dev/null --request POST --url "${jamfSERVER}JSSResource/computercommands/command/BlankPush/id/${jamfProID}")
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: commandRESULT is:\n$commandRESULT"
}

# Validate existing $jamfProTOKEN and if found invalid, a new token is requested and again validated.
checkJamfProServerToken() {
tokenCHECK=$(curl --header "Authorization: Bearer ${jamfProTOKEN}" --write-out "%{http_code}" --silent --output /dev/null --request GET --url "${jamfSERVER}api/v1/auth")
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: tokenCHECK is: $tokenCHECK"
if [[ $tokenCHECK -ne 200 ]]; then
	getJamfProToken
	tokenCHECK=$(curl --header "Authorization: Bearer ${jamfProTOKEN}" --write-out "%{http_code}" --silent --output /dev/null --request GET --url "${jamfSERVER}api/v1/auth")
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: tokenCHECK is: $tokenCHECK"
	if [[ $tokenCHECK -ne 200 ]]; then
		if [[ "$installNowOPTION" == "TRUE" ]]; then
			sendToLog "Error: Could not request Jamf Pro API token for account \"$jamfACCOUNT\", install now workflow can not continue."
			sendToStatus "Inactive Error: Could not request Jamf Pro API token for account \"$jamfACCOUNT\", install now workflow can not continue."
			notifyInstallNowFailure
			errorExit
		else
			deferSECONDS="$errorDeferSECONDS"
			sendToLog "Error: Could not request Jamf Pro API token for account \"$jamfACCOUNT\", trying again in $deferSECONDS seconds."
			sendToStatus "Pending: Could not request Jamf Pro API token for account \"$jamfACCOUNT\", trying again in $deferSECONDS seconds."
			makeLaunchDaemonCalendar
		fi
	fi
fi
}

# Invalidate and remove from local memory the $jamfProTOKEN.
deleteJamfProServerToken() {
invalidateTOKEN=$(curl --header "Authorization: Bearer ${jamfProTOKEN}" --write-out "%{http_code}" --silent --output /dev/null --request POST --url "${jamfSERVER}api/v1/auth/invalidate-token")
if [[ $invalidateTOKEN -eq 204 ]]; then
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: Jamf Pro API token successfully invalidated."
	unset jamfProTOKEN
elif [[ $invalidateTOKEN -eq 401 ]]; then
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: Jamf Pro API token already invalid."
	unset jamfProTOKEN
else
	sendToLog "Error: Invalidating Jamf Pro API token."
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: invalidateTOKEN is: $invalidateTOKEN"
fi
}

# MARK: *** Local System Validation ***
################################################################################

# Verify that super is running with root privileges.
checkRoot() {
if [[ "$(id -u)" -ne 0 ]]; then
	sendToEcho "Exit: $(basename "$0") must run with root privileges."
	errorExit
fi
}

# Set $currentUserNAME to the currently logged in GUI user or "FALSE" if there is none or a system account.
# If the current user is a normal account then this also sets $currentUserUID, $currentUserGUID, $currentUserRealNAME, $currentUserADMIN, $currentUserSecureTOKEN, and $currentUserVolumeOWNER
checkCurrentUser() {
currentUserNAME=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
if [[ -z $currentUserNAME ]]; then
	sendToLog "Status: No GUI user currently logged in."
	currentUserNAME="FALSE"
	currentUserUID="FALSE"
elif [[ "$currentUserNAME" = "root" ]] || [[ "$currentUserNAME" = "_mbsetupuser" ]] || [[ "$currentUserNAME" = "loginwindow" ]]; then
	sendToLog "Status: Current GUI user is system account \"$currentUserNAME\"."
	currentUserNAME="FALSE"
	currentUserUID="0"
else
	sendToLog "Status: Current GUI user name is \"$currentUserNAME\"."
fi
if [[ "$currentUserNAME" != "FALSE" ]]; then
	currentUserUID=$(id -u "$currentUserNAME" 2> /dev/null)
	currentUserGUID=$(dscl . read "/Users/$currentUserNAME" GeneratedUID 2> /dev/null | awk '{print $2;}')
	currentUserRealNAME=$(dscl . read "/Users/$currentUserNAME" RealName 2> /dev/null | tail -1 | sed -e 's/RealName: //g' | xargs)
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserUID is: $currentUserUID"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserGUID is: $currentUserGUID"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserRealNAME is: $currentUserRealNAME"
	if [[ -n $currentUserUID ]] && [[ -n $currentUserGUID ]] && [[ -n $currentUserRealNAME ]]; then
		if [[ $(groups "$currentUserNAME" 2> /dev/null | grep -c 'admin') -gt 0 ]]; then
			currentUserADMIN="TRUE"
		else
			currentUserADMIN="FALSE"
		fi
		if [[ $(dscl . read "/Users/$currentUserNAME" AuthenticationAuthority 2> /dev/null | grep -c 'SecureToken') -gt 0 ]]; then
			currentUserSecureTOKEN="TRUE"
		else
			currentUserSecureTOKEN="FALSE"
		fi
		if [[ $(diskutil apfs listcryptousers / 2> /dev/null | grep -c "$currentUserGUID") -gt 0 ]]; then
			currentUserVolumeOWNER="TRUE"
		else
			currentUserVolumeOWNER="FALSE"
		fi
		[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserADMIN is: $currentUserADMIN"
		[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserSecureTOKEN is: $currentUserSecureTOKEN"
		[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentUserVolumeOWNER is: $currentUserVolumeOWNER"
	else
		sendToLog "Parameter Error: Unable to determine account details for user \"$currentUserNAME\"."; parameterERROR="TRUE"
	fi
fi
}

# Validate that the account $updateACCOUNT and $updateKEYCHAIN are valid credentials is a volume owner. If not set $accountERROR.
checkLocalUpdateAccount() {
accountGUID=$(dscl . read "/Users/$updateACCOUNT" GeneratedUID 2> /dev/null | awk '{print $2;}')
if [[ -n $accountGUID ]]; then
	if ! [[ $(diskutil apfs listcryptousers / | grep -c "$accountGUID") -gt 0 ]]; then
		sendToLog "Error: Provided account \"$updateACCOUNT\" is not a system volume owner."; accountERROR="TRUE"
	fi
	accountVALID=$(dscl /Local/Default -authonly "$updateACCOUNT" "$updateKEYCHAIN" 2>&1)
	if ! [[ "$accountVALID" == "" ]];then
		sendToLog "Error: The provided password for account \"$updateACCOUNT\" is not valid."; accountERROR="TRUE"
	fi
else
	sendToLog "Error: Could not retrieve GUID for account \"$updateACCOUNT\". Verify that account exists locally."; accountERROR="TRUE"
fi
}

# Collect the available free storage and set $storageREADY accordingly. This also sets $availableStorageGB and $requiredStorageGB.
checkAvailableStorage() {
storageREADY="FALSE"
[[ -z $currentUserNAME ]] && checkCurrentUser
[[ "$currentUserNAME" != "FALSE" ]] && availableStorageGB=$(osascript -l 'JavaScript' -e "ObjC.import('Foundation'); var freeSpaceBytesRef=Ref(); $.NSURL.fileURLWithPath('/').getResourceValueForKeyError(freeSpaceBytesRef, 'NSURLVolumeAvailableCapacityForImportantUsageKey', null); Math.round(ObjC.unwrap(freeSpaceBytesRef[0]) / 1000000000)")
[[ "$currentUserNAME" == "FALSE" ]] && availableStorageGB=$(/usr/libexec/mdmclient QueryDeviceInformation 2> /dev/null | grep AvailableDeviceCapacity | head -n 1 | awk '{print $3}' | sed -e 's/;//g' -e 's/"//g' -e 's/\.[0-9]*//g')
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: availableStorageGB: $availableStorageGB"
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSUpgradeVersionTARGET: $macOSUpgradeVersionTARGET"
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: softwareUpdateMACOS: $softwareUpdateMACOS"
if [[ -z $availableStorageGB ]] || [[ ! $availableStorageGB =~ $regexNUMBER ]]; then
	if [[ "$installNowOPTION" == "TRUE" ]]; then
		sendToLog "Error: Unable to determine available free storage, install now workflow can not continue."
		sendToStatus "Inactive Error: Unable to determine available free storage, install now workflow can not continue."
		notifyInstallNowFailure
		errorExit
	else
		deferSECONDS="$errorDeferSECONDS"
		sendToLog "Error: Unable to determine available free storage, trying again in $deferSECONDS seconds."
		sendToStatus "Pending: Unable to determine available free storage, trying again in $deferSECONDS seconds."
		makeLaunchDaemonCalendar
	fi
elif [[ "$macOSUpgradeVersionTARGET" != "FALSE" ]] || [[ "$softwareUpdateMACOS" == "TRUE" ]]; then
	{ [[ -z $freeSpaceUpdateOPTION ]] && [[ $macOSSoftwareUpdateGB -gt 5 ]]; } && freeSpaceUpdateGB=$((macOSSoftwareUpdateGB*2))
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSInstallerDownloadREQUIRED: $macOSInstallerDownloadREQUIRED"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSSoftwareUpdateDownloadREQUIRED: $macOSSoftwareUpdateDownloadREQUIRED"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: freeSpaceUpgradeGB: $freeSpaceUpgradeGB"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSSoftwareUpgradeGB: $macOSSoftwareUpgradeGB"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSInstallerGB: $macOSInstallerGB"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: freeSpaceUpdateGB: $freeSpaceUpdateGB"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macOSSoftwareUpdateGB: $macOSSoftwareUpdateGB"
	if [[ "$macOSUpgradeVersionTARGET" != "FALSE" ]]; then # A macOS upgrade is available and option to allow upgrade is enabled.
		if [[ "$upgradeWORKFLOW" == "LOCAL" ]] || [[ "$upgradeWORKFLOW" == "USER" ]]; then
			if [[ $macOSVERSION -ge 1203 ]]; then # macOS 12.3 or newer upgrade via softwareupdate.
				if [[ "$macOSSoftwareUpdateDownloadREQUIRED" == "TRUE" ]]; then
					requiredStorageGB=$((freeSpaceUpgradeGB+macOSSoftwareUpgradeGB))
				else # Download calculation is not required.
					requiredStorageGB=$freeSpaceUpgradeGB
				fi
			else # Systems older than macOS 12.3 upgrade via installer.
				if [[ "$macOSInstallerDownloadREQUIRED" == "TRUE" ]]; then
					requiredStorageGB=$((freeSpaceUpgradeGB+macOSInstallerGB))
				else # Download calculation is not required.
					requiredStorageGB=$freeSpaceUpgradeGB
				fi
			fi
		elif [[ "$upgradeWORKFLOW" == "JAMF" ]]; then # MDM upgrade workflow via installer.
			if [[ "$macOSInstallerDownloadREQUIRED" == "TRUE" ]]; then
				requiredStorageGB=$((freeSpaceUpgradeGB+macOSInstallerGB))
			else # Download calculation is not required.
				requiredStorageGB=$freeSpaceUpgradeGB
			fi
		fi
	else # macOS updates are available.
		if [[ "$macOSSoftwareUpdateDownloadREQUIRED" == "TRUE" ]]; then
			requiredStorageGB=$((freeSpaceUpdateGB+macOSSoftwareUpdateGB))
		else # Download calculation is not required.
			requiredStorageGB=$freeSpaceUpdateGB
		fi
	fi
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: requiredStorageGB: $requiredStorageGB"
	[[ $availableStorageGB -ge $requiredStorageGB ]] && storageREADY="TRUE"
else # No macOS update/upgrade is available.
	storageREADY="TRUE"
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: storageREADY: $storageREADY"
}

# Validate if current system power is adequate for performing a macOS update/upgrade and set $powerREADY accordingly. Desktops, obviously, always return that they are ready.
checkAvailablePower() {
powerREADY="FALSE"
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: macBOOK: $macBOOK"
if [[ "$macBOOK" == "TRUE" ]]; then
	[[ $(pmset -g ps | grep -ic 'AC Power') -ne 0 ]] && acPOWER="TRUE"
	[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: acPOWER: $acPOWER"
	if [[ "$acPOWER" == "TRUE" ]]; then
		powerREADY="TRUE"
	else # Not plugged into AC power.
		currentBatteryLEVEL=$(pmset -g ps | grep '%' | awk '{print $3}' | sed -e 's/%;//g')
		[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: currentBatteryLEVEL: $currentBatteryLEVEL"
		if [[ -z $currentBatteryLEVEL ]] || [[ ! $currentBatteryLEVEL =~ $regexNUMBER ]]; then
			if [[ "$installNowOPTION" == "TRUE" ]]; then
				sendToLog "Error: Unable to determine battery power level, install now workflow can not continue."
				sendToStatus "Inactive Error: Unable to determine battery power level, install now workflow can not continue."
				notifyInstallNowFailure
				errorExit
			else
				deferSECONDS="$errorDeferSECONDS"
				sendToLog "Error: Unable to determine battery power level, trying again in $deferSECONDS seconds."
				sendToStatus "Pending: Unable to determine available free storage, trying again in $deferSECONDS seconds."
				makeLaunchDaemonCalendar
			fi
		else # Battery level is a real number.
			[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: batteryLevelPERCENT: $batteryLevelPERCENT"
			[[ $currentBatteryLEVEL -gt $batteryLevelPERCENT ]] && powerREADY="TRUE"
		fi
	fi
else # Mac desktop.
	powerREADY="TRUE"
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: powerREADY: $powerREADY"
}

# Validate the computer's MDM service status and set $mdmENROLLED, $mdmDEP, and $mdmSERVICE
checkMDMService() {
mdmENROLLED="FALSE"
mdmDEP="FALSE"
mdmSERVICE="FALSE"
profilesRESULT=$(profiles status -type enrollment 2>&1)
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: profilesRESULT:\n$profilesRESULT"
if [[ $(echo "$profilesRESULT" | grep -c 'MDM server') -gt 0 ]]; then
	mdmENROLLED="TRUE"
	[[ $(echo "$profilesRESULT" | grep 'Enrolled via DEP:' | grep -c 'Yes') -gt 0 ]] && mdmDEP="TRUE"
	mdmSERVICE="https://$(echo "$profilesRESULT" | grep 'MDM server' | awk -F '/' '{print $3}')"
	curlRESULT=$(curl -Is "$mdmSERVICE" | head -n 1)
	if [[ $(echo "$curlRESULT" | grep -c 'HTTP') -gt 0 ]] && [[ $(echo "$curlRESULT" | grep -c -e '400' -e '40[4-9]' -e '4[1-9][0-9]' -e '5[0-9][0-9]') -eq 0 ]]; then
		sendToLog "Status: MDM service is currently available at: $mdmSERVICE"
	else
		sendToLog "Warning: MDM service at $mdmSERVICE is currently unavailable with stauts: $curlRESULT"
		mdmSERVICE="FALSE"
	fi
else
	sendToLog "Warning: System is not enrolled with a MDM service."
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: mdmENROLLED: $mdmENROLLED"
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: mdmDEP: $mdmDEP"
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: mdmSERVICE: $mdmSERVICE"
}

# Validate that the computer's bootstrap token is properly escrowed and set $bootstrapTOKEN.
checkBootstrapToken() {
bootstrapTOKEN="FALSE"
profilesRESULT=$(profiles status -type bootstraptoken 2>&1)
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: profilesRESULT:\n$profilesRESULT"
if [[ $(echo "$profilesRESULT" | grep -c 'YES') -eq 2 ]]; then
	if [[ "$macOSVERSION" -ge 1303 ]]; then
		if [[ "$checkBootstrapTokenSERVICE" != "FALSE" ]]; then
			queryDeviceINFO=$(/usr/libexec/mdmclient QueryDeviceInformation 2> /dev/null | grep 'EACSPreflight' | sed -e 's/        EACSPreflight = //g' -e 's/"//g' -e 's/;//g')
			if [[ $(echo "$queryDeviceINFO" | grep -c 'success') -gt 0 ]] || [[ $(echo "$queryDeviceINFO" | grep -c 'EFI password exists') -gt 0 ]]; then
				sendToLog "Status: Bootstrap token escrowed and validated with MDM service."
				bootstrapTOKEN="TRUE"
			else
				sendToLog "Warning: Bootstrap token escrow validation failed with status: $queryDeviceINFO"
			fi
		else
			sendToLog "Warning: Bootstrap token was previously escrowed with MDM service but the service is currently unavailable so it can not be validated."
		fi
	else
		sendToLog "Status: Bootstrap token escrowed with MDM service."
		bootstrapTOKEN="TRUE"
	fi
else
	sendToLog "Warning: Bootstrap token is not escrowed with MDM service."
fi
[[ "$verboseModeOPTION" == "TRUE" ]] && sendToLog "Verbose Mode: Function ${FUNCNAME[0]}: bootstrapTOKEN: $bootstrapTOKEN"
}

# MARK: *** Main Workflow ***
################################################################################

mainWorkflow() {
# Initial super workflow preparations.
/bin/sleep 10
checkRoot
setDefaults
superStartup "$@"
getOptions "$@"
superInstallation
}

mainWorkflow "$@"
#cleanExit
