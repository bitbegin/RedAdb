Red []

#system [
	#include %adb-driver.reds
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
	get-max-adbs: routine [return: [integer!]][
		max-adbs
	]

	init: routine [return: [integer!]][
		init-device
	]

	close: routine [
		/local
			adb-handle	[adb-info-struct]
			index		[integer!]
	][
		index: max-adbs
		while [index > 0][
			adb-handle: get-adb-handle index
			close-device adb-handle
			index: index - 1
		]
		max-adbs: 0
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

	int-to-buffer: routine [int [integer!] return: [binary!]
	][
		int-to-bin int
	]



]
