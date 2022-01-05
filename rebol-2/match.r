REBOL [
	Title: "Match"
	Author: "Christopher Ross-Gill"
	Date: 4-Aug-2008
	Purpose: {Extract structured data from an unstructured block.}
	Version: 0.1.2
	Home: http://www.ross-gill.com/page/Match
	Usage: [
		result: match ["Product" $12.99][
			name: string!       ; requires a string value to be present, set to string value
			price: some money!  ; requires one or more money values, set to block
			place: opt url!     ; optional url value, set to url value or none
		]
	]
]

match: use [get-one get-some datatype raise][
	datatype: [
		'binary! | 'char! | 'date! | 'decimal! | 'email! | 'file! | 'get-word! |
		'integer! | 'issue! | 'lit-path! | 'lit-word! | 'logic! | 'money! | 'none! |
		'number! | 'pair! | 'paren! | 'path! | 'range! | 'refinement! | 'set-path! |
		'set-word! | 'string! | 'tag! | 'time! | 'tuple! | 'url! | 'word!
	]

	if system/version > 2.90.0 [throw: :do]

	raise: func [reason][throw make error! rejoin compose [(reason)]]

	get-one: func [source type /local out][
		parse source [some [out: type to end break | skip]]
		unless tail? out [take out]
	]

	get-some: func [source type /local rule pos out][
		out: make block! length? source
		parse source rule: [[pos: type (append out take pos) :pos | skip] opt rule]
		unless empty? out [out]
	]

	func [
		[catch]
		source [block!] "Data source"
		spec [block!] "Match specification"
		/loose "Ignore unmatched values"
		/local out val key required type
	][
		source: copy source
		remove-each item out: copy spec [not set-word? item]
		out: context append out none

		unless parse spec [
			some [
				set key set-word! (key: to-word key)
				set required ['opt | 'any | 'some | ]
				copy type [lit-word! any ['| lit-word!] | datatype any ['| datatype]]
				(
					switch/default required [
						any [val: any [get-some source type make block! 0]]
						opt [val: get-one source type]
						some [
							unless val: get-some source type [
								raise rejoin ["Required: " form key]
							]
						]
					][
						unless val: get-one source type [
							raise rejoin ["Required: " form key]
						]
					]
					out/(key): val
				)
			]
		][raise "Invalid MATCH Spec"]

		either any [loose empty? source][out][
			raise rejoin ["Too Many Options: " mold source]
		]
	]
]