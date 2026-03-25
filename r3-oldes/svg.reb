Rebol [
    Title: "SVG Tools"
    Author: "Christopher Ross-Gill"
    Date: 25-Mar-2026
    Version: 0.5.0
    File: %svg.reb

    Purpose: {
        Tools for importing and manipulating content stored in
        the SVG graphics format
    }

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.svg
    Exports: [
        svg load-svg to-svg
    ]

    Needs: [
        r3:rgchris:altxml
        r3:rgchris:rsp
        r3:rgchris:do-with
        r3:rgchris:combine
    ]

    History: [
        0.5.0 25-Mar-2026
        "Further formats reorganization; Some Filters, Text, and Animation improvements"

        0.4.3 15-Feb-2026
        "Add Tilted Linear Gradient"

        0.4.2 15-Feb-2026
        "Refactor with MAP/COMPOSE changes; remove legacy PATH code"

        0.4.1 5-Feb-2026
        "Added LINEAR-GRADIENT, RADIAL GRADIENT; cleaned up ANIMATE"

        0.4.0 24-Aug-2022
        "Separation of microformats"

        0.3.2 27-Jan-2020
        "Better handling of text whitespace; bold/italic"

        0.3.1 24-Jan-2020
        "PATH model rewrite; VIEW wrapper to view an SVG"

        0.3.0 23-Jan-2020
        "Reorganise PATH handling; render whole/partial object; further refactoring"

        0.2.2 13-Sep-2019
        "Some functions for manipulating paths; refactoring"

        0.2.1 26-Aug-2019
        "Set Stroke/Fill off by default; handle numbers with units; open paths"

        0.2.0 25-Aug-2019
        "Text support in TO-DRAW"

        0.1.0 23-Dec-2018
        "Rudimentary Shape Support"
    ]

    Comment: [
        * "Rebol 2 version: rough conversion from the Red version"

        "v0.3.2" {
        There are still many ways in which this could be more efficient, but for now the focus is
        merely having everything work. PUSH per-shape is expensive, and I'd much prefer to reuse
        font objects.

        There's still more functionality to figure out too: gradient fills, <use>, <textpath> to
        name but a few.
        }

        === "View/VID-related functions"

        "Now contained within the SVG/VID sub-object"

        [view svg/vid/quick-layout load-svg read %my-svg.svg]

        https://github.com/red/docs/blob/master/en/draw.adoc
        "Red Draw Docs"

        === "Paths"

        https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
        "MDN Overview"

        https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
        "SVG (1.1)"

        https://www.w3.org/TR/SVG/paths.html#PathDataBNF
        "SVG (2--incomplete as-of 22-Jan-2020)"

        === "Misc"

        https://github.com/MadLittleMods/svg-curve-lib
        "Length (evaluate)"

        https://stackoverflow.com/questions/5149301
        "Baking transforms"
    ]
]

