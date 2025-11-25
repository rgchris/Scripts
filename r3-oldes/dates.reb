Rebol [
    Title: "Dates"
    Author: "Christopher Ross-Gill"
    Date: 26-Jun-2025
    Version: 0.2.0
    File: %dates.reb

    Purpose: "Extended date handling in Rebol 3"

    Home: http://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.dates
    Exports: [
        dates
    ]

    Needs: [
        r3:rgchris:core
    ]

    History: [
        26-Jun-2025 0.2.0
        "Roll in FORM-DATE"

        17-Jul-2023 0.1.0
        "First Version"
    ]

    Comment: [
        https://www.rfc-editor.org/rfc/rfc822
        https://www.rfc-editor.org/rfc/rfc2822
        https://www.rfc-editor.org/rfc/rfc3339
        "Internet Date Formats"
    ]
]

dates: context [
    digit: charset "0123456789"

    upper: charset [
        #"A" - #"Z"
    ]

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
            if parse [
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
            if parse source [
                any #" "
                copy value pattern
                any #" "
                end
            ][
                ; replace value #"T" #"/"
                ; replace value #" " #"/"
                ; replace value #"Z" "+0:00"

                to date! value
            ]
        ]

        to-date: func [
            [catch]
            source [string! binary!]
        ][
            any [
                as-date source

                do make error! rejoin [
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
                upper
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
            if parse source [
                opt any #" "
                copy value pattern
                any #" "
                end
            ][
                value: split value #" "

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

                        parse value/6 [upper] [
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

                        parse value/6 [
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

                do make error! rejoin [
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

            make error! rejoin [
                "Could not convert DATE value"
            ]
        ]
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

        text: lib/form text

        skip tail insert/dup text padding length negate length
    ]

    pad-zone: func [
        time
        /flat
    ][
        rejoin [
            pick [#"-" #"+"] time < 0
            pad abs time/hour 2
            either flat [""] [#":"]
            pad time/minute 2
        ]
    ]

    pad-precise: func [
        seconds [number!]
        /local out
    ][
        seconds: lib/form make time! seconds

        head change copy "00.000000" find/last/tail lib/form seconds ":"
    ]

    to-epoch-time: func [
        date [date!]
    ][
        ; date/time: date/time - date/zone
        date: lib/form any [
            attempt [
                to integer! difference date 1-Jan-1970/0:0:0
            ]

            date - 1-Jan-1970/0:0:0 * 86400.0
        ]

        clear find/last date "."
        date
    ]

    to-iso-week: use [get-iso-year][
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
            date [date!]
            /local out d1 d2
        ][
            out: [0 0]
            set [d1 d2] get-iso-year out/2: date/year

            case [
                date < d1 [
                    d1: first get-iso-year out/1: date/year - 1
                ]

                date > d2 [
                    d1: first get-iso-year out/2: date/year + 1
                ]
            ]

            out/1: to integer! date + 8 - date/weekday - d1 / 7
            out
        ]
    ]

    strings: context [
        date:
        time:
        zone:
        is-utc: _

        codes: #[
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

            ; "Equivalent to '%h:%M:%S %p'"
            #"r" [
                rejoin [
                    pad time/hour + 11 // 12 + 1 2
                    #":" pad time/minute 2 #":" pad to integer! time/second 2
                    #" " pick ["AM" "PM"] time/hour < 12
                ]
            ]

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
                    date/year #"-" pad date/month 2 #"-" pad date/day 2 #"T"
                    pad time/hour 2 #":" pad time/minute 2 #":" pad to integer! time/second 2 
                    either is-utc [#"Z"] [pad-zone zone]
                ]
            ]
        ]
    ]

    help: #[
        #"a" {The abbreviated weekday name according to the current locale}
        #"A" {The full weekday name according to the current locale}
        #"b" {The abbreviated month name according to the current locale}
        #"B" {The full month name according to the current locale}
        #"C" "The century number (year/100) as a 2-digit integer"
        #"d" "The day of the month as a number (range 01 to 31)"
        #"D" "Equivalent to '%m/%d/%Y'"
        #"e" "The day of the month as a number, without padding"
        #"F" "Equivalent to '%Y-%m-%d'"
        #"g" "The ISO 8601 year as a number [needs review]"
        #"G" {The ISO 8601 year without century as a number [needs review]}
        #"h" {The hour as a number using a 12-hour clock (range 1 to 12)}
        #"H" {The hour as a 2-digit number using a 24-hour clock (range 00 to 23)}
        #"i" {The english suffix for numeric day value, 'st' for 01, 'th' for 04}
        #"I" {The hour as a 2-digit number using a 12-hour clock (range 01 to 12)}
        #"j" "The day of the year as a number (range 001 to 366)"
        #"J" {The day of the year as a number without padding (range 1 to 366)}
        #"m" "The month as a 2-digit number (range 01 to 12)"
        #"M" "The minute as a 2-digit number (range 00 to 59)"
        #"p" {Either 'AM' or 'PM' according to the given time value. Noon is treated as 'PM' and midnight as 'AM'}
        #"P" {Either 'am' or 'pm' according to the given time value. Noon is treated as 'pm' and midnight as 'am'}
        #"r" "Equivalent to '%h:%M:%S %p'"
        #"R" "Equivalent to '%H:%M'"
        #"s" {The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)}
        #"S" "The second as a 2-digit number (range 00 to 60)"
        #"t" "Tab character"
        #"T" "Equivalent to '%H:%M:%S'"
        #"u" {The day of the week as a number (range 1 to 7, Monday being 1). See also %w}
        #"U" {The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Sunday as the first day of week 01)}
        #"V" {The ISO 8601 week number of the current year as a 2-digit decimal number (range 01 to 53, where week 1 is the first week that has at least 4 days in the new year) [needs review]}
        #"w" {The day of the week as a number (range 0 to 6, Sunday being 0). See also %u}
        #"W" {The week number of the current year as a 2-digit number (range 00 to 53, starting with the first Monday as the first day of week 01)}
        #"x" {The second as a decimal number 00-60 with Red nanosecond precision, a period followed by 6 digits}
        #"y" {The year as a 2-digit number without a century (range 00 to 99)}
        #"Y" {The year as a number (range 0 to maximum supported)}
        #"z" {The time-zone as hour offset from UTC (without a ':' separator)}
        #"Z" "The time-zone as hour offset from UTC"
        #"c" "RFC3339 Date Stamp"
    ]
    ; Need to review help strings

    form: func [
        "Renders a date to a given format"

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

            <else> [
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

        reword/case/escape format strings/codes #"%"
    ]
]
