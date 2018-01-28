Rebol [
	Title: "JSON Parser for Rebol 3"
	Author: "Christopher Ross-Gill"
	Date: 18-Sep-2015
	Home: http://www.ross-gill.com/page/JSON_and_Rebol
	File: %altjson.reb
	Version: 0.3.6.1
	Purpose: "Convert a Rebol block to/from a JSON string"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.altjson
	Exports: [load-json to-json]
	History: [
		25-Feb-2017 0.3.6.1 "Ren-C Compatibilities"
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
	Comment: {
		- Converts date! to RFC 3339 Date String
	}
]

load-json: use [
	tree branch here val is-flat emit new-child to-parent neaten word to-word
	space comma number string block object _content value ident
][
	branch: make block! 10

	emit: func [val][here: insert/only here val]
	new-child: [(insert/only branch insert/only here here: make block! 10)]
	to-parent: [(here: take branch)]
	neaten: [
		(new-line/all head here true)
		(new-line/all/skip head here true 2)
	]

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

		func [val [string!]][
			all [
				parse val [word1 any word+]
				to word! val
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
				not parse val [opt "-" some dg][to decimal! val]
				not integer? try [val: to integer! val][to issue! val]
				val [val]
			]
		]

		[copy val nm (val: as-num val)]
	]

	string: use [ch es hx mp decode][
		ch: complement charset {\"}
		es: charset {"\/bfnrt}
		hx: charset "0123456789ABCDEFabcdef"
		mp: [#"^"" "^"" #"\" "\" #"/" "/" #"b" "^H" #"f" "^L" #"r" "^M" #"n" "^/" #"t" "^-"]

		decode: use [ch mk escape][
			escape: [
				; should be possible to use CHANGE keyword to replace escaped characters.
				mk: #"\" [
					es (mk: change/part mk select mp mk/2 2)
					|
					#"u" copy ch 4 hx (
						mk: change/part mk to char! to-integer/unsigned debase/base ch 16 6
					)
				] :mk
			]

			func [text [string! blank!]][
				either blank? text [make string! 0][
					all [parse text [any [to "\" escape] to end] text]
				]
			]
		]

		[#"^"" copy val [any [some ch | #"\" [#"u" 4 hx | es]]] #"^"" (val: decode val)]
	]

	block: use [list][
		list: [space opt [value any [comma value]] space]

		[#"[" new-child list #"]" neaten/1 to-parent]
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
						lock val
					]
				]
			)
		]
		list: [space opt [name value any [comma name value]] space]
		as-map: [(unless is-flat [here: change back here make map! pick back here 1])]

		[#"{" new-child list #"}" neaten/2 to-parent as-map]
	]

	ident: use [initial ident][
		initial: charset ["$_" #"a" - #"z" #"A" - #"Z"]
		ident: union initial charset [#"0" - #"9"]

		[initial any ident]
	]

	value: [
		  "null" (emit _)
		| "true" (emit true)
		| "false" (emit false)
		| number (emit val)
		| string (emit val)
		| _content
		| object | block
	]

	func [
		"Convert a JSON string to Rebol data"
		json [string! binary! file! url!] "JSON string"
		/flat "Objects are imported as tag-value pairs"
		/padded "Loads JSON data wrapped in a JSONP envelope"
	][
		case/all [
			any [file? json url? json][
				if error? json: try [read/string (json)][
					do :json
				]
			]
			binary? json [json: to string! json]
		]

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
	json emit emits escape emit-issue emit-date
	here lookup comma block object block-of-pairs value
][
	emit: func [data][repend json data]
	emits: func [data][emit {"} emit data emit {"}]

	escape: use [mp ch encode][
		mp: [#"^/" "\n" #"^M" "\r" #"^-" "\t" #"^"" "\^"" #"\" "\\" #"/" "\/"]
		ch: intersect ch: charset [#" " - #"~"] difference ch charset extract mp 2

		encode: func [here][
			change/part here any [
				select mp here/1
				rejoin ["\u" skip tail form to-hex to integer! here/1 -4]
			] 1
		]

		func [txt][
			parse txt [any [txt: some ch | skip (txt: encode txt) :txt]]
			head txt
		]
	]

	emit-issue: use [dg nm mk][
		dg: charset "0123456789"
		nm: [opt "-" some dg]

		[(either parse next form here/1 [copy mk nm][emit mk][emits here/1])]
	]

	emit-date: use [pad second][
		pad: func [part length][part: to string! part head insert/dup part "0" length - length? part]

		quote (
			emits rejoin collect [
				keep reduce [pad here/1/year 4 "-" pad here/1/month 2 "-" pad here/1/day 2]
				if here/1/time [
					keep reduce ["T" pad here/1/hour 2 ":" pad here/1/minute 2 ":"]
					keep either integer? here/1/second [
						pad here/1/second 2
					][
						second: split to string! here/1/second "."
						reduce [pad second/1 2 "." second/2]
					]
					keep either any [
						blank? here/1/zone
						zero? here/1/zone
					]["Z"][
						reduce [
							either here/1/zone/hour < 0 ["-"]["+"]
							pad abs here/1/zone/hour 2 ":" pad here/1/zone/minute 2
						]
					]
				]
			]
		)
	]

	lookup: [
		here: [get-word! | get-path!]
		(change here reduce reduce [here/1])
		fail
	]

	comma: [(if not tail? here [emit ","])]

	block: [
		(emit "[") any [here: value here: comma] (emit "]")
	]

	block-of-pairs: [
		  some [set-word! skip]
		| some [tag! skip]
	]

	object: [
		(emit "{")
		any [
			here: [set-word! (change here to word! here/1) | any-string! | any-word!]
			(emit [{"} escape to string! here/1 {":}])
			here: value here: comma
		]
		(emit "}")
	]

	value: [
		  lookup ; resolve a GET-WORD! reference
		| number! (emit here/1)
		| [logic! | 'true | 'false] (emit to string! here/1)
		| [blank! | 'none | 'blank] (emit quote 'null)
		| date! emit-date
		| issue! emit-issue
		| [
			any-string! | word! | lit-word! | tuple! | pair! | money! | time!
		] (emits escape form here/1)
		| any-word! (emits escape form to word! here/1)

		| [object! | map!] :here (change/only here body-of first here) into object
		| into block-of-pairs :here (change/only here copy first here) into object
		| any-block! :here (change/only here copy first here) into block

		| any-type! (emits to tag! type-of first here)
	]

	func [data][
		json: make string! 1024
		if parse compose/only [(data)][here: value][json]
	]
]
