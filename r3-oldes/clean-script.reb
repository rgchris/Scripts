Rebol [
    Title: "Rebol Script Formatter (Pretty Printer)"
    Author: "Christopher Ross-Gill"
    Date: 5-Jan-2020
    Version: 1.2.1
    File: %clean-script.reb

    Purpose: {
        Reformats (pretty prints) Rebol scripts by examining Rebol code
        and applying standard indentation and spacing.
    }

    Home: http://www.ross-gill.com/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.clean-script
    Exports: [
        clean-script
    ]

    Comment: [
        {
        This is an opinionated code cleaner. Its opinions largely conform
        to the Rebol style guide (link below). The following conventions
        are observed:
        }

        * "Spaced indents in multiples of four"
        * "Single space between values, no space inside single-line containers"
        * "Line feeds between values are preserved"
        * "Two spaces preceding comments"
        * "Indents multiline binary"
        * "Uses initial capital 'Rebol'"

        "Values are preserved as-written by the script author"

        "These conventions aid in code-folding in supported text editors"

        https://www.rebol.com/docs/core23/rebolcore-5.html#section-5
        "Rebol Style Guide"
    ]

    History: [
        5-Jan-2020 1.2.0
        "Full rewrite"

        27-May-2000 1.0.0
        "Original script"
        ("Carl Sassenrath")
    ]
]

list: context [
    new: does [
        make map! [
            first #(none)
            last #(none)
        ]
    ]

    make-node: does [
        make map! [
            parent #(none)
            back #(none)
            next #(none)
            type #(none)
            value #(none)
        ]
    ]

    insert-before: func [
        item [map!]
        /local node
    ][
        node: make-node

        node/parent: item/parent
        ; probe node/parent/count: node/parent/count + 1
        node/back: item/back
        node/next: item

        either none? item/back [
            item/parent/first: node
        ][
            item/back/next: node
        ]

        item/back: node
    ]

    insert-after: func [
        item [map!]
        /local node
    ][
        node: make-node

        node/parent: item/parent
        ; probe node/parent/count: node/parent/count + 1
        node/back: item
        node/next: item/next

        either none? item/next [
            item/parent/last: node
        ][
            item/next/back: node
        ]

        item/next: node
    ]

    insert: func [
        list [map!]
    ][
        either list/first [
            insert-before list/first
        ][
            also list/first: list/last: make-node
            list/first/parent: list
        ]
    ]

    append: func [
        list [map!]
    ][
        either list/last [
            insert-after list/last
        ][
            insert list
        ]
    ]

    probe: func [
        list [map!]
        /local walker
    ][
        walker: iterator/new list

        while [
            iterator/next walker
        ][
            print [
                "%%%" walker/event walker/node/type mold walker/node/value
            ]
        ]

        list
    ]
]

iterator: context [
    prototype: [
        'next :next
        'close :close
        'type _
        'node _
        'event 'init
    ]

    new: func [
        value [any-type!]
        /local new
    ][
        new: reduce prototype
        new/node: value
        new
    ]

    next: func [
        walker [block!]
    ][
        ; walker/node: _
        ; walker/type: _

        walker/event: case [
            walker/event = 'init [
                either walker/node/first [
                    walker/node: walker/node/first

                    either walker/node/first [
                        'open
                    ][
                        'value
                    ]
                ][
                    'end
                ]
            ]

            walker/event = 'open [
                walker/node: walker/node/first

                either walker/node/first [
                    'open
                ][
                    'value
                ]
            ]

            walker/event = 'end [
                _
            ]

            none? walker/node/next [
                either walker/node/type [
                    walker/node: walker/node/parent

                    either walker/node/type [
                        'close
                    ][
                        'end
                    ]
                ][
                    'end
                ]
            ]

            <else> [
                walker/node: walker/node/next

                either walker/node/first [
                    'open
                ][
                    'value
                ]
            ]
        ]
    ]
]

