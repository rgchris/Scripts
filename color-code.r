REBOL [
	Title: "Color REBOL Code in HTML"
	Date: 10-Jan-2013
	File: %color-code.r
	Author: ["Christopher Ross-Gill" "Carl Sassenrath"]
	Purpose: {
		Colorize source code based on datatype. Result is HTML <pre> block.
		Sample CSS: http://reb4.me/s/rebol.css
	}
	History: [
		29-May-2003 "Fixed deep parse rule bug."
		23-Oct-2009 "Adapted for CGI use and with hooks for CSS styling"
		10-Jan-2013 "Designed to work with REBOL 3"
	]
]

color-code: use [out emit emit-var rule value r2? step][
	out: none
	envelop: func [data][either block? data [data][compose [(data)]]]
	emit: func [data][data: reduce envelop data until [append out take data empty? data]]

	r2?: system/version < 2.99.0
	step: either r2? [:load][:transcode]

	emit-var: func [value start stop /local type][
		either none? :value [type: "cmt"][
			if path? :value [value: first :value]
			type: either word? :value [
				unless bound? value [
					value: any [
						in system/contexts/lib value
						value
					]
				]
				any [
					all [value = 'REBOL "rebol"]
					all [value? :value native? get :value "native"]
					all [value? :value any-function? get :value "function"]
					all [value? :value datatype? get :value "datatype"]
					"word"
				]
			][
				any [replace to-string type?/word :value "!" ""]
			]
		]

		either type [ ; (Done this way so script can color itself.)
			emit [
				"-[" {-var class="dt-} type {"-} "]-"
				copy/part start stop
				"-[" "-/var-" "]-"
			]
		][
			emit value
		]
	]

	rule: use [str new][
		[
			some [
				str:
				some [" " | tab] new: (emit copy/part str new) |
				newline (emit "^/") |
				#";" [thru newline | to end] new:
					(emit-var none str new) |
				[#"[" | #"("] (emit first str) rule |
				[#"]" | #")"] (emit first str) break |
				skip (
					set [value new] step/next str
					emit-var :value str new
				) :new
			]
		]
	]

	func [
		[catch] "Return color source code as HTML."
		source [string! binary!] "Source code text"
		/local script
	][
		out: make binary! 3 * length? source

		source: to either r2? [string!][binary!] source

		if script: script? source [
			append out copy/part source script
			source: :script
		]

		parse/all source rule
		out: to-string out

		foreach [from to] reduce [ ; (join avoids the pattern)
			"&" "&amp;" "<" "&lt;" ">" "&gt;"
			join "-[" "-" "<" join "-" "]-" ">"
		][
			replace/all out from to
		]

		insert out {<pre class="code rebol">}
		append out {</pre>}
	]
]

;Example: write %color-code.html color-code read %color-code.r
