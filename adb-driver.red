Red []

#system [
	#include %adb-windows.reds
	int-to-bin*: func [int [integer!] return: [red-binary!]
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

	bin-to-int: func [id [string!]][
		(to integer! id/1) or
		(shift/left to integer! id/2 8) or
		(shift/left to integer! id/3 16) or
		(shift/left to integer! id/4 24)
	]

	A_SYNC: bin-to-int "SYNC"
	A_CNXN: bin-to-int "CNXN"
	A_OPEN: bin-to-int "OPEN"
	A_OKAY: bin-to-int "OKAY"
	A_CLSE: bin-to-int "CLSE"
	A_WRTE: bin-to-int "WRTE"
	A_VERSION: bin-to-int "^@^@^@^A"		;#{01000000}

	ID_STAT: bin-to-int "STAT"
	ID_LIST: bin-to-int "LIST"
	ID_ULNK: bin-to-int "ULNK"
	ID_SEND: bin-to-int "SEND"
	ID_RECV: bin-to-int "RECV"
	ID_DENT: bin-to-int "DENT"
	ID_DONE: bin-to-int "DONE"
	ID_DATA: bin-to-int "DATA"
	ID_OKAY: bin-to-int "OKAY"
	ID_FAIL: bin-to-int "FAIL"
	ID_QUIT: bin-to-int "QUIT"

	PACKET_SIZE:						1024 * 64
	MAX_PAYLOAD:						4096

	adb-mode: no
	msg: make binary! 4 * 6					;to save memory
	pkg: make binary! MAX_PAYLOAD			;to save memory

	get-adbs: routine [return: [integer!]][
		adbs
	]

	get-local-id: routine [
		adb [integer!]
		return: [integer!]
	][
		get-local-id* adb
	]

	get-remote-id: routine [
		adb [integer!]
		return: [integer!]
	][
		get-remote-id* adb
	]

	set-local-id: routine [
		adb [integer!]
		local-id [integer!]
	][
		set-local-id* adb local-id
	]

	set-remote-id: routine [
		adb [integer!]
		remote-id [integer!]
	][
		set-remote-id* adb remote-id
	]

	get-error: routine [return: [string!]
		/local
			text [c-string!]
	][
		text: get-error-msg*
		string/load text length? text UTF-16LE
	]

	get-adb-error: routine [return: [string!]
		/local
			text [c-string!]
	][
		text: parse-adb-result*
		string/load text length? text UTF-8
	]

	int-to-bin: routine [int [integer!] return: [binary!]
	][
		int-to-bin* int
	]

	format-message: func [
		blk			[block!]
		;command 	[integer!]			;-- command identifier constant
		;arg0		[integer!]			;-- first argument
		;arg1		[integer!]			;-- second argument
		;data-length	[integer!]			;-- length of payload (0 is allowed)
		;data-crc32	[integer!]			;-- crc32 of data payload
		;magic		[integer!]			;-- command ^ 0xffffffff
		return: 	[binary!]
	][
		foreach i blk [
			append msg int-to-bin i
		]
		msg
	]

	init-device: routine [return: [integer!]][
		init-device*
	]

	close-device: routine [
		adb		 		[integer!]
	][
		close-device* adb
	]

	close-devices: routine [
		/local
			adb		[integer!]
	][
		adb: adbs
		while [adb > 0][
			close-device* adb
			adb: adb - 1
		]
		adbs: 0
	]

	pipe-raw: routine [
		adb-index 		[integer!]
		data			[string!]
		write			[logic!]
		return: 		[integer!]
	][
		pipe* adb-index data write
	]

	pipe: func [
		adb		 		[integer!]
		data			[string! binary!]
		return: 		[integer!]
		/write /read
	][
		either write [
			pipe-raw adb to string! data yes
		][
			pipe-raw adb to string! data no
		]
	]

	read: func [
		adb			[integer!]
		data		[string! binary!]
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
		if usb-mode [close-devices]
	]

	receive-message: func [
		adb			[integer!]
		cmd			[string! block!]
		return:		[string!]
		/authed
		/local
			recv-cmd		[string!]
			msg				[string!]
			data			[string!]
	][
		until [
			read adb pkg
			recv-cmd: either pkg/1 = null [clear pkg][
				if cmd = "ALL" [return pkg]
				copy/part pkg 4
			]
			find cmd recv-cmd
		]

		switch/default recv-cmd [
			"AUTH" [
				;-- we no rsa function in red, so TBC
			]
			"OKAY" [
				set-remote-id adb bin-to-int skip pkg 4				;arg0
			]
			"CNXN" [
				if positive? bin-to-int skip pkg 12 [				;data-length
					data: receive-message adb "ALL"
				]
			]
			"WRTE" [
				pkg: receive-message adb "ALL"
				send-message adb A_OKAY ""
			]
			"CLSE" [
				send-message adb A_CLSE ""
			]
		][pkg]
		pkg
	]

	send-message: func [
		adb			[integer!]
		cmd			[integer!]
		data		[string! binary!]
		/authed
		/local len sum msg magic arg0
	][
		if binary? data [data: to string! data]
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
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd get-local-id get-remote-id len sum magic]
			]
		]
		write adb format-message reduce msg
		unless empty? data [write adb data]
		if cmd = A_WRTE [
			if empty? receive-message adb "OKAY" [
				close-device adb
			]
		]
	]
]
