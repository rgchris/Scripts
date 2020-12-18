Red [
    Title: "Rebol Script Cleaner (Pretty Printer)"
    Date: 5-Jan-2020
    File: %clean-script.r
    Author: "Christopher Ross-Gill"
    Purpose: {
        Cleans (pretty prints) Rebol scripts by parsing the Rebol code
        and supplying standard indentation and spacing.
    }
    History: [
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

clean-script: none

make object! [
    max-indent: 16  ; adjust this number for more indent levels
    indents: collect [
        repeat x max-indent [
            keep append/dup copy "" "    " x - 1
        ]
    ]

    space: charset "^- "
    chars: complement charset "^/^- []()"

    set 'clean-script func [
        "Returns source with standard spacing (pretty printed)."
        source [string!] "Original source"
        /local tokens context part mark here token widow orphan lookup indent
    ][
        tokens: list/new

        parse source [
            any [
                copy part ["#!" some [some chars | space | "[" | "]" | "(" | ")"] newline] (
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
                copy part [#"[" | #"(" | "#[" | "#("] (
                    token: list/append tokens

                    token/type: switch part [
                        "[" [<block>]
                        "(" [<group>]
                        "#[" [<construct>]
                        "#(" [<map>]
                    ]

                    token/value: part
                    token/is-open: yes
                )
                |
                copy part [#"]" | #")"]
                (
                    token: list/append tokens
                    token/value: part

                    here: :token

                    until [
                        case [
                            not here: here/back [
                                ; this token is a orphan
                                token/type: <comment>
                                token/value: rejoin ["; " token/value " ; DETECTED ORPHAN (No Match)"]

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
                                find [<group> <map>] here/type
                            ][
                                ; the current tag is an widow
                                here/type: <comment>
                                here/value: rejoin ["; " here/value " ; DETECTED WIDOW (Bad Opener)"]
                                here/is-open: no

                                here: list/insert-after here
                                here/type: <newline>
                                here/value: newline

                                here: here/back
                                token/is-split: yes

                                false  ; skip the orphan and continue looking
                            ]

                            all [
                                token/value = ")"
                                find [<block> <construct>] here/type
                            ][
                                ; this token is a orphan
                                token/type: <comment>
                                token/value: rejoin ["; " token/value " ; DETECTED ORPHAN (No Group/Map Opener)"]

                                token: list/append tokens
                                token/type: <newline>
                                token/value: newline

                                true  ; we're done
                            ]

                            'else [
                                here/is-open: no

                                token/type: switch here/type [
                                    <block> [</block>]
                                    <group> [</group>]
                                    <construct> [</construct>]
                                    <map> [</map>]
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
                #";" any space copy part any [some chars | space | "[" | "]" | "(" | ")"]
                (
                    token: list/append tokens
                    token/type: <comment>
                    token/value: either all [part not empty? part] [
                        rejoin ["; " to string! part]
                    ][
                        ";"
                    ]
                )
                |
                skip (
                    token: list/append tokens
                    token/value: case [
                        ; might need more of these exceptions
                        parse mark [
                            [
                                "<-" here: space
                                |
                                "@" some chars here:
                            ]
                            to end
                        ][
                            token/type: <text>
                            copy/part mark here
                        ]

                        not error? try [
                            set [part here] load/next mark
                        ][
                            token/type: <text>
                            copy/part mark here
                        ]

                        parse mark [some chars here: to end] [
                            ; kwatz!
                            token/type: <text>
                            copy/part mark here
                        ]

                        here: next mark [  ; ?!?
                            token/type: <comment>
                            rejoin ["; ?!? " copy/part mark here]

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
                if find [</block> </group> </construct> </map>] token/type [
                    indent: indent - 1
                ]

                if token/is-open [
                    token/type: <comment>
                    token/value: rejoin ["; " token/value " ; DETECTED WIDOW (Unmatched Opener)"]

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

                    find [<block> <group> <construct> <map>] token/back/type []

                    find [</block> </group> </construct> </map>] token/type []

                    all [
                        token/type = <block>
                        find [</block> </construct>] token/back/type
                        token/back/back/type = <newline>

                    ][]

                    'else [
                        keep " "
                    ]
                ]

                if find [<block> <group> <construct> <map>] token/type [
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
