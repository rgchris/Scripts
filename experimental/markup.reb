#!/usr/local/bin/ren-c ../test/markup.test.reb

Red []

_: none
length-of: :length?
loop-until: :until

Rebol [
	Title: "Markup Codec"
	Author: "Christopher Ross-Gill"
	Date: 24-Jul-2017
	; Home: 
	File: %markup.reb
	Version: 0.1.0
	Purpose: "Markup Loader/Saver for Ren-C"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.markup
	Exports: [decode-markup html-tokenizer load-markup]
	History: [
		24-Jul-2017 0.1.0 "Initial Version"
	]
]

put: any [
	:put
	func [map [map!] key value][
		if any-string? key [key: lock copy key]
		poke map key value
	]
]

rgchris.markup: make map! 0

rgchris.markup/references: make object! [ ; need to update references
	codepoints: [
		34 "quot" #{22} 38 "amp" #{26} 60 "lt" #{3C} 62 "gt" #{3E} 160 "nbsp" #{C2A0}
		161 "iexcl" #{C2A1} 162 "cent" #{C2A2} 163 "pound" #{C2A3} 164 "curren" #{C2A4} 165 "yen" #{C2A5}
		166 "brvbar" #{C2A6} 167 "sect" #{C2A7} 168 "uml" #{C2A8} 169 "copy" #{C2A9} 170 "ordf" #{C2AA}
		171 "laquo" #{C2AB} 172 "not" #{C2AC} 173 "shy" #{C2AD} 174 "reg" #{C2AE} 175 "macr" #{C2AF}
		176 "deg" #{C2B0} 177 "plusmn" #{C2B1} 178 "sup2" #{C2B2} 179 "sup3" #{C2B3} 180 "acute" #{C2B4}
		181 "micro" #{C2B5} 182 "para" #{C2B6} 183 "middot" #{C2B7} 184 "cedil" #{C2B8} 185 "sup1" #{C2B9}
		186 "ordm" #{C2BA} 187 "raquo" #{C2BB} 188 "frac14" #{C2BC} 189 "frac12" #{C2BD} 190 "frac34" #{C2BE}
		191 "iquest" #{C2BF} 192 "Agrave" #{C380} 193 "Aacute" #{C381} 194 "Acirc" #{C382} 195 "Atilde" #{C383}
		196 "Auml" #{C384} 197 "Aring" #{C385} 198 "AElig" #{C386} 199 "Ccedil" #{C387} 200 "Egrave" #{C388}
		201 "Eacute" #{C389} 202 "Ecirc" #{C38A} 203 "Euml" #{C38B} 204 "Igrave" #{C38C} 205 "Iacute" #{C38D}
		206 "Icirc" #{C38E} 207 "Iuml" #{C38F} 208 "ETH" #{C390} 209 "Ntilde" #{C391} 210 "Ograve" #{C392}
		211 "Oacute" #{C393} 212 "Ocirc" #{C394} 213 "Otilde" #{C395} 214 "Ouml" #{C396} 215 "times" #{C397}
		216 "Oslash" #{C398} 217 "Ugrave" #{C399} 218 "Uacute" #{C39A} 219 "Ucirc" #{C39B} 220 "Uuml" #{C39C}
		221 "Yacute" #{C39D} 222 "THORN" #{C39E} 223 "szlig" #{C39F} 224 "agrave" #{C3A0} 225 "aacute" #{C3A1}
		226 "acirc" #{C3A2} 227 "atilde" #{C3A3} 228 "auml" #{C3A4} 229 "aring" #{C3A5} 230 "aelig" #{C3A6}
		231 "ccedil" #{C3A7} 232 "egrave" #{C3A8} 233 "eacute" #{C3A9} 234 "ecirc" #{C3AA} 235 "euml" #{C3AB}
		236 "igrave" #{C3AC} 237 "iacute" #{C3AD} 238 "icirc" #{C3AE} 239 "iuml" #{C3AF} 240 "eth" #{C3B0}
		241 "ntilde" #{C3B1} 242 "ograve" #{C3B2} 243 "oacute" #{C3B3} 244 "ocirc" #{C3B4} 245 "otilde" #{C3B5}
		246 "ouml" #{C3B6} 247 "divide" #{C3B7} 248 "oslash" #{C3B8} 249 "ugrave" #{C3B9} 250 "uacute" #{C3BA}
		251 "ucirc" #{C3BB} 252 "uuml" #{C3BC} 253 "yacute" #{C3BD} 254 "thorn" #{C3BE} 255 "yuml" #{C3BF}
		338 "OElig" #{C592} 339 "oelig" #{C593} 352 "Scaron" #{C5A0} 353 "scaron" #{C5A1} 376 "Yuml" #{C5B8}
		402 "fnof" #{C692} 710 "circ" #{CB86} 732 "tilde" #{CB9C} 913 "Alpha" #{CE91} 914 "Beta" #{CE92}
		915 "Gamma" #{CE93} 916 "Delta" #{CE94} 917 "Epsilon" #{CE95} 918 "Zeta" #{CE96} 919 "Eta" #{CE97}
		920 "Theta" #{CE98} 921 "Iota" #{CE99} 922 "Kappa" #{CE9A} 923 "Lambda" #{CE9B} 924 "Mu" #{CE9C}
		925 "Nu" #{CE9D} 926 "Xi" #{CE9E} 927 "Omicron" #{CE9F} 928 "Pi" #{CEA0} 929 "Rho" #{CEA1}
		931 "Sigma" #{CEA3} 932 "Tau" #{CEA4} 933 "Upsilon" #{CEA5} 934 "Phi" #{CEA6} 935 "Chi" #{CEA7}
		936 "Psi" #{CEA8} 937 "Omega" #{CEA9} 945 "alpha" #{CEB1} 946 "beta" #{CEB2} 947 "gamma" #{CEB3}
		948 "delta" #{CEB4} 949 "epsilon" #{CEB5} 950 "zeta" #{CEB6} 951 "eta" #{CEB7} 952 "theta" #{CEB8}
		953 "iota" #{CEB9} 954 "kappa" #{CEBA} 955 "lambda" #{CEBB} 956 "mu" #{CEBC} 957 "nu" #{CEBD}
		958 "xi" #{CEBE} 959 "omicron" #{CEBF} 960 "pi" #{CF80} 961 "rho" #{CF81} 962 "sigmaf" #{CF82}
		963 "sigma" #{CF83} 964 "tau" #{CF84} 965 "upsilon" #{CF85} 966 "phi" #{CF86} 967 "chi" #{CF87}
		968 "psi" #{CF88} 969 "omega" #{CF89} 977 "thetasym" #{CF91} 978 "upsih" #{CF92} 982 "piv" #{CF96}
		8194 "ensp" #{E28082} 8195 "emsp" #{E28083} 8201 "thinsp" #{E28089} 8204 "zwnj" #{E2808C} 8205 "zwj" #{E2808D}
		8206 "lrm" #{E2808E} 8207 "rlm" #{E2808F} 8211 "ndash" #{E28093} 8212 "mdash" #{E28094} 8216 "lsquo" #{E28098}
		8217 "rsquo" #{E28099} 8218 "sbquo" #{E2809A} 8220 "ldquo" #{E2809C} 8221 "rdquo" #{E2809D} 8222 "bdquo" #{E2809E}
		8224 "dagger" #{E280A0} 8225 "Dagger" #{E280A1} 8226 "bull" #{E280A2} 8230 "hellip" #{E280A6} 8240 "permil" #{E280B0}
		8242 "prime" #{E280B2} 8243 "Prime" #{E280B3} 8249 "lsaquo" #{E280B9} 8250 "rsaquo" #{E280BA} 8254 "oline" #{E280BE}
		8260 "frasl" #{E28184} 8364 "euro" #{E282AC} 8465 "image" #{E28491} 8472 "weierp" #{E28498} 8476 "real" #{E2849C}
		8482 "trade" #{E284A2} 8501 "alefsym" #{E284B5} 8592 "larr" #{E28690} 8593 "uarr" #{E28691} 8594 "rarr" #{E28692}
		8595 "darr" #{E28693} 8596 "harr" #{E28694} 8629 "crarr" #{E286B5} 8656 "lArr" #{E28790} 8657 "uArr" #{E28791}
		8658 "rArr" #{E28792} 8659 "dArr" #{E28793} 8660 "hArr" #{E28794} 8704 "forall" #{E28880} 8706 "part" #{E28882}
		8707 "exist" #{E28883} 8709 "empty" #{E28885} 8711 "nabla" #{E28887} 8712 "isin" #{E28888} 8713 "notin" #{E28889}
		8715 "ni" #{E2888B} 8719 "prod" #{E2888F} 8721 "sum" #{E28891} 8722 "minus" #{E28892} 8727 "lowast" #{E28897}
		8730 "radic" #{E2889A} 8733 "prop" #{E2889D} 8734 "infin" #{E2889E} 8736 "ang" #{E288A0} 8743 "and" #{E288A7}
		8744 "or" #{E288A8} 8745 "cap" #{E288A9} 8746 "cup" #{E288AA} 8747 "int" #{E288AB} 8756 "there4" #{E288B4}
		8764 "sim" #{E288BC} 8773 "cong" #{E28985} 8776 "asymp" #{E28988} 8800 "ne" #{E289A0} 8801 "equiv" #{E289A1}
		8804 "le" #{E289A4} 8805 "ge" #{E289A5} 8834 "sub" #{E28A82} 8835 "sup" #{E28A83} 8836 "nsub" #{E28A84}
		8838 "sube" #{E28A86} 8839 "supe" #{E28A87} 8853 "oplus" #{E28A95} 8855 "otimes" #{E28A97} 8869 "perp" #{E28AA5}
		8901 "sdot" #{E28B85} 8968 "lceil" #{E28C88} 8969 "rceil" #{E28C89} 8970 "lfloor" #{E28C8A} 8971 "rfloor" #{E28C8B}
		9001 "lang" #{E28CA9} 9002 "rang" #{E28CAA} 9674 "loz" #{E2978A} 9824 "spades" #{E299A0} 9827 "clubs" #{E299A3}
		9829 "hearts" #{E299A5} 9830 "diams" #{E299A6}
	]
	replacements: make map! [
		0 65533
		128 8364
		130 8218
		131 402
		132 8222
		133 8230
		134 8224
		135 8225
		136 710
		137 8240
		138 352
		139 8249
		140 338
		142 381
		145 8216
		146 8217
		147 8220
		148 8221
		149 8226
		150 8211
		151 8212
		152 732
		153 8482
		154 353
		155 8250
		156 339
		158 382
		159 376
	]
]

