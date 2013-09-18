REBOL [
	Title: "Scan Para"
	Date: 16-Feb-2009
	Author: "Christopher Ross-Gill"
	Type: 'paragraph
]

not-in-word any [
	  some space (emit copy " ") not-in-word
	| copy text some alphanum (emit text) in-word
	| newline (emit <br />) not-in-word
	| #"=" [
		  block (emit values) in-word
		; | string (emit values) in-word
		| copy char number "." (
			char: load char all [char > 31 char < 65536 emit char]
		) in-word
		| "b " (emit <b>)
		| "b." (emit </b>)
		| "i " (emit <i>)
		| "i." (emit </i>)
		; | "d " (emit <dfn>)
		; | "d." (emit </dfn>)
		| "q " (emit <q>)
		| "q." (emit </q>)
		| "x " (emit <del>)
		| "x." (emit </del>)
		| "w " (emit <var>)
		| "w." (emit </var>)
		| "n " (emit <ins>)
		| "n." (emit </ins>)
		| "h " (emit <ins>)
		| "h." (emit </ins>)
		| "c " (emit <cite>)
		| "c." (emit </cite>)
		| "." (emit </>)
	]
	| #"(" [
		  "c)" (emit 169)
		| "r)" (emit 174)
		| "o)" (emit 176)
		| "tm)" (emit 8482)
		| "e)" (emit 8364)
	] in-word
	| #"[" copy char number "]" (emit reduce ['link to-issue char])
	| #"[" (emit <sb>)
	| "]" opt [paren (emit values) | (emit </sb>)] in-word
	; | #"<" ["i>" (emit <i>) | "/i>" (emit </i>) | "b>" (emit <b>) | "/b>" (emit </b>)]
	| #"<" (emit #"<") | #">" (emit #">") | #"&" (emit #"&")
	; | #"~" (emit/after <code> </code>)
	; | #"*" (emit/after <b> </b>)
	| #"`" (emit/after <code> </code>) in-word
	| #"'" (emit/after <apos> </apos>) in-word
	| #"^"" (emit/after <quot> </quot>) in-word
	| #"." ".." (emit 8230) in-word
	| #"-" ["--" (emit 8212) | "-" (emit 8211)] in-word
	| "\" copy char ["\" | "(" | "=" | "[" | "^"" | "'" | "." | "-"] (emit to-char char)
	| copy char ascii (emit char) in-word
	| copy char ucs (emit to integer! char/1) in-word
	| copy char utf-8 (emit get-ucs-code char) in-word
	| extended (emit "[???]")
	| skip
]