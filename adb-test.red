Red []

#include %adb.red

; test
result: adb/init
either result <> 0 [
	print ["adb init code: " result]
	print ["adb init error: " adb/get-adb-error]
	print ["last system error: " adb/get-error]
][
	print ["has " adb/get-adbs " adb devices" ]
	if adb/get-adbs <> 0 [
		print "adb test"
		adb/send-message 0 adb/A_CNXN "host::^@"
		print "send msg"
		adb/receive-message 0 ["AUTH" "CNXN"]
		print "recived msg"
	]
]
