#!/bin/bash

######################
#Editable variables

#Jamf credentials
apiusername="$4"
apipassword="$5"
defaultLAPSCryptKey="$6"
defaultLAPSSecret="$7"
defaultLAPSencrypted=$(echo "$defaultLAPSCryptKey" | openssl enc -aes-256-cbc -md sha512 -a -salt -pass pass:"$defaultLAPSSecret")

jamfServer=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
jamfProID=$(defaults read "/Library/Managed Preferences/com.macjutsu.super" JamfProID)
echo "JamfProID = $jamfProID"

#Computer Extension Attribute number -- found in URL on group's page
extLAPSCryptKey="LAPS CryptKey"
extLAPSSecret="LAPS Secret"

udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')

######################

#Token function -- based on https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview
getBearerToken() {
	response=$(curl -X POST -u "$apiusername:$apipassword" -s "${jamfServer}api/v1/auth/token")
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

#get token
getBearerToken

echo "bearer = $bearerToken"

extAttName="$extLAPSCryptKey"
echo "ext name = $extAttName"

# Read LAPS CryptKey to see if already filled with a password
extensionATTRIBUTE=$(curl --silent --request GET --url ${jamfServer}JSSResource/computers/id/$jamfProID/subset/extension_attributes --header "Authorization: Bearer $bearerToken" --header 'Accept: application/xml' | xpath -e "//extension_attribute[name='$extAttName']" 2>&1 | awk -F'<value>|</value>' '{print $2}' )

echo "ext attr = $extensionATTRIBUTE"

if [ "$extensionATTRIBUTE" = "" ]; then
	echo "empty - generating extension attribute contents"
	xmlstringOne="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer><extension_attributes><extension_attribute><name>LAPS CryptKey</name><value>$defaultLAPSencrypted</value></extension_attribute></extension_attributes></computer>"
	xmlstringTwo="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer><extension_attributes><extension_attribute><name>LAPS Secret</name><value>$defaultLAPSSecret</value></extension_attribute></extension_attributes></computer>"

	echo "xml one = $xmlstringOne"
	echo "xml two = $xmlstringTwo"
	extensionRESULT=$(curl --silent --header "Authorization: Bearer $bearerToken" --request PUT -H "Content-Type: text/xml" -d "${xmlstringOne}" "${jamfServer}JSSResource/computers/udid/$udid")
	echo "ext Result = $extensionRESULT"
	extensionRESULT=$(curl --silent --header "Authorization: Bearer $bearerToken" --request PUT -H "Content-Type: text/xml" -d "${xmlstringTwo}" "${jamfServer}JSSResource/computers/udid/$udid")
	echo "ext Result = $extensionRESULT"
else
	echo "already filled"
fi
