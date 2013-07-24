REBOL [
	Title: "MakeDoc"
	Date: 14-Jun-2013
	Author: [
		"Gabriele Santilli" "FSM Concept"
		"Christopher Ross-Gill" "Reorganisation for reuse"
	]
	License: [
		"Finite State Machine"
		http://www.colellachiara.com/soft/MD3/fsm.html
	]
	; Type: 'module
	Root: %makedoc/
	Exports: [
		load-doc make-doc ; load-para make-para
	]
]

import module [ ; Amend ##;
	Title: "Amend"
	Name: reb4me.amend
	Exports: [amend]
][
	ascii: charset ["^/^-" #"^(20)" - #"^(7E)"]
	digit: charset [#"0" - #"9"]
	upper: charset [#"A" - #"Z"]
	lower: charset [#"a" - #"z"]
	alpha: union upper lower
	alphanum: union alpha digit
	hex: union digit charset [#"A" - #"F" #"a" - #"f"]

	symbol: file*: union alphanum charset "_-"
	url-: union alphanum charset "!'*,-._~" ; "!*-._"
	url*: union url- charset ":+%&=?"

	space: charset " ^-"
	ws: charset " ^-^/"

	word1: union alpha charset "!&*+-.?_|"
	word*: union word1 digit
	html*: exclude ascii charset {&<>"}

	para*: path*: union alphanum charset "!%'+-._"
	extended: charset [#"^(80)" - #"^(FF)"]

	chars: complement nochar: charset " ^-^/^@^M"
	ascii+: charset [#"^(20)" - #"^(7E)"]
	wiki*: complement charset [#"^(00)" - #"^(1F)" {:*.<>[]} #"{" #"}"]
	name: union union lower digit charset "*!',()_-"
	wordify-punct: charset "-_()!"

	bin-charset: func [set [binary!] /local out][
		out: charset {}
		foreach val set [insert out val]
		out
	]

	ucs: complement charset [#"^(00)" - #"^(7F)"]

	utf-8: use [utf-2 utf-3 utf-4 utf-5 utf-b][
		utf-2: make bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////w==}
		; #{C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF}
		utf-3: make bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//}
		; #{E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF}
		utf-4: make bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/w==}
		; #{F0F1F2F3F4F5F6F7}
		utf-5: make bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPA=}
		; #{F8F9FAFB}
		utf-b: make bitset! 64#{AAAAAAAAAAAAAAAAAAAAAP//////////}
		; #{
		; 808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F
		; A0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF
		; }

		[utf-2 1 utf-b | utf-3 2 utf-b | utf-4 3 utf-b | utf-5 4 utf-b]
	]

	inline: [ascii+ | utf-8]
	text-row: [chars any [chars | space]]
	text: [ascii | utf-8]

	ident: [alpha 0 14 file*]
	wordify: [alphanum 0 99 [wordify-punct | alphanum]]
	word: [word1 0 25 word*]
	number: [some digit]
	integer: [opt #"-" number]
	wiki: [some [wiki* | ucs]]
	ws*: white-space: [some ws]

	amend: func [rule [block!]][
		bind rule 'self
	]
]

import module [ ; Match ##;
	Title: "Match"
	Name: reb4me.match
	Exports: [match]
][
	interpolate: func [body [string!] escapes [any-block!] /local out][
		body: out: copy body

		parse/all body [
			any [
				to #"%" body: (
					body: change/part body reduce any [
						select/case escapes body/2 body/2
					] 2
				) :body
			]
		]

		out
	]

	filter: [
		result: errors: #[none]

		messages: [
			not-included "is not included in the list"
			excluded "is reserved"
			invalid "is missing or invalid"
			not-confirmed "doesn't match confirmation"
			not-accepted "must be accepted"
			empty "can't be empty"
			blank "can't be blank"
			too-long "is too long (maximum is %d characters)"
			too-short "is too short (minimum is %d characters)"
			wrong-length "is the wrong length (should be %d characters)"
			not-a-number "is not a number"
			too-many "has too many arguments"
		]

		datatype: [
			'any-string! | 'binary! | 'block! | 'char! | 'date! | 'decimal! | 'email! | 'file! |
			'get-word! | 'integer! | 'issue! | 'lit-path! | 'lit-word! | 'logic! | 'money! |
			'none! | 'number! | 'pair! | 'paren! | 'path! | 'range! | 'refinement! |
			'set-path! | 'set-word! | 'string! | 'tag! | 'time! | 'tuple! | 'url! | 'word!
		]

		else: #[none]
		otherwise: [
			['else | 'or][
				set else string! | copy else any [word! string!]
			] | (else: #[none])
		]

		source: spec: rule: key: value: required: present: target: type: format: constraints: else: none

		constraint: use [is is-not? is-or-length-is op val val-type range group][
			op: val: val-type: none
			is: ['is | 'are]
			is-or-length-is: [
				[
					['length | 'size] (val: string-length? value val-type: integer!)
					| (val: :value val-type: :type)
				] is
			]
			is-not?: ['not (op: false) | (op: true)]

			[
				is [
					'accepted otherwise (
						unless true = value [report not-accepted]
					) |
					'confirmed opt 'by set val get-word! otherwise (
						val: to-word val
						unless value = as/where :type get-from source :val format [
							report not-confirmed
						]
					) |
					is-not? 'within set group any-block! otherwise (
						either case [
							block? value [value = intersect value group]
							true [found? find group value]
						][
							unless op [report excluded]
						][
							if op [report not-included]
						]
					)
				] |
				is-or-length-is [
					is-not? 'between [set range [range! | into [2 val-type]]] otherwise (
						either op [
							case [
								val < target: range/1 [report too-short]
								val > target: range/2 [report too-long]
							]
						][
							unless any [
								val < range/1
								val > range/2
							][report excluded]
						]
					) |
					'more-than set target val-type otherwise (
						unless val > target [report too-short]
					) |
					'less-than set target val-type otherwise (
						unless val < target [report too-long]
					) |
					set target val-type otherwise (
						unless val = target [report wrong-length]
					)
				]
			]
		]

		do-constraints: does [constraints: [any constraint]]
		skip-constraints: does [constraints: [to set-word! | to end]]

		humanize: func [word][uppercase/part replace/all form word "-" " " 1]

		report: func ['message [word!]][
			message: any [
				all [string? else else]
				all [block? else select else message]
				reform [humanize key any [select messages message ""]]
			]
			unless select errors :key [repend errors [:key copy []]]
			append select errors :key interpolate message [
				#"w" [form key]
				#"W" [humanize key]
				#"d" [form target]
				#"t" [form type]
			]
		]

		engage: does [parse spec rule]
	]

	make-filter: func [source spec rule][
		spec: context compose/deep [
			(filter)
			errors: copy []
			result: copy []
			rule: [(copy/deep rule)]
			spec: [(spec)]
		]
		spec/source: copy source
		spec
	]

	get-one: func [data type /local out][
		parse data [some [out: type to end break | skip]]
		unless tail? out [take out]
	]

	get-some: func [data type /local pos out][
		out: make block! length? data
		parse data [some [pos: type (append/only out take pos) :pos | skip]]
		unless empty? out [out]
	]

	match: func [
		source [block!] spec [block!]
		/report-to exceptions [word!] "Word to assign errors to in event of failure."
	][
		spec: make-filter source spec [
			(
				remove-each item result: copy spec [not set-word? item]
				result: context append result none
			)

			some [
				set key set-word! (key: to-word key)
				set required ['opt | 'any | 'some | none]
				copy type [lit-word! any ['| lit-word!] | datatype any ['| datatype]]
				otherwise

				(
					switch/default required [
						any [
							value: get-some source type
							either value [do-constraints][skip-constraints]
						]
						opt [
							value: get-one source type
							either value [do-constraints][skip-constraints]
						]
						some [
							value: get-some source type
							either value [do-constraints][skip-constraints report invalid]
						]
					][
						value: get-one source type
						either value [do-constraints][skip-constraints report invalid]
					]

					result/(key): value
				)

				constraints
			]

			end (if all [not empty? source empty? errors][key: 'match report too-many])
		]
	
		unless spec/engage [raise "Could not parse Match specification"]

		all [exceptions set :exceptions spec/errors]
		if empty? spec/errors [spec/result]
	]
]

import module [ ; RSP ##;
	Title: "RSP Preprocessor"
	Name: reb4me.rsp
	Exports: [sanitize load-rsp render render-each]
][
	sanitize: use [ascii html* extended][
		html*: exclude ascii: charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
		extended: complement charset [#"^(00)" - #"^(7F)"]

		func [text [any-string!] /local char][
			parse/all form text [
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
			out*: "" prin: func [val][repend out* val]
			print: func [val][prin val prin newline]
		]

		to-set-block: func [block [block! object!] /local word][
			either object? block [block: third block][
				parse copy block [
					(block: copy [])
					any [set word word! (repend block [to-set-word word get/any word])]
				]
			]
			block
		]

		func [body [string!] /local code mk][
			code: make string! length? body

			append code "^/out*: make string! {}^/"
			parse/all body [
				any [
					end (append code "out*") break
					| "<%" [
						  "==" copy mk to "%>" (repend code ["prin sanitize form (" mk "^/)^/"])
						| "=" copy mk to "%>" (repend code ["prin (" mk "^/)^/"])
						| [#":" | #"!"] copy mk to "%>" (repend code ["prin build-tag [" mk "^/]^/"])
						| copy mk to "%>" (repend code [mk newline])
						| (throw make error! "Expected '%>'")
					] 2 skip
					| copy mk [to "<%" | to end] (repend code ["prin " mold mk "^/"])
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
					rsp any [locals []]
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
		out: copy ""
		locals: append any [locals []] items: compose [(items)]
		foreach :items source compose/only [
			append out render/with body (locals)
		]
		return out
	]
]

import module [ ; Make-Doc ##;
	Title: "Make Doc"
	Name: reb4me.makedoc
	Exports: [load-doc make-doc] ; make-para
][
	root: system/script/header/root

	load-next: func [string [string!] /local out][
		out: transcode/next to binary! string
		out/2: skip string subtract length? string length? to string! out/2
		out
	]

	load-scanpara: use [para!][
		para!: context amend [
			para: copy []
			emit: use [prev][
				func [data /after alt][
					all [alt in-word? data: alt]
					prev: pick back tail para 1
					case [
						not string? data [append/only para data]
						not string? prev [append para data]
						true [append prev data para]
					]
				]
			]

			text: char: values: none

			in-word?: false
			in-word: [(in-word?: true)]
			not-in-word: [(in-word?: false)]

			string: use [mk ex][
				[
					mk: {"} (
						either error? try [
							mk: load-next ex: mk
						][
							values: "="
						][
							ex: mk/2
							values: reduce ['wiki mk/1]
						]
					) :ex
				]
			]

			block: use [mk ex][
				[
					mk: #"[" (
						either error? try [
							mk: load-next ex: mk
						][
							ex
							values: "="
						][
							ex: mk/2
							values: mk/1
						]
					) :ex ; ]
				]
			]

			paren: use [mk ex][
				[
					mk: #"(" (
						either error? try [
							mk: load-next ex: mk
						][
							ex
							values: "="
						][
							ex: mk/2
							values: mk/1
						]
					) :ex ; )
				]
			]

			rule: none

			scanpara: func [paragraph [string!]][
				clear para
				parse/all paragraph rule
				new-line/all para false
				; probe para
				copy para
			]
		]

		load-scanpara: func [scanpara [file! url!]][
			if all [
				scanpara: attempt [read scanpara]
				scanpara: load/header scanpara
				'paragraph = get in take scanpara 'type
			][
				make para! compose/only [rule: (amend scanpara)]
			]
		]
	]

	load-scanner: use [para! scanner!][
		scanner!: context amend [
			doc: []
			emit: func ['style data /verbatim][
				if string? data [
					trim/tail data
					unless verbatim [data: inline/scanpara data]
					; unless verbatim [data: envelop data]
				]
				repend doc [style data]
			]

			inline: text: para: values: url-mark: none
			term: [any space [newline | end]]
			trim-each: [(foreach val values [trim/head/tail val])]
			options: []

			line:		[any space copy text text-row term (trim/head/tail text)]
			paragraph:	[copy para [text-row any [newline text-row]] term]
			lines:		[any space paragraph]
			indented:	[some space opt text-row]
			example:	[
				copy para some [indented | some newline indented]
				(para: trim/auto para)
			]
			define:		[copy text to " -" 2 skip [newline | any space] paragraph]
			commas:		[line (values: parse/all text ",") trim-each]
			pipes:		[line (values: parse/all text "|") trim-each]
			block:		[term (values: copy []) | line (values: any [attempt [load/all text][]])]
			url-start:  [url-mark: "http" opt "s" "://" opt "www."]
			url-block:  [:url-mark line (values: any [attempt [load/all text] copy []])]

			rules: none
	
			scandoc: func [document [string!]][
				clear doc
				emit options options
				parse/all document rules
				new-line/skip/all doc true 2
				doc
			]
		]

		load-scanner: func [scandoc [file! url!] scanpara [file! url!]][
			if all [
				scandoc: attempt [read scandoc]
				scandoc: load/header scandoc
				'document = get in take scandoc 'type
			][
				scandoc: make scanner! compose/only [rules: (amend scandoc)]
				if scandoc/inline: load-scanpara scanpara [
					scandoc
				]
			]
		]
	]

	fsm!: context [
		initial: state: none
		state-stack: [ ]

		goto-state: func [new-state [block!] retact [paren! none!]] [
			insert/only insert/only state-stack: tail state-stack :state :retact
			state: new-state
		]

		return-state: has [retact [paren! none!]] [
			set [state retact] state-stack
			state: any [state initial]
			do retact
			state-stack: skip clear state-stack -2
		]

		rewind-state: func [up-to [block!] /local retact stack] [
			if empty? state-stack [return false]
			stack: tail state-stack
			retact: make block! 128
			until [
				stack: skip stack -2
				append retact stack/2
				if same? up-to stack/1 [
					state: up-to
					do retact
					state-stack: skip clear stack -2
					return true
				]
				head? stack
			]
			false
		]

		event: func [
			evt [any-type!]
			/local val ovr retact done?
		][
			if not block? state [exit]
			until [
				done?: yes
				local: any [
					find state evt
					find state to get-word! type?/word evt
					find state [default:]
				]
				if local [
					parse local [
						any [any-string! | set-word! | get-word!]
						set val opt paren! (do val) [
							'continue (done?: no)
							|
							'override set ovr word! (evt: to set-word! ovr done?: no)
							|
							none
						] [
							'return (return-state)
							|
							'rewind? copy val some word! (
								if not foreach word val [
									if block? get/any word [
										if rewind-state get word [break/return true]
									]
									false
								] [
									done?: yes
								]
							)
							|
							set val word! set retact opt paren! (
								either block? get/any val [goto-state get val :retact][
									done?: yes
								]
							)
							|
							none (done?: yes)
						]
					]
				]
				done?
			]
		]

		init: func [initial-state [word! block!]] [
			; _t_ "fsm_init"
			if word? initial-state [
				unless block? initial-state: get/any :initial-state [
					make error! "Not a valid state"
				]
			]
			clear state-stack: head state-stack
			initial: state: initial-state
		]

		end: does [
			; _t_ "fsm_end"
			foreach [retact state] head reverse head state-stack [do retact]
		]
	]

	load-emitter: use [emitter! para!][
		emitter!: context [
			document: position: word: data: none

			sections: context [
				this: 0.0.0.0
				reset: does [this: 0.0.0.0]
				step: func [level /local bump mask] [
					set [bump mask] pick [
						[1.0.0.0 1.0.0.0]
						[0.1.0.0 1.1.0.0]
						[0.0.1.0 1.1.1.0]
						[0.0.0.1 1.1.1.1]
					] level
					level: form this: this + bump * mask
					clear find level ".0"
					level
				]
			]

			outline: func [doc [block!]][
				remove-each style doc: copy doc [
					not find [sect1 sect2 sect3 sect4] style
				]
				doc
			]

			init-emitter: func [doc] [
				sections/reset

				foreach [word str] doc [
					if w: find [sect1 sect2 sect3 sect4] word [
						w: index? w
						if w <= toc-levels [
							sn: sections/step w
							insert insert tail toc capture [make-heading/toc w sn copy/deep str] "<br>^/"
						]
					]
				]

				sections/reset

				if no-title [emit toc state: normal]
			]

			toc: none

			initialize: func [para [block!]][
				if string? pick para 1 [
					insert para reduce [<initial> take pick para 1 </initial>]
				]
				para
			]

			no-indent: true
			no-nums: true
			make-heading: func [level num str /toc /local lnk][
				lnk: replace/all join "section-" num "." "-"
				num: either no-nums [""] [join num pick [". " " "] level = 1]
				either toc [
					emit [{<a class="toc} level {" href="#} lnk {">}] emit-inline str emit [</a> newline]
				][
					emit [{<h} level { id="} lnk {">}] emit-inline str emit [{</h} level {>}]
				]
			]

			emit-sect: func [level str /local sn] [
				sn: sections/step level
				make-heading level sn str
			]

			form-url: func [url [url!]][
				if parse url: form url amend [
					copy url some [
						some ascii
						| change [
							copy url ucs (url: join "%" enbase/base join #{} to integer! url/1 16)
						] url | skip
					]
				][url]
			]

			hold-values: []
			hold: func [value [any-type!]][insert hold-values value value]
			release: does [take hold-values]

			out: {}
			emit: func [value][
				insert tail out reduce value
			]

			states: value: options: none

			inline: make fsm! []

			emit-inline: func [
				para [block!]
				/with state [word! block!]
				/local doc-position
			][
				doc-position: :position
				unless block? state [
					state: get in states any [:state 'inline]
				]
				inline/init state
				forall para [
					position: :para
					set 'value para/1
					inline/event :value
				]
				position: :doc-position
				inline/end
			]

			raise: func [msg] [emit ["Emitter error: " msg]]

			escape-html: :sanitize

			inherit: func [parent-state new-directives][
				append new-directives parent-state
			]
	
			raise: func [msg][
				emit compose [{<ul class="attention"><li>} (msg) {</li></ul>}]
			]

			outline: make fsm! []

			outline-do: func [doc [block!] state [block!]][
				outline/init state
				forskip doc 2 [
					position: :doc
					set [word data] doc
					outline/event to set-word! word
				]
				outline/end
			]

			generate: func [doc [block!]] [
				clear hold-values
				clear out
				sections/reset
				outline-do doc get in states 'initial
				copy out
			]
		]

		load-emitter: func [makedoc [file! url!]][
			if all [
				makedoc: attempt [read makedoc]
				makedoc: load/header makedoc
				'emitter = get in take makedoc 'type
			][
				makedoc: make emitter! compose/only [states: context (makedoc)]
			]
		]
	]

	grammar!: context [
		root: none
		template: none
		document: %document.r
		paragraph: %paragraph.r
		markup: %html.r
	]

	resolve: use [resolve-path][
		resolve-path: func [root [file! url!] target [none! file! url!]][
			case [
				none? target [target]
				url? target [target]
				url? root [root/:target]
				find/match target root [target]
				target [root/:target]
			]
		]

		resolve: func [options [object!]][
			options/root: any [options/root root]
			options/document: resolve-path options/root options/document
			options/paragraph: resolve-path options/root options/paragraph
			options/markup: resolve-path options/root options/markup
			if any [file? options/template url? options/template][
				options/template: resolve-path options/root options/template
			]
			options
		]
	]

	load-doc: use [document! form-para][
		form-para: func [para [string! block!]][
			para: compose [(para)]
		
			join "" collect [
				foreach part para [
					case [
						string? part [keep part]
						integer? part [keep form to char! part]
						switch part [
							<quot> [keep to string! #{E2809C}]
							</quot> [keep to string! #{E2809D}]
							<apos> [keep to string! #{E28098}]
							</apos> [keep to string! #{E28099}]
						][]
						char? part [keep part]
					]
				]
			]
		]

		document!: context [
			options: source: text: document: values: none
			outline: func [/level depth [integer!] /local doc][
				level: copy/part [sect1 sect2 sect3 sect4] min 4 max 1 any [depth 2]
				remove-each [style para] doc: copy document [
					not find level style
				]
				doc
			]
			title: has [title][
				if parse document [opt ['options skip] 'para set title block! to end][
					form-para title
				]
			]
			render: func [/custom options [block! object! none!]][
				make-doc/custom self make self/options any [options []]
			]
		]

		load-doc: func [
			document [file! url! string! binary! block!]
			/with model [none! block! object!]
			/custom options [none! block! object!]
			/local scanner
		][
			options: make grammar! any [options []]
			resolve options

			model: make document! any [model []]
			model/options: options
			model/values: make map! []

			case/all [
				any [file? document url? document][
					model/source: document
					document: any [read document ""]
				]
				binary? document [
					document: to string! document
				]
				string? document [
					model/text: document
					if scanner: load-scanner options/document options/paragraph [
						document: scanner/scandoc document
					]
				]
				block? document [
					model/document: :document
					model
				]
			]
		]
	]

	make-doc: func [
		document [url! file! string! binary! block! object!]
		/with model [block! object!]
		/custom options [block! object!]
		/local template emitter
	][
		options: make grammar! any [options []]
		resolve options

		unless object? document [
			document: load-doc/with/custom document model options
		]

		if object? document [
			case [
				all [
					template: options/template
					template: case/all [
						file? template [
							template: attempt [read template]
						]
						url? template [
							template: attempt [read template]
						]
						binary? template [
							template: to string! template
						]
						string? template [template]
					]
				][
					document/options/template: none
					render/with template [document]
				]

				emitter: load-emitter options/markup [
					emitter/document: document
					emitter/generate document/document
				]
			]
		]
	]
]
