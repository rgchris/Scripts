Rebol [
    Title: "Ascii85 Encode/Decode"
    Author: "Christopher Ross-Gill"
    Date: 7-Jul-2022
    Version: 0.1.0
    File: %ascii85.r

    Purpose: "Encode/Decode Ascii85 encoded content"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.ascii85
    Exports: [
        ascii85
    ]

    Needs: [
        shim
        r2c:bincode
    ]

    History: [
        7-Jul-2022 0.1.0
        "Initial Encoder/Decoder"
    ]
]

ascii85: make object! [
    factor: [
        52200625.0 614125 7225 85 1
    ]

    digit: charset [
        #"!" - #"u"
    ]

    whitespace: charset as-string #{
        00 09 0A 0C 0D 20
    }

    fail: func [
        [throw]
        mark [string!]
    ][
        throw make error! rejoin [
            "Ascii85 Encoding Error at (" index? mark "): "
            copy/part mark 6
        ]
    ]

    encode: func [
        content [binary! string!]

        /local encoding part size counter
    ][
        content: as-binary content
        encoding: make string! ""
        counter: 0
        size: 5

        parse/all content [
            any [
                content:
                skip
                (part: shift/left to integer! content/1 24)
                [
                    skip
                    (part: part + shift/left to integer! content/2 16)
                    [
                        skip
                        (part: part + shift/left to integer! content/3 8)
                        [
                            skip
                            (part: part + content/4)
                            |
                            (size: 4)
                        ]
                        |
                        (size: 3)
                    ]
                    |
                    (size: 2)
                ]
                (
                    if 16 = counter: counter + 1 [
                        append encoding newline
                        counter: 1
                    ]

                    either all [
                        zero? part
                        size == 5
                    ][
                        append encoding #"z"
                    ][
                        part: part + pick [4294967296 0] negative? part

                        repeat offset size [
                            append encoding add #"!" to integer! part / factor/:offset
                            part: to integer! remainder part factor/:offset
                        ]
                    ]
                )
            ]
        ]

        encoding
    ]

    decode: func [
        [catch]
        encoding [binary! string!]

        /local mark part size closer complete?
    ][
        content: make binary! #{}
        complete?: false

        part: 0
        size: 0

        parse/all as-string encoding [
            [
                "<~"
                (
                    closer: [
                        "~>"
                        (complete?: true)
                        mark:
                        |
                        mark:
                        (fail mark)
                    ]
                )
                |
                (
                    closer: [
                        end
                        (complete?: true)
                        |
                        mark:
                        (fail mark)
                    ]
                )
            ]

            any [
                mark: 
                digit
                (
                    size: size + 1
                    part: -33 + mark/1 * factor/:size + part

                    if size == 5 [
                        if part > 4294967295 [
                            fail mark
                        ]

                        append content unsigned-32/encode part

                        part: 0
                        size: 0
                    ]
                )
                mark:
                |
                #"z"
                (
                    if not zero? size [
                        fail mark
                    ]

                    append content #{00000000}
                )
                mark:
                |
                some whitespace
            ]

            (
                switch size [
                    1 [
                        fail mark
                    ]

                    2 3 4 [
                        part: part + factor/:size - 1

                        if part > 4294967295 [
                            fail mark
                        ]

                        insert/part tail content unsigned-32/encode part size - 1
                    ]
                ]
            )

            closer
        ]

        content
    ]
]
