Rebol [
	Title: "XML Functions"
	Author: "Christopher Ross-Gill"
	Date: 9-Jul-2017
	Home: http://www.ross-gill.com/page/XML_and_Rebol
	File: %altxml.reb
	Version: 0.5.0
	Purpose: "XML Functions for Ren-C"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.altxml
	Exports: [load-xml decode-xml]
	History: [
		09-Jul-2017 0.5.0 "Use linked lists for document model"
		02-Apr-2017 0.4.1 "Ported to Ren-C" 
		07-Apr-2014 0.4.1 "Fixed loop when handling unterminated empty tags"
		14-Apr-2013 0.4.0 "Added /PATH method"
		16-Feb-2013 0.3.0 "Switch to using PATH! type to represent Namespaces"
		22-Oct-2009 0.2.0 "Conversion from Rebol 2"
	]
]

word: use [w1 w+][
	w1: charset [
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
		#"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(02FF)"
		#"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)"
		#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
		#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
	]
	w+: charset [
		"-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
		#"^(B7)" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)"
		#"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)"
		#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
		#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
	]
	[w1 any w+]
]

decode-xml: use [nm hx ns entity char][
	nm: charset "0123456789"
	hx: charset "0123456789abcdefABCDEF"
	ns: make map! ["lt" 60 "gt" 62 "amp" 38 "quot" 34 "apos" 39 "nbsp" 160]
	; nbsp is not in the XML spec but is still commonly found in XML

	entity: [
		"&" [ ; should be #"&"
			#"#" [
				  #"x" copy char 2 4 hx ";" (char: to-integer to-issue char)
				| copy char 2 5 nm ";" (char: to-integer char)
			]
			| copy char word ";" (char: any [pick ns :char 65533])
		] (char: to-char char)
	]

	func [text [string! blank!]][
		either text [
			if parse text [any [remove entity insert char | skip]][text]
		][copy ""]
	]
]

