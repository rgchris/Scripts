Rebol [
    Title: "Collect-Deep"
    Author: "Christopher Ross-Gill"
    Date: 12-Jan-2022
    Version: 0.1.0
    File: %collect-deep.r

    Purpose: "Build a nested block of values procedurally"

    Home: https://github.com/rgchris/Scripts/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.collect-deep
    Exports: [
        collect-deep
    ]

    Needs: [
        shim
        r2c:do-with
    ]

    History: [
        31-Aug-2025 0.1.0
        "Added to separate module"
    ]
]

collect-deep: func [
    "Evaluates a block, storing values via KEEP function, and returns block of collected values."

    body [block!]
    "Block to evaluate"

    /into
    "Insert into a buffer instead (returns position after insert)"

    output [block!]
    "The buffer series (modified)"

    /local stack
][
    stack: reduce [
        any [
            output
            make block! 16
        ]
    ]

    do-with body [
        keep: func [
            value /only
        ][
            stack/1: either only [
                insert/only stack/1 :value
            ][
                insert stack/1 :value
            ]
        ]

        push: func [
            /group
        ][
            insert/only stack make either group [paren!] [block!] 16
            stack/2: insert/only stack/2 stack/1
            stack/1
        ]

        pop: func [
            [catch]
        ][
            either tail? next stack [
                throw make error! "Cannot POP"
            ][
                stack/1: head stack/1
                take stack
            ]
        ]
    ]

    remove/part stack back tail stack

    either into [take stack] [head take stack]
]
