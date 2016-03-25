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

	adb-mode: no

	get-adbs: routine [return: [integer!]][
		adbs
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





]