svg: context [
    ; quickie number parsing
    ; number*: charset "-.0123456789eE"

    default-precision: 0.001

    name*: complement charset [
        9 10 12 13 32 34 39 44 59
    ]

    spacers*: charset [
        9 10 12 13 32
    ]

    digit*: charset [
        "0123456789"
    ]

    hex*: charset [
        "0123456789abcdefABCDEF"
    ]

    lower-alpha*: charset [
        #"a" - #"z"
    ]

    ; url-safe*: charset [
    ;     #"A" - #"Z"
    ;     "!#$%&*+,-./:;=?@^^_|~"
    ;     ; unicode chars here?
    ; ]

    url-safe*: complement charset [
        0 - 32
        {"'()<>[]{}}
    ]

    space*: [
        some spacers*
    ]

    comma*: [
        space*
        opt #","
        opt space*
        |
        #","
        opt space*
    ]

    unsigned*: [
        [
            some digit*
            opt #"."
            any digit*
            |
            #"."
            some digit*
        ]

        opt [
            [#"e" | #"E"]
            opt [#"-" | #"+"]
            some digit*
        ]
    ]

    number*: [
        opt [#"+" | #"-"]
        unsigned*
    ]

    word*: [
        lower-alpha*
        some [
            some lower-alpha*
            |
            digit*
            |
            #"-"
        ]
    ]

    url*: [
        word*
        #":"
        some url-safe*
    ]

    fail-mark: _

    fail-if-not-end: [
        end
        |
        fail-mark: (
            make error! rejoin [
                "Parse Error: " copy/part mold fail-mark 30
            ]
        )
    ]

    is-value-from: func [
        value [string!]
        list [block!]
    ][
        if find list value [
            load value
        ]
    ]

    numbers: context [
        decode: func [
            encoded [string! integer! decimal!]
            /local value
        ][
            either string? encoded [
                value: load encoded
            ][
                value: encoded
            ]

            switch type-of value [
                #(decimal!) [
                    ; ; default rounding is bad, it has a destructive
                    ; ; influence on relative path values
                    ; ;
                    ; round/to value 0.001

                    value
                ]

                #(integer!) [
                    value
                ]
            ]
        ]

        from-unit: func [
            number [string!]

            /local value unit
        ][
            if parse number [
                copy value number*

                copy unit opt [
                    #"%" | "px" | "mm" | "cm" | "in" | "pt" | #"s" | "deg"
                ]
            ][
                switch unit [
                    _ "" "px" "deg" [
                        numbers/decode value
                    ]

                    #"%" [
                        .01 * to decimal! value
                    ]

                    #"s" [
                        to time! value
                    ]

                    ;@@ not yet supported
                    ; "mm" "cm" "in" "pt" [none]
                ]
            ]
        ]

        encode: func [
            value [number!]
            /with options [map!]
            /local precision
        ][
            if all [
                map? options
                number? precision: options/precision
            ][
                value: either percent? value [
                    either percent? precision [
                        round/to value precision
                    ][
                        round/to value to percent! precision / 100
                    ]
                ][
                    round/to value precision
                ]
            ]

            switch type-of value [
                #(integer!) #(percent!) [
                    form value
                ]

                #(decimal!) [
                    value: form value

                    case [
                        parse value [
                            thru ".0" end
                        ][
                            clear find value ".0"
                        ]

                        find/match value "0." [
                            remove value
                        ]

                        find/match value "-0." [
                            remove next value
                        ]
                    ]

                    value
                ]
            ]
        ]
    ]

    paths: context [
        comment [
            https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
            "MDN Overview"

            https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
            "SVG (1.1)"

            https://www.w3.org/TR/SVG/paths.html#PathDataBNF
            "SVG (2--incomplete as-of 22-Jan-2020)"

            https://github.com/MadLittleMods/svg-curve-lib
            "Length (need to evaluate)"
        ]

        commands: #[
            #"M" move   #"m" 'move
            #"Z" close  #"z" 'close
            #"L" line   #"l" 'line
            #"H" hline  #"h" 'hline
            #"V" vline  #"v" 'vline
            #"C" curve  #"c" 'curve
            #"S" curv   #"s" 'curv
            #"Q" qcurve #"q" 'qcurve
            #"T" qcurv  #"t" 'qcurv
            #"A" arc    #"a" 'arc
        ]

        space*: charset [
            9 10 13 32
        ]

        grammar: context [
            part:
            mark:
            decoder: _

            mark-here: func [
                mark [string!]
            ][
                rejoin [
                    copy/part skip mark -16 mark
                    "^^^^"
                    copy/part mark 60
                ]
            ]

            rules: #[
                #initial [
                    [
                        #"M"
                        (decoder/relative?: no)
                        |
                        #"m"
                        (decoder/relative?: yes)
                    ]
                    (
                        decoder/command: 'move
                        decoder/value: copy [0x0]
                        decoder/state: #coordinate-one
                    )
                    |
                    some space*
                    |
                    (
                        decoder/state: #error
                        decoder/value: "Expected initial MOVE command"
                    )
                ]

                #commands [
                    mark:
                    [
                        [#"L" | #"l" | #"M" | #"m" | #"T" | #"t"]
                        (
                            decoder/state: #coordinate-one
                            decoder/value: copy [0x0]
                        )
                        |
                        [#"S" | #"s" | #"Q" | #"q"]
                        (
                            decoder/state: #coordinate-one
                            decoder/value: copy [0x0 0x0]
                        )
                        |
                        [#"C" | #"c"]
                        (
                            decoder/state: #coordinate-one
                            decoder/value: copy [0x0 0x0 0x0]
                        )
                        |
                        [#"H" | #"h" | #"V" | #"v"]
                        (
                            decoder/state: #coordinate-one
                            decoder/value: copy [0]
                        )
                        |
                        [#"A" | #"a"]
                        (
                            decoder/state: #arc-radius-x
                            decoder/value: copy [0x0 0 _ _ 0x0]
                        )
                        |
                        [#"Z" | #"z"]
                        (
                            decoder/state: #emit
                            decoder/value: []
                        )
                    ]
                    (
                        decoder/command: select/case commands mark/1

                        if decoder/relative?: lit-word? decoder/command [
                            decoder/command: to word! decoder/command
                        ]
                    )
                    |
                    some space*
                    |
                    decoder/delimiter
                    :mark
                    (
                        decoder/state: #done
                        decoder/command: 'done
                    )
                    |
                    (
                        switch/default decoder/command [
                            move [
                                decoder/state: #comma-space-optional
                                decoder/next-state: #coordinate-one
                                decoder/command: 'line
                            ]

                            line
                            hline
                            vline
                            curve
                            curv
                            qcurve
                            qcurv [
                                decoder/state: #comma-space-optional
                                decoder/next-state: #coordinate-one
                            ]

                            arc [
                                decoder/state: #comma-space-optional
                                decoder/next-state: #arc-radius-x
                            ]
                        ][
                            decoder/state: #error
                            decoder/reason: "Expected next PATH command"
                        ]
                    )
                ]

                #comma-space-optional [
                    opt [
                        some space*
                        opt #","
                        |
                        #","
                    ]
                    any space*
                    (
                        decoder/state: decoder/next-state
                        decoder/next-state: _
                    )
                ]

                #comma-space [
                    [
                        #","
                        |
                        some space*
                        opt #","
                    ]
                    any space*
                    (
                        decoder/state: decoder/next-state
                        decoder/next-state: _
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: "Expected Space"
                        decoder/next-state: _
                    )
                ]

                #coordinate-one [
                    copy part number*
                    (
                        part: numbers/decode part

                        either find [hline vline] decoder/command [
                            decoder/state: #emit
                            decoder/value/1: part
                        ][
                            decoder/state: #comma-space-optional
                            decoder/next-state: #coordinate-two
                            decoder/value/1/x: part
                        ]
                    )
                    |
                    some space*
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG-1: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #coordinate-two [
                    copy part number*
                    (
                        decoder/value/1/y: numbers/decode part

                        either find [move line qcurv] decoder/command [
                            decoder/state: #emit
                        ][
                            decoder/state: #comma-space-optional
                            decoder/next-state: #coordinate-three
                        ]
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG-2: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #coordinate-three [
                    copy part number*
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #coordinate-four
                        decoder/value/2/x: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG-3: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #coordinate-four [
                    copy part number*
                    (
                        decoder/value/2/y: numbers/decode part

                        either find [curv qcurve] decoder/command [
                            decoder/state: #emit
                        ][
                            decoder/state: #comma-space-optional
                            decoder/next-state: #coordinate-five
                        ]
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG-4: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #coordinate-five [
                    copy part number*
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #coordinate-six
                        decoder/value/3/x: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG-5: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #coordinate-six [
                    copy part number*
                    (
                        decoder/state: #emit
                        decoder/value/3/y: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "Command " uppercase form decoder/command " expected ARG6: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-radius-x [
                    copy part unsigned*
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #arc-radius-y
                        decoder/value/1/x: numbers/decode part
                    )
                    |
                    some space*
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected RX value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-radius-y [
                    copy part unsigned*
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #arc-rotation
                        decoder/value/1/y: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected RY value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-rotation [
                    copy part number*
                    (
                        decoder/state: #comma-space
                        decoder/next-state: #arc-large-arc
                        decoder/value/2: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected X-AXIS-ROTATION value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-large-arc [
                    [
                        #"0"
                        (decoder/value/3: no)
                        |
                        #"1"
                        (decoder/value/3: yes)
                    ]
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #arc-sweep
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected LARGE-ARC-FLAG value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-sweep [
                    [
                        #"0"
                        (decoder/value/4: no)
                        |
                        #"1"
                        (decoder/value/4: yes)
                    ]
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #arc-coordinate-x
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected SWEEP-FLAG value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-coordinate-x [
                    copy part number*
                    (
                        decoder/state: #comma-space-optional
                        decoder/next-state: #arc-coordinate-y
                        decoder/value/5/x: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected X value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #arc-coordinate-y [
                    copy part number*
                    (
                        decoder/state: #emit
                        decoder/value/5/y: numbers/decode part
                    )
                    |
                    (
                        decoder/state: #error
                        decoder/reason: rejoin [
                            "ARC command expected X value: "
                            mold mark-here decoder/source
                        ]
                    )
                ]

                #emit [
                    (
                        decoder/state: #commands
                        decoder/continue?: no

                        switch decoder/command [
                            move [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset
                                ]

                                decoder/value/1/x: round/to decoder/value/1/x decoder/precision
                                decoder/value/1/y: round/to decoder/value/1/y decoder/precision

                                decoder/origin:
                                decoder/offset: decoder/value/1
                            ]

                            hline [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset/x
                                ]

                                decoder/value/1:
                                decoder/offset/x: round/to decoder/value/1 decoder/precision
                            ]

                            vline [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset/y
                                ]

                                decoder/value/1:
                                decoder/offset/y: round/to decoder/value/1 decoder/precision
                            ]

                            line
                            qcurv [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset
                                ]

                                decoder/value/1/x: round/to decoder/value/1/x decoder/precision
                                decoder/value/1/y: round/to decoder/value/1/y decoder/precision

                                decoder/offset: decoder/value/1
                            ]

                            curv qcurve [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset
                                    decoder/value/2: decoder/value/2 + decoder/offset
                                ]

                                decoder/value/1/x: round/to decoder/value/1/x decoder/precision
                                decoder/value/1/y: round/to decoder/value/1/y decoder/precision
                                decoder/value/2/x: round/to decoder/value/2/x decoder/precision
                                decoder/value/2/y: round/to decoder/value/2/y decoder/precision

                                decoder/offset: decoder/value/2
                            ]

                            curve [
                                if decoder/relative? [
                                    decoder/value/1: decoder/value/1 + decoder/offset
                                    decoder/value/2: decoder/value/2 + decoder/offset
                                    decoder/value/3: decoder/value/3 + decoder/offset
                                ]

                                decoder/value/1/x: round/to decoder/value/1/x decoder/precision
                                decoder/value/1/y: round/to decoder/value/1/y decoder/precision
                                decoder/value/2/x: round/to decoder/value/2/x decoder/precision
                                decoder/value/2/y: round/to decoder/value/2/y decoder/precision
                                decoder/value/3/x: round/to decoder/value/3/x decoder/precision
                                decoder/value/3/y: round/to decoder/value/3/y decoder/precision

                                decoder/offset: decoder/value/3
                            ]

                            arc [
                                if decoder/relative? [
                                    decoder/value/5: decoder/value/5 + decoder/offset
                                ]

                                decoder/value/5/x: round/to decoder/value/5/x decoder/precision
                                decoder/value/5/y: round/to decoder/value/5/y decoder/precision

                                decoder/offset: decoder/value/5
                            ]

                            close [
                                decoder/offset: decoder/origin
                            ]
                        ]
                    )
                ]

                #error [
                    (
                        ; probe neaten reduce [
                        ;     decoder/command
                        ;     decoder/value
                        ;     mark-here decoder/source
                        ; ]

                        decoder/state: #commands
                        decoder/command: 'error
                        decoder/continue?: no

                        do make error! rejoin [
                            either string? decoder/reason [
                                decoder/reason
                            ][
                                "Path Decoder Error"
                            ]
                        ]
                    )
                    skip
                ]

                #done [
                    (
                        decoder/command: _
                        decoder/continue?: no
                    )
                ]
            ]
        ]

        decoders: context [
            prototype: make object! [
                next: _
                source:
                command:
                value:
                reason: _
                offset:
                origin: 0x0
                state: #initial
                delimiter: 'end
                precision: 0.001
                next-state:
                relative?: _
                continue?: yes
            ]

            new: func [
                encoding [string!]
                /with options [block!]
                /local decoder
            ][
                decoder: make prototype [
                    source: :encoding
                    ; parse options
                ]

                decoder/next: :next

                decoder
            ]

            next: func [
                decoder [object!]
            ][
                either #done = decoder/state [
                    _
                ][
                    grammar/decoder: decoder
                    decoder/continue?: yes

                    parse/case decoder/source [
                        while [
                            if (decoder/continue?)
                            grammar/rules/(decoder/state)
                            decoder/source:
                        ]
                    ]

                    decoder/command
                ]
            ]
        ]

        decode: func [
            path [string!]
            /local decoder
        ][
            decoder: decoders/new path

            neaten/pairs collect-while [
                decoders/next decoder
            ][
                if not 'done = decoder/command [
                    keep decoder/command
                    keep/only copy decoder/value
                ]
            ]
        ]

        ; Interpret
        ;
        command-name: [
            'move | 'line | 'hline | 'vline | 'arc | 'curve | 'qcurve | 'curv | 'qcurv | 'close
        ]

        draw-params: make object! [
            move: [pair!]
            line: [pair!]
            hline: [number!]
            vline: [number!]
            arc: [pair! 3 number! opt 'sweep opt 'large]
            curve: [3 pair!]
            qcurve: [2 pair!]
            curv: [2 pair!]
            qcurv: [pair!]
            close: []
        ]

        draw-path-to-path: func [
            path [block!]
            /local here command offset origin params relative? implicit? value
        ][
            command: _

            offset: 0x0
            origin: 0x0

            implicit?: #(false)
            relative?: #(false)

            neaten/words collect [
                origin/1: 0
                origin/2: 0
                offset/1: 0
                offset/2: 0

                if not parse path [
                    some [
                        end break
                        |
                        [
                            here:
                            command-name (
                                command: to word! here/1
                                implicit?: #(false)
                                relative?: lit-word? here/1
                                params: select draw-params here/1
                            )
                            |
                            (
                                implicit?: #(true)
                                params: any [params [fail]]
                                if command = 'move [
                                    command: 'line
                                ]
                            )
                        ]

                        copy part params (
                            switch command [
                                move [
                                    if relative? [
                                        part/1: part/1 + offset/1
                                        part/2: part/2 + offset/2
                                    ]

                                    origin/1: offset/1: part/1
                                    origin/2: offset/2: part/2
                                ]

                                hline [
                                    if relative? [
                                        part/1: part/1 + offset/1
                                    ]

                                    offset/1: part/1
                                ]

                                vline [
                                    if relative? [
                                        part/1: part/1 + offset/2
                                    ]

                                    offset/2: part/1
                                ]

                                line qcurv [
                                    if relative? [
                                        part/1: part/1 + offset/1
                                        part/2: part/2 + offset/2
                                    ]

                                    offset/1: part/1
                                    offset/2: part/2
                                ]

                                curv qcurve [
                                    if relative? [
                                        part/1: part/1 + offset/1
                                        part/2: part/2 + offset/2
                                        part/3: part/3 + offset/1
                                        part/4: part/4 + offset/2
                                    ]

                                    offset/1: part/4
                                    offset/2: part/5
                                ]

                                curve [
                                    if relative? [
                                        part/1: part/1 + offset/1
                                        part/2: part/2 + offset/2
                                        part/3: part/3 + offset/1
                                        part/4: part/4 + offset/2
                                        part/5: part/5 + offset/1
                                        part/6: part/6 + offset/2
                                    ]

                                    offset/1: part/5
                                    offset/2: part/6
                                ]

                                arc [
                                    part: reduce [
                                        part/2
                                        part/3
                                        part/4
                                        block? find part 'large
                                        block? find part 'sweep
                                        part/1/x
                                        part/1/y
                                    ]

                                    if relative? [
                                        part/6: part/6 + offset/1
                                        part/7: part/7 + offset/2
                                    ]

                                    offset/1: part/6
                                    offset/2: part/7
                                ]

                                close [
                                    offset/1: origin/1
                                    offset/2: origin/2
                                ]
                            ]

                            keep reduce [
                                command part
                            ]
                        )
                    ]
                ][
                    do make error! rejoin [
                        "Could not parse path (at #" copy/part here 8 ")"
                    ]
                ]
            ]
        ]

        next-command: func [
            here [block!]
            /local params part implicit?
        ][
            if head? here [
                current/command: _
                current/position: 0x0
                implicit?: #(false)
            ]

            comment {
                Return format is: [
                    command relative? implicit? offset params new-position
                ]
            }

            case [
                tail? here [
                    _
                ]

                parse here [
                    [
                        command-name (
                            current/command: here/1
                            implicit?: #(false)
                            params: command-params/:current-command
                        )
                        |
                        (
                            implicit?: #(true)
                            params: either none? current/command [
                                [end skip]
                            ][
                                if current/command = 'move [
                                    current/command: 'line
                                ]

                                select path-params current/command
                            ]
                        )
                    ]

                    copy part params
                    here: to end
                ][
                    reduce [
                        to word! current/command
                        lit-word? current/command
                        part
                        here
                    ]
                ]

                #else [
                    do make error! rejoin [
                        "Could not parse path (at #" index? here ")"
                    ]
                ]
            ]
        ]

        round-params: func [
            command [word!]
            params [block!]
            precision [integer! decimal!]

            /local param
        ][
            params: copy params

            for-each param switch command [
                vline hline [
                    [1]
                ]

                move line qcurv [
                    [1]
                ]

                curv qcurve [
                    [1 2]
                ]

                curve [
                    [1 2 3]
                ]

                arc [
                    [1 2 5]
                ]

            ][
                poke params param round/to pick params param precision
            ]

            params
        ]

        encode: func [
            path [block!]
            /with
            options [map!]

            /local
            precision out prep emit command params value type last offset origin
        ][
            options: any [
                options
                copy #[]
            ]
            
            precision:
            options/precision: any [
                options/precision
                default-precision
            ]

            offset:
            origin: 0x0
            last: _

            out: make string! 16 * length-of path
            ; approx. pre-allocation

            prep: func [
                value [integer! decimal!]
            ][
                value: numbers/encode/with value options

                case [
                    ; can always append negative numbers without padding
                    ;
                    find/match value #"-" _

                    find/match value #"." [
                        if find [integer] last [
                            insert value #" "
                        ]
                    ]

                    find [integer decimal] last [
                        insert value #" "
                    ]
                ]

                last: either find value #"." [
                    'decimal
                ][
                    'integer
                ]

                value
            ]

            emit: func [values] [
                append out collect [
                    for-each value reduce values [
                        switch type-of value [
                            #(char!) [
                                keep value

                                last: 'word
                            ]

                            #(logic!) [
                                if find [integer decimal] last [
                                    keep #" "
                                ]

                                keep pick [1 0] value

                                last: 'logic
                            ]

                            #(word!) [
                                value: value = 'true

                                if find [integer decimal] last [
                                    keep #" "
                                ]

                                keep pick [1 0] value

                                last: 'logic
                            ]

                            #(decimal!) #(integer!) [
                                keep prep value
                            ]

                            #(pair!) [
                                keep prep value/x
                                keep prep value/y
                            ]
                        ]
                    ]
                ]
            ]

            for-each [command params] path [
                ; note that ENCODE creates an SVG path with relative coordinates

                if not command == 'close [
                    params: round-params command params precision
                ]

                switch command [
                    move [
                        emit [
                            #"m"
                            params/1 - offset
                        ]

                        origin:
                        offset: params/1
                    ]

                    hline [
                        emit [
                            #"h"
                            params/1 - offset/x
                        ]

                        offset/x: params/1
                    ]

                    vline [
                        emit [
                            #"v"
                            params/1 - offset/y
                        ]

                        offset/y: params/1
                    ]

                    line qcurv [
                        emit [
                            select [line #"l" qcurv #"t"] command
                            params/1 - offset
                        ]

                        offset: params/1
                    ]

                    curv qcurve [
                        emit [
                            select [curv #"s" qcurve #"q"] command
                            params/1 - offset
                            params/2 - offset
                        ]

                        offset: params/2
                    ]

                    curve [
                        emit [
                            #"c"
                            params/1 - offset
                            params/2 - offset
                            params/3 - offset
                        ]

                        offset: params/3
                    ]

                    arc [
                        emit [
                            #"a"
                            params/1
                            params/2
                            params/3 params/4
                            params/5 - offset
                        ]

                        offset: params/5
                    ]

                    close [
                        append out #"z"

                        offset/1: origin/1
                        offset/2: origin/2
                    ]
                ]
            ]

            uppercase/part out 1
        ]
    ]

    lists: context [
        decode: func [
            list [string!]
            /local part
        ][
            collect [
                parse list [
                    any [
                        part:
                        space*
                        opt #","
                        opt space*
                        |
                        #","
                        opt space*
                        |
                        copy part number*
                        (keep numbers/decode part)
                    ]

                    fail-if-not-end
                ]
            ]
        ]

        encode: func [
            list [block! paren!]
            /with
            options [map!]
            /comma
        ][
            comma: either comma [#","] [#" "]

            rejoin back change collect-all list [
                keep comma

                keep switch/default type-of list/1 [
                    #(integer!)
                    #(decimal!)
                    #(percent!) [
                        numbers/encode/:with list/1 options
                    ]

                    #(issue!) [
                        sanitize mold list/1
                    ]

                    #(none!) [
                        do make error! rejoin [
                            "Should not be NONE! here: " mold list
                        ]
                    ]

                    #(pair!) [
                        reduce [
                            numbers/encode/:with list/1/x options
                            comma
                            numbers/encode/:with list/1/y options
                        ]
                    ]
                ][
                    sanitize form list/1
                ]
            ] ""
        ]
    ]

    paint: context [
        named: #[
            black: 0.0.0
            navy: 0.0.128
            darkblue: 0.0.139
            mediumblue: 0.0.205
            blue: 0.0.255
            darkgreen: 0.100.0
            green: 0.128.0
            teal: 0.128.128
            darkcyan: 0.139.139
            deepskyblue: 0.191.255
            darkturquoise: 0.206.209
            mediumspringgreen: 0.250.154
            lime: 0.255.0
            springgreen: 0.255.127
            cyan: 0.255.255
            aqua: 0.255.255
            midnightblue: 25.25.112
            dodgerblue: 30.144.255
            lightseagreen: 32.178.170
            forestgreen: 34.139.34
            seagreen: 46.139.87
            darkslategray: 47.79.79
            darkslategrey: 47.79.79
            limegreen: 50.205.50
            mediumseagreen: 60.179.113
            turquoise: 64.224.208
            royalblue: 65.105.225
            steelblue: 70.130.180
            darkslateblue: 72.61.139
            mediumturquoise: 72.209.204
            indigo: 75.0.130
            darkolivegreen: 85.107.47
            cadetblue: 95.158.160
            cornflowerblue: 100.149.237
            mediumaquamarine: 102.205.170
            dimgrey: 105.105.105
            dimgray: 105.105.105
            slateblue: 106.90.205
            olivedrab: 107.142.35
            slategrey: 112.128.144
            slategray: 112.128.144
            lightslategray: 119.136.153
            lightslategrey: 119.136.153
            mediumslateblue: 123.104.238
            lawngreen: 124.252.0
            chartreuse: 127.255.0
            aquamarine: 127.255.212
            maroon: 128.0.0
            purple: 128.0.128
            olive: 128.128.0
            gray: 128.128.128
            grey: 128.128.128
            skyblue: 135.206.235
            lightskyblue: 135.206.250
            blueviolet: 138.43.226
            darkred: 139.0.0
            darkmagenta: 139.0.139
            saddlebrown: 139.69.19
            darkseagreen: 143.188.143
            lightgreen: 144.238.144
            mediumpurple: 147.112.219
            darkviolet: 148.0.211
            palegreen: 152.251.152
            darkorchid: 153.50.204
            yellowgreen: 154.205.50
            sienna: 160.82.45
            brown: 165.42.42
            darkgray: 169.169.169
            darkgrey: 169.169.169
            lightblue: 173.216.230
            greenyellow: 173.255.47
            paleturquoise: 175.238.238
            lightsteelblue: 176.196.222
            powderblue: 176.224.230
            firebrick: 178.34.34
            darkgoldenrod: 184.134.11
            mediumorchid: 186.85.211
            rosybrown: 188.143.143
            darkkhaki: 189.183.107
            silver: 192.192.192
            mediumvioletred: 199.21.133
            indianred: 205.92.92
            peru: 205.133.63
            chocolate: 210.105.30
            tan: 210.180.140
            lightgray: 211.211.211
            lightgrey: 211.211.211
            thistle: 216.191.216
            orchid: 218.112.214
            goldenrod: 218.165.32
            palevioletred: 219.112.147
            crimson: 220.20.60
            gainsboro: 220.220.220
            plum: 221.160.221
            burlywood: 222.184.135
            lightcyan: 224.255.255
            lavender: 230.230.250
            darksalmon: 233.150.122
            violet: 238.130.238
            palegoldenrod: 238.232.170
            lightcoral: 240.128.128
            khaki: 240.230.140
            aliceblue: 240.248.255
            honeydew: 240.255.240
            azure: 240.255.255
            sandybrown: 244.164.96
            wheat: 245.222.179
            beige: 245.245.220
            whitesmoke: 245.245.245
            mintcream: 245.255.250
            ghostwhite: 248.248.255
            salmon: 250.128.114
            antiquewhite: 250.235.215
            linen: 250.240.230
            lightgoldenrodyellow: 250.250.210
            oldlace: 253.245.230
            red: 255.0.0
            fuchsia: 255.0.255
            magenta: 255.0.255
            deeppink: 255.20.147
            orangered: 255.69.0
            tomato: 255.99.71
            hotpink: 255.105.180
            coral: 255.127.80
            darkorange: 255.140.0
            lightsalmon: 255.160.122
            orange: 255.165.0
            lightpink: 255.182.193
            pink: 255.192.203
            gold: 255.215.0
            peachpuff: 255.218.185
            navajowhite: 255.222.173
            moccasin: 255.228.181
            bisque: 255.228.196
            mistyrose: 255.228.225
            blanchedalmond: 255.235.205
            papayawhip: 255.239.213
            lavenderblush: 255.240.245
            seashell: 255.245.238
            cornsilk: 255.248.220
            lemonchiffon: 255.250.205
            floralwhite: 255.250.240
            snow: 255.250.250
            yellow: 255.255.0
            lightyellow: 255.255.224
            ivory: 255.255.240
            white: 255.255.255
        ]

        hex: context [
            decode: func [
                encoded [issue!]
            ][
                encoded: to string! encoded

                if 3 == length-of encoded [
                    encoded: rejoin [
                        encoded/1 encoded/1 encoded/2 encoded/2 encoded/3 encoded/3
                    ]
                ]

                to tuple! debase encoded 16
            ]

            encode: func [
                color [tuple!]
                /local r g b
            ][
                assert [
                    3 = length-of color
                ]

                either parse color: form to-hex color [
                    set r skip
                    r
                    set g skip
                    g
                    set b skip
                    b
                ][
                    to issue! lowercase rejoin [
                        r g b
                    ]
                ][
                    to issue! lowercase color
                ]
            ]
        ]

        as-color: func [
            color [string! tuple! issue! word!]
        ][
            switch type-of color [
                #(string!) [
                    decode color
                ]

                #(tuple!) [
                    color
                ]

                #(issue!) [
                    hex/decode color
                ]

                #(word!) [
                    any [
                        select named color
                        do make error! join "Unknown color: " uppercase form color
                    ]
                ]
            ]
        ]

        decode: func [
            encoded [string!]
            /local value mark
        ][
            either parse/case trim/head/tail encoded [
                ["transparent" | "none"]
                end
                (value: 'none)
                |
                copy value [some lower-alpha*]
                end
                (
                    value: to word! value

                    if not tuple? select named value [
                        value: _
                    ]
                )
                |
                copy value [
                    "#" [
                        8 hex* | 6 hex* | 3 hex*
                    ]
                ]
                end
                (value: hex/decode load value)
                |
                "rgb("
                copy value [
                    some digit*
                    comma*
                    some digit*
                    comma*
                    some digit*
                ]
                ")"
                end
                (
                    value: attempt [
                        to tuple! lists/decode value
                    ]
                )
                |
                "url("
                any space*
                [
                    #"#"
                    copy value word*
                    (value: to issue! value)
                    |
                    copy value url*
                    (value: to url! value)
                    |
                    fail
                ]
                any space*
                ")"
                end
            ][
                switch type-of value [
                    #(tuple!) [
                        for-each [name color] named [
                            if value == color [
                                value: name
                                break
                            ]
                        ]
                    ]
                ]

                value
            ][
                ; probe encoded
                0.0.0
            ]
        ]

        encode: func [
            value [tuple!]
            /with
            options [map!]
        ][
            any [
                options
                options: #[]
            ]

            switch length-of value [
                3 [
                    either options/hex-colors? [
                        mold hex/encode value
                    ][
                        rejoin [
                            "rgb("
                            value/1 #"," value/2 #"," value/3
                            #")"
                        ]
                    ]
                ]

                4 [
                    rejoin [
                        "rgba("
                        value/1 #"," value/2 #"," value/3 #","
                        numbers/encode/with value/4 / 256 options
                        #")"
                    ]
                ]
            ]
        ]
    ]

    transforms: context [
        ; experimental, unfinished
        ; would be nice to support TRANSFORM attribute *and* a general ability
        ; to arbitrarily transform shapes, e.g. move shape 100x100 or resize shape 150%
        ; https://stackoverflow.com/questions/5149301/baking-transforms-into-svg-path-element-commands
        ;
        bake: func [
            point [pair! block!]
            matrix [block!]
        ][
            point: collect [
                switch type-of point [
                    #(pair!) [
                        keep to decimal! point/x
                        keep to decimal! point/y
                    ]

                    #(block!) [
                        parse point [
                            2 [
                                point: [
                                    integer!
                                    (keep to decimal! point/1)
                                    |
                                    decimal!
                                    (keep point/1)
                                ]
                            ]
                        ]
                    ]
                ]
            ]

            if all [
                parse point [2 decimal!]
                parse matrix [6 number!]
            ][
                reduce [
                    (x * matrix/1) + (y * matrix/3) + matrix/5
                    (x * matrix/2) + (y * matrix/4) + matrix/6
                ]
            ]
        ]

        flatten: func [
            value [block!]
            /local args
        ][
            value: collect-each part value [
                switch/default type-of part [
                    #(word!) #(integer!) #(decimal!) [
                        keep part
                    ]

                    #(pair!) [
                        keep part/x
                        keep part/y
                    ]

                    #(block!) #(paren!) [
                        for-each part part [
                            switch/default type-of part [
                                #(integer!) #(decimal!) [
                                    keep value
                                ]

                                #(pair!) [
                                    keep part/x
                                    keep part/y
                                ]
                            ][
                                keep _
                            ]
                        ]
                    ]
                ][
                    keep _
                ]
            ]

            collect [
                parse value [
                    any [
                        'matrix
                        copy args 6 [integer! | decimal!]
                        (
                            keep 'matrix
                            keep/only args
                        )
                        |
                        'translate
                        copy args 1 2 [integer! | decimal!]
                        (
                            keep 'translate
                            keep/only args
                        )
                        |
                        'scale
                        copy args 1 2 [integer! | decimal!]
                        (
                            keep 'scale
                            keep/only args
                        )
                        |
                        'rotate
                        copy args [
                            [integer! | decimal!]
                            opt [
                                2 [integer! | decimal!]
                            ]
                        ]
                        (
                            keep 'rotate
                            keep/only args
                        )
                        |
                        'skewX
                        copy args [integer! | decimal!]
                        (
                            keep 'skewX
                            keep/only args
                        )
                        |
                        'skewY
                        copy args [integer! | decimal!]
                        (
                            keep 'skewY
                            keep/only args
                        )
                    ]
                ]
                [
                    end
                    |
                    (do make error! "Could not parse TRANSFORM list")
                ]
            ]
        ]

        decode: func [
            encoded [string!]
            /local type part value
        ][
            value: collect [
                parse encoded [
                    opt space*
                    any [
                        copy type [
                            "matrix" | "rotate" | "scale" | "translate" | "skewX" | "skewY"
                        ]
                        opt space*
                        "(" copy part to ")"
                        skip
                        opt comma*
                        ; shouldn't accept trailing commas, but -- oh well..
                        (
                            keep to word! type
                            keep lists/decode part
                        )
                    ]

                    fail-if-not-end
                ]
            ]

            if not empty? value [
                neaten/words value
            ]
        ]

        encode: func [
            value [block!]
            /with
            options [map!]
            /local part
        ][
            value: flatten value

            lists/encode collect [
                parse value [
                    some [
                        copy part [
                            word! [
                                paren! | block!
                            ]
                        ]
                        (
                            keep rejoin [
                                form part/1 "(" lists/encode/:with/comma part/2 options ")"
                            ]
                        )
                    ]
                ]
            ]
        ]
    ]

    font-names: context [
        decode: func [
            encoding [string!]
            /local name
        ][
            collect [
                if not parse encoding [
                    some [
                        [
                            copy name [
                                some name*
                                any [
                                    #" "
                                    some name*
                                ]
                            ]
                            (
                                name: any [
                                    is-value-from name [
                                        "serif" "sans-serif" "cursive" "fantasy" "monospace"
                                    ]

                                    name
                                ]
                            )
                            |
                            #"^""
                            copy name some [
                                some name*
                                |
                                #" " | #"," | #"'"
                            ]
                            #"^""
                            |
                            #"'"
                            copy name some [
                                some name*
                                |
                                #" " | #"," | #"^""
                            ]
                            #"'"
                        ]
                        (keep name)
                        opt space* [
                            #","
                            opt space*
                            |
                            end
                        ]
                    ]
                ][
                    keep 'sans-serif
                ]
            ]
        ]
    ]

    styles: context [
        delimiters: charset ":;"

        decode: func [
            encoded [string!]
        ][
            encoded: split encoded delimiters
            ; quickie parsing for now

            if even? index? tail encoded [
                remove back tail encoded
            ]

            neaten/pairs collect [
                for-each [key value] encoded [
                    keep to word! trim/head/tail key
                    keep trim/head/tail value
                ]
            ]
        ]
    ]

    classes: context [
        decode: func [
            encoded [string!]
        ][
            collect [
                for-each part split trim encoded #" " [
                    if not empty? part [
                        attempt [
                            keep to word! part
                            ; brute force for now
                        ]
                    ]
                ]
            ]
        ]
    ]

    attributes: context [
        decode: func [
            attribute [word! none!]
            value [string!]

            /local name handler style part
        ][
            ; Should support these
            ; https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Presentation
            ;
            switch/default attribute [
                viewbox [
                    if all [
                        value: lists/decode value

                        parse value [
                            4 integer!
                        ]
                    ][
                        value
                    ]
                ]

                id [
                    to issue! replace/all value #" " #"_"
                ]

                class [
                    classes/decode value
                ]

                fill
                stroke
                stop-color
                flood-color [
                    paint/decode value
                ]

                d [
                    paths/decode value
                ]

                points [
                    lists/decode value
                ]

                x x1 x2 y y1 y2 z
                cx cy
                dx dy
                fr fx fy
                r rx ry
                width height
                offset rotate scale begin dur end
                stroke-width stroke-miterlimit [
                    any [
                        is-value-from value [
                            "auto"
                        ]

                        numbers/from-unit value
                    ]
                ]

                fill-rule clip-rule [
                    is-value-from value [
                        "nonzero" "evenodd"
                    ]
                ]

                stroke-dasharray [
                    either "none" = value [
                        'none
                    ][
                        lists/decode value
                    ]
                ]

                stroke-linecap [
                    is-value-from value [
                        "butt" "round" "square"
                    ]
                ]

                stroke-linejoin [
                    is-value-from value [
                        "arcs" "bevel" "miter" "miter-clip" "round"
                    ]
                ]

                font-family [
                    font-names/decode value
                ]

                font-size [
                    any [
                        is-value-from value [
                            "xx-small" "x-small" "small" "medium" "large" "x-large" "xx-large" "xxx-large"
                            "larger" "smaller"
                        ]

                        numbers/from-unit value
                    ]
                ]

                font-style [
                    is-value-from value [
                        "normal" "italic" "oblique"
                    ]
                ]

                font-weight [
                    is-value-from value [
                        "normal" "bold" "lighter" "bolder"
                        "100" "200" "300" "400" "500" "600" "700" "800" "900"
                    ]
                ]

                text-anchor [
                    is-value-from value [
                        "start" "middle" "end"
                    ]
                ]

                transform [
                    transforms/decode value
                ]

                href [
                    case [
                        find/match value #"#" [
                            to issue! next value
                        ]

                        find attribute/value #":" [
                            to url! value
                        ]

                        #else [
                            to file! value
                        ]
                    ]
                ]

                cursor [
                    is-value-from value [
                        "auto" "crosshair" "default" "pointer" "move" "text" "wait" "help"
                        "e-resize" "ne-resize" "nw-resize" "n-resize"
                        "se-resize" "sw-resize" "s-resize" "w-resize"
                    ]
                ]

                display [
                    is-value-from value [
                        "contents" "none"
                    ]
                ]

                visible [
                    is-value-from value [
                        "visible" "hidden" "collapse"
                    ]
                ]

                ; ; messy, but needs to be supported
                ; clip-path
                ; https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/clipPath

                ; ; would set 'currentcolor parameter somewhere
                ; color

                opacity
                stroke-opacity
                fill-opacity [
                    numbers/from-unit value
                ]

                ; ; urls
                ; filter mask

                pointer-events [
                    is-value-from value [
                        "bounding-box" "visible" "painted" "fill" "stroke" "all" "none"
                        "visiblePainted" "visibleFill" "visibleStroke"
                    ]
                ]

                in in2 result [
                    to ref! value
                ]

                k1 k2 k3 k4 [
                    to integer! value
                ]

                mode [
                    is-value-from value [
                        "normal" "darken" "multiply" "color-burn" "lighten" "screen"
                        "color-dodge" "overlay" "soft-light" "hard-light" "difference"
                        "exclusion" "hue" "saturation" "color" "luminosity"
                    ]
                ]

                style [
                    styles/decode value
                ]
            ][
                any [
                    attempt [
                        load value
                    ]

                    value
                ]
            ]
        ]

        encode: func [
            attribute [word! none!]
            value
            /with
            options [map!]
        ][
            options: any [
                options
                #[]
            ]

            switch/default type-of value [
                #(decimal!) [
                    switch/default attribute [
                        x x1 x2
                        y y1 y2
                        cx cy
                        dx dy
                        r rx ry
                        fr fx fy
                        width height [
                            numbers/encode/with value options
                        ]

                        begin end dur [
                            join numbers/encode/with value options "s"
                        ]

                        version [
                            form value
                        ]
                    ][
                        numbers/encode/with value options
                    ]
                ]

                #(integer!) [
                    value: either all [
                        integer? options/precision
                    ][
                        numbers/encode/with value options
                    ][
                        form value
                    ]

                    switch/default attribute [
                        begin end dur [
                            join value #"s"
                        ]
                    ][
                        value
                    ]
                ]

                #(tuple!) [
                    paint/encode/with value options
                ]

                #(issue!) [
                    switch/default attribute [
                        id [
                            to string! value
                        ]

                        href [
                            mold value
                        ]
                    ][
                        either parse form value [
                            8 hex* | 6 hex* | 3 hex*
                        ][
                            paint/encode/with paint/hex/decode value options
                        ][
                            rejoin [
                                "url(#" form value ")"
                            ]
                        ]
                    ]
                ]

                #(url!) [
                    either find/match value "id:#" [
                        encode attribute to tuple! skip value 3 options
                    ][
                        form value
                    ]
                ]

                #(block!) [
                    ; path & transform attributes; others?
                    ;
                    case [
                        'd = attribute [
                            paths/encode/with value options
                        ]

                        ; 'animate = name []
                        ; should handle here but not sure how

                        parse value [
                            some [
                                ['matrix | 'translate | 'scale | 'rotate | 'skewX | 'skewY]
                                [
                                    into [
                                        some [integer! | decimal! | pair!]
                                    ]
                                    |
                                    some [integer! | decimal! | pair!]
                                ]
                            ]
                        ][
                            transforms/encode/with value options
                        ]

                        #else [
                            lists/encode/comma/:with value options
                        ]
                    ]
                ]

                #(percent!) [
                    numbers/encode/with value options
                ]

                #(time!) [
                    join numbers/encode/with to decimal! value options #"s"
                ]

                #(pair!) [
                    reform [
                        numbers/encode/with value/x options
                        numbers/encode/with value/y options
                    ]
                ]
            ][
                ; probe attribute
                form value
            ]
        ]

        from-node: func [
            node [object!]
            /local attributes name
        ][
            attributes: copy #[]

            for-each attribute node/attributes [
                case [
                    attributes/space [
                        name: to word! rejoin [
                            form attribute/space
                            #"|"
                            form attribute/name
                        ]

                        put attributes name decode name attribute/value
                    ]

                    @values = attribute/name [
                        ; special handling for values attribute
                        ; to follow
                    ]

                    #else [
                        name: to word! to string! attribute/name

                        put attributes name decode name attribute/value
                    ]
                ]
            ]

            if block? select attributes 'style [
                ; Style attributes have greater precedence:
                ; https://www.w3.org/TR/2008/REC-CSS2-20080411/cascade.html#q12
                ;
                for-each [name value] attributes/style [
                    put attributes name decode name value
                ]

                remove/key attributes 'style
            ]

            either empty? attributes [
                _
            ][
                attributes
            ]
        ]
    ]

    decoder: context [
        open-tags: _

        kids-from: func [
            node [object!]
            /local kids text
        ][
            if not empty? kids: node/children [
                neaten/triplets collect-all kids [
                    switch/default type-of kids/1/name [
                        #(tag!) [
                            insert open-tags kids/1/name

                            keep switch/default kids/1/name [
                                <g> [
                                    'group
                                ]
                            ][
                                to word! to string! kids/1/name
                            ]

                            keep attributes/from-node kids/1
                            keep/only kids-from kids/1

                            remove open-tags
                        ]

                        #(file!) [
                            keep quote 'text
                            keep _
                            keep either 'text = kids/1/name [
                                text: copy kids/1/value

                                if head? kids [
                                    trim/head text
                                ]

                                if tail? next kids [
                                    trim/tail text
                                ]

                                text
                            ][
                                copy kids/1/value
                            ]
                        ]

                        ; what even is this?
                        ;
                        other [
                            if all [
                                find open-tags 'text
                                not head? kids
                                not tail? next kids
                            ][
                                keep quote 'text
                                keep _
                                keep #" "
                            ]
                        ]
                    ][
                        probe kids/1/name
                        ; should not happen
                    ]
                ]
            ]
        ]

        decode: func [
            encoding [string! binary!]
            /local document kids
        ][
            case/all [
                binary? encoding [
                    encoding: to string! encoding
                ]

                string? encoding [
                    document: load-xml/dom encoding
                ]
            ]

            open-tags: make block! 8

            neaten/triplets compose/only [
                svg
                (attributes/from-node document)
                (kids-from document)
            ]
        ]
    ]

    decode: :decoder/decode

    creator: context [
        presentation-attributes: #[
            fill _
            stroke _
            class _
            filter _
            stop-color _
            rotate _
            scale _
            stroke-width _
            stroke-miterlimit _
            fill-rule _
            clip-rule _
            stroke-dasharray _
            stroke-linecap _
            stroke-linejoin _
            font-size _
            font-family _
            font-style _
            font-weight _
            letter-spacing _
            dominant-baseline _
            text-anchor _
            transform _
            transform-origin _
            cursor _
            display _
            visible _
            opacity _
            stroke-opacity _
            fill-opacity _
            id _
            href _
        ]

        do-attributes: func [
            node [block!]
            attributes [map! none!]
        ][
            case [
                none? attributes _
                empty? attributes _
                empty? attributes: compose/deep intersect attributes presentation-attributes _

                #else [
                    node/2: either map? node/2 [
                        union node/2 attributes
                        ; warning, any entries in node/2 overrides the presentation attributes
                    ][
                        attributes
                    ]
                ]
            ]
        ]

        tilt: func [
            center [pair!]
            angle [number!]
            length [integer! decimal! percent!]
        ][
            if percent? length [
                length: 100 * length
                ; assuming here that other coords here are * 100
            ]

            ; center: center
            length: length / 2 * as-pair cosine angle sine angle

            reduce [
                as-pair center/x - length/x center/y - length/y
                as-pair center/x + length/x center/y + length/y
            ]
        ]

        append-to: func [
            project [map!]
            node [block!]
        ][
            also tail project/here
            append project/here neaten/triplets node
        ]

        append-defs: func [
            project [map!]
            node [block!]
        ][
            also tail project/defs
            append project/defs neaten/triplets node
        ]

        append-node: func [
            parent [block!]
            node [block!]
        ][
            also tail parent/3
            append parent/3 neaten/triplets node
        ]

        make-group: func [
            project [map!]
            attributes [map! none!]
            spec [block!]
            /local here node
        ][
            node: compose/deep [
                group #[] []
            ]

            do-attributes node attributes

            here: project/here
            project/here: node/3
            do spec
            project/here: here
            node
        ]

        make-symbol: func [
            project [map!]
            id [issue!]
            size [pair!]
            spec [block!]
            /at
            offset [pair!]
            /local here node
        ][
            node: compose/deep [
                symbol #[
                    id: (id)
                    x: (if at [offset/x])
                    y: (if at [offset/y])
                    width: (size/x)
                    height: (size/y)
                    viewBox: [
                        (either at [offset/x] [0])
                        (either at [offset/y] [0])
                        (size/x)
                        (size/y)
                    ]
                ] []
            ]

            here: project/here
            project/here: node/3
            do spec
            project/here: here
            node
        ]

        make-anchor: func [
            project [map!]
            target [file! url! issue!]
            attributes [map! none!]
            spec [block!]
            /local here node
        ][
            node: compose/deep [
                a #[] []
            ]

            do-attributes node attributes

            node/2/href: target

            here: project/here
            project/here: node/3
            do spec
            project/here: here
            node
        ]

        make-rectangle: func [
            attributes [map! none!]
            offset [pair! block!]
            size [pair! block!]
            /rounded
            radius [number! pair! block!]
            /local node
        ][
            node: compose/deep [
                rect #[
                    x (offset/1)
                    y (offset/2)
                    width (size/1)
                    height (size/2)
                ] _
            ]

            switch type-of radius [
                #(pair!) #(block!) [
                    append node/2 reduce [
                        'rx radius/1
                        'ry radius/2
                    ]
                ]

                #(integer!) #(decimal!) [
                    append node/2 reduce [
                        'rx radius
                    ]
                ]
            ]

            do-attributes node attributes

            node
        ]

        make-circle: func [
            attributes [map! none!]
            center [pair!]
            radius [number!]
            /local node
        ][
            node: compose/deep [
                circle #[
                    cx (center/x)
                    cy (center/y)
                    r (radius)
                ] _
            ]

            do-attributes node attributes

            node
        ]

        make-ellipse: func [
            attributes [map! none!]
            center [pair!]
            radius [pair!]
            /local node
        ][
            node: compose/deep [
                ellipse #[
                    cx (center/x)
                    cy (center/y)
                    rx (radius/x)
                    ry (radius/y)
                ] _
            ]

            do-attributes node attributes

            node
        ]

        make-image: func [
            attributes [map! none!]
            target [url! file! issue!]
            offset [pair!]
            size [pair!]
            /local node
        ][
            node: compose/deep [
                image #[
                    href (target)
                    x (offset/x)
                    y (offset/y)
                    width (size/x)
                    height (size/y)
                ] _
            ]

            do-attributes node attributes

            node
        ]

        make-line: func [
            attributes [map! none!]
            start [pair! block!]
            end [pair! block!]
            /local node
        ][
            node: compose/deep [
                line #[
                    x1 (start/x)
                    y1 (start/y)
                    x2 (end/x)
                    y2 (end/y)
                ] _
            ]

            do-attributes node attributes

            node
        ]

        make-polyline: func [
            attributes [map! none!]
            points [block!]
            /local node
        ][
            node: compose/deep/only [
                polyline #[
                    points (
                        collect [
                            assert [
                                parse points: reduce points [
                                    some pair!
                                ]
                            ]

                            for-each point reduce points [
                                keep point/x
                                keep point/y
                            ]
                        ]
                    )
                ] _
            ]

            do-attributes node attributes

            node
        ]

        make-polygon: func [
            attributes [map! none!]
            points [block!]
            /local node
        ][
            node: compose/deep/only [
                polygon #[
                    points (
                        collect [
                            assert [
                                parse points: reduce points [
                                    some pair!
                                ]
                            ]

                            for-each point reduce points [
                                keep point/x
                                keep point/y
                            ]
                        ]
                    )
                ] _
            ]

            do-attributes node attributes

            node
        ]

        paths: context [
            path: _

            move: func [
                offset [map!]
                target [pair!]

                /local command
            ][
                offset/x: target/x
                offset/y: target/y

                command: compose/deep [
                    move [
                        (target)
                    ]
                ]

                append path command

                command
            ]

            line: func [
                offset [map!]
                target [pair!]

                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: compose/deep [
                    line [
                        (target)
                    ]
                ]

                append path command

                command
            ]

            hline: func [
                offset [map!]
                target [number!]

                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target

                command: compose/deep [
                    hline [
                        (target)
                    ]
                ]

                append path command

                command
            ]

            vline: func [
                offset [map!]
                target [number!]

                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/y: target

                command: compose/deep [
                    vline [
                        (target)
                    ]
                ]

                append path command

                command
            ]

            arc: func [
                offset [map!]
                radius [pair!]
                angle [number!]
                large-arc? [logic!]
                sweep? [logic!]
                target [pair!]
                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: compose/deep [
                    arc [
                        (radius) (angle) (large-arc?) (sweep?) (target)
                    ]
                ]

                append path command

                command
            ]

            curve: func [
                offset [map!]
                control-1 [pair!]
                control-2 [pair!]
                target [pair!]
                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: reduce [
                    'curve compose [
                        (control-1) (control-2) (target)
                    ]
                ]

                append path command

                command
            ]

            curv: func [
                offset [map!]
                control [pair!]
                target [pair!]
                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: reduce [
                    'curv compose [
                        (control) (target)
                    ]
                ]

                append path command

                command
            ]

            qcurve: func [
                offset [map!]
                control [pair!]
                target [pair!]
                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: reduce [
                    'qcurve compose [
                        (control) (target)
                    ]
                ]

                append path command

                command
            ]

            qcurv: func [
                offset [map!]
                target [pair!]
                /local command
            ][
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x
                offset/y: target/y

                command: compose/deep [
                    qcurv [
                        (target)
                    ]
                ]

                append path command

                command
            ]

            close: func [] [
                if empty? path [
                    do make error! [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                append path reduce [
                    'close make block! 0
                ]

                [close]
            ]
        ]

        make-path: func [
            attributes [map! none!]
            commands [block! string!]

            /local node offset
        ][
            node: compose/deep [
                path #[
                    d []
                ] _
            ]

            do-attributes node attributes

            offset: copy #[
                x: 0
                y: 0
            ]

            either string? commands [
                node/path/d: svg/paths/decode commands
            ][
                paths/path: node/path/d

                do-with commands [
                    large: yes
                    small: no
                    sweep: yes
                    counter: no

                    current-position: func [] [
                        copy offset
                    ]

                    fixed: func [
                        target [pair!]
                    ][
                        target
                    ]

                    by: func [
                        target [pair!]
                    ][
                        target/x: target/x + offset/x
                        target/y: target/y + offset/y

                        target
                    ]

                    left-by: func [
                        target [integer! decimal!]
                    ][
                        target: target + offset/x
                    ]

                    down-by: func [
                        target [integer! decimal!]
                    ][
                        target: target + offset/y
                    ]

                    move: func [
                        target [pair!]
                    ][
                        paths/move offset target
                    ]

                    line: func [
                        target [pair!]
                    ][
                        paths/line offset target
                    ]

                    hline: func [
                        target [number!]
                    ][
                        paths/hline offset target
                    ]

                    vline: func [
                        target [number!]
                    ][
                        paths/vline offset target
                    ]

                    arc: func [
                        radius [pair!]
                        angle [number!]
                        large-arc? [logic!]
                        sweep? [logic!]
                        target [pair!]
                    ][
                        paths/arc offset radius angle large-arc? sweep? target
                    ]

                    curve: func [
                        control-1 [pair!]
                        control-2 [pair!]
                        target [pair!]
                    ][
                        paths/curve offset control-1 control-2 target
                    ]

                    curv: func [
                        control [pair!]
                        target [pair!]
                    ][
                        paths/curv offset control target
                    ]

                    qcurve: func [
                        control [pair!]
                        target [pair!]
                    ][
                        paths/qcurve offset control target
                    ]

                    qcurv: func [
                        target [pair!]
                    ][
                        paths/qcurv offset target
                    ]

                    close: func [] [
                        paths/close
                    ]
                ]

                neaten/pairs paths/path
                paths/path: _
            ]

            node
        ]

        make-span: func [
            attributes [map! none!]
            spec [block!]

            /local node
        ][
            node: compose/deep [
                tspan #[] []
            ]

            do-with spec [
                span: _

                at: func [
                    value [integer! decimal! pair!]
                ][
                    either pair? value [
                        node/2/x: value/x
                        node/2/y: value/y

                        value
                    ][
                        node/2/x: value
                    ]
                ]

                across: func [
                    value [integer! decimal!]
                ][
                    node/2/dx: value
                ]

                down: func [
                    value [integer! decimal!]
                ][
                    node/2/dy: value
                ]

                left: func [] [
                    node/2/text-anchor: 'start
                ]

                center: func [] [
                    node/2/text-anchor: 'middle
                ]

                right: func [] [
                    node/2/text-anchor: 'end
                ]

                baseline-at: func [
                    value [integer! decimal!]
                ][
                    node/2/text-anchor: 'start
                    node/2/x: value
                ]

                emit: func [
                    text [any-string! char! pair! number!]
                ][
                    append-node node compose [
                        'text _ (form text)
                    ]
                ]
            ]

            do-attributes node attributes

            node
        ]

        make-text: func [
            attributes [map! none!]
            spec [block!]

            /local node
        ][
            node: compose/deep [
                text #[] []
            ]

            do-with spec [
                at: func [
                    value [integer! decimal! pair!]
                ][
                    either pair? value [
                        node/2/x: value/x
                        node/2/y: value/y

                        value
                    ][
                        node/2/x: value
                    ]
                ]

                across: func [
                    value [integer! decimal!]
                ][
                    node/2/dx: value
                ]

                down: func [
                    value [integer! decimal!]
                ][
                    node/2/dy: value
                ]

                left: func [] [
                    node/2/text-anchor: 'start
                ]

                center: func [] [
                    node/2/text-anchor: 'middle
                ]

                right: func [] [
                    node/2/text-anchor: 'end
                ]

                baseline-at: func [
                    value [integer! decimal!]
                ][
                    node/2/text-anchor: 'start
                    node/2/x: value
                ]

                span: func [
                    attributes [map! none!]
                    spec [block!]
                ][
                    append-node node make-span attributes spec
                ]

                emit: func [
                    text [any-string! char! pair! number!]
                ][
                    append-node node compose [
                        'text _ (form text)
                    ]
                ]
            ]

            do-attributes node attributes

            node
        ]

        make-use: func [
            id [issue!]
            offset [pair! none!]
            attributes [map! none!]

            /resize
            size [pair!]

            /local node
        ][
            node: compose/deep [
                use #[
                    x: (if offset [offset/x])
                    y: (if offset [offset/y])
                    width: (if resize [size/x])
                    height: (if resize [size/y])
                ] _
            ]

            do-attributes node attributes

            node/2/href: id

            node
        ]

        prep-for-placement: func [
            attributes [map! none!]
            target [block!]

            /local node
        ][
            assert [
                find [svg group] target/1
            ]

            node: compose/deep [
                group #[] _
            ]

            if map? target/2 [
                do-attributes node target/2
            ]

            do-attributes node attributes

            node/3: copy/deep target/3

            node
        ]

        make-stylesheet: func [
            target [file! url! string! block!]
            /embed
        ][
            target: compose [
                (target)
            ]

            compose/deep [
                style #[type "text/css"] [
                    'text _ (
                        rejoin collect-each part target [
                            keep newline

                            switch type-of part [
                                #(string!) [
                                    keep trim/auto trim/tail copy part
                                ]

                                #(file!)
                                #(url!) [
                                    keep either embed [
                                        read/string part
                                    ][
                                        rejoin [
                                            {@import url('} part {');}
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    )
                ]
            ]
        ]

        make-linear-gradient: func [
            id [issue!]
            spec [block!]

            /local node type absolute? center angle length
        ][
            type: _
            absolute?: _

            node: compose/deep [
                linearGradient #[
                    id (to string! id)
                ] []
            ]

            do-with spec [
                start: func [
                    point [pair!]
                ][
                    either type = 'tilt [
                        do make error! "START not valid for TILTED linear gradient"
                    ][
                        type: 'boxed
                    ]

                    if not zero? point/x [
                        put node/2 'x1 point/x
                    ]

                    if not zero? point/y [
                        put node/2 'y1 point/y
                    ]

                    point
                ]

                end: func [
                    point [pair!]
                ][
                    either type = 'tilt [
                        do make error! "END not valid for TILTED linear gradient"
                    ][
                        type: 'boxed
                    ]

                    put node/2 'x2 point/x

                    if not zero? point/y [
                        put node/2 'y2 point/y
                    ]

                    point
                ]

                relative: func [] [
                    absolute?: no
                ]

                ; LINEAR-GRADIENT by center, angle, length
                ;
                tilt: func [] [
                    either none? type [
                        type: 'tilt
                    ][
                        do make error! "TILT not valid for BOXED linear gradient"
                    ]

                    angle: 90
                    length: 100

                    yes
                ]

                center: func [
                    value [pair!]
                ][
                    if 'tilt <> type [
                        do make error! "CENTER not valid for BOXED linear gradient"
                    ]

                    center: value
                ]

                angle: func [
                    value [integer!]
                ][
                    if 'tilt <> type [
                        do make error! "ANGLE not valid for BOXED linear gradient"
                    ]

                    angle: value
                ]

                length: func [
                    value [number!]
                ][
                    if 'tilt <> type [
                        do make error! "LENGTH not valid for BOXED linear gradient"
                    ]

                    length: value
                ]

                user-space-on-use: func [] [
                    if none? absolute? [
                        absolute?: yes
                    ]

                    put node/2 'gradientUnits 'userSpaceOnUse
                ]

                ; object-bounding-box: func [] [
                ;     put node/2 'gradientUnits 'objectBoundingBox
                ; ]

                ; gradientTransform:
                ; This attribute provides additional transformation to the gradient coordinate
                ; system. Value type: <transform-list>; Default value: identity transform;
                ; Animatable: yes

                pad: func [] [
                    put node/2 'spreadMethod 'pad
                ]

                reflect: func [] [
                    put node/2 'spreadMethod 'reflect
                ]

                repeat: func [] [
                    put node/2 'spreadMethod 'repeat
                ]

                stop: func [
                    offset [number! none!]
                    opacity [number! none!]
                    color [tuple! word! issue! none!]
                ][
                    append-node node make-stop offset opacity color
                ]

                colors: func [
                    colors [block!]
                ][
                    append-node node make-stops colors
                ]
            ]

            if 'tilt = type [
                center: case [
                    center :center

                    absolute? [
                        as-pair container/2/width / 2 0
                    ]

                    #else 50x50
                ]

                length: tilt center angle length

                put node/2 'x1 length/1/x
                put node/2 'y1 length/1/y
                put node/2 'x2 length/2/x
                put node/2 'y2 length/2/y
            ]

            if not absolute? [
                for-each attribute [x1 y1 x2 y2] [
                    if find node/2 attribute [
                        put node/2 attribute to percent! node/2/:attribute / 100
                    ]
                ]
            ]

            node
        ]

        make-radial-gradient: func [
            id [issue!]
            stops [block!]

            /local node absolute?
        ][
            absolute?: _

            node: compose/deep [
                radialGradient #[
                    id (to string! id)
                ] []
            ]

            do-with stops [
                center: func [
                    point [pair!]
                ][
                    put node/2 'cx point/x
                    put node/2 'cy point/y

                    point
                ]

                radius: func [
                    length [number!]
                ][
                    if length <> .5 [
                        put node/2 'r length
                    ]

                    length
                ]

                focal-point: func [
                    point [pair!]
                    length [number!]
                ][
                    if not percent? length [
                        length: to percent! length / 100
                    ]

                    if 50 <> point/x [
                        put node/2 'fx to percent! point/x / 100
                    ]

                    if 50 <> point/y [
                        put node/2 'fy to percent! point/y / 100
                    ]

                    if not zero? length [
                        put node/2 'fr length
                    ]

                    node
                ]

                relative: func [] [
                    absolute?: no
                ]

                user-space-on-use: func [] [
                    if none? absolute? [
                        absolute?: yes
                    ]

                    put node/2 'gradientUnits 'userSpaceOnUse
                ]

                ; object-bounding-box: func [] [
                ;     put node/2 'gradientUnits 'objectBoundingBox
                ; ]

                ; gradientTransform:  ; This attribute provides additional transformation to the gradient coordinate system. Value type: <transform-list>; Default value: identity transform; Animatable: yes

                pad: func [] [
                    put node/2 'spreadMethod 'pad
                ]

                reflect: func [] [
                    put node/2 'spreadMethod 'reflect
                ]

                repeat: func [] [
                    put node/2 'spreadMethod 'repeat
                ]

                stop: func [
                    offset [number! none!]
                    opacity [number! none!]
                    color [tuple! word! issue! none!]
                ][
                    append-node node make-stop offset opacity color
                ]

                colors: func [
                    colors [block!]
                ][
                    append-node node make-stops colors
                ]
            ]

            if not absolute? [
                for-each [
                    attribute default
                ][
                    cx 50%
                    cy 50%
                    r 50%
                    fx 50%
                    fy 50%
                    fr 0%
                ][
                    if find node/2 attribute [
                        if not percent? node/2/:attribute [
                            put node/2 attribute to percent! node/2/:attribute / 100
                        ]

                        if default = node/2/:attribute [
                            remove/key node/2 attribute
                        ]
                    ]
                ]
            ]

            node
        ]

        make-stop: func [
            offset [number! none!]
            opacity [number! none!]
            color [tuple! word! issue! none!]
        ][
            compose/deep [
                stop #[
                    offset: (offset)

                    stop-opacity: (
                        if opacity [
                            to decimal! opacity
                        ]
                    )

                    stop-color: (color)
                ] _
            ]
        ]

        make-stops: func [
            colors [block!]

            /local offset end interval
        ][
            assert [
                not tail? next colors
            ]

            offset: 0%
            end: 100%

            interval: to percent! divide end - offset -1 + length-of colors

            collect-each color colors [
                keep compose/deep [
                    stop #[
                        offset (round/to offset 0.01%)
                        stop-color (color)
                    ] _
                ]

                offset: offset + interval
            ]
        ]

        make-filter: func [
            id [issue!]
            margin [pair! none!]
            filters [block!]

            /local node absolute?
        ][
            absolute?: _

            node: compose/deep [
                filter #[
                    id: (to string! id)
                    x: (if margin [to percent! 0 - margin/x / 100])
                    y: (if margin [to percent! 0 - margin/y / 100])
                    width: (if margin [to percent! margin/x / 50 + 100%])
                    height: (if margin [to percent! margin/y / 50 + 100%])
                ] []
            ]

            do-with filters [
                source: @SourceGraphic
                alpha: @SourceAlpha

                with: func [
                    name [ref!]
                    node [block!]
                ][
                    assert [
                        parse node [
                            word! map! [block! | none!]
                        ]
                    ]

                    node/2/in: name

                    node
                ]

                set: func [
                    name [ref!]
                    node [block!]
                ][
                    assert [
                        parse node [
                            word! map! [block! | none!]
                        ]
                    ]

                    node/2/result: name

                    node
                ]

                place: func [
                    filter [block!]
                ][
                    assert [
                        parse filter [
                            some [word! [none! | map!] [none! | block!]]
                        ]
                    ]

                    append-node node filter
                ]

                offset: func [
                    value [pair!]
                ][
                    append-node node compose/deep [
                        feOffset #[
                            in: _
                            result: _
                            dx: (value/x)
                            dy: (value/y)
                        ] _
                    ]
                ]

                flood: func [
                    color [word! tuple! issue!]
                    /opacity
                    value [integer! percent! decimal!]
                ][
                    append-node node compose/deep [
                        feFlood #[
                            in: _
                            result: _
                            flood-color: (color)
                            flood-opacity: (value)
                        ] _
                    ]
                ]

                turbulence: func [
                    frequency [decimal!]
                    octaves [integer!]
                    /noise
                ][
                    append-node node compose/deep [
                        feTurbulence #[
                            in: _
                            result: _
                            type: (either noise ["fractalNoise"] ["turbulence"])
                            baseFrequency: (frequency)
                            numOctaves: (octaves)
                        ] _
                    ]
                ]

                displacement-map: func [
                    input [ref!]
                    scale [number!]
                    x-channel [char! none!]
                    y-channel [char! none!]
                ][
                    append-node node compose/deep [
                        feDisplacementMap #[
                            in: _
                            in2: (input)
                            result: _
                            scale: (scale)
                            xChannelSelector: (x-channel)
                            yChannelSelector: (y-channel)
                        ] _
                    ]
                ]

                blur: func [
                    value [integer! decimal!]
                ][
                    append-node node compose/deep [
                        feGaussianBlur #[
                            in: _
                            result: _
                            stdDeviation: (value)
                        ] _
                    ]
                ]

                drop-shadow: func [
                    value [integer! decimal!]
                    offset [pair!]
                    color [word! issue! tuple! none!]
                    opacity [integer! decimal! percent! none!]
                ][
                    append-node node compose/deep [
                        feDropShadow #[
                            in: _
                            result: _
                            stdDeviation: (value)
                            dx: (offset/x)
                            dy: (offset/y)
                            flood-color: (color)
                            flood-opacity: (opacity)
                        ] _
                    ]
                ]

                blend: func [
                    input [ref!]
                    mode [word!]
                ][
                    assert [
                        find [
                            normal darken multiply color-burn lighten screen
                            color-dodge overlay soft-light hard-light difference
                            exclusion hue saturation color luminosity
                        ] mode
                    ]

                    append-node node compose/deep [
                        feBlendMode #[
                            in: _
                            in2: (input)
                            result: _
                            mode: (mode)
                        ] _
                    ]
                ]

                composite: func [
                    input [ref!]
                    operator [word!]
                    /with options [map!]
                ][
                    assert [
                        find [
                            over in out atop xor lighter arithmetic
                        ] operator
                    ]

                    append-node node compose/deep [
                        feComposite #[
                            in: _
                            in2: (input)
                            result: _
                            operator: (operator)
                        ] _
                    ]
                ]

                merge: func [
                    input [block!]
                ][
                    input: reduce input

                    assert [
                        parse input [
                            some ref!
                        ]
                    ]

                    append-node node compose/deep [
                        feMerge #[
                            result: _
                        ][
                            (
                                collect-each ref input [
                                    keep compose/deep [
                                        feMergeNode #[
                                            in: (ref)
                                        ] _
                                    ]
                                ]
                            )
                        ]
                    ]
                ]
            ]

            node
        ]

        animate-attribute: func [
            target [block!]
            attribute [word!]
            duration [time! integer! decimal!]
            values [block!]
        ][
            if not find target/2 attribute [
                ; put target/2 attribute ""
                put target/2 attribute first values
            ]

            compose/deep [
                animate #[
                    attributeName (attribute)
                    values (values)
                    dur (duration)
                    repeatCount "indefinite"
                ] _
            ]
        ]

        animate-transform: func [
            target [block!]
            type [word!]
            duration [time! integer! decimal!]
            values [block!]
        ][
            compose/deep [
                animateTransform #[
                    attributeName: transform
                    type: (type)
                    values: (values)
                    dur: (duration)
                    repeatCount: "indefinite"
                    additive: "sum"
                ] _
            ]
        ]

        animate-keyframes-for: func [
            target [block!]
            attribute [word!]
            duration [time! integer! decimal!]
            spec [block!]
            /local node transform? calc-mode count
        ][
            transform?: did find [rotate scale skewX skewY translate] attribute

            node: compose/deep [
                (pick [animateTransform animate] transform?) #[
                    attributeName: (either transform? ['transform] [attribute])
                    type: (if transform? [attribute])
                    begin: _
                    dur: (duration)
                    end: _
                    repeatCount: indefinite
                    values: []
                    keyTimes: []
                ] _
            ]

            do-with spec [
                splines: func [
                    spec [block!]
                ][
                    if not none? :calc-mode [
                        do make error! "Calc Mode already set"
                    ]

                    calc-mode: 'spline

                    node/2/calcMode: calc-mode
                    node/2/keySplines: spec
                ]

                begin: func [
                    mark [number! time!]
                ][
                    node/2/begin: mark
                ]

                at: func [
                    time [number!]
                    value
                ][
                    if percent? time [
                        time: to decimal! time
                    ]

                    append node/2/keyTimes time
                    append/only node/2/values value

                    time
                ]
            ]

            if 'spline = calc-mode [
                node/2/keySplines: collect [
                    loop -1 + length-of node/2/values [
                        keep/only node/2/keySplines
                    ]
                ]
            ]

            node
        ]

        animate: func [
            node [block!]
            spec [block!]
            /local child additive
        ][
            if not block? node/3 [
                node/3: make block! 0
            ]

            additive: 'replace

            do-with spec [
                values: func [
                    attribute [word!]
                    duration [time! integer! decimal!]
                    values [block!]
                ][
                    either find [translate rotate] attribute [
                        append-node node animate-transform node attribute duration values
                    ][
                        append-node node animate-attribute node attribute duration values
                    ]
                ]

                keyframes-for: func [
                    attribute [word!]
                    duration [time! integer! decimal!]
                    spec [block!]
                ][
                    child: append-node node animate-keyframes-for node attribute duration spec

                    if 'animateTransform = child/1 [
                        child/2/additive: additive
                        additive: 'sum
                        ; initial 'replace resets the child node's transform list,
                        ; accumulate thereafter
                    ]

                    child
                ]
            ]

            node
        ]

        new: func [
            size [pair!]
            body [block!]
            /with
            attributes [map!]
            /mm
            /pt

            /local project width height
        ][
            project: copy #[
                document: _
                cursor: _
                states: _
            ]

            case [
                pt [
                    width: join to integer! size/x "pt"
                    height: join to integer! size/y "pt"
                ]

                mm [
                    width: join to integer! size/x "mm"
                    height: join to integer! size/y "mm"
                ]

                #else [
                    width: to integer! size/x
                    height: to integer! size/y
                ]
            ]

            project/document: compose/deep [
                svg #[
                    xmlns: http://www.w3.org/2000/svg
                    version: 1.1
                    width: (width)
                    height: (height)
                    viewBox: [
                        0 0 (to integer! size/x) (to integer! size/y)
                    ]
                ][
                    defs _ []
                ]
            ]

            project/defs: project/document/3/3
            project/here: tail project/document/3

            do-attributes project/document attributes

            project
        ]

        create: func [
            size [pair!]
            body [block!]
            /with
            attributes [map!]
            /mm
            /pt
            /local project
        ][
            project: new/:with/:mm/:pt size body attributes

            do-with body [
                size: as-pair size/x size/y

                document: copy project/document

                comment: func [
                    text [string!]
                ][
                    append-to project compose/deep [
                        'comment _ (text)
                    ]
                ]

                stash: func [
                    id [issue!]
                    spec [block!]
                ][
                    append-defs project make-group project #[id: (id)] spec
                ]

                symbol: func [
                    id [issue!]
                    size [pair!]
                    spec [block!]
                    /at
                    offset [pair!]
                ][
                    append-defs project make-symbol/:at project id size spec offset
                ]

                group: func [
                    attributes [map! none!]
                    spec [block!]
                ][
                    append-to project make-group project attributes spec
                ]

                anchor: func [
                    target [file! url! issue!]
                    attributes [map! none!]
                    spec [block!]
                ][
                    append-to project make-anchor project target attributes spec
                ]

                line: func [
                    attributes [map! none!]
                    from [pair!]
                    to [pair!]
                ][
                    append-to project make-path attributes [
                        move from
                        line to - from
                    ]
                ]

                path: func [
                    attributes [map! none!]
                    commands [block! string!]
                ][
                    append-to project make-path attributes commands 
                ]

                rectangle: func [
                    attributes [map! none!]
                    offset [pair!]
                    size [pair!]
                    /rounded
                    radius [number! pair! block!]
                ][
                    append-to project make-rectangle/:rounded attributes offset size radius
                ]

                circle: func [
                    attributes [map! none!]
                    center [pair!]
                    radius [number!]
                ][
                    append-to project make-circle attributes center radius
                ]

                ellipse: func [
                    attributes [map! none!]
                    center [pair!]
                    radius [pair!]
                ][
                    append-to project make-ellipse attributes center radius
                ]

                polygon: func [
                    attributes [map! none!]
                    points [block!]
                ][
                    append-to project make-polygon attributes points
                ]

                text: func [
                    attributes [map! none!]
                    spec [block!]
                ][
                    append-to project make-text attributes spec
                ]

                use: func [
                    id [issue!]
                    offset [pair! none!]
                    attributes [map! none!]
                    /resize
                    size [pair!]
                ][
                    append-to project make-use/:resize id offset attributes size
                ]

                place: func [
                    node [block!]
                    attributes [map! none!]
                ][
                    append-to project prep-for-placement attributes node
                ]

                linear-gradient: func [
                    id [issue!]
                    spec [block!]
                ][
                    append-defs project make-linear-gradient id spec
                ]

                radial-gradient: func [
                    id [issue!]
                    spec [block!]
                ][
                    append-defs project make-radial-gradient id spec
                ]

                filter: func [
                    id [issue!]
                    margin [pair! none!]
                    spec [block!]
                ][
                    append-defs project make-filter id margin spec
                ]

                animate: func [
                    node [block!]
                    spec [block!]
                ][
                    animate node spec
                ]

                stylesheet: func [
                    target [string! file! url! block!]
                    /embed
                ][
                    append-defs project make-stylesheet/:embed target
                ]
            ]

            neaten/triplets project/document/3

            if empty? project/document/3/3 [
                remove/part project/document/3 3
                ; remove DEFS if empty
            ]

            project/document
        ]
    ]

    create: :creator/create

    wrap-shape: func [
        size [pair!]
        shape [string! tag!]
        /window
        top-left [pair!]
        bottom-right [pair!]
    ][
        top-left: any [
            top-left
            0x0
        ]

        bottom-right: any [
            bottom-right
            size
        ]

        trim/auto rejoin [
            {
            <svg xmlns="http://www.w3.org/2000/svg" version="1.1" }
            {width="} size/x {" }
            {height="} size/y {" }
            {viewBox="} reform [top-left/x top-left/y bottom-right/x bottom-right/y] {" }
            {xmlns:xlink="http://www.w3.org/1999/xlink">
                } shape {
            </svg>
            }
        ]
    ]

    encoder: context [
        render-node: func [
            name [word! lit-word!]
            attrs [map! none!]
            kids [block! string! none!]
            encoding [map!]

            /local out rule attribute part mark
        ][
            assert [
                find/match keys-of encoding [
                    value parents precision pretty? hex-colors?
                ]
            ]

            mark: encoding/value

            either find/case ['text 'comment] :name [
                if not string? kids [
                    do make error! rejoin [
                        "Error in SVG Object: "
                        mold reduce [
                            name _ kids
                        ]
                    ]
                ]

                switch name [
                    'text [
                        append encoding/value sanitize kids
                    ]

                    'comment [
                        append encoding/value rejoin [
                            "^/<!--"
                            either find spacers* first kids [""] [#" "]
                            kids
                            either find spacers* last kids [""] [#" "]
                            "-->"
                        ]
                    ]
                ]
            ][
                name: switch/default name [
                    group ['g]
                ][
                    name
                ]

                if not any [
                    empty? encoding/parents
                    find encoding/parents 'text
                ][
                    append encoding/value newline

                    if encoding/pretty? [
                        insert/dup tail encoding/value "  " length-of encoding/parents
                    ]
                ]

                append encoding/value build-tag collect [
                    keep name

                    if map? attrs [
                        for-each [attribute value] attrs [
                            if not none? value [
                                keep attribute

                                keep either all [
                                    find [animate animateTransform] name
                                    find [values keySplines keyTimes] attribute
                                    ; special case :(
                                ][
                                    case [
                                        not block? value [
                                            do make error! "Expected ANIMATION values block"
                                        ]

                                        not word? attrs/attributeName [
                                            do make error! "Expected ANIMATION attribute name"
                                        ]

                                        #else [
                                            combine/with map-each part value [
                                                attributes/encode/with attrs/attributeName part encoding
                                            ] #";"
                                        ]
                                    ]
                                ][
                                    attributes/encode/with attribute value encoding
                                ]
                            ]
                        ]
                    ]

                    if not all [
                        block? kids
                        not empty? kids
                    ][
                        keep [/]
                    ]
                ]

                if all [
                    block? kids
                    not empty? kids
                ][
                    insert encoding/parents name

                    for-each [name attributes kids] kids [
                        render-node :name attributes kids encoding
                    ]

                    if not find encoding/parents 'text [
                        append encoding/value newline

                        if encoding/pretty? [
                            insert/dup tail encoding/value "  " -1 + length-of encoding/parents
                        ]
                    ]

                    remove encoding/parents

                    append encoding/value rejoin [
                        "</" replace form name #"|" #":" #">"
                    ]
                ]
            ]

            mark
        ]

        encode: func [
            "Render SVG Document to SVG"

            document [block!]
            "SVG Document"

            /precise
            "Constrain numbers to a specified precision"

            precision [number!]
            "Precision value (see ROUND function's SCALE parameter)"

            /pretty
            "Use indents on the resultant XML output"

            /full-colors
            "Don't use hex notation for colors"

            /local encoding
        ][
            encoding: compose #[
                value: (make string! 1024)

                parents: (copy [])

                precision: (
                    any [
                        precision
                        default-precision
                    ]
                )

                pretty?: (did pretty)

                hex-colors?: (not full-colors)
            ]

            either parse document [
                'svg map! [block! | none!]
            ][
                render-node 'svg document/2 document/3 encoding
            ][
                do make error! "Invalid SVG document"
            ]

            encoding/value
        ]
    ]

    encode: :encoder/encode
]

load-svg: get in svg 'decode
to-svg: get in svg 'encode
