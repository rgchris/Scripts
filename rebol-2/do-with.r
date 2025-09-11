Rebol [
    Title: "Do-With"
    Date: 12-Jan-2022
    Version: 0.1.1
    File: %do-with.r
    Author: "Christopher Ross-Gill"

    Purpose: {
        Create a context for evaluating a block of code suitable
        for accumulating values (similar in concept to COLLECT/KEEP)
    }

    Home: https://github.com/rgchris/Scripts/
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.do-with
    Exports: [
        reduce-only do-with
    ]

    Needs: [
        shim
    ]

    History: [
        12-Jan-2022 0.1.0 "Created module"
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
            set [value block] do/next block
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

    args: collect-each [name value] context [
        keep to get-word! name
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
