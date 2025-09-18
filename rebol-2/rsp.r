Rebol [
    Title: "RSP Preprocessor"
    Author: "Christopher Ross-Gill"
    Date: 13-Aug-2013
    Version: 0.4.1
    File: %rsp.r

    Purpose: "Rebol-based hypertext pre-processor"

    Home: https://github.com/rgchris/Scripts/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.rsp
    Exports: [
        build-tag
        load-rsp render render-each
    ]

    Needs: [
        shim
        r2c:sanitize
    ]

    History: [
        17-Jan-2017 0.4.1
        "Updated Unicode/UTF8 handling"

        13-Aug-2013 0.4.0
        "Extracted from the QuarterMaster web framework"
    ]

    Usage: [
        {<% ... "evaluate Rebol code" [ ... %>nested literal<% ... ] %>}
        {<%= ... "evaluate Rebol code and emit the product" ... %>}
        {<%== ... "evaluate Rebol code, sanitize and emit the product" ... %>}
        {<%! ... "pass contents to COMPOSE then BUILD-TAG and emit" ... %>}
    ]
]

build-tag: use [
    to-name has-namespace slash
][
    to-name: func [
        name [word! path! set-word! set-path!]
    ][
        name: mold name
        replace name ":" ""
        replace/all name "/" ":"
    ]

    has-namespace: use [mark] [
        [
            mark:
            path!
            :mark
            into [
                word! word!
            ]
        ]
    ]

    slash: to lit-word! first [/]

    func [
        "Generates a tag from a composed block."

        values [block!]
        "Block of parens to evaluate and other data."

        /local tag has-value xml? name is-name value mark
    ][
        xml?: no

        tag: collect [
            is-name: [
                word! | has-namespace
            ]

            has-value: [
                [
                    set value [
                        get-word! | get-path! | paren!
                    ]
                    (value: do reduce reduce [value])
                    |
                    set value [
                        any-string! | logic! | char! | lit-word! | none!
                        |
                        number! | date! | time! | tuple! | money!
                    ]
                    |
                    set value [
                        'true | 'false | 'none
                    ]
                    (value: get value)
                ]
                (
                    value: switch type-of/word :value [
                        string!
                        url!
                        email! [
                            value
                        ]

                        logic!
                        none! [
                            either :value [name] [none]
                        ]

                        binary! [
                            enbase value
                        ]

                        tag! [
                            to string! value
                        ]

                        file! [
                            replace/all form value #" " "%20"
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
                                #"#" enbase/base to binary! value 16
                            ]
                        ]

                        issue!
                        integer!
                        decimal!
                        money!
                        time! [
                            mold value
                        ]

                        lit-word! [
                            to string! value
                        ]
                    ]
                )
            ]

            parse values [
                set name refinement!
                (keep mold name)
                |
                slash
                set name is-name
                (
                    keep #"/"
                    keep to-name name
                )
                |
                set name [
                    '?xml
                    (xml?: true)
                    |
                    is-name
                ]
                (keep to-name name)

                any [
                    slash
                    end
                    (
                        keep either xml? ["?"] [" /"]
                        xml?: false
                    )
                    |
                    set name [is-name | set-word!]
                    [
                        has-value (
                            if value [
                                keep rejoin [
                                    #" " to-name name
                                    {="} sanitize form value {"}
                                ]
                            ]
                        )
                        |
                        (
                            keep #" "
                            keep to-name name
                        )
                    ]
                ]
                end
                (
                    if xml? [
                        keep #"?"
                    ]
                )
                |
                end
            ]
        ]

        if not empty? tag [
            to tag! rejoin tag
        ]
    ]
]

load-rsp: use [
    make-local-context
][
    make-local-context: func [
        context [block! object!]
        /local word
    ][
        construct either object? context [
            body-of context
        ][
            collect [
                parse context [
                    any [
                        set word word!
                        (
                            keep reduce [
                                to-set-word word get/any word
                            ]
                        )
                    ]
                ]
            ]
        ]
    ]

    load-rsp: func [
        [catch]

        body [string!]
        "Pre-processed Markup"

        /with
        context [block! object!]
        "Context to be bound to"

        /local source part mark
    ][
        collect/into [
            keep trim/auto {
                Rebol [
                    Title: "RSP Output"
                ]

                head collect/into bind [
                    prin: func [value] [
                        keep value
                    ]

                    print: func [value] [
                        keep value
                        keep newline
                    ]
            }

            parse/all body [
                any [
                    end break
                    |
                    "<%" [
                        "==" copy part to "%>"
                        (
                            keep {^/keep sanitize form any [( }
                            keep part
                            keep { ) ""]}
                        )
                        |
                        "=" copy part to "%>"
                        (
                            keep {^/keep any [( }
                            keep part
                            keep { ) ""]}
                        )
                        |
                        [#":" | #"!"] copy part to "%>"
                        (
                            keep {^/keep any [build-tag [ }
                            keep part
                            keep { ] ""]}
                        )
                        |
                        #"#" to "%>"
                        ; comment
                        |
                        copy part to "%>" (
                            keep "^/"
                            keep part
                        )
                        |
                        mark:
                        (throw make error! "Expected '%>'")
                    ]

                    2 skip
                    |
                    copy part [
                        to "<%" | to end
                    ]
                    (
                        keep "^/keep "
                        keep mold part
                    )
                ]
            ]

            keep {^/] #[object! [prin: #[none] print: #[none]]] make string! }
            keep form length-of body
        ] source: make string! length-of body

        throw-on-error [
            assert [
                block? source: load source
            ]
        ]

        if with [
            bind source :context
        ]

        func [
            args [block! object!]
        ] compose/only [
            args: make-local-context args
            do bind/copy (source) args
        ]
    ]
]

render: use [
    depth*
][
    depth*: 0
    ; recursion counter

    func [
        [catch]
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
                rsp: as-string rsp
            ]

            string? rsp [
                throw-on-error [
                    rsp: load-rsp rsp
                ]

                throw-on-error [
                    rsp any [
                        locals []
                    ]
                ]
            ]
        ]

        depth*: depth* - 1

        rsp
    ]
]

render-each: func [
    'word [word! block!]
    data [series!]
    body [file! url! string!]
    /with locals
][
    locals: any [
        locals
        make block! 8
    ]

    append locals word

    head collect/into reduce [
        :foreach :word 'data reduce [
            'keep 'render/with :body :locals
        ]
    ] make string! 1024
]
