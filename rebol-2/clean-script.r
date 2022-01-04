Rebol [
    Title: "Rebol Script Cleaner (Pretty Printer)"
    Date: 5-Jan-2020
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/
    File: %clean-script.r
    Version: 1.2.1
    Purpose: {
        Cleans (pretty prints) Rebol scripts by parsing the Rebol code
        and supplying standard indentation and spacing.
    }

    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.clean-script
    Exports: [
        clean-script
    ]

    Notes: {
        Originally created by Carl Sassenrath, this version has far-reaching
        changes including spacing between values (excepting specific criteria
        between blocks), multi-line and nesting blocks and some others.
        Formatting of values themselves remain untouched to preserve author's
        intent.
    }

    History: [
        "Christopher Ross-Gill" 1.2.1 05-Jan-2020 "Indent binary values"
        "Christopher Ross-Gill" 1.2.0 05-Jan-2020 "Rewrite"
        "Carl Sassenrath"       1.1.0 29-May-2003 {Fixes indent and parse rule.}
        "Carl Sassenrath"       1.0.0 27-May-2000 "Original program."
    ]
]

list: make object! [
    new: does [
        reduce [
            'first none
            'last none
            ; 'count 0
        ]
    ]

    make-node: does [
        reduce [
            'parent none
            'back none
            'next none
            'type none
            'value none
            'is-split none
            'is-open none
        ]
    ]

    insert-before: func [item [block!] /local node] [
        node: make-node

        node/parent: item/parent
        ; node/parent/count: node/parent/count + 1
        node/back: item/back
        node/next: item

        either none? item/back [
            item/parent/first: node
        ][
            item/back/next: node
        ]

        item/back: node
    ]

    insert-after: func [item [block!] /local node] [
        node: make-node

        node/parent: item/parent
        ; node/parent/count: node/parent/count + 1
        node/back: item
        node/next: item/next

        either none? item/next [
            item/parent/last: node
        ][
            item/next/back: node
        ]

        item/next: node
    ]

    insert: func [list [block!]] [
        either list/first [
            insert-before list/first
        ][
            also list/first: list/last: make-node
            list/first/parent: list
        ]
    ]

    append: func [list [block!]] [
        either list/last [
            insert-after list/last
        ][
            insert list
        ]
    ]
]

