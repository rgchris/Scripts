Rebol [
	Title: "cURL"
	Purpose: "Rebol wrapper for cURL command."
	Needs: [2.102.0]
	Date: 21-Oct-2012
	File: %curl.reb
	Version: 0.1.3
	Author: "Christopher Ross-Gill"
	Rights: http://opensource.org/licenses/Apache-2.0
	Comments: ["cURL Home Page" http://curl.haxx.se/]
	Type: module
	Name: rgchris.curl
	Exports: [curl]
]

curl: use [user-agent form-headers enquote][
	user-agent: reform ["Rebol" system/product system/version]

	enquote: func [
		data [block! any-string!]
		/local mark
	][
		mark: switch/default system/version/4 [3 [{"}]]["'"]
		rejoin compose [mark (data) mark]
	]

	form-headers: func [headers [block! object!] /local out][
		collect [
			foreach [header value] switch type?/word headers [
				block! [headers]
				object! [body-of headers]
			][
				if value [
					keep rejoin [" -H " enquote [form header ": " value]]
				]
			]
		]
	]

	curl: func [
		"Wrapper for the cURL shell function"
		url [url!] "URL to Retrieve"
		/method "Specify HTTP request method"
		verb [word! string! blank!] "HTTP request method"
		/send "Include request body"
		data [string! binary! file! blank!] "Request body"
		/header "Specify HTTP headers"
		headers [block! object! blank!] "HTTP headers"
		/as "Specify user agent"
		agent [string!] "User agent"
		/user "Provide User Credentials"
		name [string! blank!] "User Name"
		pass [string! blank!] "User Password"
		/full "Include HTTP headers in response"
		/binary "Receive response as binary"
		/follow "Follow HTTP redirects"
		/fail "Return blank! on 4xx/5xx HTTP responses"
		/secure "Disallow 'insecure' SSL transactions"
		/into "Specify result string"
		out [string! binary! blank!] "String to contain result"
		/error "Specify error string"
		err [string! blank!] "String to contain error"
		/timeout "Specify a time limit"
		time [time! blank!] "Time limit"
		/local command code
	][
		out: any [:out make binary! 0]
		err: any [:err make string! 0]

		command: rejoin collect [
			keep "curl -s"

			case/all [
				full [keep "i"]
				fail [keep "f"]
				not secure [keep "k"]
				follow [keep "L"]
				all [method verb] [keep " -X " keep verb: uppercase form verb]
				all [timeout time] [keep " -m " keep to integer! time]
				all [send data] [
					either file? data [
						keep reduce [" -d @" form data]
						data: ""
					][
						keep " -d @-"
					]
				]
				all [user name pass][keep " -u " keep enquote [name ":" pass]]
				all [header headers] [keep form-headers headers]
			]

			keep reduce [
				" -A " enquote any [:agent user-agent]
			]

			keep reduce [" " enquote url]
		]

		if empty? data: any [:data make binary! 0][
			data: _  ; 2.0.99.2.5 breaks with empty string
		]

		code: call/shell/wait/input/output/error command data out err

		; net-utils/net-log [to-word any [verb "GET"] url]
		; net-utils/net-log command
		; net-utils/net-log reform ["cURL Response Code:" code]

		switch/default code [
			0 18 [
				either binary [
					out
				][
					to string! out
				]
			]
			1 [
				if empty? trim/head/tail err [
					err: "Unsupported protocol. This build of curl has no support for this protocol."
				]
				do make error! :err
			]
			2 [do make error! "Failed to initialize."]
			3 [do make error! "URL malformed. The syntax was not correct."]
			4 [do make error! "Feature not included in this cURL build."]
			6 [do make error! "Couldn't resolve host. The given remote host was not resolved."]
			7 [do make error! "Failed to connect to host."]
			22 [_]
			28 [do make error! "Request timed out."]
			50 [do make error! "OS shell error."]
			52 [do make error! "The server didn't reply anything."]
		][
			code: reform ["cURL Error Code" code trim/head/tail err]
			do make error! code
		]
	]
]