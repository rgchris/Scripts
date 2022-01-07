Rebol [
    Title: "RSP Preprocessor"
    Date: 12-Jun-2013
    Author: "Christopher Ross-Gill"
    Home: http://ross-gill.com/page/RSP
    File: %rsp.r3
    Version: 0.4.1
    Purpose: {Rebol-embedded Markup}
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.rsp
    Exports: [
        sanitize build-tag load-rsp render render-each
    ]

    Notes: "Extracted from QuarterMaster"
]

sanitize: use [
    ascii html* extended
][
    ascii: charset ["^/^-" #"^(20)" - #"^(7E)"]
    html*: exclude ascii charset {&<>"}
    extended: complement charset [#"^(00)" - #"^(7F)"]

    func [
        text [any-string!]
        /local char
    ][
        parse form text [
            copy text any [
                text: some html*
                |
                change #"<" "&lt;"
                |
                change #">" "&gt;"
                |
                change #"&" "&amp;"
                |
                change #"^"" "&quot;"
                |
                remove #"^M"
                |
                remove copy char extended
                (
                    char: rejoin [
                        "&#" to integer! char/1 ";"
                    ]
                )
                insert char
                |
                change skip "&#65533;"
            ]
        ]

        any [
            text copy ""
        ]
    ]
]

build-tag: use [
    to-name slash
][
    to-name: func [
        name [word! path!]
    ][
        back replace/all next mold name "/" ":"
    ]

    slash: to lit-word! first [/]

    func [
        "Generates a tag from a composed block"

        values [block!]
        "Block of parens to evaluate and other data."

        /local tag has-value xml? name is-name value
    ][
        xml?: false

        tag: collect [
            is-name: [
                word!
                |
                and path! into [
                    word! word!
                ]
            ]

            has-value: [
                [
                    set value [
                        get-word! | get-path! | paren!
                        |
                        'true | 'false | 'none
                    ]
                    (value: take/last reduce reduce [value])
                    |
                    and not [
                        slash | is-name
                    ]
                    set value skip
                ]
                (
                    value: switch/default type?/word :value [
                        string! url! email! [
                            value
                        ]

                        logic! none! [
                            either :value [
                                name
                            ][
                                none
                            ]
                        ]

                        binary! [
                            enbase value
                        ]

                        tag! [
                            to string! value
                        ]

                        file! [
                            replace/all to string! value #" " "%20"
                        ]

                        char! [
                            form value
                        ]

                        date! [
                            ; form-date value "%c"
                            form value
                        ]

                        tuple! [
                            rejoin [
                                "#" enbase/base to binary! value 16
                            ]
                        ]

                        issue! integer! decimal! money! time! percent! [
                            mold value
                        ]

                        lit-word! [
                            form value
                        ]
                    ][
                        none
                    ]
                )
            ]

            parse values [
                set name [
                    '?xml
                    (xml?: true)
                    |
                    is-name
                ]
                (keep to-name name)

                any [
                    slash end
                    (
                        keep either xml? ["?"] [" /"]
                        xml?: false
                    )
                    |
                    set name is-name
                    [
                        has-value
                        (
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
                    if xml? [
                        keep "?"
                    ]
                )
                |
                and set name path! into [
                    none! word! opt word!
                ]
                to end
                (keep to-name name)
                |
                end
                (tag: [])
            ]
        ]

        to tag! rejoin tag
    ]
]

load-rsp: use [
    prototype to-set-block
][
    prototype: make object! [
        out*: ""

        prin: func [val] [
            repend out* val
        ]

        print: func [val] [
            prin val prin newline
        ]
    ]

    to-set-block: func [
        block [block! object!]
        /local word
    ][
        either object? block [
            block: third block
        ][
            parse copy block [
                (block: copy [])
                any [
                    set word word!
                    (
                        repend block [
                            to-set-word word
                            get/any word
                        ]
                    )
                ]
            ]
        ]

        block
    ]

    func [
        body [string!]
        /local code part
    ][
        code: make string! length? body

        append code "^/out*: make string! {}^/"

        parse body [
            any [
                end
                (append code "out*")
                break
                |
                "<%" [
                    "==" copy part to "%>"
                    (
                        repend code [
                            "prin sanitize form (" part "^/)^/"
                        ]
                    )
                    |
                    "=" copy part to "%>"
                    (
                        repend code [
                            "prin (" part "^/)^/"
                        ]
                    )
                    |
                    [#":" | #"!"]
                    copy part to "%>"
                    (
                        repend code [
                            "prin build-tag [" part "^/]^/"
                        ]
                    )
                    |
                    #"#" to "%>"  ; comment
                    |
                    copy part to "%>"
                    (
                        repend code [
                            part newline
                        ]
                    )
                    |
                    (throw make error! "Expected '%>'")
                ]

                2 skip
                |
                copy part [
                    to "<%"
                    |
                    to end
                ]
                (
                    repend code [
                        "prin " mold part "^/"
                    ]
                )
            ]
        ]

        func [
            args [block! object!]
        ] compose/only [
            args: make prototype to-set-block args
            do bind/copy (load code) args
        ]
    ]
]

render: use [depth*] [
    depth*: 0  ; -- to break recursion

    func [
        rsp [file! url! string!]
        /with
        locals [block! object!]
    ][
        if depth* > 20 [
            return ""
        ]

        depth*: depth* + 1

        rsp: case/all [
            file? rsp [
                rsp: read rsp
            ]

            url? rsp [
                rsp: read rsp
            ]

            binary? rsp [
                rsp: to string! rsp
            ]

            string? rsp [
                rsp: load-rsp rsp

                rsp any [
                    locals []
                ]
            ]
        ]

        depth*: depth* - 1

        rsp
    ]
]

render-each: func [
    'items [word! block!]
    source [series!]
    body [file! url! string!]
    /with locals [object! block!]
][
    locals: collect [
        switch type?/word locals [
            object! [
                keep words-of locals
            ]

            block! [
                keep locals
            ]
        ]

        keep items
    ]

    rejoin collect [
        foreach :items source compose/only [
            keep render/with body (locals)
        ]
    ]
]