clean-script: use [
    indents max-indent space chars
][
    max-indent: 16  ; adjust this number for more indent levels
    indents: collect [
        repeat x max-indent [
            keep join "" remove array/initial x "    "
        ]
    ]

    space: charset "^- "
    chars: complement charset "^/^- [](){}"

    func [
        "Returns source with standard spacing (pretty printed)."
        source [string!] "Original source"

        /local tokens context part mark here token widow orphan lookup indent
    ][
        tokens: list/new

        parse/all source [
            any [
                copy part [
                    "#!" some [
                        some chars
                        |
                        space
                        |
                        "[" | "]" | "(" | ")"
                    ]
                    newline
                ]
                (
                    token: list/append tokens
                    token/type: <comment>
                    token/value: part
                )
            ]

            any [
                mark:
                newline
                (
                    token: list/append tokens
                    token/type: <newline>
                    token/value: newline
                )
                |
                any space #"^@" to end
                (
                    token: list/append tokens
                    token/type: <null>
                    token/value: mark
                )
                |
                some space
                |
                copy part [
                    #"[" | #"(" | "#[" | "#("
                    |
                    "#{" | "2#{" | "16#{" | "64#{"
                ]
                (
                    token: list/append tokens

                    token/type: switch part [
                        "[" [
                            <block>
                        ]

                        "(" [
                            <group>
                        ]

                        "#[" [
                            <construct>
                        ]

                        "#(" [
                            <map>
                        ]

                        "#{" "2#{" "16#{" "64#{" [
                            <binary>
                        ]
                    ]

                    token/value: part
                    token/is-open: yes
                )
                |
                copy part [
                    #"]" | #")" | #"}"
                ]
                (
                    token: list/append tokens
                    token/value: part

                    here: :token

                    until [
                        case [
                            not here: here/back [
                                ; this token is a orphan
                                token/type: <comment>
                                token/value: rejoin [
                                    "; " token/value " ; DETECTED ORPHAN (No Match)"
                                ]

                                token: list/append tokens
                                token/type: <newline>
                                token/value: newline

                                true  ; at head -- no need to continue
                            ]

                            here/type = <newline> [
                                token/is-split: yes

                                false  ; continue looking
                            ]

                            not here/is-open [
                                false  ; continue looking
                            ]

                            all [
                                token/value = "]"
                                find [<group> <map> <binary>] here/type
                            ][
                                ; the current tag is an widow
                                here/type: <comment>
                                here/is-open: no
                                here/value: rejoin [
                                    "; " here/value " ; DETECTED WIDOW (Bad Opener)"
                                ]


                                here: list/insert-after here
                                here/type: <newline>
                                here/value: newline

                                here: here/back
                                token/is-split: yes

                                false  ; skip the orphan and continue looking
                            ]

                            all [
                                token/value = ")"
                                find [<block> <construct> <binary>] here/type
                            ][
                                ; this token is a orphan
                                token/type: <comment>
                                token/value: rejoin [
                                    "; " token/value " ; DETECTED ORPHAN (No Group/Map Opener)"
                                ]

                                token: list/append tokens
                                token/type: <newline>
                                token/value: newline

                                true  ; we're done
                            ]

                            all [
                                token/value = "}"
                                find [<block> <construct> <group> <map>] here/type
                            ][
                                ; this token is a orphan
                                token/type: <comment>
                                token/value: rejoin [
                                    "; " token/value " ; DETECTED ORPHAN (No Binary Opener)"
                                ]

                                token: list/append tokens
                                token/type: <newline>
                                token/value: newline

                                true  ; we're done
                            ]

                            <else> [
                                here/is-open: no

                                token/type: switch here/type [
                                    <block> [</block>]
                                    <group> [</group>]
                                    <construct> [</construct>]
                                    <map> [</map>]
                                    <binary> [</binary>]
                                ]

                                if token/is-split [
                                    if not find [<newline> <comment>] here/next/type [
                                        here: list/insert-after here
                                        here/type: <newline>
                                        here/value: newline
                                    ]

                                    if not find [<newline>] token/back/type [
                                        here: list/insert-before token
                                        here/type: <newline>
                                        here/value: newline
                                    ]
                                ]

                                true  ; we've found a match
                            ]
                        ]
                    ]
                )
                |
                #";" any space copy part any [
                    some chars
                    |
                    space
                    |
                    "[" | "]" | "(" | ")"
                ]
                (
                    token: list/append tokens
                    token/type: <comment>
                    token/value: either all [part not empty? part] [
                        join "; " as-string part
                    ][
                        ";"
                    ]
                )
                |
                skip
                (
                    token: list/append tokens

                    case [
                        ; might need more of these exceptions
                        ;
                        parse/all mark [
                            [
                                "<-" here: space
                                |
                                "@" some chars here:
                            ]
                            to end
                        ][
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        not error? try [
                            set [part here] load/next mark
                        ][
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        parse/all mark [some chars here: to end] [
                            ; binary blobs or kwatz!
                            ;
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        here: next mark [  ; ?!?
                            token/type: <comment>
                            join "; ?!? " copy/part mark here

                            token: list/insert-after token
                            token/type: <newline>
                            token/value: newline
                        ]
                    ]
                )
                :here
            ]
        ]

        ; probe neaten/pairs collect [
        ;     token: tokens/first
        ;     until [
        ;         keep token/type
        ;         keep token/value
        ;         none? token: token/next
        ;     ]
        ; ]

        rejoin collect [
            token: tokens/first
            indent: 1

            while [token] [
                if find [</block> </group> </construct> </map> </binary>] token/type [
                    indent: indent - 1
                ]

                if token/is-open [
                    token/type: <comment>
                    token/value: rejoin [
                        "; " token/value " ; DETECTED WIDOW (Unmatched Opener)"
                    ]

                    token: list/insert-after token
                    token/type: <newline>
                    token/value: newline

                    token: token/back
                ]

                case [
                    none? token/back []

                    token/type = <null> []

                    token/type = <newline> []

                    token/back/type = <newline> [
                        keep pick indents min max-indent indent
                    ]

                    token/type = <comment> [
                        keep "  "
                    ]

                    token/back/type = <null> [
                        keep " "
                    ]

                    find [<block> <group> <construct> <map> <binary>] token/back/type []

                    find [</block> </group> </construct> </map> </binary>] token/type []

                    all [
                        token/type = <block>
                        find [</block> </construct>] token/back/type
                        token/back/back/type = <newline>
                    ][]

                    <else> [
                        keep " "
                    ]
                ]

                if find [<block> <group> <construct> <map> <binary>] token/type [
                    indent: indent + 1
                ]

                keep token/value
                token: token/next
            ]

            if all [
                tokens/last
                tokens/last/type <> <newline>
            ][
                keep newline
            ]
        ]
    ]
]
