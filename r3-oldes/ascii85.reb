Rebol [
    Title: "Ascii85 Encoder/Decoder"
    Author: "Christopher Ross-Gill"
    Date: 7-Jul-2022
    Version: 0.1.0
    File: %ascii85.reb

    Purpose: "Encode/Decode Ascii85 encoded content"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.ascii85
    Exports: [
        ascii85
    ]

    Needs: [
        r3:rgchris:core
    ]

    History: [
        7-Jul-2022 0.1.0
        "Initial Encoder/Decoder"
    ]
]

ascii85: context private [
    factor: #(uint32! [52200625 614125 7225 85 1])
    mask: #(uint32! [4278190080 16711680 65280 255])
    divider: #(uint32! [16777216 65536 256 1])

    space: charset [
        00 09 10 12 13 20
    ]

    digit-1: charset [
        #"!" - #"r"
    ]

    digit-2: charset [
        #"!" - #"7"
    ]

    digit-3: charset [
        #"!" - #"V"
    ]

    digit-4: charset [
        #"!" - #","
    ]

    digit: charset [
        #"!" - #"u"
    ]

    decoders: context [
        decoder: _
        store: #(uint32! [84 84 84 84 84])
        part:
        upper: _

        error: quote (
            insert clear decoder/queue make error! rejoin [
                "Ascii85 encoding error at (" index? decoder/source ") "
                to tag! uppercase form decoder/state ": "
                mold copy/part decoder/source 15
            ]

            decoder/state: #done
        )

        overlarge-error: quote (
            insert clear decoder/queue make error! rejoin [
                "Ascii85 overlarge error, " form decoder/state " position at ("
                index? decoder/source "): " mold copy/part decoder/source 15
            ]

            decoder/state: #done
        )

        done: quote (
            decoder/state: #done
        )

        rules: #[
            #initial [
                "<~"
                (
                    decoder/state: #first
                    decoder/closer: "~>"
                )
                |
                (decoder/state: #first)
                |
                some space
            ]

            #first [
                any space
                [
                    set part [
                        digit-1
                        (upper: no)
                        |
                        #"s"
                        (upper: yes)
                    ]
                    (
                        change store [84 84 84 84 84]

                        store/1: -33 + part
                        decoder/state: #second
                    )
                    |
                    digit
                    overlarge-error
                    |
                    #"z"
                    (
                        append decoder/queue [
                            0 0 0 0
                        ]
                    )
                ]
                |
                if (decoder/closer)
                [
                    any space
                    decoder/closer
                    done
                    |
                    error
                ]
                |
                done
            ]

            #second [
                any space
                set part [
                    if (not upper)
                    digit
                    |
                    [
                        digit-2
                        (upper: no)
                        |
                        #"8"
                    ]
                ]
                (
                    store/2: -33 + part
                    decoder/state: #third
                )
                |
                digit
                overlarge-error
                |
                error
            ]

            #third [
                any space
                set part [
                    if (not upper)
                    digit
                    |
                    [
                        digit-3
                        (upper: no)
                        |
                        #"W"
                    ]
                ]
                (
                    store/3: -33 + part
                    decoder/state: #fourth
                )
                |
                digit
                overlarge-error
                |
                (
                    insert/part decoder/queue to block! divide mask and sum store * factor divider 1
                    decoder/state: #done
                )
            ]

            #fourth [
                any space
                set part [
                    if (not upper)
                    digit
                    |
                    [
                        digit-4
                        (upper: no)
                        |
                        #"-"
                    ]
                ]
                (
                    store/4: -33 + part
                    decoder/state: #fifth
                )
                |
                digit
                overlarge-error
                |
                (
                    insert/part decoder/queue to block! divide mask and sum store * factor divider 2
                    decoder/state: #done
                )
            ]

            #fifth [
                any space
                set part [
                    if (not upper)
                    digit
                    |
                    #"!"
                ]
                (
                    store/5: -33 + part
                    decoder/state: #first

                    insert decoder/queue to block! divide mask and sum store * factor divider
                )
                |
                digit
                overlarge-error
                |
                (
                    insert/part decoder/queue to block! divide mask and sum store * factor divider 3
                    decoder/state: #done
                )
            ]

            #done (
                insert decoder/queue _
            )
        ]
    ]

    prototype: make object! [
        source:
        value:
        queue:
        window:
        store:
        buffer:
        closer: _
        is-done: no
        state: 'initial
    ]
][
    new: func [
        encoding [string! binary!]
        /with
        options [block!]
    ][
        make prototype [
            source: encoding
            queue: make block! 4
            is-done: no
            state: 'initial

            if with [
                parse options [
                    /window
                    set window integer!
                    (buffer: make binary! window + 4)
                    |
                    skip
                ]
            ]
        ]
    ]

    next: func [
        decoder
        /local continue? out
    ][
        decoders/decoder: decoder
        continue?: yes

        while [
            continue?
        ][
            either decoder/window [
                case [
                    not empty? decoder/queue [
                        switch type-of first decoder/queue [
                            #(integer!) [
                                append decoder/buffer take/all decoder/queue
                            ]

                            #(error!) [
                                continue?: no
                                out: take decoder/queue
                            ]

                            #(none!) [
                                remove decoder/queue
                            ]
                        ]
                    ]

                    decoder/window <= length-of decoder/buffer [
                        continue?: no
                        decoder/buffer: take/all skip out: decoder/buffer decoder/window
                    ]

                    'done <> decoder/state [
                        parse/case decoder/source [
                            while [
                                if (empty? decoder/queue)
                                decoders/rules/(decoder/state)
                            ]

                            decoder/source:
                        ]
                    ]

                    #(true) [
                        continue?: no

                        if not empty? decoder/buffer [
                            out: take/all decoder/buffer
                            ; out: take/part decoder/buffer decoder/window (?)
                        ]
                    ]
                ]
            ][
                case [
                    not empty? decoder/queue [
                        continue?: no
                        out: take decoder/queue
                    ]

                    'done <> decoder/state [
                        parse/case decoder/source [
                            while [
                                if (empty? decoder/queue)
                                decoders/rules/(decoder/state)
                            ]

                            decoder/source:
                        ]
                    ]

                    #(true) continue?: no
                ]
            ]
        ]

        decoder/value: switch type-of out [
            #(integer!)
            #(binary!) [
                out
            ]

            #(error!) [
                do :out
            ]
        ]
    ]

    decode: func [
        encoding [binary! string!]
        /local decoder
    ][
        decoder: new/with encoding [
            /window 1024
        ]

        head collect/into [
            while [
                next decoder
            ][
                keep decoder/value
            ]
        ] make binary! 1024
    ]

    encode: func [
        content [binary! string!]

        /local encoding part size counter
    ][
        if string? content [
            content: to binary! content
        ]

        encoding: make string! ""
        counter: 0
        size: 5

        parse content [
            any [
                content:
                skip
                (part: shift to integer! content/1 24)
                [
                    skip
                    (part: part + shift to integer! content/2 16)
                    [
                        skip
                        (part: part + shift to integer! content/3 8)
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
]
