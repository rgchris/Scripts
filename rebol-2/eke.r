Rebol [
    Title: "Value Converter/Validator"
    Author: "Christopher Ross-Gill"
    Date: 14-Aug-2013
    Version: 0.5.5
    File: %eke.r

    Purpose: "Converts string values to Rebol types where conformant"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.eke
    Exports: [
        charsets amend eke
    ]

    Needs: [
        shim
        r2c:dates
        r2c:utf-8
    ]

    History: [
        14-Aug-2013 0.5.4
        "Extract from QuarterMaster"
    ]
]

charsets: context [
    ascii: charset [
        "^/^-"
        #"^(20)" - #"^(7E)"
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

    symbol: file*: union alphanum charset "_-"

    url-: union alphanum charset "!'*,-._~"
    ; "!*-._"

    url*: union url- charset ":+%&=?"

    space: charset " ^-"

    punct: charset "!'#$%&`*+,-./:;=?@[/]^^{|}~"
    ; regex 'punct without ()<>

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

    utf-space: [
        U+0020 U+00A0 U+1680 U+2000 U+2001 U+2002 U+2003 U+2004
        U+2005 U+2006 U+2007 U+2008 U+2009 U+200A U+202F U+205F U+3000
    ]

    utf-xml-avoid: [
        #x7F - #x84
        #x86 - #x9F
        #xFDD0 - #xFDEF
        #x1FFFE - #x1FFFF
        #x2FFFE - #x2FFFF
        #x3FFFE - #x3FFFF
        #x4FFFE - #x4FFFF
        #x5FFFE - #x5FFFF
        #x6FFFE - #x6FFFF
        #x7FFFE - #x7FFFF
        #x8FFFE - #x8FFFF
        #x9FFFE - #x9FFFF
        #xAFFFE - #xAFFFF
        #xBFFFE - #xBFFFF
        #xCFFFE - #xCFFFF
        #xDFFFE - #xDFFFF
        #xEFFFE - #xEFFFF
        #xFFFFE - #xFFFFF
        #x10FFFE - #x10FFFF
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
]

amend: func [
    rule [block!]
][
    bind rule charsets
]

eke: use [
    masks
][
    masks: reduce amend [
        issue! [
            some url*
        ]

        word! [
            word
        ]

        url! [
            ident #":" some [
                url* | #":" | #"/"
            ]
        ]

        email! [
            some url* #"@" some url*
        ]

        path! [
            word 1 5 [
                #"/" [
                    word | integer
                ]
            ]
        ]

        integer! [
            integer
        ]

        decimal! [
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

        string! [
            some [
                some ascii | utf-8/character/match
            ]
        ]

        'positive [
            number
        ]

        'id [
            ident
        ]

        'key [
            word 0 6 [
                #"." word
            ]
        ]
    ]

    eke: func [
        [catch]
        type [datatype!]
        value [any-type!]
        /where
        format [none! block! any-word!]
        /local error
    ][
        ; [
        ;     unset? get/any 'value [
        ;         none
        ;     ]
        ;
        ;     none? value [
        ;         either type == logic! [false] [none]
        ;     ]
        ;
        ;     type == type? value [
        ;         case/all [
        ;             word? format [
        ;             ]
        ;         ]
        ;     ]
        ;
        ;     string? value [
        ;     ]
        ; ]

        if error? error: try [
            case/all [
                type == logic! [
                    return case [
                        find ["true" "on" "yes" "1" 1 true on yes #[true]] value [
                            return true
                        ]

                        find ["false" "off" "no" "0" 0 false off no none _ #[false] #[none]] :value [
                            return false
                        ]

                        <else> [
                            return _
                        ]
                    ]
                ]

                none? value [
                    return _
                ]

                all [
                    string? value

                    any [
                        type <> string!
                        any-word? format
                    ]
                ][
                    value: trim value
                ]

                all [
                    string? value
                    type == date!
                ][
                    if none? value: attempt [
                        dates/as-date value
                    ][
                        type: none!
                    ]
                ]

                block? format [
                    format: amend bind format 'value
                ]

                none? format [
                    format: select masks type
                ]

                none? format [
                    if type == type? value [
                        return value
                    ]
                ]

                any-word? format [
                    format: select masks to word! format
                ]

                block? format [
                    if not parse/all value: form value format [
                        return none
                    ]
                ]

                type == path! [
                    return load value
                ]
            ]
        ][
            print [
                type mold value
            ]

            throw :error
        ]

        try [
            make type value
        ]
    ]
]
