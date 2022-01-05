REBOL [
	Title: "MetaStore"
	Author: "Christopher Ross-Gill"
	Version: 1.0.0
	Date: 18-Mar-2010
	Purpose: "Quick associative database"
	Comment: {Extracted from QuarterMaster project.}
	Usage: [
		write meta/Subject/key "Value"
		read meta/Subject/key
		read meta/Subject
		write meta/(probe "Subject")/key "Value"
	]
	Folder: %/My/DB/Target/
]

meta: use [root meta with url-encode load-spec][
	root: any [
		system/script/args
		system/script/header/folder
	]

	assert/type [root file!]
	
	with: func [object [any-word! object! port!] block [any-block!] /only][
		block: bind block object
		either only [block] :block
	]

	url-encode: use [ch sp][
		ch: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]

		func [text [any-string!] /wiki][
			sp: either wiki ["_"]["+"]

			either parse/all copy to-binary text [
				copy text any [
					text: some ch | end | change #" " sp |
					if (wiki) change #"_" "%5F" | #"_" |
					(text: join "%" back back tail to-hex text/1 16)
					change skip text
				]
			][to-string text][""]
		]
	]

	load-spec: func [spec [object!]][
		all with/only spec [
			url? ref
			spec: find/tail ref meta
			spec: parse/all spec "/" ; to be 'split
			parse spec [
				set host string!
				(host: join lowercase url-encode/wiki host %.r)
				set path opt string!
				(path: all [path to-word path])
			]
		]
	]

	sys/make-scheme [
		name: 'meta
		title: "Mini-MetaDB"

		actor: [
			open: func [port][
				port/locals: any [
					all [
						load-spec port/spec
						attempt [load root/(port/spec/host)]
					]
					copy []
				]
			]

			read: func [port][
				open port
				either port/spec/path [
					select port/locals port/spec/path
				][
					port/locals
				]
			]

			write: func [port value][
				open port
				with port [
					remove-each [key val] locals [key = spec/path]
					if all [spec/path value][repend locals [spec/path value]]
					new-line/all/skip locals true 2
					save/all root/(spec/host) locals
				]
			]
		]
	]

	meta: meta://
]
