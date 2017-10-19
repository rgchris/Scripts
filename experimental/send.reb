Rebol [
	Title: "Send for Ren-C"
	Author: "Christopher Ross-Gill"
	Date: 18-Oct-2017
	Home: https://github.com/rgchris/Scripts
	File: %send.reb
	Version: 0.2.0
	Type: module
	Name: rgchris.send
	Rights: http://opensource.org/licenses/Apache-2.0
	Purpose: "Build and send email messages via SMTP"
	Exports: [send]
	Needs: [<smtp>]
	History: [
		18-Oct-2017 0.2.0 "First Version for Ren-C"
	]
	Usage: [
		; note: use SET-NET to establish the default SMTP credentials
		send/header/attach luke@rebol.info "Message From Send!" "Message Body" [
			BCC: han@rebol.info
			Reply-To: replies@rebol.info
		][
			%attachment.bin #{DECAFBAD}
		]
	]
]

extend system/standard 'email make object! [
	To: CC: BCC: From: Reply-To: Date: Subject:
	Return-Path: Organization: Message-Id: Comment: _
	X-Rebol: rejoin [
		"Rebol/" system/product " " system/version " http://rebol.info"
	]
	MIME-Version: Content-Type: Content: _
]

send: use [default-mailbox to-idate to-iheader build-attach-body][
	default-mailbox: [
		scheme: 'smtp
		host: system/user/identity/smtp
		user: system/user/identity/esmtp-user
		pass: system/user/identity/esmtp-pass
		ehlo: system/user/identity/fqdn
	]

	to-idate: use [to-itime][
		to-itime: func [
			{Returns a standard internet time string (two digits for each segment)} 
			time [time! number! block! blank!] 
			/local pad
		][
			time: make time! time 
			pad: func [n][head insert/dup n: form n #"0" 2 - length? n] 
			unspaced [
				pad time/hour ":" pad time/minute ":" 
				pad round/down time/second
			]
		]

		func [
			"Returns a standard Internet date string." 
			date [date!] 
			/local str
		][
			str: form date/zone 
			remove find str ":" 
			if (first str) <> #"-" [insert str #"+"] 
			if (length? str) <= 4 [insert next str #"0"] 
			spaced [
				pick ["Mon," "Tue," "Wed," "Thu," "Fri," "Sat," "Sun,"] date/weekday 
				date/day 
				pick ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"] date/month 
				date/year 
				to-itime any [date/time 0:00] 
				str
			]
		]
	]

	to-iheader: func [
		{Export an object to something that looks like a header} 
		object [object!] "Object to export"
	][
		unspaced collect [
			foreach word words-of object [
				unless any [
					void? get word
					blank? get word
				][
					keep reduce [
						form word ": " get word newline
					]
				]
			]
		]
	]

	build-attach-body: use [make-mime-header break-lines make-boundary][
		break-lines: func [data [string!] /at size [integer!]] [
			size: any [:size 72]

			collect [
				while [not tail? data] [
					keep copy/part data size #"^/"
					data: skip data size
				]
			]
		]

		make-mime-header: func [file][
			to-iheader context [
				Content-Type: join-of {application/octet-stream; name="} [file {"}]
				Content-Transfer-Encoding: "base64"
				Content-Disposition: join-of {attachment; filename="} [file {"^M^/}]
			]
		]

		make-boundary: does [
			unspaced [
				"--__Rebol--" form system/product "--" system/version "--"
				enbase/base checksum/secure to binary! form now/precise 16 "__"
			]
		]

		build-attach-body: func [
			"Return an email body with attached files."
			headers [object!] "The message header"
			body [string!] "The message body"
			files [block!] {List of files to send [%file1.r [%file2.r "data"]]}
			/local file content boundary value
		][
			boundary: make-boundary

			insert body reduce [boundary "^/Content-Type: " headers/Content-Type "^M^/^/"]

			headers/MIME-Version: "1.0"
			headers/Content-Type: join-of "multipart/mixed; boundary=" [{"} skip boundary 2 {"}]

			head insert tail body unspaced collect [
				parse files [
					some [
						set file file! [
							set value [string! | binary!]
							| (value: read/binary file)
						] (
							keep "^/^/"
							keep boundary
							keep "^/"
							keep make-mime-header any [
								find/last/tail file #"/"
								file
							]
							keep break-lines enbase value
						)
					]
				]

				keep "^/^/"
				keep boundary
				keep "--^/"
			]
		]
	]

	send: func [
		{Send a message to an address/some addresses}
		address [email! block!] "An address or block of addresses"
		subject [string!] "Subject of message"
		message [string!] "Text of message"
		/header "Use a customized header"
		headers [block! object!] "Customized header"
		/attach "Append attachments"
		files [file! block!] "The filename(s)/content to attach to the message"
		/into "Use an alternate SMTP mailbox"
		mailbox [block! port!] "Mailbox or mailbox spec"
		/local from
	][
		; bases any custom object on SYSTEM/STANDARD/EMAIL
		headers: make system/standard/email any [:headers []]

		; RECIPIENTS
		either blank? from: any [
			headers/from
			headers/from: system/user/identity/email
		][
			do make error! "SEND: Email header not set: no from address"
		][
			if all [
				string? system/user/name
				not empty? system/user/name
			][
				headers/from: rejoin [system/user/name " <" from ">"]
			]
		]

		address: collect [
			foreach recipient compose [(address)][
				if email? recipient [keep recipient]
			]
		]

		if find [email! block!] to word! type-of headers/To [
			remove-each recipient headers/To: unique compose [(headers/To)][
				either email? recipient [
					append address recipient
					false ; don't remove
				][
					true ; remove
				]
			]
		]

		headers/To: either empty? address [_][
			delimit address: unique address ", "
		]

		headers/CC: if find [email! block!] to word! type-of headers/CC [
			remove-each recipient headers/CC: unique compose [(headers/CC)][
				either email? recipient [
					append address recipient
					false ; don't remove
				][
					true ; remove
				]
			]

			unless empty? headers/CC [delimit headers/CC ", "]
		]

		; notes on BCC here: http://stackoverflow.com/a/26611044/292969
		if find [email! block!] to word! type-of headers/BCC [
			remove-each recipient headers/BCC: unique compose [(headers/BCC)][
				either email? recipient [
					append address recipient
					false ; don't remove
				][
					true ; remove
				]
			]
		]

		headers/BCC: _ ; BCC header is not sent to the server.

		if empty? address: unique address [
			do make error! "SEND: No recipients specified."
		]

		; HEADERS
		headers/Subject: subject

		if blank? headers/Date [
			headers/Date: to-idate now
		]

		case [
			blank? headers/Content-Type [
				headers/Content-Type: "text/plain; charset=utf-8"
			]

			parse headers/Content-Type ["text/" ["plain" | "html"]][
				headers/Content-Type: join-of headers/Content-Type "; charset=UTF-8"
			]
		]

		; CONTENT
		message: copy message

		if attach [
			remove-each part files: flatten compose [(files)][
				not find [file! string! binary!] to word! type-of part
			]

			either parse files [
				any [file! opt [string! | binary!]]
			][
				message: build-attach-body headers message files
			][
				do make error! "SEND: Invalid Attachment Spec"
			]
		]

		message: reduce [
			quote from: from
			quote to: address
			quote message: head insert insert tail to-iheader headers newline message
		]

		; SMTP expects insert of [email! into [some email!] string!] where STRING! is a fully
		; formed email message with headers.
		write either void? :mailbox [default-mailbox][mailbox] message
	]
]
