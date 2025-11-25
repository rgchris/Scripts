Rebol [
    Title: "Spaced/Unspaced"
    Author: "Brian Dickens"
    Date: 28-March-2014  ; or thereabouts
    Version: 0.1.0
    File: %combine.reb

    Purpose: "Nuanced string concatenation"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.combine
    Exports: [
        combine
    ]

    Comment: [
        "Based on the COMBINE function from early Ren-C"
    ]
]

lib/combine:
combine: func [
    "Combine evaluated expressions and substitute block variables to produce a string"

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
        value: do/next content 'content

        ; Blocks are substituted in evaluation, like the recursive nature
        ; of parse rules.
        ;
        switch/default type-of/word :value [
            unset! none! []

            function! [
                do make error! "Evaluation in COMBINE gave function"
            ]

            block! [
                pre-delimit
                out: combine/into value out
            ]

            paren! path! set-path! get-path! lit-path! [
                do make error! "Evaluation in COMBINE gave non-block! block"
            ]

            word! set-word! get-word! lit-word! refinement! [
                do make error! rejoin [
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
