Red [
    Title: "Date Formatter for Red"
    Author: "Christopher Ross-Gill"
    Date: 10-Jul-2017
    Home: http://scripts.rebol.info/scripts/form-date,docs
    File: %form-date.red
    Version: 1.1.1
    Purpose: "Return formatted date string using strftime style format specifiers"
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: 'module
    Name: 'rgchris.form-date
    Exports: [form-date form-time]
    History: [
        10-Jul-2017 1.1.1 "Ported to Red"
        06-Sep-2015 1.1.0 "Reviewed for Publication"
        12-Jun-2013 1.0.0 "Ported from Rebol 2 to Rebol 3"
    ]
    Comment: {Extracted from the QuarterMaster web framework}
]

interpolate: func [body [string!] escapes [any-block!] /local out][
    body: out: copy body

    parse body [
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

pad: func [text length [integer!] /with padding [char!]][
    padding: any [padding #"0"]
    text: form text
    skip tail insert/dup text padding length negate length
]

pad-zone: func [time /flat][
    rejoin [
        pick "-+" time/hour < 0
        pad absolute time/hour 2
        either flat [""][#":"]
        pad time/minute 2
    ]
]

pad-precise: func [second /local point] [
    second: form second
    unless point: find second "." [insert point: tail second "."]
    second: pad copy/part second point 2
    point: head change copy ".000000" point
    rejoin [second point]
]

date-codes: [
    #"a" [copy/part pick system/locale/days date/weekday 3]
    #"A" [pick system/locale/days date/weekday]
    #"b" [copy/part pick system/locale/months date/month 3]
    #"B" [pick system/locale/months date/month]
    #"C" [to integer! date/year / 100]
    #"d" [pad date/day 2]
    #"D" [date/year #"-" pad date/month 2 #"-" pad date/day 2]
    #"e" [date/day]
    #"F" [pad date/month 2 #"/" pad date/day 2 #"/" date/year]
    #"g" [pad date/year 2] ; for review
    #"G" [date/year] ; for review
    #"h" [time/hour + 11 // 12 + 1]
    #"H" [pad time/hour 2]
    #"i" [switch/default date/day [1 21 31 ["st"] 2 22 ["nd"] 3 23 ["rd"]]["th"]]
    #"I" [pad time/hour + 11 // 12 + 1 2]
    #"j" [pad date/julian 3]
    #"J" [date/julian]
    #"m" [pad date/month 2]
    #"M" [pad time/minute 2]
    #"p" [pick ["AM" "PM"] time/hour < 12]
    #"P" [pick ["am" "pm"] time/hour < 12]
    #"r" [
        pad time/hour + 11 // 12 + 1 2
        #":" pad time/minute 2 #":" pad to integer! time/second 2
        #" " pick ["AM" "PM"] time/hour < 12
    ]
    #"R" [pad time/hour 2 #":" pad time/minute 2]
    #"s" [to integer! date]
    #"S" [pad to integer! time/second 2]
    #"t" [#"^-"]
    #"T" [pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2]
    #"u" [date/weekday]
    #"U" [pad to integer! date/julian + 6 - (date/weekday // 7) / 7 2]
    #"V" [pad date/isoweek 2] ; for review
    #"w" [date/weekday // 7]
    #"W" [pad to integer! date/julian + 7 - date/weekday / 7 2]
    #"x" [pad-precise time/second]
    #"y" [pad date/year // 100 2]
    #"Y" [date/year]
    #"z" [pad-zone/flat zone]
    #"Z" [pad-zone zone]

    #"c" [
        date/year #"-" pad date/month 2 "-" pad date/day 2 "T"
        pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
        either utc ["Z"][pad-zone zone]
    ]
]

form-date: func [date [date!] format [any-string!] /utc /local time zone nyd][
    either date/time [
        if utc [date/timezone: 0]
    ][
        date/time: 0:00
        date/zone: either utc [0:00][now/zone]
    ]

    time: date/time
    zone: date/zone
    interpolate format bind date-codes 'date
]

form-time: func [time [time!] format [any-string!] /local date zone][
    date: now/date zone: 0:00
    interpolate format bind date-codes 'time
]
