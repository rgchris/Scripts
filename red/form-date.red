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

form-date: make object! [
    interpolate: func [body [string!] escapes [block!] /local out][
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
        "The abbreviated weekday name according to the current locale."
        #"a" [copy/part pick system/locale/days date/weekday 3]

        "The full weekday name according to the current locale."
        #"A" [pick system/locale/days date/weekday]

        "The abbreviated month name according to the current locale."
        #"b" [copy/part pick system/locale/months date/month 3]

        "The full month name according to the current locale."
        #"B" [pick system/locale/months date/month]

        "The century number (year/100) as a 2-digit integer."
        #"C" [to integer! date/year / 100]

        "The day of the month as a number (range 01 to 31)."
        #"d" [pad date/day 2]

        "Equivalent to %Y/%m/%d."
        #"D" [date/year #"-" pad date/month 2 #"-" pad date/day 2]

        "The day of the month as a number, without padding."
        #"e" [date/day]

        "Equivalent to %Y-%m-%d."
        #"F" [pad date/month 2 #"/" pad date/day 2 #"/" date/year]

        "The ISO 8601 year with century as a number."
        #"g" [pad date/year 2] ; for review

        "The ISO 8601 year without century as a number."
        #"G" [date/year] ; for review

        "The hour as a number using a 12-hour clock (range 1 to 12)."
        #"h" [time/hour + 11 // 12 + 1]

        "The hour as a 2-digit number using a 24-hour clock (range 00 to 23)."
        #"H" [pad time/hour 2]

        "The english suffix for numeric day value, 'st' for 01, 'th' for 04."
        #"i" [switch/default date/day [1 21 31 ["st"] 2 22 ["nd"] 3 23 ["rd"]]["th"]]

        "The hour as a 2-digit number using a 12-hour clock (range 01 to 12)."
        #"I" [pad time/hour + 11 // 12 + 1 2]

        "The day of the year as a number (range 001 to 366)."
        #"j" [pad date/julian 3]

        "The day of the year as a number without padding (range 1 to 366)."
        #"J" [date/julian]

        "The month as a 2-digit number (range 01 to 12)."
        #"m" [pad date/month 2]

        "The minute as a 2-digit number (range 00 to 59)"
        #"M" [pad time/minute 2]

        "Either 'AM' or 'PM' according to the given time value. Noon is treated as 'PM' and midnight as 'AM'."
        #"p" [pick ["AM" "PM"] time/hour < 12]

        "Either 'am' or 'pm' according to the given time value. Noon is treated as 'pm' and midnight as 'am'."
        #"P" [pick ["am" "pm"] time/hour < 12]

        "Equivalent to %h:%M:%S %p"
        #"r" [
            pad time/hour + 11 // 12 + 1 2
            #":" pad time/minute 2 #":" pad to integer! time/second 2
            #" " pick ["AM" "PM"] time/hour < 12
        ]

        "Equivalent to %H:%M."
        #"R" [pad time/hour 2 #":" pad time/minute 2]

        "The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)."
        #"s" [to integer! date]

        "The second as a 2-digit number (range 00 to 60)."
        #"S" [pad to integer! time/second 2]

        "Tab character."
        #"t" [#"^-"]

        "Equivalent to %H:%M:%S."
        #"T" [pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2]

        "The day of the week as a number (range 1 to 7, Monday being 1). See also %w."
        #"u" [date/weekday]

        "The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Sunday as the first day of week 01)."
        #"U" [pad to integer! date/julian + 6 - (date/weekday // 7) / 7 2]

        "The ISO 8601 week number of the current year as a 2-digit decimal number (range 01 to 53, where week 1 is the first week that has at least 4 days in the new year)."
        #"V" [pad date/isoweek 2] ; for review

        "The day of the week as a number (range 0 to 6, Sunday being 0). See also %u."
        #"w" [date/weekday // 7]

        "The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Monday as the first day of week 01)."
        #"W" [pad to integer! date/julian + 7 - date/weekday / 7 2]

        "The second as a decimal number 00-60 with REBOL nanosecond precision, a period followed by 6 digits."
        #"x" [pad-precise time/second]

        "The year as a 2-digit number without a century (range 00 to 99)."
        #"y" [pad date/year // 100 2]

        "The year as a number without a century (range 0 to maximum supported)."
        #"Y" [date/year]

        "The time-zone as hour offset from UTC (without a ':' separator)."
        #"z" [pad-zone/flat zone]

        "The time-zone as hour offset from UTC."
        #"Z" [pad-zone zone]

        "RFC3339 Date Stamp"
        #"c" [
            date/year #"-" pad date/month 2 "-" pad date/day 2 "T"
            pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
            either utc ["Z"][pad-zone zone]
        ]
    ]

    description: rejoin collect [
        keep "Target format. Available codes:"
        while [not tail? date-codes][
            keep reduce ["^/        %" date-codes/2 "  " take date-codes]
            date-codes: skip date-codes 2
        ]
    ]

    date-codes: head date-codes

    form-date: func compose [
        "Formats a date to a given specification (similar to STRFTIME)"
        date [date!] "Date to Format"
        format [any-string!] (description)
        /utc "Convert the date to UTC prior to formatting"
        /local time zone
    ] compose/only [
        either date/time [
            if utc [date/timezone: 0]
        ][
            date/time: 0:00
            date/zone: either utc [0:00][now/zone]
        ]

        time: date/time
        zone: date/zone
        interpolate format (date-codes)
    ]

    form-time: func [time [time!] format [any-string!] /local date zone][
        date: now/date zone: 0:00
        interpolate format bind date-codes 'time
    ]
]

form-time: get in form-date 'form-time
form-date: get in form-date 'form-date