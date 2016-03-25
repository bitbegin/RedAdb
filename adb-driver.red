Red []

#system [
	#include %adb-windows.reds
	int-to-bin: func [int [integer!] return: [red-binary!]
		/local
			bin [red-binary!]
			b   [red-binary!]
			p	[int-ptr!]
			s	[series!]
	][
		bin: as red-binary! stack/arguments
		b: binary/make-at as cell! bin 4
		s: GET_BUFFER(b)
		p: as int-ptr! s/tail
		p/1: int
		s/tail: as cell! p + 1
		b
	]
]

adb-driver: context [

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

	#define AUTH_TOKEN						1
	#define AUTH_SIGNATURE					2
	#define AUTH_RSAPUBLICKEY				3

	#define PACKET_SIZE						1024 * 64
	#define MAX_PAYLOAD						4096

	adb-mode: no
	msg: make binary! 4 * 6					;to save memory

	get-adbs: routine [return: [integer!]][
		adbs
	]

	get-local-id: routine [
		adb [integer!]
		return: [integer!]
	][
		get-local-id adb
	]

	get-remote-id: routine [
		adb [integer!]
		return: [integer!]
	][
		get-remote-id adb
	]

	get-error: routine [return: [string!]
		/local
			text [c-string!]
	][
		text: get-error-msg
		string/load text length? text UTF-16LE
	]

	get-adb-error: routine [return: [string!]
		/local
			text [c-string!]
	][
		text: parse-adb-result
		string/load text length? text UTF-8
	]

	int-to-bin: routine [int [integer!] return: [binary!]
	][
		int-to-bin int
	]

	format-message: func [
		command 	[integer!]			;-- command identifier constant
		arg0		[integer!]			;-- first argument
		arg1		[integer!]			;-- second argument
		data-length	[integer!]			;-- length of payload (0 is allowed)
		data-crc32	[integer!]			;-- crc32 of data payload
		magic		[integer!]			;-- command ^ 0xffffffff
		return: 	[binary!]
	][
		bin: make binary! 4 * 6
		append msg int-to-bin command
		append msg int-to-bin arg0
		append msg int-to-bin arg1
		append msg int-to-bin data-length
		append msg int-to-bin data-crc32
		append msg int-to-bin magic
		bin
	]

	init-device: routine [return: [integer!]][
		init-device
	]

	close-device: routine [
		/local
			adb			[adb-info-struct]
			index		[integer!]
	][
		index: adbs
		while [index > 0][
			adb: get-adb-handle index
			close-device adb
			index: index - 1
		]
		adbs: 0
	]

	pipo: routine [
		adb-index 		[integer!]
		data			[string!]
		return: 		[integer!]
		/write /read
	][
		either write [
			pipo adb-index data 1
		][
			pipo adb-index data 0
		]
	]

	read: func [
		adb			[integer!]
		data		[string!]
	][
		either adb-mode [
			pipe/read adb data
		][
			;-- TCP mode
		]
	]

	write: func [
		adb			[integer!]
		data		[string! binary!]
	][
		either adb-mode [
			pipe/write adb data
		][
			;-- TCP mode
		]
	]

	;; higher level
	init: func [return: [integer!]
		/local
			ret		[integer!]
	][
		if ret: init-device [usb-mode: yes return ret]
	]

	close: func [][
		if usb-mode [close-device]
	]

	send-message: func [
		adb			[integer!]
		cmd			[integer!]
		data		[string! binary!]
		/authed
		/local len sum msg magic arg0
	][
		if binary? data [data: to-string data]
		magic: cmd xor -1
		len: length? data
		sum: 0
		foreach c data [sum: sum + (to integer! c)]
		case [
			cmd = A_CNXN [
				msg: [cmd A_VERSION MAX_PAYLOAD len sum magic]
			]
			cmd = A_OPEN [
				msg: [cmd get-local-id adb 0 len sum magic]
			]
			cmd = A_CLSE [
				msg: [cmd 0 get-remote-id adb len sum magic]
			]
			cmd = A_AUTH [
				arg0: either authed [AUTH_RSAPUBLICKEY][AUTH_SIGNATURE]
				msg: [cmd arg0 0 len sum magic]
			]
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd get-local-id get-remote-id len sum magic]
			]
		]
		write adb format-message reduce msg
		unless empty? data [write adb data]
		;if cmd = A_WRTE [
		;	if empty? receive-message device "OKAY" [
		;		print "**ADB**: Error: Send message failed"
		;		print ["message: " copy/part data 4]
		;		close-device device
		;		halt
		;	]
		;]
	]



]
