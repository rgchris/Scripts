Rebol [
	Title: "cURL"
	Author: "Christopher Ross-Gill"
	Date: 08-Feb-2019
	Home: http://ross-gill.com/page/REST_Protocol
	File: %curl.reb
	Version: 0.1.5
	Purpose: "Rebol wrapper for cURL command."
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.curl
	Exports: [curl]
	History: [
		08-Feb-2019 0.1.5 "Ren-C compatibilities"
		04-Feb-2018 0.1.4 "Ren-C compatibilities"
		18-Jul-2017 0.1.3 "Initial Ren-C version"
		02-May-2013 0.1.2 "Use COLLECT; basic Auth support"
		21-Oct-2012 0.1.1 "Initial published version"
	]
	Comment: ["cURL Home Page" http://curl.haxx.se/]
]

curl: use [user-agent form-headers enquote][
	user-agent: unspaced ["Rebol/" uppercase/part form system/product 1 " " system/version]

	enquote: func [
		data [block! any-string!]
		/local mark
	][
		mark: switch system/version/4 [3 [{"}] ("'")]
		unspaced compose [mark (data) mark]
	]

	form-headers: func [headers [block! object!] /local out][
		collect [
			for-each [header value] switch type of headers [
				block! [headers]
				object! [body of headers]
			][
				if value [
					keep unspaced [" -H " enquote [as text! header ": " value]]
				]
			]
		]
	]

	curl: func [
		"Wrapper for the cURL shell function"
		url [url!] "URL to Retrieve"
		/method "Specify HTTP request method"
		verb [word! text! blank!] "HTTP request method"
		/send "Include request body"
		data [text! binary! file! blank!] "Request body"
		/header "Specify HTTP headers"
		headers [block! object! blank!] "HTTP headers"
		/as "Specify user agent"
		agent [text!] "User agent"
		/user "Provide User Credentials"
		name [text! blank!] "User Name"
		pass [text! blank!] "User Password"
		/full "Include HTTP headers in response"
		/binary "Receive response as binary"
		/follow "Follow HTTP redirects"
		/quiet "Return blank! on 4xx/5xx HTTP responses"
		/secure "Disallow 'insecure' SSL transactions"
		/into "Specify result string"
		out [text! binary! blank!] "String to contain result"
		/error "Specify error string"
		err [text! blank!] "String to contain error"
		/timeout "Specify a time limit"
		time [time! integer! blank!] "Time limit"
		/local command options code
	][
		out: any [:out make binary! 0]
		err: any [:err make text! 0]

		options: unspaced collect [
			keep "-s"

			case/all [
				full [keep "i"]
				quiet [keep "f"]
				not secure [keep "k"]
				follow [keep "L"]

				:verb [
					keep " -X "
					keep verb: uppercase form verb
				]

				:time [
					keep " -m "
					keep to integer! time
				]

				not send [data: _]

				file? data [
					keep reduce [" -d @" form data]
					data: _
				]

				data [
					either empty? data [
						data: _
					][
						keep " -d @-"
						data: to binary! data
					]
				]

				all [:name :pass][
					keep " -u "
					keep enquote [name ":" pass]
				]

				:headers [keep form-headers headers]
			]

			keep reduce [
				" -A " enquote any [:agent user-agent]
			]
		]

		command: spaced ["curl" options enquote url]

		code: call/shell/wait/input/output/error command data out err

		switch code [
			0 18 [
				either binary [out][
					to text! out
				]
			]
			1 [
				if empty? trim/head/tail err [
					err: "Unsupported protocol. This build of curl has no support for this protocol."
				]
				fail/where :err 'url
			]
			2 [fail/where "Failed to initialize." 'url]
			3 [fail/where "URL malformed. The syntax was not correct." 'url]
			4 [fail/where "Feature not included in this cURL build." 'url]
			6 [fail/where "Couldn't resolve host. The given remote host was not resolved." 'url]
			7 [fail/where "Failed to connect to host." 'url]
			22 [_]
			28 [fail/where "Request timed out." 'url]
			50 [fail/where "OS shell error." 'url]
			52 [fail/where "The server didn't reply anything." 'url]
			(
				code: spaced ["cURL Error Code" code trim/head/tail err]
				fail/where :code 'url
			)
		]
	]
]
