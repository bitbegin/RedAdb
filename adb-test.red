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
	adb/test
]
