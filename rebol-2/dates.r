Rebol [
    Title: "Dates"
    Author: "Christopher Ross-Gill"
    Date: 17-Jul-2023
    Version: 0.1.0
    File: %dates.r

    Purpose: "Date Handler"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.dates
    Exports: [
        dates
    ]

    Needs: [
        shim
    ]

    History: [
        17-Jul-2023 0.1.0
        "Initial Version"
    ]

    Comment: [
        https://www.rfc-editor.org/rfc/rfc822
        https://www.rfc-editor.org/rfc/rfc2822
        https://www.rfc-editor.org/rfc/rfc3339
        "Internet Date Formats"
    ]
]

dates: context private [
    interpolate: func [
        body [string!]
        escapes [any-block!]
        /local out
    ][
        body:
        out: copy body

        parse/all body [
            any [
                to #"%"
                body:
                (
                    body: change/part body reduce any [
                        select/case escapes body/2
                        body/2
                    ] 2
                )
                :body
            ]
        ]

        out
    ]

    pad: func [
        text
        length [integer!]
        /with
        padding [char!]
    ][
        padding: any [
            padding #"0"
        ]

        text: form text

        skip tail insert/dup text padding length negate length
    ]

    pad-zone: func [
        time /flat
    ][
        rejoin [
            pick "-+" time/hour < 0
            pad absolute time/hour 2
            either flat [""] [#":"]
            pad time/minute 2
        ]
    ]

    pad-precise: func [
        seconds [number!]
        /local out
    ][
        seconds: form round/to make time! seconds 1E-6
        ; works so long as 0 <= seconds < 60

        head change copy "00.000000" find/last/tail form seconds ":"
    ]
][
    day: [
        "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun"
    ]

    month: [
        "Jan" | "Feb" | "Mar" | "Apr" | "May" | "Jun"
        |
        "Jul" | "Aug" | "Sep" | "Oct" | "Nov" | "Dec"
    ]

    months: [
        "Jan" "Feb" "Mar" "Apr" "May" "Jun"
        "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"
    ]

    ; RFC3339 Timestamps
    ;
    timestamp: context [
        pattern: [
            3 5 digit
            #"-"
            1 2 digit
            #"-"
            1 2 digit

            opt [
                [#"T" | #" "]
                1 2 digit
                #":"
                1 2 digit

                opt [
                    #":"
                    1 2 digit
                    opt [
                        #"."
                        1 6 digit
                    ]
                ]

                opt [
                    #"Z"
                    |
                    [#"+" | #"-"]
                    1 2 digit
                    #":"
                    1 2 digit
                ]
            ]
        ]

        detect: func [
            source [string! binary!]
            /local mark value
        ][
            if parse/all [
                copy value pattern
                mark:
                to end
            ][
                reduce [
                    value mark
                ]
            ]
        ]

        as-date: func [
            [catch]
            source [string! binary!]
            /local value
        ][
            if parse/all source [
                any #" "
                copy value pattern
                any #" "
                end
            ][
                replace value #"T" #"/"
                replace value #" " #"/"
                replace value #"Z" "+0:00"

                throw-on-error [
                    to date! value
                ]
            ]
        ]

        to-date: func [
            [catch]
            source [string! binary!]
        ][
            any [
                as-date source

                throw make error! rejoin [
                    "Could not convert TIMESTAMP value"
                ]
            ]
        ]
    ]

    ; RFC822 Dates
    ;
    idate: context [
        pattern: [
            day
            ", "
            1 2 digit
            #" "
            month
            #" "
            4 digit
            #" "
            1 2 digit
            #":"
            1 2 digit
            opt [
                #":" 2 digit
            ]
            #" "
            [
                "UTC" | "UT" | "GMT" | #"Z"
                |
                "EDT"
                |
                "EST" | "CDT"
                |
                "CST" | "MDT"
                |
                "MST" | "PDT"
                |
                "PST"
                |
                upper-alpha
                |
                [#"+" | #"-"]
                2 digit
                opt #":"
                2 digit
            ]
        ]

        as-date: func [
            source [string! binary!]
            /local value
        ][
            if parse/all source [
                any #" "
                copy value pattern
                any #" "
                end
            ][
                value: parse/all value " "

                to date! reduce [
                    to integer! value/4
                    index? find months value/3
                    to integer! value/2
                    to time! value/5

                    any [
                        switch value/6 [
                            "UTC" "UT" "GMT" "Z" [
                                0:00
                            ]

                            "J" [
                                now/zone
                                ; local time zone
                            ]

                            "EDT" [
                                -4:00
                            ]

                            "EST" "CDT" [
                                -5:00
                            ]

                            "CST" "MDT" [
                                -6:00
                            ]

                            "MST" "PDT" [
                                -7:00
                            ]

                            "PST" [
                                -8:00
                            ]
                        ]

                        parse/all value/6 [
                            upper-alpha
                        ][
                            to time! reduce [
                                case [
                                    value/6/1 < #"J" [
                                        negate -64 + value/6/1
                                    ]

                                    value/6/1 < #"M" [
                                        negate -65 + value/6/1
                                    ]

                                    /else [
                                        -77 + value/6/1
                                    ]
                                ]
                            ]
                        ]

                        parse/all value/6 [
                            [#"-" | #"+"]
                            4 digit
                        ][
                            insert skip value/6 3 #":"
                            to time! value/6
                        ]

                        /else [
                            to time! value/6
                        ]
                    ]
                ]
            ]
        ]

        to-date: func [
            [catch]
            source [string! binary!]
        ][
            any [
                as-date source

                throw make error! rejoin [
                    "Could not convert IDATE value"
                ]
            ]
        ]
    ]

    as-date: func [
        source [string! binary!]
    ][
        any [
            attempt [
                to date! source
            ]

            timestamp/as-date source
            idate/as-date source
        ]
    ]

    to-date: func [
        [catch]
        source [string! binary!]
    ][
        any [
            as-date source

            throw make error!
            "Could not convert DATE value"
        ]
    ]

    to-epoch-time: func [
        date [date!]
    ][
        ; date/time: date/time - date/zone
        date: to string! any [
            attempt [
                to integer! difference date 1-Jan-1970/0:0:0
            ]

            date - 1-Jan-1970/0:0:0 * 86400.0
        ]

        clear find/last date "."

        date
    ]

    to-iso-week: use [
        get-iso-year
    ][
        get-iso-year: func [
            year [integer!]
            /local d1 d2
        ][
            d1: to-date join "4-Jan-" year
            d2: to-date join "28-Dec-" year
            reduce [
                d1 + 1 - d1/weekday d2 + 7 - d2/weekday
            ]
        ]

        func [
            date [date!] /local out d1 d2
        ][
            out: 0x0
            set [d1 d2] get-iso-year out/y: date/year

            case [
                date < d1 [
                    d1: first get-iso-year out/y: date/year - 1
                ]

                date > d2 [
                    d1: first get-iso-year out/y: date/year + 1
                ]
            ]

            out/x: date + 8 - date/weekday - d1 / 7

            out
        ]
    ]

    strings: context [
        date:
        time:
        zone: _

        is-utc: no

        codes: [
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
            #"D" [pad date/month 2 #"/" pad date/day 2 #"/" date/year]

            "The day of the month as a number, without padding"
            #"e" [date/day]

            "Equivalent to '%Y-%m-%d'"
            #"F" [date/year #"-" pad date/month 2 #"-" pad date/day 2]

            "The ISO 8601 year as a number [needs review]"
            #"g" [pad (to integer! second to-iso-week date) // 100 2]
            ; more than likely needs revision

            "The ISO 8601 year without century as a number [needs review]"
            #"G" [to integer! second to-iso-week date]
            ; more than likely needs revision

            "The hour as a number using a 12-hour clock (range 1 to 12)"
            #"h" [time/hour + 11 // 12 + 1]

            "The hour as a 2-digit number using a 24-hour clock (range 00 to 23)"
            #"H" [pad time/hour 2]

            "The english suffix for numeric day value, 'st' for 01, 'th' for 04"
            #"i" [switch/default date/day [1 21 31 ["st"] 2 22 ["nd"] 3 23 ["rd"]]["th"]]

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
                pad time/hour + 11 // 12 + 1 2
                #":" pad time/minute 2 #":" pad to integer! time/second 2
                #" " pick ["AM" "PM"] time/hour < 12
            ]

            "Equivalent to '%H:%M'"
            #"R" [pad time/hour 2 #":" pad time/minute 2]

            "The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)"
            #"s" [to integer! date]

            "The second as a 2-digit number (range 00 to 60)"
            #"S" [pad to integer! time/second 2]

            "Tab character"
            #"t" [#"^-"]

            "Equivalent to '%H:%M:%S'"
            #"T" [pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2]

            "The day of the week as a number (range 1 to 7, Monday being 1). See also %w"
            #"u" [date/weekday]

            "The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Sunday as the first day of week 01)"
            #"U" [pad to integer! date/julian + 6 - (date/weekday // 7) / 7 2]

            "The ISO 8601 week number of the current year as a 2-digit decimal number (range 01 to 53, where week 1 is the first week that has at least 4 days in the new year) [needs review]"
            #"V" [pad to integer! first to-iso-week date 2]
            ; more than likely needs revision

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
                date/year #"-" pad date/month 2 #"-" pad date/day 2 #"T"
                pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
                either is-utc [#"Z"][pad-zone zone]
            ]
        ]
    ]

    form: func compose [
        (
            rejoin collect [
                keep "Formats a date to a given specification (similar to STRFTIME). Possible codes:"

                foreach [description code action] strings/codes [
                    keep rejoin [
                        newline "        " #"%" code "  " description
                    ]
                ]
            ]
        )

        date [date! time!]
        "Time or Date to format"

        format [any-string!]
        "Format (string largely compatible with strftime)"

        /utc
        "Align time with UTC"

        /local time zone
    ][
        case [
            time? date [
                time: date
                date: now/date
                date/time: time
                zone: 0:00
            ]

            date/time [
                if date/zone [
                    date/time: date/time - date/zone
                ]

                date/zone: either utc [
                    0:00
                ][
                    date/zone
                ]

                date/time: date/time + date/zone
            ]

            #else [
                date/time: 0:00

                date/zone: either utc [
                    0:00
                ][
                    now/zone
                ]
            ]
        ]

        strings/date: date
        strings/time: date/time
        strings/zone: date/zone
        strings/is-utc: did utc

        interpolate format strings/codes
    ]
]
