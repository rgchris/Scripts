Red [
	Title: "JSON Decoder/Encoder for Red"
	Author: "Christopher Ross-Gill"
	Date: 24-Feb-2018
	Home: http://www.ross-gill.com/page/JSON_and_Rebol
	File: %altjson.red
	Version: 0.4.0
	Purpose: "Convert a Red block to a JSON string"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: 'module
	Name: 'rgchris.altjson
	Exports: [load-json to-json]
	History: [
		24-Feb-2018 0.4.0 "New TO-JSON engine, /PRETTY option"
		12-Sep-2017 0.3.6.1 "Red Compatibilities"
		18-Sep-2015 0.3.6 "Non-Word keys loaded as strings"
		17-Sep-2015 0.3.5 "Added GET-PATH! lookup"
		16-Sep-2015 0.3.4 "Reinstate /FLAT refinement"
		21-Apr-2015 0.3.3 {
			- Merge from Reb4.me version
			- Recognise set-word pairs as objects
			- Use map! as the default object type
			- Serialize dates in RFC 3339 form
		}
		14-Mar-2015 0.3.2 "Converts Json input to string before parsing"
		07-Jul-2014 0.3.0 "Initial support for JSONP"
		15-Jul-2011 0.2.6 "Flattens Flickr '_content' objects"
		02-Dec-2010 0.2.5 "Support for time! added"
		28-Aug-2010 0.2.4 "Encodes tag! any-type! paired blocks as an object"
		06-Aug-2010 0.2.2 "Issue! composed of digits encoded as integers"
		22-May-2005 0.1.0 "Original Version"
	]
	Notes: {
		- Converts date! to RFC 3339 Date String
		- Flattens Flicker '_content' objects
		- Handles Surrogate Pairs
		- Supports JSONP
	}
]

#macro ['use set locals block!] func [s e][
	reduce [
		make function! [
			[locals [object!] body [block!]]
			[do bind body locals]
		]
		make object! collect [
			forall locals [keep to set-word! locals/1]
			keep none
		]
	]
]

