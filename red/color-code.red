Red [
	Title: "Color Code"
	Author: "Christopher Ross-Gill"
	Date: 5-Nov-2017
	Home: https://github.com/rgchris/Scripts
	File: %color-code.red
	Version: 2.1.2
	Purpose: {Colorize Red source code}
	Rights: http://opensource.org/licenses/Apache-2.0
	History: [
		05-Nov-2017 2.2.0 "First Red version" "Christopher Ross-Gill"
		23-Oct-2009 2.1.0 "Rewritten as QM module." "Christopher Ross-Gill"
		29-May-2003 1.0.0 "Fixed deep parse rule bug." "Carl Sassenrath"
	]
	Comment: {
		Result is HTML <pre> block.
		Sample CSS: http://reb4.me/s/rebol.css
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

sanitize: use [html*][
	html*: exclude charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}

	sanitize: func [text [string!]][
		also text: copy text parse text [
			any [
				some html*
				| change #"&" ("&amp;")
				| change #"<" ("&lt;")
				| change #">" ("&gt;")
				| change #"^"" ("&quot;")
				| remove #"^M"
				| text: change skip (rejoin ["&#" to integer! text/1 ";"])
			]
		]
	]
]

color-code: use [delim mark-up values][
	delim: charset "^-^/^M ])"

	mark-up: func [value [any-type!] from mark /local type part][
		either none? :value [type: "cmt"][
			if path? :value [value: first :value]

			type: case [
				find [Red Rebol Topaz Freebell World] :value ["lang"]
				not word? :value [replace form type? :value "!" ""]
				not value? :value [none] ; could be "word" ?
				any-function? get :value ["function"]
				datatype? get :value ["datatype"]
				value ["word"]
			]
		]

		part: sanitize copy/part from mark

		either type [
			rejoin [{<var class="dt-} type {">} part {</var>}]
		][
			part
		]
	]

	values: use [value mark here rule][
		rule: [
			some [
				  mark: some [" " | "^-"] here: keep (
					replace/all copy/part mark here "^-" "    "
				)
				| [crlf | newline] keep ("^/")
				| #";" [to newline | to end] here: keep (
					mark-up none mark here
				)
				| keep [opt #"#" [#"[" | #"("]] rule
				| keep [#"]" | #")"] break
				| skip keep (
					if error? value: try [load/next mark 'here][
						here: any [
							find mark delim
							tail mark
						]
					]
					mark-up :value mark here
				) :here
			]
		]

		[
			collect [rule [end | mark: to end keep (sanitize mark)]]
		]
	]

	func [
		[catch] "Return color source code as HTML."
		text [string!] "Source code text"
	][
		rejoin collect [
			keep {<pre class="code rebol">}
			keep parse text values
			keep {</pre>}
		]
	]
]
