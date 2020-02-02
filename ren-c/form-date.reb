Rebol [
    Title: "Date Formatter for Ren-C"
    Author: "Christopher Ross-Gill"
    Date: 2-Feb-2020
    Home: http://scripts.rebol.info/scripts/form-date,docs
    File: %form-date.reb
    Version: 1.1.0
    Purpose: {Return formatted date string using strftime style format specifiers}
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.form-date
    Exports: [form-date form-time]
    History: [
        02-Feb-2020 1.1.0 "Port to Ren-C"
        06-Sep-2015 1.1.0 "Change to use REWORD; Deprecate /GMT"
        12-Jun-2013 1.0.0 "Ported from Rebol 2"
    ]
    Notes: {Extracted from the QuarterMaster web framework}
]

pad: func [text length [integer!] /with [char!]][
    with: default [#"0"]
    text: form text
    skip tail insert/dup text with length negate length
]

pad-zone: func [time /flat][
    rejoin [
        pick "-+" time/hour < 0
        pad abs time/hour 2
        either flat [""][#":"]
        pad time/minute 2
    ]
]

pad-precise: func [seconds [any-number!] <local> out][
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
    get-iso-year: func [
        year [integer!]
        <local> d1 d2
    ][
        d1: to date! join "4-Jan-" year
        d2: to date! join "28-Dec-" year
        reduce [d1 + 1 - d1/weekday d2 + 7 - d2/weekday]
    ]

    func [
        date [date!]
        <local> out d1 d2
    ][
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
    "The abbreviated weekday name according to the current locale"
    #"a" [copy/part pick system/locale/days date/weekday 3]

    "The full weekday name according to the current locale"
    #"A" [pick system/locale/days date/weekday]

    "The abbreviated month name according to the current locale"
    #"b" [copy/part pick system/locale/months date/month 3]

    "The full month name according to the current locale"
    #"B" [pick system/locale/months date/month]

    "The century number (year/100) as a 2-digit integer"
    #"C" [to integer! date/year / 100]

    "The day of the month as a number (range 01 to 31)"
    #"d" [pad date/day 2]

    "Equivalent to '%m/%d/%Y'"
    #"D" [
        unspaced [
            date/year #"-" pad date/month 2 #"-" pad date/day 2
        ]
    ]
    "The day of the month as a number, without padding"
    #"e" [date/day]

    "Equivalent to '%Y-%m-%d'"
    #"F" [
        unspaced [
            date/year #"-" pad date/month 2 #"-" pad date/day 2
        ]
    ]

    "The ISO 8601 year as a number [needs review]"
    #"g" [pad to integer! (second to-iso-week date) // 100 2]

    "The ISO 8601 year without century as a number [needs review]"
    #"G" [to integer! second to-iso-week date]

    "The hour as a number using a 12-hour clock (range 1 to 12)"
    #"h" [time/hour + 11 // 12 + 1]

    "The hour as a 2-digit number using a 24-hour clock (range 00 to 23)"
    #"H" [pad time/hour 2]

    "The english suffix for numeric day value, 'st' for 01, 'th' for 04"
    #"i" [switch date/day [1 21 31 ["st"] 2 22 ["nd"] 3 23 ["rd"] default ["th"]]]

    "The hour as a 2-digit number using a 12-hour clock (range 01 to 12)"
    #"I" [pad time/hour + 11 // 12 + 1 2]

    "The day of the year as a number (range 001 to 366)"
    #"j" [pad date/julian 3]

    "The day of the year as a number without padding (range 1 to 366)"
    #"J" [date/julian]

    "The month as a 2-digit number (range 01 to 12)"
    #"m" [pad date/month 2]

    "The minute as a 2-digit number (range 00 to 59)"
    #"M" [pad time/minute 2]

    "Either 'AM' or 'PM' according to the given time value. Noon is treated as 'PM' and midnight as 'AM'"
    #"p" [pick ["am" "pm"] time/hour < 12]

    "Either 'am' or 'pm' according to the given time value. Noon is treated as 'pm' and midnight as 'am'"
    #"P" [pick ["AM" "PM"] time/hour < 12]

    "Equivalent to '%h:%M:%S %p'"
    #"r" [
        unspaced [
            pad time/hour + 11 // 12 + 1 2
            #":" pad time/minute 2 #":" pad to integer! time/second 2
            #" " pick ["AM" "PM"] time/hour < 12
        ]
    ]

    "Equivalent to '%H:%M'"
    #"R" [pad time/hour 2 #":" pad time/minute 2]

    "The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)"
    #"s" [to-epoch-time date]

    "The second as a 2-digit number (range 00 to 60)"
    #"S" [pad to integer! time/second 2]

    "Tab character"
    #"t" [#"^-"]

    "Equivalent to '%H:%M:%S'"
    #"T" [
        unspaced [
            pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2
        ]
    ]

    "The day of the week as a number (range 1 to 7, Monday being 1). See also %w"
    #"u" [date/weekday]

    "The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Sunday as the first day of week 01)"
    #"U" [pad to integer! date/julian + 6 - (date/weekday // 7) / 7 2]

    "The ISO 8601 week number of the current year as a 2-digit decimal number (range 01 to 53, where week 1 is the first week that has at least 4 days in the new year) [needs review]"
    #"V" [pad to integer! first to-iso-week date 2]

    "The day of the week as a number (range 0 to 6, Sunday being 0). See also %u"
    #"w" [date/weekday // 7]

    "The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Monday as the first day of week 01)"
    #"W" [pad to integer! date/julian + 7 - date/weekday / 7 2]

    "The second as a decimal number 00-60 with Red nanosecond precision, a period followed by 6 digits"
    #"x" [pad-precise time/second]

    "The year as a 2-digit number without a century (range 00 to 99)"
    #"y" [pad date/year // 100 2]

    "The year as a number (range 0 to maximum supported)"
    #"Y" [date/year]

    "The time-zone as hour offset from UTC (without a ':' separator)"
    #"z" [pad-zone/flat zone]

    "The time-zone as hour offset from UTC"
    #"Z" [pad-zone zone]

    "RFC3339 Date Stamp"
    #"c" [
        unspaced [
            date/year #"-" pad date/month 2 "-" pad date/day 2 "T"
            pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
            either utc ["Z"][pad-zone zone]
        ]
    ]
]

; self-documentation to follow
remove-each item date-codes [text? item]

form-date: func [
    "Renders a date to a given format"
    date [date!] "Date to gormat"
    format [any-string!] "Format (string largely compatible with strftime)"
    /utc "Align time with UTC"
    <local> time zone
][
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

form-time: func [
    time [time!]
    format [any-string!]
    <local> date zone
][
    date: now/date zone: 0:00
    reword/case/escape format bind date-codes 'time #"%"
]
