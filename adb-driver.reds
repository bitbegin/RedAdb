Red/System []

#define handle!								int-ptr!

#define FORMAT_MESSAGE_FROM_SYSTEM			00001000h
#define FORMAT_MESSAGE_IGNORE_INSERTS		00000200h

#define DIGCF_DEFAULT						00000001h
#define DIGCF_PRESENT						00000002h
#define DIGCF_ALLCLASSES					00000004h
#define DIGCF_PROFILE						00000008h
#define DIGCF_DEVICEINTERFACE				00000010h

#define GENERIC_READ						80000000h
#define GENERIC_WRITE						40000000h
#define GENERIC_EXECUTE						20000000h
#define GENERIC_ALL							10000000h

#define FILE_SHARE_READ						00000001h
#define FILE_SHARE_WRITE					00000002h

#define FILE_FLAG_OVERLAPPED				40000000h

#define PIPE_TRANSFER_TIMEOUT				03h
#define USB_ENDPOINT_DIRECTION_MASK			80h

#define CREATE_NEW							1
#define CREATE_ALWAYS						2
#define OPEN_EXISTING						3


pipe-info-struct: alias struct! [
	pipeType								[integer!]
	pipeID									[byte!]
	maxPackSize								[integer!]
	;interval								[byte!]
]

dev-info-data: alias struct! [
	cbSize									[integer!]
	ClassGuid								[integer!]
	pad1									[integer!]
	pad2									[integer!]
	pad3									[integer!]
	DevInst									[integer!]
	reserved								[integer!]
]

dev-interface-data: alias struct! [
	cbSize									[integer!]
	ClassGuid								[integer!]
	pad1									[integer!]
	pad2									[integer!]
	pad3									[integer!]
	Flags									[integer!]
	reserved								[integer!]
]

dev-interface-detail: alias struct! [
	cbSize									[integer!]
	DevicePath								[c-string!]
]

overlapped-struct: alias struct! [
	Internal	 							[integer!]
	InternalHigh 							[integer!]
	Offset		 							[integer!]
	OffsetHight  							[integer!]
	hEvent		 							[integer!]
]

guid-struct: alias struct! [
	data1									[integer!]
	data2									[integer!]
	data3									[integer!]
	data4									[integer!]
]

SECURITY_ATTRIBUTES: declare struct! [
	nLength				 					[integer!]
	lpSecurityDescriptor					[integer!]
	bInheritHandle							[integer!]
]

