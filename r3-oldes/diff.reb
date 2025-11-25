Rebol [
    Title: "SimpleDiff"
    Author: "Christopher Ross-Gill"
    Date: 25-Aug-2016
    Version: 1.1.1
    File: %diff.reb

    Purpose: "Detect difference between two series"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.diff
    Exports: [
        diff
    ]

    Needs: [
        r3:rgchris:core
    ]

    History: [
        25-Aug-2016 1.1.1
        "Issue differentiating capitalized WORD! values"

        25-Aug-2016 1.1.0
        "Tweaked to be compatible with Ren-C and Red"

        22-May-2014 1.0.0
        "Original Version"
    ]

    Comment: [
        https://github.com/paulgb/simplediff
        "Based on Simple Diff for Python, CoffeeScript v0.1"
        "(C) Paul Butler 2008 <http://www.paulbutler.org/>"
    ]
]

diff: func [
    {
    Find the differences between two blocks. Returns a block of pairs, where the first value
    is in [+ - =] and represents an insertion, deletion, or no change for that list.
    The second value of the pair is the element.
    }

    before [block! string! binary!]
    "Original Series"

    after [block! string! binary!]
    "Updated series"

    /local
    items-before starts-before starts-after run this-run test tests limit
][
    assert [
        equal? type-of before type-of after
    ]

    run: 0

    ; Build a block with elements from 'before as keys, and
    ; each position starting with each element as values.
    ;
    items-before: copy []

    forall before [
        append/only any [
            select/case items-before first before

            last repend items-before [
                first before copy []
            ]
        ] before
    ]

    ; Find the largest subseries common to before and after
    ;
    forall after [
        if tests: select/case items-before first after [
            limit: length-of after

            foreach test tests [
                repeat offset min limit length-of test [
                    this-run: :offset

                    ; using 'strict-equal? here doesn't work with Rebol 2
                    ;
                    if not find/case/only/match at test offset after/:offset [
                        this-run: offset - 1
                        break
                    ]
                ]

                if this-run > run [
                    run: :this-run
                    starts-before: :test
                    starts-after: :after
                ]
            ]
        ]
    ]

    collect [
        either zero? run [
            ; If no common subseries is found, assume that an
            ; insert and delete has taken place
            ;
            if not tail? before [
                keep reduce [
                    '- before
                ]
            ]

            if not tail? after [
                keep reduce [
                    '+ after
                ]
            ]
        ][
            ; Otherwise the common subseries is considered to have no change, and
            ; we recurse on the text before and after the substring
            ;
            keep diff copy/part before starts-before copy/part after starts-after

            keep reduce [
                '= copy/part starts-after run
            ]

            keep diff copy skip starts-before run copy skip starts-after run
        ]
    ]
]
