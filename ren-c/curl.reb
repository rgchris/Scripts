Rebol [
	Title: "cURL"
	Author: "Christopher Ross-Gill"
	Date: 21-Oct-2012
	Home: http://ross-gill.com/page/REST_Protocol
	File: %curl.reb
	Version: 0.1.4
	Purpose: "Rebol wrapper for cURL command."
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.curl
	Exports: [curl]
	History: []
	Comment: ["cURL Home Page" http://curl.haxx.se/]
]

curl: use [user-agent form-headers enquote][
	user-agent: unspaced ["Rebol/" uppercase/part form system/product 1 " " system/version]

	enquote: func [
		data [block! any-string!]
		/local mark
	][
		mark: switch/default system/version/4 [3 [{"}]]["'"]
		rejoin compose [mark (data) mark]
	]

	form-headers: func [headers [block! object!] /local out][
		collect [
			foreach [header value] switch type-of headers [
				:block! [headers]
				:object! [body-of headers]
			][
				if value [
					keep unspaced [" -H " enquote [spelling-of header ": " value]]
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
		time [time! integer! blank!] "Time limit"
		/local command options code
	][
		out: any [:out make binary! 0]
		err: any [:err make string! 0]

		options: unspaced collect [
			keep "-s"

			case/all [
				full [keep "i" true]
				fail [keep "f" true]
				not secure [keep "k" true]
				follow [keep "L" true]
				not void? :verb [keep " -X " keep verb: uppercase form verb true]
				any [:time _] [keep " -m " keep to integer! time]
				void? :data [data: _]
				file? data [
					keep reduce [" -d @" form data]
					data: _
				]
				data [
					either empty? data [
						data: _ ; 3.0.99.2.5 breaks with empty string
					][
						keep " -d @-"
					]
				]
				not void? all [:name :pass][keep " -u " keep enquote [name ":" pass] true]
				not void? :headers [keep form-headers headers true]
			]

			keep reduce [
				" -A " enquote any [:agent user-agent]
			]

			; keep " "
		]

		command: spaced ["curl" options url]

		code: call/shell/wait/input/output/error command data out err

		; net-utils/net-log [to-word any [verb "GET"] url]
		; net-utils/net-log command
		; net-utils/net-log reform ["cURL Response Code:" code]
		; print [to-word any [:verb "GET"] url]
		print command
		; print reform ["cURL Response Code:" code]

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
