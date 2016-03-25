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

adb: context [

	str-to-int: func [id [string!]][
		(to integer! id/1) or
		(shift/left to integer! id/2 8) or
		(shift/left to integer! id/3 16) or
		(shift/left to integer! id/4 24)
	]

	A_SYNC: str-to-int "SYNC"
	A_CNXN: str-to-int "CNXN"
	A_OPEN: str-to-int "OPEN"
	A_OKAY: str-to-int "OKAY"
	A_CLSE: str-to-int "CLSE"
	A_WRTE: str-to-int "WRTE"
	A_VERSION: str-to-int "^@^@^@^A"		;#{01000000}

	ID_STAT: str-to-int "STAT"
	ID_LIST: str-to-int "LIST"
	ID_ULNK: str-to-int "ULNK"
	ID_SEND: str-to-int "SEND"
	ID_RECV: str-to-int "RECV"
	ID_DENT: str-to-int "DENT"
	ID_DONE: str-to-int "DONE"
	ID_DATA: str-to-int "DATA"
	ID_OKAY: str-to-int "OKAY"
	ID_FAIL: str-to-int "FAIL"
	ID_QUIT: str-to-int "QUIT"

	PACKET_SIZE:							1024 * 64
	MAX_PAYLOAD:							4096

	adb-mode: no
	msg: make binary! 4 * 6					;to save memory
	pkg: make binary! MAX_PAYLOAD			;to save memory

	get-adbs: routine [return: [integer!]][
		adbs
	]

	get-local-id: routine [
		iadb [integer!]
		return: [integer!]
	][
		get-local-id* iadb
	]

	get-remote-id: routine [
		iadb [integer!]
		return: [integer!]
	][
		get-remote-id* iadb
	]

	set-local-id: routine [
		iadb [integer!]
		local-id [integer!]
	][
		set-local-id* iadb local-id
	]

	set-remote-id: routine [
		iadb [integer!]
		remote-id [integer!]
	][
		set-remote-id* iadb remote-id
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

	init-adb: routine [return: [integer!]][
		init-adb*
	]

	close-adb: routine [
		adb		 		[integer!]
	][
		close-adb* adb
	]

	close-adbs: routine [
		/local
			iadb		[integer!]
	][
		iadb: adbs
		while [iadb > 0][
			close-adb* iadb
			iadb: iadb - 1
		]
		adbs: 0
	]

	pipe-raw: routine [
		iadb	 		[integer!]
		data			[string!]
		write			[logic!]
		return: 		[integer!]
	][
		pipe* iadb data write
	]

	pipe: func [
		iadb		 	[integer!]
		data			[string! binary!]
		return: 		[integer!]
		/write /read
	][
		either write [
			pipe-raw iadb to string! data yes
		][
			pipe-raw iadb to string! data no
		]
	]

	read: func [
		iadb		[integer!]
		data		[string! binary!]
	][
		either adb-mode [
			pipe/read iadb data
		][
			;-- TCP mode
		]
	]

	write: func [
		iadb		[integer!]
		data		[string! binary!]
	][
		either adb-mode [
			pipe/write iadb data
		][
			;-- TCP mode
		]
	]

	;; higher level
	init: func [return: [integer!]
		/local
			ret		[integer!]
	][
		if ret: init-adb [adb-mode: yes return ret]
	]

	close: func [][
		if adb-mode [close-adbs]
	]

	receive-message: func [
		iadb		[integer!]
		cmd			[string! block!]
		return:		[string!]
		/authed
		/local
			recv-cmd		[string!]
			msg				[string!]
			data			[string!]
	][
		until [
			read iadb pkg
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
				set-remote-id iadb str-to-int skip pkg 4				;arg0
			]
			"CNXN" [
				if positive? str-to-int skip pkg 12 [				;data-length
					data: receive-message iadb "ALL"
				]
			]
			"WRTE" [
				pkg: receive-message iadb "ALL"
				send-message iadb A_OKAY ""
			]
			"CLSE" [
				send-message iadb A_CLSE ""
			]
		][pkg]
		pkg
	]

	send-message: func [
		iadb		[integer!]
		cmd			[integer!]
		data		[string! binary!]
		/local
			len		[integer!]
			sum		[integer!]
			msg		[block!]
			magic	[integer!]
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
				msg: [cmd get-local-id iadb 0 len sum magic]
			]
			cmd = A_CLSE [
				msg: [cmd 0 get-remote-id iadb len sum magic]
			]
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd get-local-id iadb get-remote-id iadb len sum magic]
			]
		]
		write iadb format-message reduce msg
		unless empty? data [write iadb data]
		if cmd = A_WRTE [
			if empty? receive-message iadb "OKAY" [
				close-adb iadb
			]
		]
	]
]
