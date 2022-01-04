REBOL [
	Title: "Amazon S3 Protocol"
	Author: "Christopher Ross-Gill"
	Date: 20-Mar-2013
	File: %s3.r
	Version: 0.1.0
	Purpose: {Basic retrieve and upload protocol for Amazon S3.}
	Example: [
		do/args http://reb4.me/r/s3 [args (see settings)]
		write s3://<bucket>/file/foo.txt "Foo"
		read s3://<bucket>/file/foo.txt
	]
	History: [
		23-Nov-2008 ["Graham Chiu" "Maarten Koopmans" "Gregg Irwin"]
	]
	Settings: [
		AWSAccessKeyId: <AWSAccessKeyId>
		AWSSecretAccessKey: <AWSSecretAccessKey>
		Secure: false ; optional
	]
]

sys/make-scheme bind [
	title: "Amazon S3 Protocol"
	name: 's3

	actor: [
		open: funct [port [port!]] [
			port/spec/path: any [port/spec/path "/"]

			subport: make port! rejoin [
				either settings/secure [https://][http://]
				any [select port/spec 'user settings/awsaccesskeyid] ":"
				any [select port/spec 'pass settings/awssecretaccesskey] "@"
				port/spec/host ".s3.amazonaws.com" port/spec/path
			]

			subport/locals: context [
				parent: port
				response: none
			]

			port/locals: context compose [
				subport: (subport)
				response: none
			]

			port
		]

		open?: func [port [port!]][
			all [
				port/locals
				open? port/locals/subport
			]
		]

		read: func [port [port!]][
			open port
			send "GET" port/locals/subport none
		]

		write: func [port [port!] content [none! string! binary! block!]][
			case/all [
				none? content [content: #{}]
				not block? content [content: join [body:] content]
				block? content [content: make request content]
			]

			open port
			send "PUT" port/locals/subport content
		]

		delete: func [port [port!]][
			open port
			send "DELETE" port/locals/subport none
		]

		query: func [port /local headers][
			open port

			if headers: send "HEAD" port/locals/subport none [
				context [
					name: port/spec/ref
					size: any [headers/content-length 0]
					date: headers/last-modified
					type: either dir? port/spec/ref ['dir]['file]
					content-type: headers/content-type
				]
			]
		]

		close: func [port][
			close port/locals/subport
		]
	]
] context [
	settings: make context [
		awsaccesskeyid: awssecretaccesskey: ""
		secure: false
	] any [
		system/script/args
		bind system/script/header/settings system/contexts/user
	]

	request: context [body: size: type: md5: access: none]

	send: use [timestamp detect-mime sign compose-request response][
		timestamp: func [/for date [date!]][
			date: any [date now]
			date/time: date/time - date/zone

			rejoin [
				copy/part pick system/locale/days date/weekday 3 
				", " next form 100 + date/day " " 
				copy/part pick system/locale/months date/month 3 
				" " date/year " "
				next form 100 + date/time/hour ":"
				next form 100 + date/time/minute ":"
				next form 100 + to-integer date/time/second " GMT" 
			]
		]

		detect-mime: use [types][
			types: [
				application/octet-stream
				text/html %.html %.htm
				image/jpeg %.jpg %.jpeg
				image/png %.png
				image/tiff %.tif %.tiff
				application/pdf %.pdf
				text/plain %.txt %.r
				application/xml %.xml
				video/mpeg %.mpg %.mpeg
				video/x-m4v %.m4v
			]

			func [file [file! url! string! none!]][
				if file [
					file: any [find types suffix? file next types]
					first find/reverse file path!
				]
			]
		]

		sign: func [verb [string!] spec [object!] request [object!]][
			rejoin [
				"AWS " spec/user ":" enbase/base checksum/secure/key rejoin [
					#{} verb newline
					newline ; any [port/locals/md5 ""] newline
					any [request/type ""] newline
					timestamp newline
					either request/access [join "x-amz-acl:" [request/access "^/"]][""]
					"/" copy/part spec/host find/last spec/host ".s3.amazonaws.com" spec/path
				] spec/pass 64
			]
		]

		compose-request: func [
			method [string!] port [port!] content [object! none!]
			/local prefix
		][
			content: any [content make request []]

			content/size: all [content/body length? content/body]
			content/type: all [content/body form any [content/type detect-mime port/spec/path]]
			content/access: all [
				content/body switch/default content/access [
					read ["public-read"] write ["public-read-write"]
				][content/access]
			]

			port/spec/method: method
			port/spec/content: content/body

			if parse port/spec/path [skip thru #"/"][
				prefix: remove port/spec/path
				port/spec/path: copy "/"
			]

			port/spec/headers: collect [
				foreach [header value][
					Date: [timestamp]
					Content-Type: [content/type]
					Content-Length: [content/size]
					Authorization: [sign method port/spec content]
					x-amz-acl: [content/access]
					Pragma: ["no-cache"]
					Cache-Control: ["no-cache"]
				][
					if value: all :value [
						keep header
						keep form value
					]
				]
			]

			if prefix [append port/spec/path join "?prefix=" prefix]
		]

		send: func [[catch] method [string!] port [port!] content [any-type!]][
			compose-request method port content

			port/awake: func [event][
				switch event/type [
					connect [read event/port false]
					done [true]
				]
			]

			open port
			response: query port

			; unless port?
			wait [port 1]
			; [make error! "No Response from Port"]

			port/locals/parent/data: switch/default response/response-parsed [
				ok [
					switch method [
						"GET" [
							either dir? response/name [
								collect [
									parse decode 'markup port/data use [name][
										[any [thru <key> copy name string! (keep to file! name)]]
									]
								]
							][port/data]
						]
						"PUT" [content/body]
						"HEAD" [response/headers]
					]
				]
				no-content [port/locals/parent] ; DELETE
			][
				make error! rejoin collect [
					parse decode 'markup port/data use [message][
						[
							thru <Error> thru <Message> set message string!
							(keep [message " (" skip response/response-line 9 ")"])
						]
					]
				]
			]
		]
	]
]