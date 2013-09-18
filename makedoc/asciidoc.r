REBOL [
	Title: "AsciiDoc Emitter"
	Type: 'emitter
	License: %license.r
]

with: func [
	"Binds and evaluates a block to a specified context."
	object [any-word! object! port!] "Target context."
	block [any-block!] "Block to be bound."
	/only "Returns the block unevaluated."
][
	block: bind block object
	either only [block] :block
]

else: :true
press: :rejoin
envelop: func [
	"Returns a block, encloses any value not already of any-block type."
	values [any-type!]
][
	case [
		any-block? values [values]
		none? values [make block! 0]
		else [reduce [values]]
	]
]


;-- Helpers
last-feed: none
feed: does [last-feed: emit newline]

emit-boilerplate: func [boilerplate [string!] /local lines name value][
	lines: parse/all boilerplate "^/"
	foreach line lines [
		emit-inline reduce either parse/all line [copy name to ": " 2 skip copy value to end][
			[":" name ": " value]
		][
			[line]
		] feed
	]
]

open-table: func [position /local count][
	count: 0
	parse position [
		'table-in skip
		some [
			  'column skip
			| 'table-row to end
			| skip skip (count: count + 1)
		]
	]
	rejoin [{[grid="rows",options="header",cols=} count "]"]
]

indentation: 1
indent: func [para /local tab][
	tab: head insert/dup next copy "^/" " " indentation * 4
	replace/all compose [(next tab) (para)] <br /> tab 
]

emit-smarttag: func [spec [block!] /local tag errs rel][
	errs: []
	unless switch take tag: copy spec [
		link [
			if tag: match tag [
				href: file! | url! | email!
				anchor: opt string!
				rel: opt get-word! is within [:flow :nofollow]
			][
				with tag [
					anchor: any [anchor form href]
					if email? href [href: join #[url! "mailto:"] href]
					emit ["<a" to-attr href to-attr rel ">" sanitize anchor </a>]
				]
			]
		]
		wiki [
			if tag: match tag [
				href: string!
				anchor: opt string!
			][
				with tag [
					anchor: any [anchor href]
					href: url-encode/wiki href
					emit ["<a" to-attr href ">" sanitize anchor </a>]
				]
			]
		]
		img image icon [
			either tag: match/report-to tag [
				src: file! | url! else "Image Tag Needs Valid Source"
				alt: string! else "Image tag requires ALT text"
				size: opt pair!
			] errs [
				use [width height] with/only tag [
					width: all [size/x > -1 size/x]
					height: all [size/y > -1 size/y]
					emit ["<img" to-attr src to-attr width to-attr height to-attr alt { class="icon" />}]
				]
			][
				foreach [key reasons] errs [
					foreach reason reasons [
						emit ["[" sanitize reason "]"]
					]
				]
			]
		]
	][
		emit {<span class="attention">!Unable to parse tag!</span>}
	]
]

emit-image: func [spec [block!] /local out image][
	either image: match spec [
		src: file! | url!
		size: opt pair!
		alt: string!
		title: opt string!
		href: opt file! | url!
	][
		out: copy []
		with image [
			src: to-attr src
			alt: to-attr alt
			title: to-attr title
			size: any [size -1x-1]
			width: either 0 > width: size/x [""][to-attr width]
			height: either 0 > height: size/y [""][to-attr height]
			repend out ["<img" width height src alt title " />"]
			if href [
				insert append out </a> reduce ["<a" to-attr href ">"]
			]
		]

		emit [{<div class="img">^/} press out {^/</div>}]
	][
		raise ["Invalid Image Spec #" sanitize mold spec]
	]
]

emit-video: func [spec [block!] /youtube /vimeo /local video][
	unless any [youtube vimeo][raise "Invalid Video Request" exit]

	either video: match spec [
		id: issue!
		ratio: opt pair! is within [16x9 4x3]
	][
		video/id: join case [
			youtube [https://youtube.com/embed/]
			vimeo [http://player.vimeo.com/video/]
		] sanitize video/id
		emit [{<div class="tube">^/<iframe type="text/html" src="} video/id {"></iframe>^/</div>}]
	][
		raise ["Invalid Video Spec #" sanitize mold spec]
	]
]

;-- Paragraph States
initial: [
	options: ()
	para: (
		emit-inline data
		emit head insert/dup next copy "^/^/" "=" length? out
	) boilerplate (feed emit "////^/; done")
	default: continue boilerplate
]

boilerplate: [
	code: (emit-boilerplate data) normal
	default: continue normal
]

in-block: normal: [
	para: (feed emit-inline data feed)
	sect1: (feed emit "== " emit-inline data feed)
	sect2: (feed emit "=== " emit-inline data feed)
	sect3: (feed emit "==== " emit-inline data feed)
	sect4: (feed emit "===== " emit-inline data feed)
	bullet: (feed emit "* " emit-inline data feed)
	bullet2: (feed emit "** " emit-inline data feed)
	bullet3: (feed emit "*** " emit-inline data feed)
	enum: (feed emit ". " emit-inline data feed)
	enum2: (feed emit ".. " emit-inline data feed)
	enum3: (feed emit "... " emit-inline data feed)
	code: (feed emit "----" feed emit-inline envelop detab data feed emit "----" feed)
	define-term: (feed emit-inline data emit "::") in-definition
	table-in: (feed emit open-table position feed emit "|===") in-table (feed emit "|===" feed)
	note-in: (if data [feed emit "." emit-inline data] feed emit "[NOTE]" feed emit "========") in-note (emit "========" feed)
	default: (emit form word)
]

in-definition: [
	; define-term: (feed emit <dt> emit-inline data emit </dt>)
	define-desc: (feed emit-inline indent data feed)
	default: continue return
]

in-table: [
	table-row: (feed) column: ()
	para: (feed emit "| " emit-inline data)
	default: (feed emit ["| `" uppercase form word "` WHAT SHOULD I DO HERE???"])
	table-out: return
]

media: [
	youtube: (feed emit-video/youtube data) return
	vimeo: (feed emit-video/vimeo data) return
	image: (feed emit-image data) return
]

in-note: inherit normal [
	note-out: return
]


;-- Inline States
inline: [
	<p> ()
	default: continue paragraph
]

paragraph: [
	:string! (emit value)
	<b> (emit "*") in-bold (emit "*")
	<i> (emit "_") in-italic (emit "_")
	<q> (emit "``") in-qte (emit "''")
	<code> <var> (emit "`") in-code (emit "`")
	<br/> <br /> (feed)
	:integer! :char! (emit ["&#" to-integer value ";"])
	</> ()
	; :block! (emit-smarttag value)
	default: "[???]"
]

in-bold: inherit paragraph [</b> return </> continue return]

in-italic: inherit paragraph [</i> return </> continue return]

in-qte: inherit paragraph [</q> return </> continue return]

in-code: inherit paragraph [</var> </code> return </> continue return]
