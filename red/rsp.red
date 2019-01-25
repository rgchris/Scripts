Red [
    Title: "RSP Preprocessor"
    Author: "Christopher Ross-Gill"
    Date: 25-Jan-2019
    Home: http://ross-gill.com/page/RSP
    File: %rsp.red
    Version: 0.4.3
    Purpose: {Red-embedded Markup}
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.rsp
    Exports: [sanitize load-rsp render render-each]
    History: [
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

; from Rebol 2
build-tag: func [
    "Generates a tag from a composed block."
    values [block!] "Block of parens to evaluate and other data."
    /local tag value-rule xml? name attribute value
][
    tag: make string! 7 * length? values
    xml?: false
    value-rule: [
        set value any-type! (
            switch type?/word :value [
                get-word! get-path! group! [value: reduce value]
            ]

            value: switch type?/word :value [
                logic! none! [either :value [name][none]]
                string! url! email! [value]
                binary! [enbase value]
                tag! [to string! value]
                file! [replace/all to string! value #" " "%20"]
                char! [form value]
                date! [form value]
                tuple! [mold as-color value]
                issue! integer! float! money! time! percent! [mold value]
                word! get-word! set-word! lit-word! refinement! [form to word! value]
            ]
        )
    ]

    parse compose values [
        [
            set name ['?xml (xml?: true) | word! | ahead path! into [2 word!]] (
                append tag replace mold name "/" ":"
            )
            any [
                set attribute [set-word! | word! | and path! into [2 word!]] value-rule (
                    if value [
                        attribute: switch type?/word attribute [
                            word! [mold attribute]
                            set-word! [mold to word! attribute]
                            path! [replace mold attribute "/" ":"]
                        ]
                        repend tag [#" " attribute {="} sanitize form value {"}]
                    ]
                )
                | value-rule (repend tag [#" " sanitize value])
            ]
            end (if xml? [append tag #"?"])
        ]
        |
        [set name refinement! to end (tag: mold name)]
    ]
    to tag! tag
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
