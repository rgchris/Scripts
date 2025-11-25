Rebol [
    Title: "Do-With"
    Author: "Christopher Ross-Gill"
    Date: 31-Aug-2025
    Version: 0.1.1
    File: %do-with.reb

    Purpose: {
        Create a context for evaluating a block of code suitable
        for accumulating values (similar in concept to COLLECT/KEEP)
    }

    Home: https://github.com/rgchris/Scripts/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.do-with
    Exports: [
        reduce-only do-with reduce-with
    ]

    Needs: [
        r3:rgchris:core
    ]

    History: [
        31-Aug-2025 0.1.1
        "Remove COLLECT-DEEP"

        12-Jan-2022 0.1.0
        "First conception"
    ]

    Comment: [
        * "Such functionality could be useful in Core"
    ]
]

reduce-only: func [
    "Evaluates a block of expressions excepting SET-WORD! values"

    block [block!]
    "Block to evaluate"

    /local value
][
    collect-while [
        not tail? block
    ][
        either set-word? first block [
            keep first block
            block: next block
        ][
            value: do/next block 'block
            keep/only :value
        ]
    ]
]

do-with: func [
    "Evaluate a block with a collection of context-sensitive functions"

    body [block!]
    "Block to evaluate"

    context [block!]
    "Specification for the context-sensitive functions"

    /local
    args
][
    context: reduce-only context

    args: collect-each [name value] context [
        keep to get-word! name
    ]

    do collect [
        keep func args copy/deep body

        foreach [name value] context [
            keep/only :value
        ] 
    ]
]

reduce-with: func [
    body [block!]
    "Evaluate a block with a collection of context-sensitive functions"

    context [block!]
    "Context to evaluate with"

    /local args
][
    context: reduce-only context

    args: collect [
        foreach [name value] context [
            keep to get-word! name
        ]
    ]

    do collect [
        keep func args compose/only [
            reduce (body)
        ]

        foreach [name value] context [
            keep/only :value
        ]
    ]
]
