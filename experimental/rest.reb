Rebol [
	Title: "Transaction-based HTTP(S) Protocol"
	Author: "Christopher Ross-Gill"
	Date: 5-Jun-2017
	Home: http://ross-gill.com/page/REST_Protocol
	File: %rest.reb
	Version: 0.0.2
	Purpose: {Minimal HTTP(S) scheme with elemental Request/Response model}
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.rest
	Needs: [
		<webform> ; %../ren-c/altwebform.reb
		<curl> ; %../experimental/curl.reb
	]
	Usage: [
		read [
			scheme: rest
			url: http://www.ross-gill.com/
		]

		write [
			scheme: rest
			method: post
			type: text/html
			url: http://somewhere-to-write/target
		][
			some data
		]
	]
]

use [prepare fetch transcribe][
	prepare: use [
		request-prototype header-prototype
		oauth-credentials oauth-prototype
		sign
	][
		request-prototype: make object! [
			version: 1.1
			action: headers: query: _
			oauth: target: content: length: timeout: _
			type: 'application/x-www-form-urlencoded
		]

		header-prototype: make object! [
			Accept: "*/*"
			Connection: "close"
			User-Agent: rejoin ["Rebol/" system/product " " system/version]
			Content-Length: Content-Type: Authorization: Range: _
		]

		oauth-credentials: make object! [
			consumer-key: consumer-secret:
			oauth-token: oauth-token-secret:
			oauth-callback: _
		]

		oauth-prototype: make object! [
			oauth_callback: _
			oauth_consumer_key: _
			oauth_token: oauth_nonce: _
			oauth_signature_method: "HMAC-SHA1"
			oauth_timestamp: _
			oauth_version: 1.0
			oauth_verifier: oauth_signature: _
		]

		sign: func [request [object!] /local header params timestamp out][
			out: make string! 0
			timestamp: now/precise

			header: make oauth-prototype [
				oauth_consumer_key: request/oauth/consumer-key
				oauth_token: request/oauth/oauth-token
				oauth_callback: request/oauth/oauth-callback
				oauth_nonce: enbase/base checksum/secure to binary! unspaced [now/precise oauth_consumer_key] 64
				oauth_timestamp: form any [
					attempt [to integer! difference timestamp 1-Jan-1970/0:0:0]
					timestamp - 1-Jan-1970/0:0:0 * 86400.0
				]
				clear find/last oauth_timestamp "."
			]

			params: make header any [request/content []]
			params: sort/skip body-of params 2

			header/oauth_signature: enbase/base checksum/secure/key to binary! unspaced [
				uppercase form request/action "&" url-encode form request/url "&"
				url-encode replace/all to-webform params "+" "%20"
			] to binary! unspaced [
				request/oauth/consumer-secret "&" any [request/oauth/oauth-token-secret ""]
			] 64

			foreach [name value] body-of header [
				if value [
					repend out [", " spelling-of name {="} url-encode form value {"}]
				]
			]

			switch request/action [
				"GET" [
					if request/content [
						request/url: join-of request/url to-webform/prefix request/content
						request/content: _
					]
				]

				"POST" "PUT" [
					request/content: to-webform any [request/content []]
					request/headers/Content-Type: "application/x-www-form-urlencoded"
				]
			]

			request/headers/Authorization: join-of "OAuth" next out
		]

		prepare: func [port [port!] /with content /local request url][
			port/locals/request: request: make request-prototype compose port/locals/request
			request/content: any [:content _]

			request/action: uppercase form any [
				get in request 'action
				either request/content ["POST"]["GET"]
			]

			request/headers: make header-prototype any [request/headers []]

			either request/oauth [
				request/oauth: make oauth-credentials request/oauth
				sign request
			][
				request/headers/Authorization: any [
					request/headers/authorization
					if all [port/spec/user port/spec/pass][
						join-of "Basic " enbase join-of port/spec/user [#":" port/spec/pass]
					]
				]
			]

			; if port/state/index > 0 [
			; 	request/version: 1.1
			; 	request/headers/Range: rejoin ["bytes=" port/state/index "-"]
			; ]

			case/all [
				block? request/content [
					request/content: to-webform request/content
					request/headers/Content-Type: "application/x-www-form-urlencoded"
				]

				string? request/content [
					request/length: length? request/content
					request/headers/Content-Length: length? request/content
					request/headers/Content-Type: request/type
				]
			]

			port
		]
	]

	fetch: func [port [port!]][
		port/locals/request
		curl/full/method/header/send/timeout/into ; url action headers content response
			port/locals/request/url
			port/locals/request/action
			port/locals/request/headers
			port/locals/request/content
			port/locals/request/timeout
			port/locals/response
	]

	transcribe: use [
		response-code header-feed header-name header-part
		response-prototype header-prototype
	][
		response-code: use [digit][
			digit: charset "0123456789"
			[3 digit]
		]

		header-feed: [newline | crlf]

		header-part: use [chars][
			chars: complement charset [#"^(00)" - #"^(1F)"]
			[some chars any [header-feed some " " some chars]]
		]

		header-name: use [chars][
			chars: charset ["_-0123456789" #"a" - #"z" #"A" - #"Z"]
			[some chars]
		]

		space: use [space][
			space: charset " ^-"
			[some space]
		]

		response-prototype: context [
			status: message: http-headers: headers: content: binary: type: length: _
		]

		header-prototype: context [
			Date: Server: Last-Modified: Accept-Ranges: Content-Encoding: Content-Type:
			Content-Length: Location: Expires: Referer: Connection: Authorization: _
		]

		transcribe: func [port [port!] /local response name value pos][
			port/locals/response: response: make response-prototype [
				unless parse port/locals/response [
					"HTTP/" [
						"1." ["0" | "1"] space copy status response-code
						space copy message header-part
						|
						"2" space copy status response-code (message: _)
						opt [space opt [copy message header-part]]
					] header-feed
					(
						status: load status
						headers: make block! []
						message: either empty? any [message ""][_][
							to string! message
						]
					)
					some [
						copy name header-name #":" any #" "
						copy value header-part header-feed
						(repend headers [to set-word! to string! name to string! value])
					]
					header-feed content: to end (
						content: to string! binary: copy content
					)
					| pos: fail
				][
					do make error! "Could Not Parse Response"
				]

				headers: make header-prototype http-headers: new-line/skip headers true 2

				type: all [
					path? type: attempt [load headers/Content-Type]
					type
				]

				length: any [attempt [headers/Content-Length: to integer! headers/Content-Length] 0]
			]
		]
	]

	sys/make-scheme [
		Title: "Service-oriented HTTP Protocol"
		Name: 'rest

		Spec: make object! [title: url: ref: user: pass: _]

		Init: func [port [port!] /local url][
			port/locals: make object! [
				request: case/all [
					url? port/spec/ref [
						port/spec/ref: compose [
							url: (to url! replace form port/spec/ref rest:// https://)
						]
					]

					block? port/spec/ref [
						unless url: case/all [
							get-word? url: pick find compose port/spec/ref quote url: 2 [
								url: get :url
							]

							url? url [url]
						][
							return make error! "REST spec needs a URL"
						]

						unless parse url ["http" opt "s" "://" to end] [
							return make error! "REST only supports HTTP(S) URLs"
						]

						port/spec/ref
					]
				]

				response: make binary! 0
			]

			; do make error! "Not Finished Yet."
		]

		Actor: [
			read: func [port [port!]][
				prepare port
				fetch port
				transcribe port
			]

			write: func [port [port!] content [any-value!]][
				probe content
				prepare/with port :content
				fetch port
				transcribe port
			]
		]
	]
]
