Rebol [
	Title: "Date Formatter for Rebol 3"
	Author: "Christopher Ross-Gill"
	Date: 6-Sep-2015
	Home: http://scripts.rebol.info/scripts/form-date,docs
	File: %form-date.r
	Version: 1.1.0
	Purpose: {Return formatted date string using strftime style format specifiers}
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: 'module
	Name: 'rgchris.form-date
	Exports: [form-date form-time]
	History: [
		06-Sep-2015 1.1.0 "Change to use REWORD; Deprecate /GMT"
		12-Jun-2013 1.0.0 "Ported from Rebol 2"
	]
	Comment: {Extracted from the QuarterMaster web framework}
]

pad: func [text length [integer!] /with padding [char!]][
	padding: any [padding #"0"]
	text: form text
	skip tail insert/dup text padding length negate length
]

pad-zone: func [time /flat][
	rejoin [
		pick "-+" time/hour < 0
		pad abs time/hour 2
		either flat [""][#":"]
		pad time/minute 2
	]
]

pad-precise: func [seconds [number!] /local out][
	seconds: form make time! seconds
	head change copy "00.000000" find/last/tail form seconds ":"
]

to-epoch-time: func [date [date!]][
	; date/time: date/time - date/zone
	date: form any [
		attempt [to integer! difference date 1-Jan-1970/0:0:0]
		date - 1-Jan-1970/0:0:0 * 86400.0
	]
	clear find/last date "."
	date
]

to-iso-week: use [get-iso-year][
	get-iso-year: func [year [integer!] /local d1 d2][
		d1: to-date join "4-Jan-" year
		d2: to-date join "28-Dec-" year
		reduce [d1 + 1 - d1/weekday d2 + 7 - d2/weekday]
	]

	func [date [date!] /local out d1 d2][
		out: [0 0]
		set [d1 d2] get-iso-year out/2: date/year

		case [
			date < d1 [d1: first get-iso-year out/1: date/year - 1]
			date > d2 [d1: first get-iso-year out/2: date/year + 1]
		]

		out/1: to integer! date + 8 - date/weekday - d1 / 7
		out
	]
]

date-codes: [
	#"a" [copy/part pick system/locale/days date/weekday 3]
	#"A" [pick system/locale/days date/weekday]
	#"b" [copy/part pick system/locale/months date/month 3]
	#"B" [pick system/locale/months date/month]
	#"C" [to integer! date/year / 100]
	#"d" [pad date/day 2]
	#"D" [
		rejoin [
			date/year #"-" pad date/month 2 #"-" pad date/day 2
		]
	]
	#"e" [date/day]
	#"g" [pad to integer! (second to-iso-week date) // 100 2]
	#"G" [to integer! second to-iso-week date]
	#"h" [time/hour + 11 // 12 + 1]
	#"H" [pad time/hour 2]
	#"i" [switch/default date/day [1 21 31 ["st"] 2 22 ["nd"] 3 23 ["rd"]]["th"]]
	#"I" [pad time/hour + 11 // 12 + 1 2]
	#"j" [pad date/julian 3]
	#"J" [date/julian]
	#"m" [pad date/month 2]
	#"M" [pad time/minute 2]
	#"p" [pick ["am" "pm"] time/hour < 12]
	#"P" [pick ["AM" "PM"] time/hour < 12]
	#"R" [pad time/hour 2 #":" pad time/minute 2]
	#"s" [to-epoch-time date]
	#"S" [pad to integer! time/second 2]
	#"t" [#"^-"]
	#"T" [
		rejoin [
			pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2
		]
	]
	#"u" [date/weekday]
	#"U" [pad to integer! date/julian + 6 - (date/weekday // 7) / 7 2]
	#"V" [pad to integer! first to-iso-week date 2]
	#"w" [date/weekday // 7]
	#"W" [pad to integer! date/julian + 7 - date/weekday / 7 2]
	#"x" [pad-precise time/second]
	#"y" [pad date/year // 100 2]
	#"Y" [date/year]
	#"z" [pad-zone/flat zone]
	#"Z" [pad-zone zone]

	#"c" [
		rejoin [
			date/year #"-" pad date/month 2 "-" pad date/day 2 "T"
			pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
			either utc ["Z"][pad-zone zone]
		]
	]
]

form-date: func [
	"Renders a date to a given format"
	date [date!] "Date to gormat"
	format [any-string!] "Format (string largely compatible with strftime)"
	/utc "Align time with UTC"
	/gmt "To be deprecated"
	/local time zone
][
	if all [gmt not system/options/quiet][
		print "/GMT is to be deprecated, use /UTC"
	]

	utc: any [utc gmt]

	either date/time [
		if date/zone [date/time: date/time - date/zone]
		date/zone: either utc [0:00][date/zone]
		date/time: date/time + date/zone
	][
		date/time: 0:00
		date/zone: either utc [0:00][now/zone]
	]

	time: date/time
	zone: date/zone
	reword/case/escape format bind date-codes 'date #"%"
]

form-time: func [time [time!] format [any-string!] /local date zone][
	date: now/date zone: 0:00
	reword/case/escape format bind date-codes 'time #"%"
]