#import [
	"kernel32.dll" stdcall [
		CreateEvent: "CreateEventA" [
			lpEventAttributes				[integer!]
			bManualReset					[integer!]
			bInitialState					[integer!]
			lpName							[integer!]
			return:							[integer!]
		]
		CloseHandle: "CloseHandle" [
			hObject							[integer!]
			return: 						[integer!]
		]
		CreateFile: "CreateFileA" [
			lpFileName						[c-string!]
			dwDesiredAccess					[integer!]
			dwShareMode						[integer!]
			lpSecurityAttributes			[integer!]
			dwCreationDisposition			[integer!]
			dwFlagsAndAttributes			[integer!]
			hTemplateFile					[integer!]
			return:							[integer!]
		]
		GetLastError: "GetLastError" [
			return:							[integer!]
		]
		FormatMessage: "FormatMessageW" [
			dwFlags		 					[integer!]
			lpSource	 					[integer!]
			dwMessageId  					[integer!]
			dwLanguageId 					[integer!]
			lpBuffer	 					[c-string!]
			nSize		 					[integer!]
			Arguments	 					[integer!]
			return:		 					[integer!]
		]
	]
	"setupapi.dll" stdcall [
		SetupDiGetClassDevs: "SetupDiGetClassDevsA" [
			ClassGuid						[guid-struct]
			Enumerator						[integer!]
			hwndParent						[integer!]
			Flags							[integer!]
			return: 						[integer!]
		]
		SetupDiDestroyDeviceInfoList: "SetupDiDestroyDeviceInfoList" [
			handle							[integer!]
			return: 						[logic!]
		]
		SetupDiEnumDeviceInterfaces: "SetupDiEnumDeviceInterfaces" [
			DeviceInfoSet 					[integer!]
			DeviceInfoData					[integer!]
			InterfaceClassGuid				[guid-struct]
			MemberIndex						[integer!]
			DeviceInterfaceData				[dev-interface-data]
			return: 						[logic!]
		]
		SetupDiGetDeviceInterfaceDetail: "SetupDiGetDeviceInterfaceDetailA" [
			DeviceInfoSet 					[integer!]
			DeviceInterfaceData				[dev-interface-data]
			DeviceInterfaceDetailData		[c-string!]
			DeviceInterfaceDetailDataSize	[integer!]
			RequiredSize					[int-ptr!]
			DeviceInfoData					[integer!]
			return: 						[logic!]
		]
	]
	"winusb.dll" stdcall [
		WinUsb_Initialize: "WinUsb_Initialize" [
			DeviceHandle					[integer!]
			InterfaceHandle					[handle!]
			return:							[logic!]
		]
		WinUsb_Free: "WinUsb_Free" [
			InterfaceHandle					[integer!]
			return:							[logic!]
		]
		WinUsb_QueryPipe: "WinUsb_QueryPipe" [
			InterfaceHandle					[integer!]
			AlternateInterfaceNumber		[byte!]
			PipeIndex						[byte!]
			PipeInformation					[pipe-info-struct]
			return:							[logic!]
		]
		WinUsb_GetCurrentAlternateSetting: "WinUsb_GetCurrentAlternateSetting" [
			DeviceHandle					[integer!]
			AltSetting						[int-ptr!]
			return:							[logic!]
		]
		WinUsb_WritePipe: "WinUsb_WritePipe" [
			handle							[integer!]
			pipeID							[byte!]
			buffer							[c-string!]
			buf-len							[integer!]
			trans-len						[int-ptr!]
			overlapped						[overlapped-struct]
			return:							[logic!]
		]
		WinUsb_ReadPipe: "WinUsb_ReadPipe" [
			handle							[integer!]
			pipeID							[byte!]
			buffer							[c-string!]
			buf-len							[integer!]
			trans-len						[int-ptr!]
			overlapped						[overlapped-struct]
			return:							[logic!]
		]
		WinUsb_GetOverlappedResult: "WinUsb_GetOverlappedResult" [
			handle							[integer!]
			overlapped						[overlapped-struct]
			trans-len						[int-ptr!]
			wait?							[byte!]
			return:							[logic!]
		]
		WinUsb_SetPipePolicy: "WinUsb_SetPipePolicy" [
			handle							[integer!]
			pipeID							[byte!]
			policy							[integer!]
			value-len						[integer!]
			value							[int-ptr!]
			return:							[logic!]
		]
	]
]

;high level interface

#define UsbdPipeTypeControl					0
#define UsbdPipeTypeIsochronous				1
#define UsbdPipeTypeBulk		 			2
#define UsbdPipeTypeInterrupt	 			3

#define ERROR_NO_MORE_ITEMS					259

last-error: 0
last-adb-err: 0

#enum adb-err![
	ADB-GET-DEV-INFO-SET: 1
	ADB-NO-DEVS: 2
	ADB-OPEN-FAILED: 3
	ADB-INIT-FAILED: 4
	ADB-BUFF-OVER: 5
	ADB-WRITE-PIPO: 6
]

GUID: declare guid-struct
ANDROID_USB_CLASS_ID: declare guid-struct
ANDROID_USB_CLASS_ID: as guid-struct [
	F72FE0D4h
	407DCBCBh
	D69E1488h
	6BDDD073h
]

fmt-msg-flags: FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS

#define MAX-ADBS-ALLOWED	10

max-adbs: 0

adb-info-struct: alias struct! [
	device-set								[integer!]
	device									[integer!]
	interface								[integer!]
	read-id									[byte!]
	write-id								[byte!]
	local-id								[integer!]
	remote-id								[integer!]
	zero-mask								[integer!]
]

adb-array: allocate MAX-ADBS-ALLOWED * size? adb-info-struct
adb-ptr: as adb-info-struct adb-array