load-xml: use [
	trees root branch node xml! doc make-node name-to-tag is-tag is-attr
	xml-rule probe-node discern-tag
][
	trees: make object! [
		new: does [make map! [parent _ first _ last _ type document]]

		make-item: func [parent [block! map! blank!]][
			make map! compose/only [
				parent (parent) back _ next _ first _ last _
				type _ name _ namespace _ value _
			]
		]

		; new: does [new-line/all/skip copy [parent _ first _ last _ type document] true 2]
		;
		; make-item: func [parent [block! map! blank!]][
		; 	new-line/all/skip compose/only [
		; 		parent (parent) back _ next _ first _ last _
		; 		type _ name _ namespace _ value _
		; 	] true 2
		; ]

		insert-before: func [item [block! map!] /local new][
			new: make-item item/parent

			new/back: item/back
			new/next: item

			either blank? item/back [
				item/parent/first: new
			][
				item/back/next: new
			]

			item/back: new
		]

		insert-after: func [item [block! map!] /local new][
			new: make-item item/parent

			new/back: item
			new/next: item/next

			either blank? item/next [
				item/parent/last: new
			][
				item/next/back: new
			]

			item/next: new
		]

		insert: func [list [block! map!]][
			either list/first [
				insert-before list/first
			][
				list/first: list/last: make-item list
			]
		]

		append: func [list [block! map!]][
			either list/last [
				insert-after list/last
			][
				insert list
			]
		]

		remove: func [item [block! map!] /back][
			either item/back [
				item/back/next: item/next
			][
				item/parent/first: item/next
			]

			either item/next [
				item/next/back: item/back
			][
				item/parent/last: item/back
			]

			also either back [item/back][item/next]
			item/parent: item/back: item/next: _ ; in case references are still held elsewhere
		]

		clear: func [list [block! map!]][
			while [list/first][remove list/first]
		]

		clear-from: func [item [block! map!]][
			also item/back
			loop-until [not item: remove item]
		]
	]

	discern-tag: func [tag [tag! issue! word!]][
		reduce case [
			word? tag [
				['type 'element 'name tag]
			]
			tag? tag [
				['type 'element 'name to word! to string! tag]
			]
			issue? tag [
				['type 'attribute 'name to word! tag]
			]
		]
	]

	xml!: context [
		name: namespace: tree: _

		find-element: func [element [tag! issue! datatype! word!]][
			do make error! "Function is deprecated."
		]

		walk: func [callback [block!] /into child [block! map!] /only][
			also _ use [node] compose/deep [
				node: any [:child tree/first]
				while [node][
					(callback) |
					if all [not only node/first][
						walk/into :callback node/first
					]
					node: node/next
				]
			]
		]

		attributes: does [
			collect [
				walk/only [
					if node/type = 'attribute [
						keep make-node node
					]
				]
			]
		]

		children: does [
			collect [
				walk/only [
					unless node/type = 'attribute [
						keep make-node node
					]
				]
			]
		]

		get-by-tag: func [tag [tag! issue!] /local type][
			tag: discern-tag tag

			collect [
				walk [
					if all [
						node/type = tag/type
						node/name = tag/name
					][
						keep make-node node
					]
				]
			]
		]

		get-by-id: func [id [issue! string!] /local rule at hit][
			any [
				string? id
				id: remove mold id
			]

			catch [
				walk [
					; probe-node node
					all [
						node/type = 'attribute
						node/name = 'id
						node/value = id
						throw make-node node/parent
					]
				]
			]
		]

		text: func [/local rule text part][
			unspaced collect [
				walk [
					if find [text whitespace cdata] node/type [
						keep node/value
					]
				]
			]
		]

		get: func [tag [issue! tag! word!] /object /text][
			tag: discern-tag tag

			catch [
				walk/only [
					if all [
						node/type = tag/type
						node/name = tag/name
					][
						node: make-node node

						throw case [
							node/type = 'attribute [node/value]
							object [node]
							text [node/text]
							/else [node]
						]
					]
				]
			]
		]

		sibling: func [/before /after][
			case [
				all [after tree/next][
					make-node tree/next
				]

				all [before tree/back not find [attribute] tree/back/type][
					make-node tree/back
				]
			]
		]

		parent: func [/local branch][
			unless tree/parent/type = 'document [
				make-node tree/parent
			]
		]

		path: func [path [block! path!] /local result selectors selector kids][
			unless parse path [some ['* [tag! | issue!] | tag! | issue! | integer!] opt '?][
				do make error! "Invalid XML Path Spec"
			]

			result: :self

			; this is running REALLY slow...
			unless parse path [
				opt [
					tag! (
						selector: discern-tag pick path 1
						unless all [
							selector/type = result/type
							selector/name = result/name
						][
							result: _
						]
					)
				]

				any [
					selectors:
					['* [tag! | issue!]]
					(
						kids: collect [
							foreach kid compose [(any [:result []])][
								keep kid
							]
						]

						result: collect [
							foreach kid kids [
								keep kid/get-by-tag pick selectors 2
							]
						]
					)
					|
					[tag! | issue!] (
						selector: discern-tag pick selectors 1

						kids: collect [
							foreach kid collect [if result [keep result]] [
								keep either selector/type = 'attribute [kid/attributes][kid/children]
							]
						]

						remove-each kid kids [
							not equal? kid/name selector/name
						]

						result: :kids
					)
					|
					integer! (
						result: pick compose [(any [:result []])] pick selectors 1
					)
				]

				opt [
					'? (
						case [
							block? result [
								result: collect [
									foreach kid result [
										keep either kid/type = 'element [
											kid/text
										][
											kid/value
										]
									]
								]
							]

							object? result [
								result: either result/type = 'element [
									result/text
								][
									result/value
								]
							]
						]
					)
				]
			][do make error! rejoin ["Error at: " mold selectors]]

			result
		]

		; Target Manipulation Functions:
		; clone (complete clone)
		; insert (texts, blocks or xml)
		; append
		; remove
		; clear
		; insert-before
		; insert-after

		as-block: use [form-node][
			form-node: func [node [block! map!]][
				new-line/all/skip collect [
					keep switch/default node/type [
						element [to tag! node/name]
						attribute [to issue! node/name]
						text [%.txt]
					][
						node/name
					]

					either node/first [
						keep/only collect [
							walk/into/only [keep form-node node] node/first
						]
					][
						keep node/value
					]
				] true 3
			]

			does [form-node tree]
		]

		flatten: use [xml path emit encode enspace form-node][
			encode: func [text][
				parse text: copy text [
					some [
						  change #"<" "&lt;"
						| change #"^"" "&quot;"
						| change #"&" "&amp;"
						| skip
					]
				]

				head text
			]

			path: copy []
			emit: func [data][repend xml data]

			enspace: func [namespace [blank! word!]][
				either namespace [mold to set-word! namespace][""]
			]

			form-node: func [node [block! map!] /child][
				switch node/type [
					element [
						emit ["<" enspace node/namespace form node/name]
						either blank? node/first [
							emit " />"
						][
							emit either node/first/type = 'attribute [" "][">"]

							walk/only/into [form-node/child node] node/first

							emit either node/last/type = 'attribute [" />"][
								["</" enspace node/namespace form node/name ">"]
							]
						]
					]

					attribute [
						emit [enspace node/namespace form node/name {="} encode form node/value {"}]
						if all [child node/next][
							emit either node/next/type = 'attribute [" "][">"]
						]
					]

					text whitespace [
						emit encode node/value
					]

					cdata [
						emit [{<![CDATA[} node/value {]]>}]
					]
				]
			]

			does [
				also xml: copy "" form-node tree
			]
		]
	]

	probe-node: func [node [block! map!] /local clone][
		clone: copy node
		clone/parent: all [block? clone/parent to tag! clone/parent/name]
		clone/next: all [block? clone/next to tag! clone/next/name]
		clone/back: all [block? clone/back to tag! clone/back/name]
		clone/first: all [block? clone/first to tag! clone/first/name]
		clone/last: all [block? clone/last to tag! clone/last/name]
		probe clone
		node
	]

	make-node: func [base [block! map!] /document][
		make xml! [
			tree: :base
			name: tree/name
			namespace: tree/namespace
			value: tree/value
			type: tree/type
			document?: truthy? document
		]
	]

	xml-rule: use [space whitespace entity text attribute element header content][
		space: use [space value this][
			space: charset "^-^/^M "
			[	some space]
		]

		whitespace: use [value this][
			[	copy value space (
					this: trees/append node
					this/type: 'whitespace
					this/name: %.space
					this/value: value
				)
			]
		]

		entity: use [nm hx][
			nm: charset "0123456789"
			hx: charset "0123456789abcdefABCDEF"
			[#"&" [word | #"#" [1 5 nm | #"x" 1 4 hx]] ";" | #"&"]
		]

		text: use [this char value][
			; intersect charset ["^-^/^M" #" " - #"^(FF)"] complement charset [#"^(00)" - #"^(20)" "&<"]
			char: charset ["^-^/^M" #"^(20)" - #"^(25)" #"^(27)" - #"^(3B)" #"^(3D)" - #"^(FFFF)"] ; "
			[	copy value [
					opt space [char | entity]
					any [char | entity | space]
				] (
					this: trees/append node
					this/type: 'text
					this/name: %.txt
					this/value: decode-xml value
				)
			]
		]

		attribute: use [attr name namespace value][
			[	(namespace: _)
				opt space
				copy name word opt [#":" (namespace: to word! name) copy name word]
				opt space "=" opt space [
					  {"} copy value to {"}
					| {'} copy value to {'}
				] skip (
					attr: trees/append node
					attr/type: 'attribute
					attr/name: to word! name
					attr/namespace: namespace
					attr/value: decode-xml value
				)
			]
		]

		element: use [tag name namespace value mark this][
			[	#"<" [
					(namespace: _)
					copy tag [
						copy name word opt [#":" (namespace: to word! name) copy name word]
					] (
						insert/only branch node: trees/append node
						insert branch tag

						node/type: 'element
						node/name: to word! name
						node/namespace: namespace
						node/parent: pick branch 4
					)
					any attribute opt space [
						"/>" (
							remove/part branch 2
							node: pick branch 2
						)
						|
						#">" content [
							"</" branch/1 opt space #">" (
								remove/part branch 2
								node: pick branch 2
							)
							|
							; temporary error marker
							mark: "</" (print ["Expected:" rejoin [</> branch/1]]) :mark ?? fail
						]
						|
						; temporary error marker
						(print "Expected '>'") ?? fail
					]
					| #"!" [
						  "--" copy value to "-->" 3 skip ; (doc/append-child %.cmt value)
						| "[CDATA[" copy value to "]]>" 3 skip (
							this: trees/append node
							this/type: 'cdata
							this/name: %.cdata
							this/value: value
						)
					]
				]
			]
		]

		header: [
			any [
				  space 
				| "<" ["?xml" thru "?>" | "!" ["--" thru "-->" | thru ">"] | "?" thru "?>"]
			]
		]

		content: [any [text | element | whitespace]]

		[header element to end]
	]

	root: branch: node: _

	load-xml: func [
		"Transform an XML document to a Rebol block"
		source [any-string!] "An XML string/location to transform"
		/dom "Returns an object with DOM-like methods to traverse the XML tree"
		/local document
	][
		case/all [
			any [file? source url? source][source: read source]
			binary? source [source: to string! source]
		]

		root: node: trees/new
		branch: reduce ['document root]

		either parse/case source xml-rule [
			document: make-node/document root/last
			either dom [document][document/as-block]
		][
			do make error! "Could Not Parse XML Source"
		]
	]
]