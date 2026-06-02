set deviceName to "AirPods"
set blueutil to "/opt/homebrew/bin/blueutil"
set deviceAddress to do shell script blueutil & " --paired --format json | /opt/homebrew/bin/jq -r '.[] | select(.name == \"" & deviceName & "\") | .address'"

if deviceAddress is "" then
	display alert deviceName message "Device not paired" giving up after 2
	return
end if

set isConnected to do shell script blueutil & " --is-connected " & quoted form of deviceAddress
if isConnected is "1" then
	display alert deviceName message deviceName & " connected" giving up after 1
	return
end if

do shell script blueutil & " --connect " & quoted form of deviceAddress & " --wait-connect " & quoted form of deviceAddress & " 5"
display alert deviceName message deviceName & " connected" giving up after 1