get-adb-handle: func [
	adb-index [integer!]
	return: [adb-info-struct]
][
	adb-ptr + adb-index
]

out: make-c-string 256
get-error-msg: func [return: [c-string!]][
	set-memory as byte-ptr! out as byte! 0 256
	FormatMessage fmt-msg-flags 0 last-error 0 out 256 0
	out
]

parse-adb-result: func [return: [c-string!]][
	set-memory as byte-ptr! out as byte! 0 256
	switch last-adb-err [
		0						[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Init Success!" 100]
		ADB-GET-DEV-INFO-SET	[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: Can not get device information set" 100]
		ADB-NO-DEVS				[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: No android devices" 100]
		ADB-OPEN-FAILED			[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: Can not open android device" 100]
		ADB-INIT-FAILED			[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: Can not initialize interface" 100]
		ADB-BUFF-OVER			[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: Buffer overflow" 100]
		ADB-WRITE-PIPO			[copy-memory as byte-ptr! out as byte-ptr! "**ADB**: Error: Write data failed" 100]
	]
	out
]

set-timeout: func [adb [adb-info-struct] seconds [integer!] /local time [int-ptr!] sec [integer!]][
	sec: seconds * 1000
	time: :sec
	WinUsb_SetPipePolicy adb/interface adb/read-id PIPE_TRANSFER_TIMEOUT 4 time
	WinUsb_SetPipePolicy adb/interface adb/write-id PIPE_TRANSFER_TIMEOUT 4 time
]

#define ADB-NAME-BUFFER-RAW-SIZE	510
#define ADB-NAME-BUFFER-SIZE		500
buffer: make-c-string ADB-NAME-BUFFER-RAW-SIZE
interface-name: make-c-string ADB-NAME-BUFFER-SIZE

init-device: func [return: [integer!]
	/local
		dev-info			[integer!]
		interface-data		[dev-interface-data]
		size-value			[integer!]
		required-size		[int-ptr!]
		dev-handle			[integer!]
		if-handle-value		[integer!]
		interface-handle	[int-ptr!]
		if-number-value		[integer!]
		interface-number	[int-ptr!]
		pipe-read			[byte!]
		pipe-write			[byte!]
		index				[integer!]
		if-num				[integer!]
		pipe-info			[pipe-info-struct]
		max-packet-size		[integer!]
		byte-p				[pointer! [byte!]]
		adb					[adb-info-struct]
][
	dev-info: SetupDiGetClassDevs ANDROID_USB_CLASS_ID 0 0 DIGCF_DEVICEINTERFACE or DIGCF_PRESENT
	if -1 = dev-info [
		last-error: GetLastError
		last-adb-err: ADB-GET-DEV-INFO-SET
		return last-adb-err
	]

	if-num: 0
	interface-data: declare dev-interface-data
	size-value: 0
	required-size: :size-value

	if-handle-value: 0
	interface-handle: :if-handle-value
	if-number-value: 0
	interface-number: :if-number-value
	pipe-info: declare pipe-info-struct
	until [
		interface-data/cbSize: size? dev-interface-data
		if false = SetupDiEnumDeviceInterfaces dev-info 0 ANDROID_USB_CLASS_ID if-num interface-data [
			last-error: GetLastError
			if ERROR_NO_MORE_ITEMS = last-error [
				max-adbs: if-num
				last-adb-err: 0
				return last-adb-err
			]
			SetupDiDestroyDeviceInfoList dev-info
			last-adb-err: ADB-NO-DEVS
			return last-adb-err
		]

		set-memory as byte-ptr! buffer as byte! 0 ADB-NAME-BUFFER-RAW-SIZE
		buffer/1: as byte! 5		;-- sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA)
		SetupDiGetDeviceInterfaceDetail dev-info interface-data as c-string! 0 0 required-size 0
		if size-value > ADB-NAME-BUFFER-SIZE [
			last-error: GetLastError
			last-adb-err: ADB-BUFF-OVER
			return last-adb-err
		]
		SetupDiGetDeviceInterfaceDetail dev-info interface-data buffer ADB-NAME-BUFFER-RAW-SIZE required-size 0
		copy-memory as byte-ptr! interface-name as byte-ptr! (buffer + 4) ADB-NAME-BUFFER-SIZE ;length? as c-string! (buffer + 4)
		print-line ["interface-name: " interface-name]
		dev-handle: CreateFile interface-name
						GENERIC_READ or GENERIC_WRITE
						FILE_SHARE_READ or FILE_SHARE_WRITE
						0 OPEN_EXISTING
						FILE_FLAG_OVERLAPPED 0
		if -1 = dev-handle [
			last-error: GetLastError
			SetupDiDestroyDeviceInfoList dev-info
			last-adb-err: ADB-OPEN-FAILED
			return last-adb-err
		]

		;;-- get interface handle
		if false = WinUsb_Initialize dev-handle interface-handle [
			last-error: GetLastError
			CloseHandle dev-handle
			SetupDiDestroyDeviceInfoList dev-info
			last-adb-err: ADB-INIT-FAILED
			return last-adb-err
		]

		;;-- get write pipe id & read pipe id
		WinUsb_GetCurrentAlternateSetting interface-handle/value interface-number

		index: 0
		while [index < 3][
			if false = WinUsb_QueryPipe
							interface-handle/value
							as byte! interface-number/value
							as byte! index
							pipe-info [break]
			if pipe-info/pipeType = UsbdPipeTypeBulk [
				either (as byte! 0) = (pipe-info/pipeID and as byte! USB_ENDPOINT_DIRECTION_MASK) [
					pipe-write: pipe-info/pipeID
					byte-p: declare pointer! [byte!]
					byte-p: as pointer! [byte!] pipe-info
					max-packet-size:  ((as integer! byte-p/6) << 8) + (as integer! byte-p/7)
				][
					pipe-read: pipe-info/pipeID
				]
			]
			index: index + 1
		]

		adb: get-adb-handle if-num
		adb/device-set: dev-info
		adb/device: dev-handle
		adb/interface: interface-handle/value
		adb/read-id: pipe-read
		adb/write-id: pipe-write
		adb/zero-mask: max-packet-size - 1
		set-timeout adb 1

		if-num: if-num + 1
		if-num >= MAX-ADBS-ALLOWED
	]

	max-adbs: if-num
	last-adb-err: 0
	return last-adb-err
]

close-device: func [adb [adb-info-struct]][
	if adb/interface = 0 [WinUsb_Free adb/interface]
	if adb/device = 0 [CloseHandle adb/device]
	if adb/device-set = 0 [SetupDiDestroyDeviceInfoList adb/device-set]
]

adb-pipe: func [
	adb		[adb-info-struct]
	data	[red-string!]
	write	[logic!]
	return: [integer!]
	/local
		s					[series!]
		ovlap				[overlapped-struct]
		interface 			[integer!]
		transferred			[int-ptr!]
		len					[integer!]
		num					[integer!]
		p					[c-string!]
][
	s: GET_BUFFER(data)
	p: as c-string! s/offset
	len: length? p

	interface: adb/interface
	ovlap: declare overlapped-struct
	ovlap/hEvent: CreateEvent 0 1 0 0
	num: 0
	transferred: :num
	either write [
		WinUsb_WritePipe interface adb/write-id p len transferred ovlap
		if all [
			positive? adb/zero-mask
			zero? (adb/zero-mask and len)
		][
			WinUsb_WritePipe interface adb/write-id "" 0 transferred ovlap
		]
	][
		WinUsb_ReadPipe interface adb/read-id p len transferred ovlap
	]

	WinUsb_GetOverlappedResult interface ovlap transferred as byte! 1
	if write [
		if transferred/1 <> len [
			unless zero? ovlap/hEvent [CloseHandle ovlap/hEvent]
			close-device adb
			last-adb-err: ADB-WRITE-PIPO
			return last-adb-err
		]
	]
	unless zero? ovlap/hEvent [CloseHandle ovlap/hEvent]
	last-adb-err: 0
	return last-adb-err
]
