Rebol [
    Title: "RSP Preprocessor"
    Author: "Christopher Ross-Gill"
    Date: 8-Feb-2019
    Home: http://ross-gill.com/page/RSP
    File: %rsp.reb
    Version: 0.5.0
    Purpose: {Rebol-embedded Markup}
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.rsp
    Exports: [sanitize build-tag load-rsp render render-each]
    History: [
        08-Feb-2019 0.5.0 "Reworked BUILD-TAG function"
        11-Dec-2018 0.4.3 "Ren-C Late 2018 Changes; Add BUILD-TAG"
        02-Sep-2017 0.4.2 "Replace GET/ANY"
        21-Jul-2017 0.4.1 ""
        13-Jun-2013 0.4.0 "Support Extended Characters in SANITIZE"
        12-Jun-2013 0.3.0 "Add SANITIZE function"
        12-Jun-2013 0.2.0 "Extracted from QuarterMaster"
        14-Nov-2002 _ "Build-Tag 1.2.0 by Andrew Martin"
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
                (char: rejoin ["&#" to integer! char/1 ";"])
                insert char
                |
                change skip "&#65533;"
            ]
        ]

        any [text copy ""]
    ]
]

build-tag: use [to-name slash][
    to-name: func [name [word! path!]][
        back replace/all next mold name "/" ":"
    ]

    slash: first [/]

    make action! [
        [
            "Generates a tag from a composed block." 
            values [block!] "Block of parens to evaluate and other data." 
            /local tag has-value xml? name is-name value
        ]
        [
            xml?: false

            tag: collect [
                is-name: [
                    word! | and path! into [word! word!]
                ]

                has-value: [
                    [
                        set value [get-word! | get-path! | group!] (
                            value: eval value
                        )
                        |
                        and not [slash | is-name]
                        set value skip
                    ]
                    (
                        value: switch type of :value [
                            text! url! email! [value]
                            logic! blank! [either :value [name][_]]
                            binary! [enbase value]
                            tag! [to text! value]
                            file! [replace/all as text! value #" " "%20"]
                            char! date! [form value]
                            tuple! [unspaced ["#" enbase/base to binary! value 16]]
                            issue! integer! decimal! money! time! percent! [mold value]
                            lit-word! [as text! value]
                            (_)
                        ]
                    )
                ]

                parse values [
                    set name ['?xml (xml?: true) | is-name] (
                        keep to-name name
                    )
                    any [
                        slash end (
                            keep either xml? ["?"][" /"]
                            xml?: false
                        )
                        |
                        set name is-name [
                            has-value (
                                if value [
                                    keep unspaced [
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
                    and set name path! into [blank! word! opt word!] to end (
                        keep to-name name
                    )
                    |
                    end (tag: [])
                ]
            ]

            if tag: unspaced tag [to tag! tag]
        ]
    ]
]

load-rsp: use [prototype to-set-block][
    prototype: context [
        out*: _ prin: method [value][append out* unspaced compose [(value)]]
        print: method [val][prin value prin newline]
    ]

    to-set-block: func [locals [block! object!] /local word][
        case [
            object? locals [
                body of locals
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

    func [body [text!] /local source mark return: [action!]][
        source: unspaced collect [
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
                            keep unspaced ["prin any [build-tag [" mark "^/] {}]^/"]
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
                do bind/copy (load source) args
            ]
        ]
    ]
]

render: use [depth*][
    depth*: 0  ; to break recursion

    make action! [
        [
            rsp [file! url! text!]
            /with locals [block! object!]
        ]
        [
            either depth* > 20 [return ""][
                depth*: depth* + 1

                case/all [
                    file? rsp [rsp: read rsp]
                    url? rsp [rsp: read rsp]
                    binary? rsp [rsp: to text! rsp]
                    text? rsp [
                        rsp: load-rsp rsp
                        rsp any [:locals | make block! 0]
                    ]
                ]

                elide depth*: depth* - 1
            ]
        ]
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
