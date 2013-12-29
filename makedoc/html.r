REBOL [
	Title: "HTML Emitter"
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

press: :rejoin

;-- Helpers
feed: does [emit newline]

wrap: func [text [string! block!] tag [tag! none!]][
	either tag [
		insert text tag
		parse/all form tag ["<" tag: (insert tag "/") [to " " | to ">"] tag: (clear tag)]
		append text tag
	][text]
]

to-attr: func ['attr [word!]][
	if url? get :attr [
		set :attr form-url get :attr
	]

	either get :attr [
		press [" " form attr {="} sanitize form get :attr {"}]
	][""]
]

emit-smarttag: func [spec [block!] /local name tag errs rel][
	errs: []
	unless switch name: take tag: copy spec [
		a link [
			if tag: match tag [
				href: file! | url! | email!
				anchor: opt string!
				title: opt string!
				rel: opt get-word! is within [:flow :nofollow]
			][
				with tag [
					if name = 'a [title: :anchor]
					anchor: any [anchor form href]
					all [rel rel: next form rel]
					if email? href [href: join #[url! "mailto:"] href]
					emit switch name [
						link [["<a" to-attr href to-attr rel to-attr title ">" sanitize anchor </a>]]
						a [["<a" to-attr href to-attr rel to-attr title ">"]]
					]
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

emit-square: use [rule counter finish code][
	rule: [
		(code: none counter: 0 finish: [])
		some [
			  <sb> (++ counter)
			| </sb> (-- counter if zero? counter [finish: [to end]]) finish
			| set code paren! (-- counter) to end break
			| skip
		]
	]

	does [
		parse position rule
		either all [code zero? counter][
			emit-smarttag join [a] code
			hold </a>
		][
			emit "["
			hold ""
		]
	]
]

emit-instagram: func [spec [block!] /local photo href src alt][
	either all [
		photo: match/loose spec [
			id: url!
			size: opt 'medium | 'large
			alt: opt string!
		]
		parse/all photo/id amend [
			"http://instagram.com/p/" copy src some alphanum opt "/"
		]
	][
		href: photo/id
		src: press ["http://instagr.am/p/" src "/media/" either photo/size = 'large ["?size=l"][""]]
		alt: any [photo/alt ""]
		emit [
			{^/<div class="instagram img">^/<a href="} href {">}
			{<img src="} src {" alt="} alt {"/></a>^/</div>}
		]
	][
		raise ["Invalid Instagram Spec #" sanitize mold spec]
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

get-video-id: func [spec [url!] /local id][
	if parse/all spec amend [
		"http" opt "s" "://" opt "www." [
			; YouTube
			"youtu" [".be" | "be.com"] "/"
			["embed/" | "b/" | "watch?v="]
			copy id 10 12 symbol to end
			|
			; Vimeo
			opt "player." "vimeo.com/" any [wordify "/"]
			copy id 6 11 digit to end
		]
	][to issue! form id]
]

emit-video: func [spec [block!] /youtube /vimeo /local video][
	unless any [youtube vimeo][raise "Invalid Video Request" exit]

	either video: match spec [
		id: issue! | url!
		ratio: opt pair! is within [16x9 4x3]
	][
		if url? video/id [video/id: get-video-id video/id]
		video/id: join case [
			youtube [https://youtube.com/embed/]
			vimeo [http://player.vimeo.com/video/]
		] sanitize next mold video/id
		emit [{<div class="tube">^/<iframe type="text/html" src="} video/id {"></iframe>^/</div>}]
	][
		raise ["Invalid Video Spec #" sanitize mold spec]
	]
]

get-list-options: func [options [block!]][
	either options: match options [
		tag: opt 'bullets
		reversed: opt 'reversed
		start: opt integer! is more-than 0
	][
		make options [
			end: either tag = 'bullets [
				tag: <ul> </ul>
			][
				tag: to tag! rejoin ["ol" to-attr reversed to-attr start]
				</ol>
			]
		]
	][
		context [tag: <ol> end: </ol> start: 1]
	]
]

;-- Paragraph States
initial: [
	options: place: topics: ()
	; para: (emit <p> emit-inline initialize data emit [</p> newline]) normal
	default:
		(emit "^/<!-- document begin -->")
		continue normal
		(emit "^/<!-- document end -->^/")
]

normal: [
	para: (feed emit <p> emit-inline data emit </p>)
	sect1: 
		(feed emit-sect 1 data unless no-indent [emit <section>])
		in-sect
		(unless no-indent [emit </section>])
	sect2:
		(feed emit-sect 2 data unless no-indent [emit <section>])
		in-sect
		(unless no-indent [emit </section>])
	sect3: (feed emit-sect 3 data)
	sect4: (feed emit-sect 4 data)
	bullet: bullet2: bullet3: (feed emit [<ul> newline <li>] emit-inline data) in-bul (emit [</li> newline </ul>])
	enum: enum2: enum3: (feed emit [<ol> newline <li>] emit-inline data) in-enum (emit [</li> newline </ol>])
	code: (feed emit [<pre><code> sanitize data </code></pre>])
	output: (feed emit data) ; to output html directly
	define-term: (feed emit <dl class="short">) continue in-deflist (feed emit </dl>)
	image: flickr: instagram: (feed emit <figure class="image">) continue media (feed emit </figure>)
	youtube: vimeo: (feed emit <figure class="media">) continue media (feed emit </figure>)
	break: (feed emit <hr />)
	figure-in: (feed emit <figure>) in-figure (feed emit </figure>)
	figure-out: (raise "Unbalanced Figure")
	sidebar-in: (feed emit <aside class="sidebar">) in-sidebar (feed emit </aside>)
	sidebar-out: (raise "Unbalanced Sidebar")
	table-in:
		(feed emit {<table><tr>})
		table-header
		(feed emit {</tr></table>})
	table-out: (raise "Unbalanced table-out")
	list-in:
		(
			options: get-list-options data
			feed emit [options/tag <li>]
			hold options
		)
		in-list
		(
			options: release
			feed emit [</li> options/end]
		)
	center-in:
		(feed emit <center>)
		in-center
		(feed emit </center>)
	center-out: (raise "Unbalanced center-out")
	note-in:
		(feed emit [<div class="note"><p><b>] emit-inline data emit [</b></p>])
		in-note
		(emit </div>)
	note-out: (raise "Unbalanced note-out")
	define-in:
		(feed emit [<dl><dt>] emit-inline data emit </dt> feed emit <dd>)
		in-define
		(feed emit [</dd></dl>])
	define-out: (raise "Unbalanced define-out")
	indent-in:
		(feed emit <div class="indented">)
		in-indent
		(feed emit </div>)
	indent-out: (raise "Unbalanced indent-out")
	column-in:
		(feed emit {<table><tr><td>})
		in-column
		(feed emit {</td></tr></table>})
	column-out: (raise "Unbalanced column-out")
	quote-in:
		(feed emit either find any [data []] 'pullquote [<blockquote class="pullquote">][<blockquote>])
		in-quote
		(feed emit </blockquote>)
	pullquote-in:
		(feed emit <blockquote class="pullquote">)
		in-pullquote
		(feed emit </blockquote>)
	column: (raise "column command not inside column group")
	group-in: in-group ; useless in normal mode, here just to enforce balanced commands
	group-out: (raise "Unbalanced Group-Out")
	; default: (emit [<p> uppercase/part form word 1 " Unknown</p>"])
]

in-block: inherit normal [
	sect1: (feed emit <h1> emit-inline data emit </h1>)
	sect2: (feed emit <h2> emit-inline data emit </h2>)
]

in-list: inherit in-block [
	list-item: (feed emit {</li><li>})
	list-out: return
]

in-bul: [
	bullet: (emit [</li> newline <li>] emit-inline data)
	bullet2: (feed emit [<ul> newline <li>] emit-inline data) in-bul2 (emit [</li> newline </ul> newline])
	bullet3: (feed emit [<ul> newline <li>]) continue in-bul2 (emit [</li> newline </ul> newline])
	enum2: (feed emit [<ol> newline <li>] emit-inline data) in-enum2 (emit [</li> newline </ol> newline])
	enum3: (feed emit [<ol> newline <li>]) continue in-enum2 (emit [</li> newline </ol> newline])
	default: continue return
]

in-bul2: [
	bullet2: (feed emit [</li> newline <li>] emit-inline data)
	bullet3: (feed emit <ul>) continue in-bul3 (feed emit </ul>)
	enum3: (feed emit <ol>) continue in-enum3 (feed emit </ol>)
	default: continue return
]

in-bul3: [
	bullet3: (feed emit <li> emit-inline data emit </li>)
	default: continue return
]

in-enum: [
	enum: (emit [</li> newline <li>] emit-inline data)
	bullet2: (feed emit [<ul> newline <li>] emit-inline data) in-bul2 (emit [</li> newline </ul> newline])
	bullet3: (feed emit [<ul> newline <li>]) continue in-bul2 (emit [</li> newline </ul> newline])
	enum2: (feed emit [<ol> newline <li>] emit-inline data) in-enum2 (emit [</li> newline </ol> newline])
	enum3: (feed emit [<ol> newline <li>]) continue in-enum2 (emit [</li> newline </ol> newline])
	default: continue return
]

in-enum2: [
	enum2: (emit [</li> newline <li>] emit-inline data)
	bullet3: (feed emit <ul>) continue in-bul3 (feed emit [</ul> newline])
	enum3: (feed emit <ol>) continue in-enum3 (feed emit [</ol> newline])
	default: continue return
]

in-enum3: [
	enum3: (feed emit <li> emit-inline data emit </li>)
	default: continue return
]

in-deflist: [
	define-term: (feed emit <dt> emit-inline data emit </dt>)
	define-desc: (feed emit <dd> emit-inline data emit </dd>)
	default: continue return
]

table-header: [
	table-out: return
	table-row: (emit {^/</tr><tr>}) table-rows
	para: (emit <th> emit-inline data emit </th>)
	sect1: (emit <th> emit-sect 1 data emit </th>) ; sections make no sense here, but can we just ignore them?
	sect2: (emit <th> emit-sect 2 data emit </th>)
	sect3: (emit <th> emit-sect 3 data emit </th>)
	sect4: (emit <th> emit-sect 4 data emit </th>)
	bullet: bullet2: bullet3: (emit "<th><ul>") continue in-bul (emit "</ul></th>")
	enum: enum2: enum3: (emit "<th><ol>") continue in-enum (emit "</ol></th>")
	code: (emit [<th> <pre> sanitize data </pre> </th>])
	output: (emit data) ; to output html directly

	define-term:
		(emit {^/<th><dl>^/<dt>} emit-inline data emit "</dt>^/")
		in-table-define
		(emit {</dl></th>})
	image: (
		emit [
			either data/2 = 'center [<th class="centered">][<th>]
			{<img src="} data/1 {"/>}
			</th>
		]
	)
	center-in:
		(emit "<th><center>")
		in-center
		(emit "</center></th>")
	center-out: (raise "Unbalanced center-out")
	note-in:
		(emit [<th><div class="note"><p><b>] emit-inline data emit [</b></p>])
		in-note
		(emit "</div></th>")
	note-out: (raise "Unbalanced note-out")
	indent-in:
		(emit "<th><blockquote>") ; doesn't make much sense either, does it?
		in-indent
		(emit "</blockquote></th>")
	indent-out: (raise "Unbalanced indent-out")
	column-in:
		(emit {<th><table><tr><td>})
		in-column
		(emit {</td></tr></table></th>})
	column-out: (raise "Unbalanced column-out")
	column: (raise "column command not inside column group")
	group-in: (emit <th>) in-group (emit </th>)
	group-out: (raise "Unbalanced group-out")
]

table-rows: [
	table-out: continue return ; back to table-header which goes back to caller
	table-row: (emit {</tr>^/<tr>})
	para: (emit <td> emit-inline data emit </td>)
	; sections make no sense here, but can we just ignore them?
	sect1: (emit <td> emit-sect 1 data emit </td>)
	sect2: (emit <td> emit-sect 2 data emit </td>)
	sect3: (emit <td> emit-sect 3 data emit </td>)
	sect4: (emit <td> emit-sect 4 data emit </td>)
	bullet: bullet2: bullet3: (emit {<td><ul>}) continue in-bul (emit {</ul></td>})
	enum: enum2: enum3: (emit {<td><ol>}) continue in-enum (emit {</ol></td>})
	code: (emit [<td> <pre><code> sanitize data </code></pre> </td> newline])
	output: (emit data) ; to output html directly

	define-term:
		(emit {^/<td><dl>^/<dt>} emit-inline data emit "</dt>^/")
		in-table-define
		(emit {</dl></td>})
	image:
		(emit <td>) continue media (emit </td>)
	table-in: ; nested table
		(emit {<td><table>^/<tr>})
		table-header
		(emit "</tr>^/</table></td>")
	center-in:
		(emit <td style="align: center;">)
		in-center
		(emit </td>)
	center-out: (raise "Unbalanced center-out")
	note-in:
		(emit [<td><div class="note">] emit-inline data emit [</div></td>])
		in-note
		(emit "</div></td>")
	note-out: (raise "Unbalanced note-out")
	indent-in:
		(emit {<td class="indented">}) ; doesn't make much sense either, does it?
		in-indent
		(emit </td>)
	indent-out: (raise "Unbalanced indent-out")
	column-in:
		(emit {<td><table><tr><td>})
		in-column
		(emit {</td></tr></table></td>})
	column-out: (raise "Unbalanced column-out")
	column: (raise "column command not inside column group")
	group-in: (emit <td>) in-group (emit </td>)
	group-out: (raise "Unbalanced group-out")
]

in-table-define: [
	define-desc: (emit <dd> emit-inline data emit "</dd>^/") return
]

in-group: inherit normal [
	sect1: sect2: (raise "No Headings In Here!")
	group-out: return
]

in-center: inherit in-block [
	center-out: return
]

media: [
	youtube: (feed emit-video/youtube data) return
	vimeo: (feed emit-video/vimeo data) return
	flickr: (feed emit-flickr data) return
	instagram: (feed emit-instagram data) return
	image: (feed emit-image data) return
]

in-figure: [
	image: youtube: vimeo: continue media
	para: (feed emit <figcaption> emit-inline data emit </figcaption>)
	group-in: (feed emit <figcaption>) in-group (feed emit </figcaption>)
	default: (raise "Content Misplaced in Figure")
	figure-out: return
]

in-sidebar: inherit in-block [
	sidebar-out: return
]

in-note: inherit in-block [
	sect1: sect2: (raise "No Headings In Here!")
	note-out: return
]

in-quote: inherit in-block [
	quote-out: (if data [emit [<h4> data </h4>]]) return
]

in-pullquote: inherit in-block [
	pullquote-out: return
]

in-define: inherit in-block [
	define-out: return
]

in-indent: inherit in-block [
	indent-out: return
]

in-column: inherit in-block [
	column-out: return
	column: (emit {^/</td><td valign=top>^/})
]

in-sect: inherit normal [
	sect1: sect2: continue return ; pop out of the <indent>
]

;-- Inline States
inline: [
	<p> ()
	default: continue paragraph
]

paragraph: [
	:string! (emit value)
	<b> (emit <b>) in-bold (emit </b>)
	<i> (emit <i>) in-italic (emit </i>)
	<q> (emit <q>) in-qte (emit </q>)
	<dfn> (emit <dfn>) in-dfn (emit </dfn>)
	<del> (emit <del>) in-del (emit </del>)
	<ins> (emit <ins>) in-ins (emit </ins>)
	<cite> (emit <cite>) in-cite (emit </cite>)
	<var> <code> (emit <code>) in-code (emit </code>)
	<apos> (emit "&#8216;") </apos> (emit "&#8217;")
	<quot> (emit "&#8220;") </quot> (emit "&#8221;")
	<initial> (emit <span class="initial">) in-initial (emit </span>)
	<br/> <br /> (emit <br/>)
	<sb> (emit-square) in-square (emit release)
	</sb> (emit "]")
	:integer! :char! (emit ["&#" to integer! value ";"])
	:block! (emit-smarttag value)
	</> ()
	default: (emit "[???]")
]

in-square: inherit paragraph [
	</sb> (emit "]") return
	:paren! return
]

in-bold: inherit paragraph [</b> return </> continue return]

in-italic: inherit paragraph [</i> return </> continue return]

in-qte: inherit paragraph [</q> return </> continue return]

in-dfn: inherit paragraph [</dfn> return </> continue return]

in-del: inherit paragraph [</del> return </> continue return]

in-ins: inherit paragraph [</ins> return </> continue return]

in-cite: inherit paragraph [</cite> return </> continue return]

in-code: inherit paragraph [
	</var> </code> return
	<apos> </apos> (emit "'")
	<quot> </quot> (emit {"})
	</> continue return
]

in-initial: inherit paragraph [</initial> return </> continue return]
