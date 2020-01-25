Red [
    Title: "RSP Preprocessor"
    Author: "Christopher Ross-Gill"
    Date: 25-Jan-2020
    Home: http://ross-gill.com/page/RSP
    File: %rsp.red
    Version: 0.5.0
    Purpose: {Red-embedded Markup}
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.rsp
    Exports: [sanitize load-rsp render render-each]
    History: [
        25-Jan-2020 0.5.0 "Renovated BUILD-TAG function, fix PATH! namespaced tag/attribute name handling"
        25-Jan-2019 0.4.3 "Red Late 2018 Changes"
    ]
    Notes: "Extracted from QuarterMaster"
]

sanitize: func [text [any-string!] /local mark] bind [
    either parse text: form text [
        copy text any [
            some safe | change #"&" "&amp;" | change #"<" "&lt;" | change #">" "&gt;"
            | change #"^"" "&quot;" | change #"'" "&apos;" | remove #"^M"
            | change mark: extended (char: rejoin ["&#" to integer! mark/1 ";"])
            | change skip "&#65533;"
        ]
    ][
        text
    ][
        make string! 0
    ]
]
    make object! [
        safe: exclude ascii: charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
        extended: complement charset [#"^(00)" - #"^(7F)"]
    ]

build-tag: func [
    "Generates a tag from a composed block."
    values [block!] "Block of parens to evaluate and other data."
    /local to-name tag is-name has-value name value xml?
][
    to-name: func [name [word! path! set-word! set-path!]][
        name: mold name
        replace name ":" ""
        replace/all name "/" ":"
    ]

    xml?: false

    tag: collect [
        is-name: [
            word! | ahead path! into [2 word!]
        ]

        has-value: [
            [
                set value [get-word! | get-path! | paren!] (
                    value: do reduce reduce [value]
                )
                |
                ahead word! set value ['true | 'false | 'none] (value: get value)
                |
                set value [
                    any-string! | logic! | char! | lit-word! | word! | issue!
                    |
                    number! | date! | time! | tuple! ; | money!
                ]
            ]
            (
                value: switch type?/word :value [
                    string! url! email! [value]
                    logic! none! [either :value [name][none]]
                    binary! [enbase value]
                    tag! [to string! value]
                    file! [replace/all form value #" " "%20"]
                    char! [form value]
                    date! [
                        ; form-date value "%c"
                        form value
                    ]
                    tuple! [mold as-color value/1 value/2 value/3]
                    issue! integer! float! percent! money! time! [mold value]
                    word! lit-word! [to string! value]
                ]
            )
        ]

        parse values [
            set name ['?xml (xml?: true) | is-name] (
                keep to-name name
            )
            any [
                '/ end (
                    keep either xml? ["?"]["/"]
                    xml?: false
                )
                |
                set name [is-name | set-word!] [
                    has-value (
                        if value [
                            keep rejoin [
                                " " to-name name {="} sanitize form value {"}
                            ]
                        ]
                    )
                    |
                    (
                        keep " "
                        keep to-name name
                    )
                ]
            ]
            end (
                if xml? [keep "?"]
            )
            |
            [set name refinement! to end (tag: mold name)]
        ]
    ]

    if tag: rejoin tag [to tag! tag]
]

load-rsp: func [body [string!] /local code mark return: [function!]] bind [
    code: rejoin collect [
        keep rejoin ["^/out*: make string! " length? body "^/"]
        parse body [
            any [
                end (keep "^/out*") break
                |
                "<%" [
                    "==" copy mark to "%>" (
                        keep rejoin ["prin sanitize form (" mark "^/)^/"]
                    )
                    |
                    "=" copy mark to "%>" (
                        keep rejoin ["prin (" mark "^/)^/"]
                    )
                    |
                    [#":" | #"!"] copy mark to "%>" (
                        keep rejoin ["prin build-tag [" mark "^/]^/"]
                    )
                    |
                    #"#" to "%>" ; comment
                    |
                    copy mark to "%>" (keep rejoin [mark newline])
                    |
                    (
                        do make error! "Expected '%>'"
                    )
                ] 2 skip
                | copy mark [to "<%" | to end] (
                    keep rejoin ["prin " mold mark "^/"]
                )
            ]
        ]
    ]

    func [args [block! object!]] compose/only [
        args: make prototype to-set-block args
        do bind/copy (load code) args
    ]
]
    make object! [
        prototype: context [
            out*: none prin: func [val][append reduce out* val]
            print: func [val][prin val prin newline]
        ]

        to-set-block: func [locals [block! object!] /local word][
            case [
                object? locals [
                    body-of locals
                ]

                block? locals [
                    collect [
                        parse locals [
                            any [
                                set word word! (
                                    keep reduce [to set-word! word get :word]
                                )
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

render: func [
    rsp [file! url! string!]
    /with locals [block! object!]
] bind [
    if depth* > 20 [return ""]
    depth*: depth* + 1

    rsp: case/all [
        file? rsp [rsp: read rsp]
        url? rsp [rsp: read rsp]
        binary? rsp [rsp: to string! rsp]
        string? rsp [
            rsp: load-rsp rsp
            rsp any [:locals []]
        ]
    ]

    depth*: depth* - 1
    rsp
]
    make object! [
        depth*: 0
    ]

render-each: func [
    'items [word! block!]
    source [series!]
    body [file! url! string!]
    /with locals /local out
][
    locals: append any [locals []] items: compose [(items)]
    rejoin collect [
        foreach :items source compose/only [
            append out render/with body (locals)
        ]
    ]
]