rgchris.markup/word: [ ; reserved for future use
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
	word: [w1 any w+]
]

rgchris.markup/decode: make object! [
	digit: charset "0123456789"
	hex-digit: charset "0123456789abcdefABCDEF"
	specials: charset [#"0" - #"9" #"=" #"a" - #"z" #"A" - #"Z"]
	prohibited: charset collect [
		keep [0 - 8 11 13 - 31 127 - 159 55296 - 57343 64976 - 65007]
		if char? attempt [to char! 65536][
			keep [
				65534 65535 131070 131071 196606 196607
				262142 262143 327678 327679 393214 393215
				458750 458751 524286 524287 589822 589823
				655358 655359 720894 720895 786430 786431
				851966 851967 917502 917503 983038 983039
				1048574 1048575 1114110 1114111
			]
		]
	]

	resolve: func [char [integer!]][
		any [
			select rgchris.markup/references/replacements char
			if find prohibited char [65533]
			char
		]
	]

	codepoint: name: character: _
	codepoints: make map! 0
	names: remove sort/skip/compare/reverse collect [
		foreach [codepoint name character] rgchris.markup/references/codepoints [
			put codepoints name to string! character
			keep '|
			keep name
			put codepoints name: rejoin [name ";"] to string! character
			keep '|
			keep name
		]
	] 2 2

	get-hex: func [hex [string!]][
		insert/dup hex #"0" 8 - length-of hex
		to integer! debase/base hex 16
	]

	decode-markup: func [position [string!] /attribute /local char mark response][
		; [char exit unresolvable no-terminus 
		also response: reduce [_ position false false false]
		parse/case position [
			#"#" [
				[#"x" | #"X"] [any #"0" copy char some hex-digit | some "0" (char: "00")] (
					either 7 > length-of char [char: get-hex char][
						response/3: 'could-not-resolve
						char: 65533
					]
				)
				|
				[any #"0" copy char some digit | some #"0" (char: "0")] (
					either 8 > length-of char [char: to integer! char][
						response/3: 'could-not-resolve
						char: 65533
					]
				)
			]
			mark: [#";" mark: | (response/4: 'no-semicolon)]
			(
				unless equal? char char: resolve char [response/3: 'could-not-resolve]
				response/1: any [attempt [to char! char] to char! 65533]
				response/2: :mark
			)
			|
			copy char names mark: (
				unless #";" = last char [response/4: 'no-semicolon]
				either all [response/4 attribute find specials mark/1][
					response/4: _
					response/5: 'no-semicolon-in-attribute
				][
					response/1: select codepoints char
					response/2: mark
				]
			)
		]
	]
]

decode-markup: get in rgchris.markup/decode 'decode-markup

rgchris.markup/html-tokenizer: make object! [
	; 8.2.4 Tokenization https://www.w3.org/TR/html5/syntax.html#tokenization
	series: mark: buffer: attribute: token: last-token: character: additional-character: _
	is-paused: is-done: false

	b: [#"b" | #"B"]
	c: [#"c" | #"C"]
	d: [#"d" | #"D"]
	e: [#"e" | #"E"]
	i: [#"i" | #"I"]
	l: [#"l" | #"L"]
	m: [#"m" | #"M"]
	o: [#"o" | #"O"]
	p: [#"p" | #"P"]
	s: [#"s" | #"S"]
	t: [#"t" | #"T"]
	u: [#"u" | #"U"]
	y: [#"y" | #"Y"]

	space: charset "^-^/^M "
	upper-alpha: charset "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	lower-alpha: charset "abcdefghijklmnopqrstuvwxyz"
	alpha: union upper-alpha lower-alpha
	digit: charset "0123456789"
	alphanum: union alpha digit
	hex-digit: charset "0123456789abcdefABCDEF"
	non-markup: complement charset "^@&<"
	; word: get in rgchris.markup/word 'word

	error: [(report "Parse Error")]
	null-error: [#"^@" (report "Null Character")]
	unknown: to string! #{EFBFBD}
	timely-end: [end (is-done: true emit [end]) fail]
	untimely-end: [end (report "Premature End" use data)]
	emit-one: [mark: skip (emit mark/1)]

	states: make object! [
		data: [
			  copy mark some non-markup (emit mark)
			| #"&" (use character-reference-in-data)
			| #"<" (use tag-open)
			| null-error (emit #"^@")
			| timely-end
		]

		character-reference-in-data: [
			(use data)
			end
			|
			and [space | #"&" | #"<"]
			|
			mark: (
				character: decode-markup mark
				mark: character/2
				either character/1 [
					emit character/1
				][
					emit #"&"
				]
			) :mark
		]

		rcdata: [
			  #"&" (use character-reference-in-rcdata)
			| #"<" (use rcdata-less-than-sign)
			| null-error (emit unknown)
			| timely-end
			| emit-one
		]

		character-reference-in-rcdata: [
			(use rcdata)
			end
			|
			and [space | #"<" | #"&"]
			|
			(
				character: decode-markup series
				mark: character/2
				either character/1 [
					emit character/1
				][
					emit #"&"
				]
			) :mark
		]

		rawtext: [
			  #"<" (use rawtext-less-than-sign)
			| null-error (emit unknown)
			| emit-one
			| timely-end
		]

		script-data: [
			  #"<" (use script-data-less-than-sign)
			| null-error (emit unknown)
			| emit-one
			| timely-end
		]

		plaintext: [
			  null-error (emit unknown)
			| emit-one
			| timely-end
		]

		tag-open: [
			#"!" (
				use markup-declaration-open
			)
			|
			#"/" (
				use end-tag-open
			)
			|
			copy mark [alpha any alphanum] (
				use tag-name
				token: reduce ['tag lowercase mark _ _]
			)
			|
			and "?" (
				use bogus-comment
				report 
			)
			|
			(
				use data
				report "Unexpected character after '<'"
				emit #"<" 
			)
		]

		end-tag-open: [
			copy mark some alpha (
				use tag-name
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			#">" (
				use data
				report "Premature '>'"
			)
			|
			untimely-end (
				emit "</"
			)
			|
			(
				use bogus-comment
				report "Unexpected character after '</'"
			)
		]

		tag-name: [
			some space (
				use before-attribute-name
			)
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			copy mark some alpha (
				append token/2 lowercase mark
			)
			|
			null-error (
				append token/2 unknown
			)
			|
			untimely-end
			|
			skip (
				append token/2 series/1
			)
		]

		rcdata-less-than-sign: [
			#"/" (
				use rcdata-end-tag-open
				buffer: make string! 0
			)
			|
			(
				use rcdata
				emit #"<"
			)
		]

		rcdata-end-tag-open: [
			copy mark some alpha (
				use rcdata-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use rcdata
				emit "</"
				buffer: _
			)
		]

		rcdata-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = "title"
					; token/2 = last-tag
				][
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							token/2: to word! token/2
							emit also token token: buffer: _
						]
					]
				][
					use rcdata
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use rcdata
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		rawtext-less-than-sign: [
			#"/" (
				use rawtext-end-tag-open
				buffer: make string! 0
			)
			|
			(
				use rawtext
				emit #"<"
			)
		]

		rawtext-end-tag-open: [
			copy mark some alpha (
				use rawtext-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use rawtext
				emit "</"
				emit also buffer buffer: _
			)
		]

		rawtext-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					find ["style" "textarea"] token/2
					; token/2 = last-tag
				][
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							token/2: to word! token/2
							emit also token token: buffer: _
							mark: next series
						]
					]
				][
					use rawtext
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use rawtext
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-less-than-sign: [
			#"/" (
				use script-data-end-tag-open
				buffer: make string! 0
			)
			|
			#"!" (
				use script-data-escape-start
				emit "<!"
			)
			|
			(
				use script-data
				emit #"<"
			)
		]

		script-data-end-tag-open: [
			copy mark some alpha (
				use script-data-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use script-data
				emit "</"
				emit also buffer buffer: _
			)
		]

		script-data-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = "script"
					; token/2 = last-tag
				][
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next mark
							token/2: to word! token/2
							emit also token token: buffer: _
						]
					]
				][
					use script-data
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use script-data
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-escape-start: [
			#"-" (
				use script-data-escape-start-dash
				emit #"-"
			)
			|
			(
				use script-data
			)
		]

		script-data-escape-start-dash: [
			#"-" (
				use script-data-escaped-dash-dash
				emit #"-"
			)
			|
			(
				use script-data
			)
		]

		script-data-escaped: [
			#"-" (
				use script-data-escaped-dash
				emit #"-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one
		]

		script-data-escaped-dash: [
			#"-" (
				use script-data-escaped-dash-dash
				emit #"-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-escaped
			)
		]

		script-data-escaped-dash-dash: [
			#"-" (
				emit #"-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			#">" (
				use script-data
				emit #">"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-escaped
			)
		]

		script-data-escaped-less-than-sign: [
			#"/" (
				use script-data-escaped-end-tag-open
				buffer: make string! 0
			)
			|
			copy mark some alpha (
				use script-data-double-escape-start
				emit #"<"
				emit mark
				buffer: lowercase mark
			)
			|
			(
				use script-data-escaped
				emit #"<"
			)
		]

		script-data-escaped-end-tag-open: [
			copy mark some alpha (
				use script-data-escaped-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use script-data-escaped
				emit "</"
			)
		]

		script-data-escaped-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = "script"
					; token/2 = last-tag
				][
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							token/2: to word! token/2
							emit also token token: buffer: _
						]
					]
				][
					use script-data-escaped
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use script-data-escaped
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-double-escape-start: [
			[space | #"/" | #">"] (
				either buffer == "script" [
					use script-data-double-escaped
				][
					use script-data-escaped
				]
				emit series/1
			)
			|
			copy mark some alpha (
				emit mark
				append buffer lowercase mark
			)
			|
			(
				use script-data
			)
		]

		script-data-double-escaped: [
			#"-" (
				use script-data-double-escaped-dash
				emit #"-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign
				emit #"<"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one
		]

		script-data-double-escaped-dash: [
			#"-" (
				use script-data-double-escaped-dash-dash-state
				emit #"-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign-state
				emit #"<"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-double-escaped
			)
		]

		script-data-double-escaped-dash-dash: [
			#"-" (
				emit #"-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign
				emit #"<"
			)
			|
			#">" (
				use script-data
				emit #">"
			)
			|
			null-error (
				use script-data-double-escaped
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-double-escaped
			)
		]

		script-data-double-escaped-less-than-sign: [
			#"/" (
				use script-data-double-escape-end
				emit #"/"
				buffer: make string! 0
			)
			|
			[end | emit-one] (
				use script-data-double-escaped
			)
		]

		script-data-double-escape-end: [
			mark:
			[space | #"/" | #">"] (
				either buffer == "script" [
					use script-data-escaped
				][
					use script-data-double-escaped
				]
				emit mark/1
			)
			|
			copy mark some alpha (
				emit mark
				append buffer lowercase mark
			)
			|
			(
				use script-data-double-escaped
			)
		]

		before-attribute-name: [
			some space
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end
			|
			[
				  null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| copy mark [#"^(22)" | #"'" | #"<" | #"="] error
				| copy mark skip
			] (
				use attribute-name
				token/3: any [token/3 make map! 0]
				attribute: reduce [mark make string! 0]
			)
		]

		attribute-name: [
			[
				  some space (use after-attribute-name)
				| #"/" (use self-closing-start-tag)
				| #"=" (use before-attribute-value)
				| untimely-end
			] (
				either find token/3 attribute/1 [
					report "Attribute already in tag"
				][
					put token/3 attribute/1 attribute/2
				]
			)
			|
			#">" (
				use data
				either find token/3 attribute/1 [
					report "Attribute already in tag"
				][
					put token/3 attribute/1 attribute/2
				]
				emit also token token: attribute: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| copy mark [#"^(22)" | #"'" | #"<"] error
				| copy mark skip
			] (
				append attribute/1 mark
			)
		]

		after-attribute-name: [
			some space
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#"=" (
				use before-attribute-value
			)
			|
			#">" (
				use data
				emit token
			)
			|
			untimely-end
			|
			[
				  null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| [#"^(22)" | #"'" | #"<"] error
				| copy mark skip
			] (
				use attribute-name
				attribute: reduce [mark make string! 0]
			)
		]

		before-attribute-value: [
			some space
			|
			#"^(22)" (
				use attribute-value-double-quoted
				additional-character: #"^(22)"
			)
			|
			#"'" (
				use attribute-value-single-quoted
				additional-character: #"'"
			)
			|
			#">" (
				use data
				report "Premature '>' in tag"
				emit also token token: attribute: _
			)
			|
			untimely-end
			|
			and #"&" (
				use attribute-value-unquoted
				additional-character: #">"
			)
			|
			and [
				  null-error
				| [#"<" | #"=" | #"`"] (report "Unexpected Token")
				| skip
			] (
				use attribute-value-unquoted
				additional-character: #">"
			)
		]

		attribute-value-double-quoted: [ ; 38
			#"^(22)" (
				use after-attribute-value-quoted
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			untimely-end
			|
			[null-error (mark: unknown) | copy mark skip] (
				append attribute/2 mark
			)
		]

		attribute-value-single-quoted: [
			#"'" (
				use after-attribute-value-quoted
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			untimely-end
			|
			[null-error (mark: unknown) | copy mark skip] (
				append attribute/2 mark
			)
		]

		attribute-value-unquoted: [
			some space (
				use before-attribute-name
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end
			|
			[
				  null-error (mark: unknown)
				| copy mark [#"^(22)" | #"'" | #"<" | #"=" | #"`"] error
				| copy mark skip
			] (
				append attribute/2 mark
			)
		]

		character-reference-in-attribute-value: [
			(use :last-state-name)
			and [space | #"&" | #"<" | additional-character]
			|
			end
			|
			mark: (
				character: decode-markup mark
				mark: character/2
				either character/1 [
					append attribute/2 character/1
				][
					append attribute/2 #"&"
				]
			) :mark
		]

		after-attribute-value-quoted: [
			some space (
				use before-attribute-name
			)
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end
			|
			(
				use attribute-name-state
			)
		]

		self-closing-start-tag: [
			#">" (
				use data
				token/4: 'self-closing
				emit token
			)
			|
			untimely-end
			|
			(
				use before-attribute-name
				report "Expected '>'"
			)
		]

		bogus-comment: [
			(use data)
			[
				  copy mark to #">" skip
				| copy mark to end
			] (
				emit reduce ['comment mark]
			)
		]

		markup-declaration-open: [
			"--" (
				use comment-start
				token: reduce ['comment make string! 0]
			)
			|
			d o c t y p e (
				use doctype
			)
			|
			and "[CDATA[" (
				use bogus-comment
				report "CDATA not supported"
			)
			|
			(
				use bogus-comment
				report "Malformed comment"
			)
		]

		comment-start: [
			#"-" (
				use comment-start-dash
			)
			|
			#">" (
				use data
				report "Malformed Comment"
				emit also token token: _
			)
			|
			untimely-end
			|
			[
				  null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 mark
			)
		]

		comment-start-dash: [
			#"-" (
				use comment-end
			)
			|
			#">" (
				use data
				report "Malformed comment"
				emit also token token: _
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			(
				use comment
				emit #"-"
			)
		]

		comment: [
			#"-" (
				use comment-end-dash
			)
			|
			#">" (
				use data
				report "Malformed comment"
				emit also token token: _
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark some alpha
				| copy mark skip
			] (
				append token/2 mark
			)
		]

		comment-end-dash: [
			#"-" (
				use comment-end
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 #"-"
				append token/2 mark
			)
		]

		comment-end: [
			#">" (
				use data
				emit also token token: _
			)
			|
			"!" (
				use comment-end-bang
				report "Malformed comment"
			)
			|
			#"-" (
				report "Too many consecutive dashes in comment"
				append token/2 #"-"
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark skip (report "Expected end of comment")
			] (
				append token/2 "--"
				append token/2 mark
			)
		]

		comment-end-bang: [
			#"-" (
				use comment-end-dash
				append token/2 "--!"
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 "--!"
				append token/2 mark
			)
		]

		doctype: [
			some space (
				use before-doctype-name
			)
			|
			untimely-end (
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
			|
			(
				use before-doctype-name
				report "Extraneous characters in doctype"
			)
		]

		before-doctype-name: [
			some space
			|
			[
				  null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| copy mark skip
			] (
				use doctype-name
				token: reduce ['doctype mark _ _ _]
			)
			|
			#">" (
				use data
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
			|
			untimely-end (
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
		]

		doctype-name: [
			space (
				use after-doctype-name
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark any alpha (lowercase mark)
				| copy mark skip
			] (
				append token/2 mark
			)
		]

		after-doctype-name: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			p u b l i c (
				use after-doctype-public-keyword
			)
			|
			s y s t e m (
				use after-doctype-system-keyword
			)
			|
			skip (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		after-doctype-public-keyword: [
			some space (
				use before-doctype-public-identifier-state
			)
			|
			#"^(22)" error (
				use doctype-public-identifier-double-quoted
				token/3: make string! 0
			)
			|
			#"'" error (
				use doctype-public-identifier-single-quoted
				token/3: make string! 0
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		before-doctype-public-identifier: [
			some space
			|
			#"^(22)" (
				use doctype-public-identifier-double-quoted
				token/3: make string! 0
			)
			|
			#"'" (
				use doctype-public-identifier-single-quoted
				token/3: make string! 0
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		doctype-public-identifier-double-quoted: [
			#"^(22)" (
				use after-doctype-public-identifier-state
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[null-error (mark: unknown) | copy mark [some alpha | skip]] (
				append token/3 mark
			)
		]

		doctype-public-identifier-single-quoted: [
			#"'" (
				use after-doctype-public-identifier-state
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark [some alpha | skip]
			] (append token/3 mark)
		]

		after-doctype-public-identifier: [
			space (use between-doctype-public-and-system-identifiers)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			#"^(22)" error (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" error (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		between-doctype-public-and-system-identifiers: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			untimely-end (
				token/5: 'force-quirks
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		after-doctype-system-keyword: [
			some space (
				use before-doctype-system-identifier
			)
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			#">" (
				use data
				report "Premature end of DOCTYPE System ID"
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip (
				use bogus-doctype
				report "Unexpected value in DOCTYPE declaration"
				token/5: 'force-quirks
			)
		]

		before-doctype-system-identifier: [
			some space
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			#">" error (
				use data
				report "System identifier missing"
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		doctype-system-identifier-double-quoted: [
			#"^(22)" (
				use after-doctype-system-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark some [space | alpha] (lowercase mark)
				| copy mark skip
			] (
				append token/4 mark
			)
		]

		doctype-system-identifier-single-quoted: [
			#"'" (
				use after-doctype-system-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
				  null-error (mark: unknown)
				| copy mark some [space | alpha] (lowercase mark)
				| copy mark skip
			] (
				append token/4 mark
			)
		]

		after-doctype-system-identifier: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip (
				use bogus-doctype
			)
		]

		bogus-doctype: [
			#">" (
				use data
				emit token
			)
			|
			end (
				use data
				emit token
			)
			|
			skip
		]

		cdata-section: [
			(use data)
			[copy mark to "]]>" 3 skip | copy mark to end]
			(emit mark)
		]
	]

	emit: report: _

	this-state-name: this-state: state: last-state-name: _

	use: func ['target [word!]][
		last-state-name: :this-state-name
		this-state-name: target
		; probe to tag! target
		; probe copy/part series 10
		state: this-state: any [
			get in states :target
			do make error! "No Such State"
		]
	]

	rule: [
		while [series: state]
		series: (
			; Work around Red issue: https://github.com/red/red/issues/2907
			loop-until [
				any [
					is-paused
					is-done
					; (probe state false)
					parse/case series [series: state]
				]
			]
		)
	]

	init: func [
		"Initialize the tokenization process"
		source [string!] "A markup string to tokenize"
		token-handler [function!] "A function to handle tokens"
		error-handler [function!] "A function to handle errors"
	][
		mark: buffer: attribute: token: last-token: character: additional-character: _
		this-state-name: this-state: state: last-state-name: _
		is-paused: is-done: false
		series: :source
		emit: :token-handler
		report: :error-handler
		self
	]

	start: func [
		"Start the tokenization process"
	][
		unless string? series [
			do make error! "Tokenization process has not been initialized"
		]
		use data
		parse/case series rule
	]

	pause: func [
		"Pause the tokenization process"
	][
		is-paused: true
		state: [fail]
	]

	resume: func [
		"Resume the tokenization process"
	][
		unless string? series [
			do make error! "Tokenization process has not been initialized"
		]
		is-paused: false
		state: :this-state
		parse/case series rule
	]
]

html-tokenizer: rgchris.markup/html-tokenizer

rgchris.markup/load: make object! [
	last-token: _

	load-markup: func [source [string!]][
		last-token: _
		collect [
			html-tokenizer/init source
			func [token [block! char! string!]][
				case [
					not block? token [
						either all [
							last-token
							last-token/1 = 'text
						][
							append last-token/2 token
							token: last-token
						][
							token: reduce ['text to string! token]
							keep token/2
						]
					]

					token/1 = 'tag [
						keep to tag! token/2
						if map? token/3 [keep token/3]
						if token/4 [keep </>]

						switch token/2 [
							"script" [html-tokenizer/use script-data]
							"title" [html-tokenizer/use rcdata]
							"style" [html-tokenizer/use rawtext]
						]
					]

					token/1 = 'end-tag [
						keep to tag! rejoin ["/" token/2]
					]

					token/1 = 'comment [
						keep to tag! rejoin ["!--" token/2 "--"]
					]
				]

				also _ last-token: :token
			]
			func [value][value]

			html-tokenizer/start
		]
	]
]

load-markup: get in rgchris.markup/load 'load-markup

