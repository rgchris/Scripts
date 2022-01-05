Rebol [
    Title: "AS Function"
    Date: 14-Aug-2013
    Author: "Christopher Ross-Gill"
    File: %as.r3
    Version: 0.5.4
    Purpose: "Coerce arbitrary data into Rebol values."

    Type: module
    Name: rgchris.as
    Exports: [
        amend as
    ]
]

wrap: func [body [block!]][
    use collect [
        parse body [
            any [body: set-word! (keep to word! body/1) | skip]
        ]
    ] head body
]

amend: wrap [
    ascii: charset ["^/^-" #"^(20)" - #"^(7E)"]
    digit: charset [#"0" - #"9"]
    upper: charset [#"A" - #"Z"]
    lower: charset [#"a" - #"z"]
    alpha: union upper lower
    alphanum: union alpha digit
    hex: union digit charset [#"A" - #"F" #"a" - #"f"]

    symbol: file*: union alphanum charset "_-"
    url-: union alphanum charset "!'*,-._~" ; "!*-._"
    url*: union url- charset ":+%&=?"

    space: charset " ^-"
    ws: charset " ^-^/"

    word1: union alpha charset "!&*+-.?_|"
    word*: union word1 digit
    html*: exclude ascii charset {&<>"}

    para*: path*: union alphanum charset "!%'+-._"
    extended: charset [#"^(80)" - #"^(FF)"]

    chars: complement nochar: charset " ^-^/^@^M"
    ascii+: charset [#"^(20)" - #"^(7E)"]
    wiki*: complement charset [#"^(00)" - #"^(1F)" {:*.<>} #"{" #"}"]
    name: union union lower digit charset "*!',()_-"
    wordify-punct: charset "-_()!"

    ucs: charset ""
    utf-8: use [utf-2 utf-3 utf-4 utf-5 utf-b][
        utf-2: #[bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////wAAAAA=}]
        utf-3: #[bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AAA=}]
        utf-4: #[bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wA=}]
        utf-5: #[bitset! 64#{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8=}]
        utf-b: #[bitset! 64#{AAAAAAAAAAAAAAAAAAAAAP//////////AAAAAAAAAAA=}]

        [utf-2 1 utf-b | utf-3 2 utf-b | utf-4 3 utf-b | utf-5 4 utf-b]
    ]

    get-ucs-code: decode-utf: use [utf-os utf-fc int][
        utf-os: [0 192 224 240 248 252]
        utf-fc: [1 64 4096 262144 16777216]

        func [char][
            int: 0
            char: change char char/1 xor pick utf-os length? char
            forskip char 1 [change char char/1 xor 128]
            char: head reverse head char
            forskip char 1 [int: (to integer! char/1) * (pick utf-fc index? char) + int]
            all [int > 127 int <= 65535 int]
        ]
    ]

    inline: [ascii+ | utf-8]
    text-row: [chars any [chars | space]]
    text: [ascii | utf-8]

    ident: [alpha 0 14 file*]
    wordify: [alphanum 0 99 [wordify-punct | alphanum]]
    word: [word1 0 25 word*]
    number: [some digit]
    integer: [opt #"-" number]
    wiki: [some [wiki* | utf-8]]
    ws*: white-space: [some ws]

    amend: func [rule [block!]][
        bind rule 'amend
    ]
]

as: wrap [
    masks: reduce amend [
        issue!    [some url*]
        logic!    ["true" | "on" | "yes" | "1"]
        word!     [word]
        url!      [ident #":" some [url* | #":" | #"/"]]
        email!    [some url* #"@" some url*]
        path!     [word 1 5 [#"/" [word | integer]]]
        integer!  [integer]
        string!   [some [some ascii | utf-8]]
        'positive [number]
        'id       [ident]
        'key      [word 0 6 [#"." word]]
    ]

    load-date: func [date [string!]][
        all [
            date: attempt [load date]
            date? date
            date
        ]
    ]

    load-rfc3339: func [date [string!]][
        if parse/all date amend [
            copy date [
                3 5 digit "-" 1 2 digit "-" 1 2 digit
                opt [
                    ["T" | " "] 1 2 digit ":" 1 2 digit
                    opt [":" 1 2 digit opt ["." 1 6 digit]]
                    opt ["Z" | ["+" | "-"] 1 2 digit ":" 1 2 digit]
                ]
            ]
        ][
            replace date "T" "/"
            replace date " " "/"
            replace date "Z" "+0:00"
            load-date date
        ]
    ]

    load-rfc822: use [day month][
        ; http://www.w3.org/Protocols/rfc822/#z28

        day: ["Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun"]

        month: [
              "Jan" | "Feb" | "Mar" | "Apr" | "May" | "Jun"
            | "Jul" | "Aug" | "Sep" | "Oct" | "Nov" | "Dec"
        ]

        ; "Tue, 08 Jan 2013 15:19:11 UTC"
        func [date [string!] /local part checked][
            date: collect [
                checked: parse/all date amend [
                    any space
                    day ", "
                    copy part 1 2 digit (keep part) ; permissive--spec says 2 digit
                    " " (keep "-")
                    copy part month (keep part)
                    " " (keep "-")
                    copy part 4 digit (keep part)
                    " " (keep "/")
                    copy part [
                        1 2 digit ":" 1 2 digit opt [":" 2 digit]
                    ] (keep part)
                    " "
                    [
                          "UTC" | "UT" | "GMT" | "Z"
                        | "EDT" (keep "-4:00")
                        | ["EST" | "CDT"] (keep "-5:00")
                        | ["CST" | "MDT"] (keep "-6:00")
                        | ["MST" | "PDT"] (keep "-7:00")
                        | "PST" (keep "-8:00")
                        | part: upper ( ; though not using PARSE/CASE
                            part: to integer! uppercase first part
                            case [
                                part < 74 [keep reduce ["+" part - 64 ":00"]]
                                part = 74 [keep now/zone] ; J is local time
                                part < 78 [keep reduce ["+" part - 65 ":00"]]
                                part > 77 [keep reduce ["-" part - 77 ":00"]]
                            ]
                        )
                        | copy part [["+" | "-"] 2 digit ":" 2 digit] (keep part)
                        | copy part [["+" | "-"] 4 digit] (
                            insert at part 4 ":"
                            keep part
                        )
                    ]
                    any space
                    end ; expects date to be the only content in the string
                ]
            ]
            if checked [load-date rejoin date]
        ]
    ]

    as: func [
        [catch] type [datatype!] value [any-type!]
        /where format [none! block! any-word!]
    ][
        case/all [
            none? value [return none]
            all [string? value any [type <> string! any-word? format]][value: trim value]
            type = logic! [if find ["false" "off" "no" "0" 0 false off no #[false]] value [return false]]
            all [string? value type = date!][
                value: any [
                    load-date value
                    load-rfc3339 value
                    load-rfc822 value
                ]
            ]
            block? format [format: amend bind format 'value]
            none? format [format: select masks type]
            none? format [if type = type? value [return value]]
            any-word? format [format: select masks to word! format]
            block? format [
                unless parse/all value: form value format [return none]
            ]
            type = path! [return load value]
        ]

        attempt [make type value]
    ]
]