clean-script: use [
    indents max-indent
    space chars delim digit alpha date
    load-next as-newline promote-kids describe-outlier
][
    max-indent: 16
    ; adjust token number for more indent levels

    indents: collect [
        repeat x max-indent [
            keep join "" remove array/initial x "    "
        ]
    ]

    space: charset "^- "
    digit: charset "0123456789"
    chars: complement charset "^/^- [](){}"
    delim: charset "^@^-^/^M ^"();/[]{}"
    ; delim from l-scan.c (Rebol source) + tab

    alpha: charset [
        #"A" - #"Z"
        #"a" - #"z"
    ]

    ; specifically targeting Rebol 2-style dates
    ; does not have to be exact, but does need to capture a broad range
    ;
    date: [
        [
            1 4 digit #"-" [3 9 alpha | 1 2 digit] #"-" 1 4 digit
            |
            1 4 digit #"/" [3 9 alpha | 1 2 digit] #"/" 1 4 digit
        ]
        [#"/" | #"T"]
        1 2 digit #":" 1 2 digit
        opt [
            #":" 1 2 digit
            opt [
                #"." some digit
            ]
        ]
        opt [
            [#"+" | #"-"]
            1 2 digit #":" 1 2 digit
            |
            #"Z"
        ]
    ]

    load-next: func [
        string [string!]
        /local out
    ][
        out: transcode/next to binary! string
        out/2: skip string subtract length-of string length-of to string! out/2
        out
    ]

    promote-kids: func [
        token [map!]
    ][
        if token/first [
            token/first/back: token
            token/last/next: token/next
            token/next: token/first

            token/first: _
            token/last: _

            while [
                token/next
            ][
                token/next/parent: token/parent
                token: token/next
            ]

            token/parent/last: token
        ]
    ]

    as-newline: func [
        token [map!]
    ][
        token/type: <newline>
        token/value: newline
        token/parent/has-newline: yes
    ]

    describe-outlier: func [
        part [char! string!]
    ][
        part rejoin [
            "; "
            part
            " ; IMBALANCE DETECTED: "
            switch/default part [
                "[" "(" "#[" "#(" "#{" "2#{" "16#{" "64#{" "85#{" [
                    "WIDOW"
                ]

                #"]" #")" #"}" [
                    "ORPHAN"
                ]
            ][
                "ERK"
            ]
            " ("
            switch/default part [
                "[" ["Unclosed Block"]
                "(" ["Unclosed Group"]
                "#[" ["Unclosed Map"]
                "#(" ["Unclosed Construct"]

                "#{"
                "2#{"
                "16#{"
                "64#{"
                "85#{" [
                    "Unclosed Construct"
                ]

                #"]" ["Unopened Block/Map"]
                #")" ["Unopened Group/Construct"]
                #"}" ["Unopened String/Binary"]
            ][
                "Unmatched Symbol"
            ]
            ")"
        ]
    ]

    func [
        "Returns source with standard spacing (pretty printed)."

        source [string!]
        "Original source"

        /local
        container context part mark here token
        widow orphan lookup indent walker
    ][
        container: list/new

        parse/case source [
            ; Shebang
            ;
            any [
                copy part [
                    "#!" some [
                        some chars
                        |
                        space
                        |
                        #"[" | #"]" | #"(" | #")"
                    ]
                ]
                newline
                (
                    token: list/append container
                    token/type: <comment>
                    token/value: part
                )
            ]

            any [
                mark:
                newline
                (as-newline list/append container)
                |
                any space
                #"^@"
                to end
                (
                    while [
                        container/parent/type
                    ][
                        container: container/parent
                        container/disposition: 'widow
                    ]

                    token: list/append container
                    token/type: <null>
                    token/value: mark
                )
                |
                some space
                |
                copy part [
                    #"[" | #"(" | "#[" | "#("
                    |
                    "#{" | "2#{" | "16#{" | "64#{" | "85#{"
                ]
                (
                    token: list/append container

                    token/type: switch part [
                        "[" [
                            <block>
                        ]

                        "(" [
                            <group>
                        ]

                        "#[" [
                            <map>
                        ]

                        "#(" [
                            <construct>
                        ]

                        "#{"
                        "2#{"
                        "16#{"
                        "64#{"
                        "85#{" [
                            <binary>
                        ]
                    ]

                    token/value: part

                    container: token
                )
                |
                set part [
                    #"]" | #")" | #"}"
                ]
                (
                    case [
                        not container/type [
                            token: list/append container
                            token/type: <comment>
                            token/value: describe-outlier part
                        ]

                        part = switch container/type [
                            <block>
                            <map> [
                                #"]"
                            ]

                            <group>
                            <construct> [
                                #")"
                            ]

                            <binary> [
                                #"}"
                            ]
                        ][
                            if none? container/first [
                                container/value: switch container/type [
                                    <block> [
                                        "[]"
                                    ]

                                    <map> [
                                        "#[]"
                                    ]

                                    <group> [
                                        "()"
                                    ]

                                    <contruct> [
                                        "#()"
                                    ]

                                    <binary> [
                                        "#{}"
                                    ]
                                ]

                                container/type: <text>
                            ]

                            if container/has-newline [
                                if not find [<newline> <comment>] container/first/type [
                                    as-newline list/insert container
                                ]

                                if not find [<newline> <comment>] container/last/type [
                                    as-newline list/append container
                                ]

                                container/parent/has-newline: yes
                            ]

                            container: container/parent
                        ]

                        <else> [
                            switch part [
                                #"]" [
                                    token: container

                                    ; look for potential block closers or root
                                    ;
                                    until [
                                        token: token/parent
                                        find [<block> <map> #(none)] token/type
                                    ]

                                    ; if it's root, we just orphan in place
                                    ; otherwise we widow everything else still open
                                    ;
                                    either none? token/type [
                                        token: list/append container
                                        token/type: <comment>
                                        token/value: describe-outlier part
                                    ][
                                        until [
                                            promote-kids container

                                            container/type: <comment>
                                            container/value: describe-outlier container/value

                                            container: container/parent

                                            find [<block> <map>] container/type
                                        ]

                                        container: container/parent
                                    ]
                                ]

                                #")" [
                                    token: list/append container
                                    token/type: <comment>
                                    token/value: describe-outlier part
                                ]

                                #"}" [
                                    token: list/append container
                                    token/type: <comment>
                                    token/value: describe-outlier part
                                ]
                            ]
                        ]
                    ]
                )
                |
                #";"
                any space
                copy part any [
                    some chars
                    |
                    space
                    |
                    #"[" | #"]" | #"(" | #")" | #"{" | #"}"
                ]
                [newline | end]
                (
                    token: list/append container
                    token/type: <comment>
                    token/value: either all [
                        part
                        not empty? part
                    ][
                        join "; " to string! part
                    ][
                        #";"
                    ]

                    container/has-newline: yes
                )
                |
                skip
                (
                    token: list/append container

                    case [
                        ; might need more of these exceptions
                        ;
                        parse mark [
                            [
                                "<-" here:
                                |
                                "@" some chars here:
                                |
                                date here:
                            ]
                            [delim to end | end]
                        ][
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        ; an indulgence--standardize case for 'Rebol'
                        ;
                        parse/case mark [
                            [#"R" | #"r"]
                            [#"E" | #"e"]
                            [#"B" | #"b"]
                            [#"O" | #"o"]
                            [#"L" | #"l"]
                            here:
                            [space to end | end]
                        ][
                            token/type: <text>
                            token/value: "Rebol"
                        ]

                        not error? try [
                            set [part here] load-next mark
                        ][
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        parse mark [
                            some chars
                            here:
                            to end
                        ][
                            ; binary blobs or kwatz!
                            ;
                            token/type: <text>
                            token/value: copy/part mark here
                        ]

                        here: next mark [  ; ?!?
                            token/type: <comment>
                            join "; ?!? " copy/part mark here
                        ]
                    ]
                )
                :here
            ]

            end
            (
                while [
                    container/type
                ][
                    container/type: <comment>
                    container/value: describe-outlier container/value

                    promote-kids container

                    container: container/parent
                ]

                if not find [<newline> <comment>] container/last/type [
                    as-newline list/append container
                ]
            )
        ]

        walker: iterator/new container

        rejoin collect [
            indent: 1

            while [
                iterator/next walker
            ][
                token: walker/node

                ; print [
                ; walker/event token/type mold token/value
                ; ]

                switch/all walker/event [
                    open value [
                        case [
                            none? token/back [
                                if all [
                                    token/type = <comment>
                                    token/parent/type
                                ][
                                    keep "  "
                                ]
                            ]

                            token/type = <null> []

                            token/type = <newline> []

                            find [<newline> <comment>] token/back/type [
                                keep pick indents min max-indent indent
                            ]

                            token/type = <comment> [
                                keep "  "
                            ]

                            token/back/type = <null> [
                                keep " "
                            ]

                            all [
                                token/type = <block>
                                token/back/type = <block>
                                token/has-newline
                                token/back/has-newline
                            ] []

                            <else> [
                                keep " "
                            ]
                        ]

                        keep token/value

                        if <comment> = token/type [
                            keep newline
                        ]
                    ]

                    open [
                        if token/type <> <comment> [
                            indent: indent + 1
                        ]
                    ]

                    close [
                        if token/type <> <comment> [
                            indent: indent - 1

                            if token/has-newline [
                                keep pick indents min max-indent indent
                            ]

                            keep switch token/type [
                                <block>
                                <map> [
                                    #"]"
                                ]

                                <group>
                                <construct> [
                                    #")"
                                ]

                                <binary> [
                                    #"}"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
]
