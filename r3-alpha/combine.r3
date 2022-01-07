Rebol [
    Title: "Combine"
    Date: 28-March-2014  ; or thereabouts
    Author: "Brian Dickens"
    Version: 1.0.0

    Type: module
    Name: hostilefork.combine
    Exports: [
        combine
    ]
]

combine: func [
    {Combine evaluated expressions and substitute block variables to produce a string}
    block [block! any-string!] "Specification to process"
    /with "Add delimiter between values (will be combined if a block)"
    delimiter [block! any-string! char!]
    /into "Insert output into an existing string instead of making a new one"
    out [any-string!]
    /local
    value pre-delimit needs-delimiter
][
    out: any [out make string! 10]

    unless block? block [
        block: reduce [block]
    ]

    if block? delimiter [
        delimiter: combine delimiter
    ]

    needs-delimiter: none

    pre-delimit: does [
        either needs-delimiter [
            out: append out delimiter
        ][
            needs-delimiter: true? with
        ]
    ]

    ; Do evaluation of the block until a non-none evaluation result
    ; is found... or the end of the input is reached.
    ;
    while [not tail? block] [
        try/except [
            value: do/next block 'block
        ][
            do system/state/last-error
        ]

        ; Blocks are substituted in evaluation, like the recursive nature
        ; of parse rules.
        ;
        switch/default type?/word :value [
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
                do make error! join "Evaluation in COMBINE gave symbolic word: " mold value
            ]
        ][
            pre-delimit
            append out (form :value)
        ]
    ]

    either into [
        out
    ][
        head out
    ]
]
