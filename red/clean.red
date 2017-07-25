Red [
	Title: "Clean"
	Author: "Christopher Ross-Gill"
	Date: 18-Jul-2017
	File: %clean.red
	Version: 0.1.1
	Purpose: "Converts errant CP-1252 codepoints within a UTF-8 binary"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.clean
	Exports: [clean]
	History: [
		18-Jul-2017 0.1.2 "Red Version"
		14-Aug-2013 0.1.1 "Working Version"
	]
]

rgchris.clean: context [
	codepoints: #(
		; CP-1252 specific range
		128 #{E282AC} 130 #{E2809A} 131 #{C692} 132 #{E2809E} 133 #{E280A6} 134 #{E280A0}
		135 #{E280A1} 136 #{CB86} 137 #{E280B0} 138 #{C5A0} 139 #{E280B9} 140 #{C592}
		142 #{C5BD} 145 #{E28098} 146 #{E28099} 147 #{E2809C} 148 #{E2809D} 149 #{E280A2}
		150 #{E28093} 151 #{E28094} 152 #{CB9C} 153 #{E284A2} 154 #{C5A1} 155 #{E280BA}
		156 #{C593} 158 #{C5BE}
	)

	ascii: charset [#"^(00)" - #"^(7F)"]
	utf-2: charset [#"^(C2)" - #"^(DF)"]
	utf-3: charset [#"^(E0)" - #"^(EF)"]
	utf-4: charset [#"^(F0)" - #"^(F4)"]
	utf-b: charset [#"^(80)" - #"^(BF)"]

	here: none

	cleaner: [
		ascii
		  ; simplistic representation of UTF-8
		| utf-2 utf-b | utf-3 2 utf-b | utf-4 3 utf-b
		| change here: skip (
			case [
				codepoints/(here/1) [codepoints/(here/1)]
				here/1 > 191 [reduce [#{C3} here/1 and 191]]
				here/1 > 158 [reduce [#{C2} here/1]]
				/else [#{EFBFBD}]
			]
		)
	]

	clean: func [
		"Converts errant CP-1252 codepoints within a UTF-8 binary"
		string [binary!] "Binary to convert"
	][
		parse string [any cleaner]
		to string! string
	]
]

clean: get in rgchris.clean 'clean