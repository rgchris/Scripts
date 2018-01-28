Rebol [
	Title: "RSP Preprocessor"
	Author: "Christopher Ross-Gill"
	Date: 25-Jul-2017
	; Home: tbd
	File: %rsp.reb
	Version: 0.4.2
	Purpose: {Rebol-embedded Markup}
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.rsp
	Exports: [sanitize load-rsp render render-each]
	History: ["To Follow"]
	Notes: "Extracted from QuarterMaster"
]

sanitize: use [ascii html* extended][
	html*: exclude ascii: charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
	extended: complement charset [#"^(00)" - #"^(7F)"]

	func [text [any-string!] /local char][
		parse form text [
			copy text any [
				text: some html*
				| change #"<" "&lt;" | change #">" "&gt;" | change #"&" "&amp;"
				| change #"^"" "&quot;" | remove #"^M"
				| remove copy char extended (char: rejoin ["&#" to integer! char/1 ";"]) insert char
				| remove copy char skip (char: rejoin ["#(" to integer! char/1 ")"]) insert char
			]
		]

		any [text copy ""]
	]
]

load-rsp: use [prototype to-set-block][
	prototype: context [
		out*: _ prin: func [val][repend out* val]
		print: func [val][prin val prin newline]
	]

	to-set-block: func [locals [block! object!] /local word][
		case [
			object? locals [
				body-of locals
			]

			block? locals [
				collect [
					parse locals [
						any [
							set word word! (keep reduce [to set-word! word get :word])
						]
					]
				]
			]
		]
	]

	func [body [string!] /local code mark return: [function!]][
		code: unspaced collect [
			keep unspaced ["^/out*: make string! " length-of body "^/"]
			parse body [
				any [
					end (keep "^/out*") break
					|
					"<%" [
						"==" copy mark to "%>" (
							keep unspaced ["prin sanitize form (" mark "^/)^/"]
						)
						|
						"=" copy mark to "%>" (
							keep unspaced ["prin (" mark "^/)^/"]
						)
						|
						[#":" | #"!"] copy mark to "%>" (
							keep unspaced ["prin build-tag [" mark "^/]^/"]
						)
						|
						copy mark to "%>" (keep unspaced [mark newline])
						|
						(
							throw make error! "Expected '%>'"
						)
					] 2 skip
					| copy mark [to "<%" | to end] (
						keep unspaced ["prin " mold mark "^/"]
					)
				]
			]
		]

		func [args [block! object!]] compose/only [
			args: make prototype to-set-block args
			do bind/copy (load code) args
		]
	]
]

render: use [depth*][
	depth*: 0 ;-- to break recursion

	func [
		rsp [file! url! string!]
		/with locals [block! object!]
	][
		if depth* > 20 [return ""]
		depth*: depth* + 1

		rsp: case/all [
			file? rsp [rsp: read rsp]
			url? rsp [rsp: read rsp]
			binary? rsp [rsp: to string! rsp]
			string? rsp [
				rsp: load-rsp rsp
				rsp any [:locals []]
			]
		]

		depth*: depth* - 1
		rsp
	]
]

render-each: func [
	'items [word! block!]
	source [series!]
	body [file! url! string!]
	/with locals /local out
][
	locals: append any [locals []] items: compose [(items)]
	unspaced collect [
		foreach :items source compose/only [
			append out render/with body (locals)
		]
	]
]
