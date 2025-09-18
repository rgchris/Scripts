Rebol [
    Title: "Combine for Rebol 2"
    Author: "Brian Dickens"
    Date: 28-March-2014
    Version: 0.2.0
    File: %combine.r

    Purpose: "Evaluates a block and concatenates the contents"

    Home: http://blog.hostilefork.com/combine-alternative-rebol-red-rejoin/

    Type: module
    Name: r2c.combine
    Exports: [
        combine
    ]

    Needs: [
        shim
        r2c:bincode
    ]

    History: [
        28-March-2014 0.1.0
        "Original Version"
    ]
]

combine: func [
    [catch]
    "Evaluates a block and concatenates the contents"

    content [block! any-string!]
    "Content to combine"

    /with
    "Add delimiter between values (will be combined if a block)"

    delimiter [block! any-string! char!]

    /into
    "Insert output into an existing string instead of making a new one"

    out [any-string!]

    /local
    value delimit? pre-delimit needs-delimiter
][
    out: any [
        out make string! 10
    ]

    if not block? content [
        content: reduce [
            content
        ]
    ]

    if block? delimiter [
        delimiter: combine delimiter
    ]

    delimit?: no

    ; Do evaluation of the block until a non-none evaluation result
    ; is found... or the end of the input is reached.
    ;
    while [
        not tail? content
    ][
        throw-on-error [
            set [value content] do/next content
        ]

        ; Blocks are substituted in evaluation, like the recursive nature
        ; of parse rules.
        ;
        switch/default type-of/word :value [
            unset!
            none! []

            function! [
                throw make error! "Evaluation in COMBINE gave function"
            ]

            block! [
                pre-delimit
                out: combine/into value out
            ]

            paren!
            path!
            set-path!
            get-path!
            lit-path! [
                throw make error! "Evaluation in COMBINE gave non-block! block"
            ]

            word!
            set-word!
            get-word!
            lit-word!
            refinement! [
                throw make error! rejoin [
                    "Evaluation in COMBINE gave symbolic word: " mold value
                ]
            ]
        ][
            either delimit? [
                append out delimiter
            ][
                delimit?: did with
            ]

            append out (form :value)
        ]
    ]

    either into [
        out
    ][
        head out
    ]
]
