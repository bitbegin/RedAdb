Red []

#include %adb-driver.red

adb: context [

	MKID: func [id [string!]][
		(to integer! id/1) or
		(shift/left to integer! id/2 8) or
		(shift/left to integer! id/3 16) or
		(shift/left to integer! id/4 24)
	]

	A_SYNC: MKID "SYNC"
	A_CNXN: MKID "CNXN"
	A_OPEN: MKID "OPEN"
	A_OKAY: MKID "OKAY"
	A_CLSE: MKID "CLSE"
	A_WRTE: MKID "WRTE"
	A_VERSION: MKID "^@^@^@^A"		;#{01000000}

	ID_STAT: MKID "STAT"
	ID_LIST: MKID "LIST"
	ID_ULNK: MKID "ULNK"
	ID_SEND: MKID "SEND"
	ID_RECV: MKID "RECV"
	ID_DENT: MKID "DENT"
	ID_DONE: MKID "DONE"
	ID_DATA: MKID "DATA"
	ID_OKAY: MKID "OKAY"
	ID_FAIL: MKID "FAIL"
	ID_QUIT: MKID "QUIT"


	adbs: 0 ;make block! adb-driver/get-max-adbs
	adb-name: make string! 100
	usb-mode: no

	init: func [return: [integer!]][
		adb-driver/init
	]
	close: func [][
		adb-driver/close
	]
	get-name: func [adb [integer!] return: [string!]][

	]
	select: func [adb [integer!]][

	]

	receive-message: func [
		adb			[integer!]
		cmd			[string!]
	][
		either usb-mode [
			;usb/receive-message device cmd
		][
			;-- TCP mode
		]
	]

	send-message: func [
		adb			[integer!]
		cmd			[integer!]
		data		[string! binary!]
	][
		either usb-mode [
			;usb/send-message device cmd data
		][
			;-- TCP mode
		]
	]

	modified-time?: func [file-path /local date][]
	file-size?: func [file-path /local size unit][]

	get-device-name: func [data [string!]][
		attempt [
			data: parse data ";"
			data: parse data/1 "="
			data/2
		]
	]

	push: func [
		adb			[integer!]
		apk-path	[file!]
	][]

	install: func [
		adb			[integer!]
		apk-path	[file!]
	][]
]

; test
result: adb/init
either result <> 0 [
	print ["adb init code: " result]
	print ["adb init error: " adb-driver/get-adb-error]
	print ["last system error: " adb-driver/get-error]
][
	print ["has " adb-driver/get-max-adbs " adb devices" ]
]