load-json: use [
	tree branch here val is-flat emit new-child to-parent neaten-one neaten-two word to-word
	space comma number string array object _content value ident
][
	branch: make block! 10

	emit: func [val][here: insert/only here val]
	new-child: quote (insert/only branch insert/only here here: make block! 10)
	to-parent: quote (here: take branch)
	neaten-one: quote (new-line/all head here true)
	neaten-two: quote (new-line/all/skip head here true 2)

	to-word: use [word1 word+][
		; upper ranges borrowed from AltXML
		word1: charset [
			"!&*=?ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz|~"
			#"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(02FF)"
			#"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)"
			#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
			#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
		]

		word+: charset [
			"!&'*+-.0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz|~"
			#"^(B7)" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)"
			#"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)"
			#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
			#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
		]

		func [text [string!]][
			all [
				parse text [word1 any word+]
				to word! text
			]
		]
	]

	space: use [space][
		space: charset " ^-^/^M"
		[any space]
	]

	comma: [space #"," space]

	number: use [dg ex nm as-num][
		dg: charset "0123456789"
		ex: [[#"e" | #"E"] opt [#"+" | #"-"] some dg]
		nm: [opt #"-" some dg opt [#"." some dg] opt ex]

		as-num: func [val [string!]][
			case [
				not parse val [opt "-" some dg][to float! val]
				not integer? try [val: to integer! val][to issue! val]
				val [val]
			]
		]

		[copy val nm (val: as-num val)]
	]

	string: use [ch es hx mp decode-surrogate decode][
		ch: complement charset {\"}
		hx: charset "0123456789ABCDEFabcdef"
		mp: #(#"^"" "^"" #"\" "\" #"/" "/" #"b" "^H" #"f" "^L" #"r" "^M" #"n" "^/" #"t" "^-")
		es: charset words-of mp

		decode-surrogate: func [char [string!]][
			char: debase/base char 16
			#"^(10000)"
				+ (shift/left 03FFh and to integer! take/part char 2 10)
				+ (03FFh and to integer! char)
		]

		decode: use [char escape][
			escape: [
				change [
					#"\" [
						char: es (char: select mp char/1)
						|
						#"u" copy char [
							#"d" [#"8" | #"9" | #"a" | #"b"] 2 hx
							"\u"
							#"d" [#"c" | #"d" | #"e" | #"f"] 2 hx
						] (
							char: decode-surrogate head remove remove skip char 4
						)
						|
						#"u" copy char 4 hx (
							char: to char! to integer! to issue! char
						)
					]
				] (char)
			]

			func [text [string! none!]][
				either none? text [make string! 0][
					all [parse text [any [to "\" escape] to end] text]
				]
			]
		]

		[#"^"" copy val [any [some ch | #"\" [#"u" 4 hx | es]]] #"^"" (val: decode val)]
	]

	array: use [list][
		list: [space opt [value any [comma value]] space]

		[#"[" new-child list #"]" neaten-one to-parent]
	]

	_content: [#"{" space {"_content"} space #":" space value space "}"] ; Flickr

	object: use [name list as-map][
		name: [
			string space #":" space (
				emit either is-flat [
					to tag! val
				][
					any [
						to-word val
						val
					]
				]
			)
		]
		list: [space opt [name value any [comma name value]] space]
		as-map: [(unless is-flat [here: change back here make map! pick back here 1])]

		[#"{" new-child list #"}" neaten-two to-parent as-map]
	]

	ident: use [initial ident][
		initial: charset ["$_" #"a" - #"z" #"A" - #"Z"]
		ident: union initial charset [#"0" - #"9"]

		[initial any ident]
	]

	value: [
		  "null" (emit none)
		| "true" (emit true)
		| "false" (emit false)
		| number (emit val)
		| string (emit val)
		| _content
		| array
		| object
	]

	func [
		"Convert a JSON string to Red data"
		json [string!] "JSON string"
		/flat "Objects are imported as tag-value pairs"
		/padded "Loads JSON data wrapped in a JSONP envelope"
	][
		is-flat: :flat
		tree: here: make block! 0

		either parse json either padded [
			[space ident space "(" space opt value space ")" opt ";" space]
		][
			[space opt value space]
		][
			pick tree 1
		][
			do make error! "Not a valid JSON string"
		]
	]
]

to-json: use [
	json emit emit-part stack is-pretty indent colon circular unknown
	
	escape emit-string emit-issue emit-date
	emit-array emit-object emit-value
][
	emit: func [data][repend json data]
	emit-part: func [from [string!] to [string!]][
		append/part json from to
	]

	stack: make block! 16 ; check for recursion

	indent: ""
	colon: ":"
	circular: {["..."]}
	unknown: {"\uFFFD"}

	increase: func [indent [string!]][
		either is-pretty [
			append indent "    "
		][
			indent
		]
	]

	decrease: func [indent [string!]][
		either is-pretty [
			head clear skip tail indent -4
		][
			indent
		]
	]

	emit-array: func [
		elements [block!]
	][
		emit #"["
		unless tail? elements [
			increase indent
			while [not tail? elements][
				emit indent
				emit-value pick elements 1
				unless tail? elements: next elements [
					emit #","
				]
			]
			emit decrease indent
		]
		emit #"]"
	]

	emit-object: func [
		members [block!]
	][
		emit #"{"
		unless tail? members [
			increase indent
			while [not tail? members][
				emit indent
				emit-string pick members 1
				emit colon
				emit-value pick members 2
				unless tail? members: skip members 2 [
					emit #","
				]
			]
			emit decrease indent
		]
		emit #"}"
	]

	emit-string: use [escapes chars emit-char][
		escapes: #(#"^/" "\n" #"^M" "\r" #"^-" "\t" #"^"" "\^"" #"\" "\\")
		chars: intersect chars: charset [#" " - #"~"] difference chars charset words-of escapes

		emit-char: func [char [char!]][
			emit ["\u" skip tail form to-hex to integer! char -4]
		]

		func [
			value [any-type!]
			/local mark extent
		][
			value: switch/default type?/word value [
				string! [value]
				get-word! set-word! [to string! to word! value]
				binary! [enbase value]
			][
				to string! value
			]

			emit #"^""
			parse value [
				any [
					  mark: some chars extent: (emit-part mark extent)
					| skip (
						case [
							find escapes mark/1 [emit select escapes mark/1]
							mark/1 < 10000h [emit-char mark/1]
							mark/1 [ ; surrogate pairs
								emit-char mark/1 - 10000h / 400h + D800h
								emit-char mark/1 - 10000h // 400h + DC00h
							]
							/else [emit "\uFFFD"]
						]
					)
				]
			]
			emit #"^""
		]
	]

	emit-date: func [value [date!] /local second][
		emit #"^""
		emit [
			pad/left/with value/year 4 #"0"
			#"-" pad/left/with value/month 2 #"0"
			#"-" pad/left/with value/day 2 #"0"
		]
		if value/time [
			emit [
				#"T" pad/left/with value/hour 2 #"0"
				#":" pad/left/with value/minute 2 #"0"
				#":"
			]
			emit pad/left/with to integer! value/second 2 #"0"
			any [
				".0" = second: find form round/to value/second 0.000001 #"."
				emit second
			]
			emit either any [
				none? value/zone
				zero? value/zone
			][#"Z"][
				[
					either value/zone/hour < 0 [#"-"][#"+"]
					pad/left/with absolute value/zone/hour 2 #"0"
					#":" pad/left/with value/zone/minute 2 #"0"
				]
			]
		]
		emit #"^""
	]

	emit-issue: use [digit number][
		digit: charset "0123456789"
		number: [opt #"-" some digit]

		func [value [issue!]][
			value: next mold value
			either parse value number [
				emit value
			][
				emit-string value
			]
		]
	]

	emit-value: func [value [any-type!]][
		if any [
			get-word? :value
			get-path? :value
		][
			; probe "GETTING"
			set/any 'value take reduce reduce [value]
		]

		switch value [
			none blank null _ [value: none]
			true yes [value: true]
			false no [value: false]
		]

		switch/default type?/word value [
			block! [
				either find/only/same stack value [
					emit circular
				][
					insert/only stack value
					either parse value [some [set-word! skip] | some [tag! skip]][
						emit-object value
					][
						emit-array value
					]
					remove stack
				]
			]

			object! map! [
				either find/same stack value [
					emit circular
				][
					emit-object body-of value
				]
			]

			string! binary! file! email! url! tag! pair! time! tuple! money!
			word! lit-word! get-word! set-word! refinement! [
				emit-string value
			]

			issue! [
				emit-issue value
			]

			date! [
				emit-date value
			]

			integer! float! decimal! [
				emit to string! value
			]

			logic! [
				emit to string! value
			]

			none! unset! [
				emit "null"
			]

			paren! path! get-path! set-path! lit-path! [
				emit-array value
			]
		][
			emit unknown
		]

		json
	]

	func [
		"Convert a Red value to JSON string"
		item [any-type!] "Red value to convert"
		/pretty "Format Output"
	][
		is-pretty: :pretty
		indent: pick ["^/" ""] is-pretty
		colon: pick [": " ":"] is-pretty

		clear stack
		json: make string! 1024
		emit-value item
	]
]
