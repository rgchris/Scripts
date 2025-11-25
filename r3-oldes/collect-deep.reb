Rebol [
    Title: "Collect Deep"
    Date: 12-Jan-2022
    Author: "Christopher Ross-Gill"
    Version: 0.1.0
    File: %do-with.reb

    Purpose: "Procedural deep-container construction"

    Home: https://github.com/rgchris/Scripts/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.collect-deep
    Exports: [
        collect-deep
    ]

    Needs: [
        r3:rgchris:do-with
    ]

    History: [
        31-Aug-2025 0.1.0
        "Initialize as standalone module"
    ]
]

collect-deep: func [
    "Evaluates a block creating a nested values structure using KEEP, PUSH, POP, and THIS"

    body [block!]
    "Block to evaluate"

    /map
    "Initiate with a MAP! value"

    /group
    "Initiate with a PAREN! value"

    /into
    "Initiate with an existing container (returns position after insert for ANY-BLOCK)"

    output [block! paren! map!]
    "Initial container (modified)"

    /local stack
][
    stack: reduce [
        case [
            into [
                output
            ]

            map [
                copy #[]
            ]

            group [
                copy quote ()
            ]

            <else> [
                copy []
            ]
        ]
    ]

    do-with body [
        this: func [] [
            either map? stack/1 [
                stack/1
            ][
                do make error! "COLLECT-DEEP: THIS used outside MAP! container"
            ]
        ]

        keep: func [
            value /only
        ][
            case [
                map? stack/1 [
                    do make error! "COLLECT-DEEP: can't KEEP on MAP! container"
                ]

                only [
                    stack/1: insert/only stack/1 :value
                ]

                <else> [
                    stack/1: insert stack/1 :value
                ]
            ]
        ]

        push: func [
            /map
            /group
        ][
            case [
                map [
                    insert/only stack copy #[]
                ]

                group [
                    insert/only stack copy quote ()
                ]

                <else> [
                    insert/only stack copy []
                ]
            ]

            if not map? stack/2 [
                stack/2: insert/only stack/2 stack/1
            ]

            stack/1
        ]

        pop: func [
            /block
            /map
            /group
            ; refinements only needed for sanity checks
        ][
            either tail? next stack [
                do make error! "COLLECT-DEEP: Popped beyond open containers"
            ][
                case [
                    block [
                        assert [
                            block? stack/1
                        ]
                    ]

                    map [
                        assert [
                            map? stack/1
                        ]
                    ]

                    group [
                        assert [
                            paren? stack/1
                        ]
                    ]
                ]

                if not map? stack/1 [
                    stack/1: head stack/1
                ]

                take stack
            ]
        ]
    ]

    ; perhaps better to 
    remove/part stack back tail stack

    either any [
        into
        map
    ][
        take stack
    ][
        head take stack
    ]
]
