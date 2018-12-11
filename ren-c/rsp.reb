Rebol [
    Title: "RSP Preprocessor"
    Author: "Christopher Ross-Gill"
    Date: 25-Jul-2017
    ; Home: tbd
    File: %rsp.reb
    Version: 0.4.3
    Purpose: {Rebol-embedded Markup}
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.rsp
    Exports: [sanitize build-tag load-rsp render render-each]
    History: [
        11-Dec-2018 0.4.3 "Ren-C Late 2018 Changes"
        "To Follow"
    ]
    Notes: "Extracted from QuarterMaster"
]

sanitize: use [ascii html* extended][
    html*: exclude ascii: charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
    extended: complement charset [#"^(00)" - #"^(7F)"]

    func [text [text!] /local char][
        parse form text [
            copy text any [
                text: some html*
                | change #"<" "&lt;" | change #">" "&gt;" | change #"&" "&amp;"
                | change #"^"" "&quot;" | remove #"^M"
                | remove copy char extended (char: rejoin ["&#" to integer! char/1 ";"]) insert char
                | change skip "&#65533;"
            ]
        ]

        any [text copy ""]
    ]
]

build-tag: use [to-name][
    to-name: func [name [word! path!]][
        replace/all mold name "/" ":"
    ]

    func [
        "Generates a tag from a composed block." 
        values [block!] "Block of parens to evaluate and other data." 
        /local tag value-rule xml? name attribute value
    ][
        tag: make text! 7 * length-of values
        xml?: false
        value-rule: [
            set value any-value! (
                switch type-of :value [
                    :get-word! :get-path! :group! [value: eval value]
                ]

                value: switch type-of :value [
                    :logic! :blank! [either :value [name][_]]
                    :text! :url! :email! [value]
                    :binary! [enbase value]
                    :tag! [to text! value]
                    :file! [replace/all to text! value #" " "%20"]
                    :char! [form value]
                    :date! [form value]
                    :tuple! [unspaced ["#" enbase/base to binary! value 16]]
                    :issue! :integer! :decimal! :money! :time! :percent! [mold value]
                    :word! :get-word! :set-word! :lit-word! :refinement! [spelling-of value]
                    (_)
                ]
            )
        ]

        parse values [
            [
                set name ['?xml (xml?: true) | word! | and path! into [2 word!]] (
                    append tag to-name name
                )
                any [
                    set attribute [word! | and path! into [2 word!]] value-rule (
                        if value [
                            append tag unspaced [#" " to-name attribute {="} sanitize form value {"}]
                        ]
                    )
                    | value-rule (append tag unspaced [#" " value])
                ]
                end (if xml? [append tag #"?"])
            ]
            |
            [set name refinement! to end (tag: mold name)]
        ]

        to tag! tag
    ]
]

load-rsp: use [prototype to-set-block][
    prototype: context [
        out*: _ prin: bind func [value][append out* unspaced value] 'prin
        print: bind func [val][prin value prin newline] 'print
    ]

    to-set-block: func [locals [block! object!] /local word][
        case [
            object? locals [
                body-of locals
            ]

            block? locals [
                collect [
                    keep []
                    parse locals [
                        any [
                            set word word! (keep reduce [to set-word! word get :word])
                        ]
                    ]
                ]
            ]
        ]
    ]

    func [body [text!] /local code mark return: [action!]][
        code: unspaced collect [
            keep unspaced ["^/out*: make text! " length-of body "^/"]
            parse body [
                any [
                    end (keep "^/out*") break
                    |
                    "<%" [
                        "==" copy mark to "%>" (
                            keep unspaced ["prin sanitize form (" mark "^/)^/"]
                        )
                        |
                        "=" copy mark to "%>" (
                            keep unspaced ["prin (" mark "^/)^/"]
                        )
                        |
                        [#":" | #"!"] copy mark to "%>" (
                            keep unspaced ["prin build-tag [" mark "^/]^/"]
                        )
                        |
                        #"#" to "%>" ; comment
                        |
                        copy mark to "%>" (keep unspaced [mark newline])
                        |
                        mark: (
                            fail ["Expected '%>' at" mold copy/part mark 20]
                        )
                    ] 2 skip
                    | copy mark [to "<%" | to end] (
                        keep unspaced ["prin " mold mark "^/"]
                    )
                ]
            ]
        ]

        make action! compose/deep/only [
            [args [block! object!]]
            [
                args: make prototype to-set-block args
                do bind/copy (load code) args
            ]
        ]
    ]
]

render: use [depth*][
    depth*: 0 ;-- to break recursion

    func [
        rsp [file! url! text!]
        /with locals [block! object!]
    ][
        if depth* > 20 [return ""]
        depth*: depth* + 1

        rsp: case/all [
            file? rsp [rsp: read rsp]
            url? rsp [rsp: read rsp]
            binary? rsp [rsp: to text! rsp]
            text? rsp [
                rsp: load-rsp rsp
                rsp :locals or []
            ]
        ]

        depth*: depth* - 1
        rsp
    ]
]

render-each: func [
    'items [word! block!]
    source [any-series!]
    body [file! url! text!]
    /with locals
][
    locals: compose [(:locals) (items)]
    "" unless unspaced try collect [
        for-each :items source compose/only [
            keep render/with body (locals)
        ]
    ]
]
