Rebol [
    Title: "Test Runner"
    Author: "Christopher Ross-Gill"
    Date:  2-Feb-2022
    Version: 0.1.0
    Purpose: "Test Runner"

    Needs: [
        shim
        r2c:scheme-error
        r2c:scheme-capture
        r2c:form-error
        r2c:diff
    ]

    Type: module
    Name: rgchris.test-runner
    Exports: [
        tester
    ]
]

delta-time: func [
    {Delta-time - returns the time (in seconds) it takes to evaluate the block.} 
    block [block!] /local 
    start
][
    start: now/precise 
    do block 
    difference now/precise start
]

tester: context [
    results: []

    launch: func [
        script [file!]
    ][
        call/shell reduce either system/version/4 == 3 [
            [{start "" } system/options/boot " -cs " script]
        ][
            [system/options/boot " -cs " script " &"]
        ]
    ]

    has-equality?: func [
        value-1 [any-type!]
        value-2 [any-type!]
    ][
        not not all [
            equal? type? :value-1 type? :value-2

            switch/default type?/word :value-1 [
                object! function! [
                    strict-equal? mold :value-1 mold :value-2
                ]
            ][
                strict-equal? :value-1 :value-2
            ]
        ]
    ]

    as-lines: func [
        value [string!]
    ][
        parse/all trim/tail copy value "^/"
    ]

    clean-diff: func [
        changes [block!]
    ][
        assert [
            block? second changes
        ]

        new-line/all/skip collect [
            foreach [disposition lines] changes [
                switch disposition [
                    - + [
                        foreach line lines [
                            keep disposition
                            keep line
                        ]
                    ]

                    = [
                        either 5 < length? lines [
                            keep reduce [
                                '= first lines
                                '= second lines
                                '... '...
                                '= last lines
                            ]
                        ][
                            foreach line lines [
                                keep disposition
                                keep line
                            ]
                        ]
                    ]
                ]
            ]
        ] true 2
    ]

    form-integer: func [
        value [integer!]
    ][
        value: tail form value

        while [
            4 < index? value
        ][
            value: skip value -3
            insert value #"'"
        ]

        head value
    ]

    form-time: func [
        value [time!]
    ][
        rejoin [
            "(" form-integer to integer! 1000 * value "ms)"
        ]
    ]

    print-disposition: func [
        disposition [word!]
        lapsed [time!]
    ][
        print [
            " ..." form disposition form-time lapsed
        ]
    ]

    run: func [
        name [tag!]
        suite [block!]
        /local has-errors results result error lapsed capture-port output
    ][
        has-errors: false

        results: reduce [
            'name name
            'pass? #[false]
            'passed 0
            'failed 0
            'lapsed 0
            'errors make block! 4
        ]

        results/lapsed: delta-time [
            foreach [name expected test] suite [
                output: ""

                prin uppercase name

                switch type?/word :expected [
                    get-word!
                    get-path! [
                        expected: try compose [(expected)]
                    ]

                    paren! [
                        expected: try to block! expected
                    ]
                ]

                case [
                    unset? :expected [
                        print-disposition 'unset 0:00

                        repend results/errors [
                            name rejoin [
                                "Can't use UNSET as a test condition" newline
                                "Use `(true) [unset? ...]`"
                            ]
                        ]
                    ]

                    not block? :test [
                        print-disposition 'unset 0:00

                        repend results/errors [
                            name rejoin [
                                "Tests must be of type BLOCK!" newline
                                mold :test
                            ]
                        ]
                    ]

                    not time? lapsed: delta-time [
                        output: capture-output [
                            has-error: error? set/any 'result try test
                        ]
                    ][
                        print-disposition 'um-should-not-happen 0:00
                    ]

                    has-error [
                        print-disposition 'error lapsed

                        ; no idea why this is necessary...
                        ; FORM-ERROR is returning the error, not the message
                        ;
                        if error? result: try [
                            form-error :result
                        ][
                            result: form-error :result
                        ]

                        repend results/errors [
                            name result
                        ]

                        results/failed: results/failed + 1
                    ]

                    unset? get/any 'result [
                        print-disposition 'unset lapsed

                        repend results/errors [
                            name rejoin [
                                "Tests cannot resolve to UNSET!" newline
                                mold :test
                            ]
                        ]

                        results/failed: results/failed + 1
                    ]

                    has-equality? :expected :result [
                        print-disposition 'ok lapsed
                        results/passed: results/passed + 1
                    ]

                    <else> [
                        print-disposition 'FAILED lapsed

                        test: trim/head/tail mold test

                        if 200 < length? test [
                            change/part at test 192 " ..." back tail test
                        ]

                        if all [
                            binary? :expected
                            binary? :result
                        ][
                            expected: mold expected
                            result: mold result
                        ]

                        repend results/errors [
                            name rejoin [
                                test newline

                                either all [
                                    string? :expected
                                    string? :result
                                    ; same? type? :expected type? :result
                                ][
                                    mold clean-diff diff as-lines expected as-lines result
                                ][
                                    rejoin [
                                        "expect: " mold :expected newline
                                        "result: " mold :result
                                    ]
                                ]
                            ]
                        ]

                        results/failed: results/failed + 1
                    ]
                ]

                if not empty? output [
                    print rejoin [
                        "-------------------- Test Output --------------------^/"
                        trim/tail output
                        "^/-----------------------------------------------------"
                    ]
                ]
            ]

            true
        ]

        if not empty? results/errors [
            write error:// rejoin collect [
                keep "^/=== errors^/=== ======^/"

                foreach [name message] results/errors [
                    keep reduce [
                        newline
                        name
                        newline newline
                        message
                        newline
                    ]
                ]
            ]
        ]

        results/pass?: zero? results/failed

        print [
            "^/=== tests concluded^/=== ===============^/"
            pick ["ok" "FAILED"] results/pass?
            "|" results/passed "passed"
            "|" results/failed "failed"
            "|" form-time results/lapsed
        ]

        repend self/results [
            name results/pass?
        ]

        results
    ]
]
