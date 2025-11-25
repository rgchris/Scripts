Rebol [
    Title: "Value Converter/Validator"
    Author: "Christopher Ross-Gill"
    Date: 24-Nov-2025
    Version: 0.6.0
    File: %eke.reb

    Purpose: "Attempts to eke a value of given type from given value"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.eke
    Exports: [
        amend eke
    ]

    Needs: [
        r3:rgchris:core
        r3:rgchris:dates
        r3:rgchris:utf-8
    ]

    History: [
        24-Nov-2025 0.6.0
        "Version for Rebol 3"

        14-Aug-2013 0.5.4
        "Extracted from QuarterMaster"
    ]

    Comment: [
        "EKE returns NONE if"
        * "The TYPE argument is #(none!)"
        * "If it's unable to discern a value matching the TYPE argument"
    ]
]

amend: wrap [
    ascii: charset [
        9 10 32 - 126
    ]

    digit: charset [
        #"0" - #"9"
    ]

    upper: charset [
        #"A" - #"Z"
    ]

    lower: charset [
        #"a" - #"z"
    ]

    alpha: union upper lower

    alphanum: union alpha digit

    hex: union digit charset [
        #"A" - #"F"
        #"a" - #"f"
    ]

    symbol:
    file*: union alphanum charset "_-"

    url-: union alphanum charset "!'*,-._~"  ; "!*-._"
    url*: union url- charset ":+%&=?"

    space: charset " ^-"
    ws: charset " ^-^/"

    punct: charset "!'#$%&`*+,-./:;=?@[/]^^{|}~"
    ; regex 'punct without ()<>

    word1: union alpha charset "!&*+-.?_|"
    word*: union word1 digit

    html*: exclude ascii charset {&<>"}

    para*:
    path*: union alphanum charset "!%'+-._"

    ascii+: charset [
        32 - 126
    ]

    extended: charset [
        128 - 255
    ]

    chars: complement nochar: charset " ^-^/^@^M"

    wiki*: complement charset [
        #"^(00)" - #"^(1F)" {:*.<>} #"{" #"}"
    ]

    name: union union lower digit charset "*!',()_-"

    wordify-punct: charset "-_()!"

    unicode: context [
        space: make bitset! decompress #{
            6360606068604005e8fc51300a860a681868070c31f0ff01906004331907d421
            a36040400300
        } 'deflate

        ; charset [
        ; 32 160 5760 8192 8193 8194 8195 8196 8197
        ; 8198 8199 8200 8201 8202 8239 8287 12288
        ; ]
    ]

    inline: [
        ascii+ | utf-8/character/match
    ]

    text-row: [
        chars any [
            chars | space
        ]
    ]

    text: [
        ascii | utf-8/character/match
    ]

    ident: [
        alpha 0 14 file*
    ]

    wordify: [
        alphanum 0 99 [
            wordify-punct | alphanum
        ]
    ]

    word: [
        word1 0 25 word*
    ]

    number: [
        some digit
    ]

    integer: [
        opt #"-" number
    ]

    wiki: [
        some [
            wiki* | utf-8/character/match
        ]
    ]

    ws*:
    white-space: [
        some ws
    ]

    amend: func [
        rule [block!]
    ][
        bind rule 'amend
    ]
]

eke: use [
    masks
][
    masks: make map! amend [
        #(issue!) [
            some url*
        ]

        #(word!) [
            word
        ]

        #(url!) [
            ident #":" some [
                url* | #":" | #"/"
            ]
        ]

        #(email!) [
            some url* #"@" some url*
        ]

        #(path!) [
            word 1 5 [
                #"/" [
                    word | integer
                ]
            ]
        ]

        #(integer!) [
            integer
        ]

        #(decimal!) [
            opt #"-"
            some digit

            opt [
                #"."
                some digit
            ]

            opt [
                [#"e" | #"E"]
                opt [
                    #"-" | #"+"
                ]
                some digit
            ]
        ]

        #(string!) [
            some [
                some ascii | utf-8/character/match
            ]
        ]

        positive [
            number
        ]

        id [
            ident
        ]

        key [
            word 0 6 [
                #"." word
            ]
        ]
    ]

    eke: func [
        type [datatype!]
        value [any-type!]
        /where
        format [none! block! word!]
        /local error
    ][
        case [
            unset? :value _

            type == #(logic!) [
                case [
                    find ["true" "on" "yes" "1" 1 true on yes #(true)] value [
                        #(true)
                    ]

                    find ["false" "off" "no" "0" 0 false off no none #(false) _] value [
                        #(false)
                    ]

                    _
                ]
            ]

            none? value _

            <else> [
                if string? value [
                    if any [
                        type <> #(string!)
                        any-word? format
                    ][
                        value: trim copy value
                    ]
                ]

                switch type-of format [
                    #(none!) [
                        if find masks type [
                            format: masks/:type
                        ]
                    ]

                    #(word!) [
                        either find masks format [
                            format: masks/:format
                        ][
                            do make error! join "Unknown format: " uppercase form format
                        ]
                    ]

                    #(block!) [
                        amend format
                    ]
                ]

                if block? format [
                    if not parse value: trim/head/tail form value format [
                        type: #(none!)
                    ]
                ]

                attempt [
                    switch/default type [
                        #(date!) [
                            dates/as-date value
                        ]

                        #(path!) [
                            load value
                        ]
                    ][
                        make type value
                    ]
                ]
            ]
        ]
    ]
]
