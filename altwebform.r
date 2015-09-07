Rebol [
	Title: "Web Form Encoder/Decoder for Rebol 3"
	Author: "Christopher Ross-Gill"
	Date: 6-Jul-2013
	Home: http://www.ross-gill.com/page/Web_Forms_and_REBOL
	File: %altwebform.r
	Version: 0.10.0
	Purpose: "Convert a Rebol block to a URL-Encoded Web Form string"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: 'module
	Name: 'rgchris.altwebform
	Exports: [url-decode url-encode load-webform to-webform]
	History: [
		06-Sep-2015 0.10.0 "Add Ruby-style paths to encoding"
		06-Jul-2013  0.9.5 "Fix encoding/decoding of _ character"
		01-Mar-2013  0.9.4 "Detach URL-DECODE and URL-ENCODE"
		27-Feb-2013  0.9.2 "Correct encoding of UTF-8 values"
		18-Nov-2009  0.1.0 "Original Version"
	]
	Example: [
		"a=3&aa.a=1&b.c=1&b.c=2"
		[a "3" aa [a "1"] b [c ["1" "2"]]]
	]
]

url-decode: use [as-is hex space][
	as-is: charset ["-.~" #"0" - #"9" #"A" - #"Z" #"a" - #"z"]
	hex: charset [#"0" - #"9" #"a" - #"f" #"A" - #"F"]

	func [text [any-string!] /wiki][
		space: either wiki [#"_"][#"+"]
		either parse text: to binary! text [
			copy text any [
				  some as-is | remove space insert " "
				| [#"_" | #"+" | #"." | #","]
				| change "%0D%0A" "^/" ; de-crlf
				| remove ["%" copy text 2 hex] (text: debase/base text 16) insert text
			]
		][to string! text][none]
	]
]

url-encode: use [as-is space percent-encode][
	as-is: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]
	percent-encode: func [text][
		insert next text enbase/base copy/part text 1 16 change text "%"
	]

	func [text [any-string!] /wiki][
		space: either wiki [#"_"][#"+"]
		either parse text: to binary! text [
			copy text any [
				  text: some as-is | end | change " " space
				| [#"_" | #"."] (either wiki [percent-encode text][text])
				| skip (percent-encode text)
			]
		][to string! text][""]
	]
]

load-webform: use [result path string pair as-path term][
	result: copy []

	as-path: func [name [string!]][
		to path! to block! replace/all name #"." #" "
	]

	path: use [aa an wd][
		aa: charset [#"a" - #"z" #"A" - #"Z" #"_"]
		an: charset [#"-" #"0" - #"9" #"a" - #"z" #"A" - #"Z" #"_"]
		wd: [aa 0 40 an] ; one alpha, any alpha/numeric/dash/underscore
		[wd 0 6 [#"." wd]]
	]

	string: use [ch hx][
		ch: charset ["-._~" #"0" - #"9" #"A" - #"Z" #"a" - #"z"]
		hx: charset [#"0" - #"9" #"a" - #"f" #"A" - #"F"]
		[any [ch | #"+" | #"%" 2 hx]] ; any [unreserved | percent-encoded]
	]

	term: [#"&" | end]

	pair: use [name value tree][
		[
			copy name path [
				#"=" copy value string term | term (value: none)
			] (
				tree: :result
				name: as-path name
				value: url-decode value

				until [
					tree: any [
						find/tail tree name/1
						insert tail tree name/1
					]

					name: next name

					switch type?/word tree/1 [
						none! [unless tail? name [insert/only tree tree: copy []]]
						string! [change/only tree tree: reduce [tree/1]]
						block! [tree: tree/1]
					]

					if tail? name [append tree value]
				]
			)
		]
	]

	func [
		[catch] "Loads Data from a URL-Encoded Web Form string"
		webform [string! none!]
	][
		webform: any [webform ""]
		result: copy []

		either parse webform [opt [#"&" | #"?"] any pair][result][
			make error! "Not a URL Encoded Web Form"
		]
	]
]

to-webform: use [
	webform form-key emit ruby-style?
	here path reference value block array object
][
	path: []
	form-key: does [
		rejoin collect [
			keep first path
			foreach key next path [
				keep reduce either ruby-style? [["[" key "]"]][["." key]]
			]
		]
	]

	emit: func [data][
		repend webform ["&" form-key "=" url-encode data]
	]

	reference: [
		some [
			here: get-word!
			(change/only here attempt [get/any here/1])
			| skip
		]
	]

	value: [
		  here: number! (emit form here/1)
		| [logic! | 'true | 'false] (emit form here/1)
		| [none! | 'none]
		| date! (replace form date "/" "T")
		| [any-string! | tuple! | money! | time! | pair! | issue!] (emit form here/1)
	]

	array: [and opt reference any value end]

	object: [
		and opt reference any [
			here: [word! | set-word!] (
				append path url-encode to string! to word! here/1
			)
			[value | block] (remove back tail path)
		] end
	]

	block: [
		here: and [
			  any-block! (change/only here copy here/1)
			| object! (change/only here body-of here/1)
		] into [object | array]
	]

	func [
		"Serializes block data as URL-Encoded Web Form string"
		data [block! object!] /prefix /ruby-style
	][
		clear path
		webform: copy ""
		data: either object? data [body-of data][copy data]
		ruby-style?: :ruby-style

		if parse copy data object [
			either all [
				prefix not tail? next webform
			][
				back change webform "?"
			][
				remove webform
			]
		]
	]
]