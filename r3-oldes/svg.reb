Rebol [
    Title: "SVG Tools"
    Author: "Christopher Ross-Gill"
    Date: 15-Feb-2026
    Version: 0.4.2
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

svg: make object! [
    ; quickie number parsing
    ; number*: charset "-.0123456789eE"

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
            /precision
            scale
        ][
            if precision [
                value: round/to value scale
                ;@@ should this take PERCENT! into account?
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

        default-precision: 0.001

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

            foreach param switch command [
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
            /precise
            precision [number!]

            /local
            out prep emit command params value type last offset origin
        ][
            precision: any [
                precision self/default-precision
            ]

            offset:
            origin: 0x0
            last: _

            out: make string! 16 * length-of path
            ; approx. pre-allocation

            prep: func [
                value [integer! decimal!]
            ][
                value: numbers/encode/precision value precision

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
                    foreach value reduce values [
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

            foreach [command params] path [
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

    lists: make object! [
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
            /with-comma
        ][
            with-comma: either with-comma [#","] [#" "]

            rejoin back change collect [
                forall list [
                    keep with-comma

                    keep case [
                        number? list/1 [
                            numbers/encode list/1
                        ]

                        issue? list/1 [
                            sanitize mold list/1
                        ]

                        none? list/1 [
                            do make error! rejoin [
                                "Should not be NONE! here: " mold list
                            ]
                        ]

                        pair? list/1 [
                            reduce [
                                numbers/encode list/1/x
                                with-comma
                                numbers/encode list/1/y
                            ]
                        ]

                        #else [
                            sanitize form list/1
                        ]
                    ]
                ]
            ] ""
        ]
    ]

    paint: make object! [
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

        from-hex: func [
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
                (value: from-hex load value)
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
                ; |  ; handle-URL
                ; "url(" ")"
            ][
                if tuple? value [
                    foreach name words-of named [
                        if named/:name == value [
                            value: name
                            break
                        ]
                    ]
                ]

                value
            ][
                ; probe encoded
                0.0.0
            ]
        ]

        ; are these significantly different?
        ;
        decode-from-style: func [
            encoded [string!]
            /local value
        ][
            either parse/case encoded [
                ["transparent" | "none"]
                end
                (value: 'none)
                |
                copy value [
                    some lower-alpha*
                ]
                end
                (
                    value: to word! value
                    tuple? select named value
                )
                |
                copy value [
                    "#" [
                        8 hex* | 6 hex* | 3 hex*
                    ]
                ]
                end
                (value: from-hex load value)
                |
                "rgb(" copy part to ")" skip
                (value: to tuple! lists/decode part)
            ][
                value
            ][
                ; probe encoded
                black
            ]
        ]

        encode: func [
            value [tuple!]
        ][
            case [
                3 = length-of value [
                    rejoin [
                        "rgb(" value/1 #"," value/2 #"," value/3 #")"
                    ]
                ]

                4 = length-of value [
                    rejoin [
                        "rgba(" value/1 #"," value/2 #"," value/3 #"," numbers/encode value/4 / 256 #")"
                    ]
                ]
            ]
        ]
    ]

    transforms: make object! [
        ; experimental, unfinished
        ; would be nice to support TRANSFORM attribute *and* a general ability
        ; to arbitrarily transform shapes, e.g. move shape 100x100 or resize shape 150%
        ; https://stackoverflow.com/questions/5149301/baking-transforms-into-svg-path-element-commands
        ;
        apply: func [
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
                        opt comma*  ; shouldn't accept trailing commas, but -- oh well..
                        (
                            keep to word! type
                            keep/only to paren! lists/decode part
                        )
                    ]

                    fail-if-not-end
                ]
            ]

            if not empty? value [
                neaten/pairs value
            ]
        ]

        encode: func [
            value [block!]
            /local part
        ][
            lists/encode/with-comma collect [
                parse value [
                    some [
                        copy part [
                            word! [
                                paren! | block!
                            ]
                        ]
                        (
                            keep rejoin [
                                form part/1 "(" lists/encode/with-comma part/2 ")"
                            ]
                        )
                    ]
                ]
            ]
        ]
    ]

    font-names: make object! [
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
                                    " "
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
                                " " | "," | "'"
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

    styles: make object! [
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
                foreach [key value] encoded [
                    keep to word! trim/head/tail key
                    keep trim/head/tail value
                ]
            ]
        ]
    ]

    classes: make object! [
        decode: func [
            encoded [string!]
        ][
            collect [
                foreach part split trim encoded #" " [
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

    decoder: context [
        handle-attributes: func [
            node [object!]

            /local attributes attribute name handler value style part
        ][
            attributes: collect [
                ; Should support these
                ; https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Presentation
                ;
                foreach attribute node/attributes [
                    name: keep either attribute/space [
                        to word! rejoin [
                            form attribute/space
                            #"|"
                            form attribute/name
                        ]
                    ][
                        to word! to string! attribute/name
                    ]

                    keep/only switch/default name [
                        viewbox [
                            if all [
                                value: lists/decode attribute/value

                                parse value [
                                    4 integer!
                                ]
                            ][
                                value
                            ]
                        ]

                        id [
                            to issue! replace/all attribute/value #" " #"_"
                        ]

                        class [
                            classes/decode attribute/value
                        ]

                        fill stroke stop-color [
                            paint/decode attribute/value
                        ]

                        d [
                            paths/decode attribute/value
                        ]

                        points [
                            lists/decode attribute/value
                        ]

                        cx cy dx dy fr fx fy r rx ry x x1 x2 y y1 y2 z
                        width height offset rotate scale
                        stroke-width stroke-miterlimit [
                            any [
                                is-value-from attribute/value [
                                    "auto"
                                ]

                                numbers/from-unit attribute/value
                            ]
                        ]

                        fill-rule clip-rule [
                            is-value-from attribute/value [
                                "nonzero" "evenodd"
                            ]
                        ]

                        stroke-dasharray [
                            either attribute/value = "none" [
                                _
                            ][
                                lists/decode attribute/value
                            ]
                        ]

                        stroke-linecap [
                            is-value-from attribute/value [
                                "butt" "round" "square"
                            ]
                        ]

                        stroke-linejoin [
                            is-value-from attribute/value [
                                "arcs" "bevel" "miter" "miter-clip" "round"
                            ]
                        ]

                        font-size [
                            any [
                                is-value-from attribute/value [
                                    "xx-small" "x-small" "small" "medium" "large" "x-large" "xx-large" "xxx-large"
                                    "larger" "smaller"
                                ]

                                numbers/from-unit attribute/value
                            ]
                        ]

                        font-family [
                            font-names/decode attribute/value
                        ]

                        font-style [
                            is-value-from attribute/value [
                                "normal" "italic" "oblique"
                            ]
                        ]

                        font-weight [
                            is-value-from attribute/value [
                                "normal" "bold" "lighter" "bolder"
                                "100" "200" "300" "400" "500" "600" "700" "800" "900"
                            ]
                        ]

                        text-anchor [
                            is-value-from attribute/value [
                                "start" "middle" "end"
                            ]
                        ]

                        transform [
                            transforms/decode attribute/value
                        ]

                        href [
                            case [
                                find/match attribute/value #"#" [
                                    to issue! next attribute/value
                                ]

                                find attribute/value #":" [
                                    to url! attribute/value
                                ]

                                <else> [
                                    to file! attribute/value
                                ]
                            ]
                        ]

                        cursor [
                            is-value-from attribute/value [
                                "auto" "crosshair" "default" "pointer" "move" "text" "wait" "help"
                                "e-resize" "ne-resize" "nw-resize" "n-resize"
                                "se-resize" "sw-resize" "s-resize" "w-resize"
                            ]
                        ]

                        display [
                            is-value-from attribute/value [
                                "contents" "none"
                            ]
                        ]

                        visible [
                            is-value-from attribute/value [
                                "visible" "hidden" "collapse"
                            ]
                        ]

                        ; ; messy, but needs to be supported
                        ; clip-path

                        ; ; would set 'currentcolor parameter somewhere
                        ; color

                        opacity stroke-opacity fill-opacity [
                            numbers/from-unit attribute/value
                        ]

                        ; ; urls
                        ; filter mask

                        pointer-events [
                            is-value-from attribute/value [
                                "bounding-box" "visible" "painted" "fill" "stroke" "all" "none"
                                "visiblePainted" "visibleFill" "visibleStroke"
                            ]
                        ]

                        style [
                            styles/decode attribute/value
                        ]
                    ][
                        any [
                            attempt [
                                load attribute/value
                            ]

                            attribute/value
                        ]
                    ]
                ]
            ]

            if block? select attributes 'style [
                ; Style attributes have greater precedence:
                ; https://www.w3.org/TR/2008/REC-CSS2-20080411/cascade.html#q12
                ;
                foreach [attribute value] attributes/style [
                    if value: switch/default attribute [
                        ; this is largely a repeat of the above, need to hang out to DRY.

                        fill stroke [
                            paint/decode-from-style value
                        ]

                        stroke-dasharray [
                            lists/decode value
                        ]

                        stroke-width stroke-miterlimit font-size [
                            numbers/from-unit value
                        ]

                        fill-rule clip-rule [
                            is-value-from value [
                                "nonzero" "evenodd"
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
                    ][
                        value
                    ][
                        remove/part find/skip attributes/style attribute 2 2
                        put attributes attribute value
                    ]
                ]

                if empty? attributes/style [
                    remove/part find/skip attributes 'style 2 2
                ]
            ]

            either empty? attributes [
                _
            ][
                make map! attributes
            ]
        ]

        open-tags: _

        handle-kid: func [
            node [object!]
            /local attributes kids kid
        ][
            neaten/words/force collect [
                keep switch/default node/name [
                    <g> [
                        'group
                    ]
                ][
                    to word! to string! node/name
                ]

                keep/only attributes: handle-attributes node

                keep/only either empty? kids: neaten/triplets collect [
                    kids: node/children

                    while [
                        not tail? kids
                    ][
                        kid: kids/1

                        switch/default type-of kid/name [
                            #(tag!) [
                                insert open-tags kid/name
                                keep handle-kid kid
                                remove open-tags
                            ]

                            #(file!) [
                                keep quote 'text
                                keep _
                                keep either node/name = 'text [
                                    kid: copy kid/value

                                    if head? kids [
                                        trim/head kid
                                    ]

                                    if tail? next kids [
                                        trim/tail kid
                                    ]

                                    kid
                                ][
                                    copy kid/value
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
                        ]

                        kids: next kids
                    ]
                ][
                    _
                ][
                    kids
                ]
            ]
        ]

        decode: func [
            svg [string! binary!]
            /local kid kids desc defs
        ][
            case/all [
                binary? svg [
                    svg: to string! svg
                ]

                string? svg [
                    svg: load-xml/dom svg
                    ; probe svg/as-block
                ]
            ]

            open-tags: make block! 8

            neaten/words/force collect [
                keep 'svg
                keep/only handle-attributes svg

                keep/only either empty? kids: collect [
                    foreach kid svg/children [
                        if tag? kid/name [
                            insert open-tags kid/name
                            ; switch/default kid/name [
                            ;     ; defs [defs: handle-defs kid]
                            ;     desc [desc: kid/text]
                            ; ][
                                keep handle-kid kid
                            ; ]
                            remove open-tags
                        ]
                    ]
                ][
                    _
                ][
                    kids
                ]
            ]
        ]
    ]

    decode: :decoder/decode

    creator: make object! [
        presentation-attributes: #[
            fill _
            stroke _
            id _
            class _
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
            text-anchor _
            transform _
            href _
            cursor _
            display _
            visible _
            opacity _
            stroke-opacity _
            fill-opacity _
        ]

        do-attributes: func [
            node [block!]
            attributes [map! none!]
        ][
            case [
                none? attributes _
                empty? attributes _
                empty? attributes: intersect attributes presentation-attributes _

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

        to-color: func [
            color [tuple! word! issue!]
        ][
            switch type-of color [
                #(tuple!) [
                    paint/encode color
                ]

                #(word!) [
                    form color
                ]

                #(issue!) [
                    paint/from-hex color
                ]
            ]
        ]

        append-node: func [
            parent [block!]
            node [block!]
        ][
            also tail parent/3
            append parent/3 neaten/first node
        ]

        add-rectangle: func [
            container [block!]
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

            append-node container node
        ]

        add-circle: func [
            container [block!]
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

            append-node container node
        ]

        add-ellipse: func [
            container [block!]
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

            append-node container node
        ]

        add-image: func [
            container [block!]
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

            append-node container node
        ]

        add-line: func [
            container [block!]
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

            append-node container node
        ]

        add-polyline: func [
            container [block!]
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

                            foreach point reduce points [
                                keep point/x
                                keep point/y
                            ]
                        ]
                    )
                ] _
            ]

            do-attributes node attributes

            append-node container node
        ]

        add-polygon: func [
            container [block!]
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

                            foreach point reduce points [
                                keep point/x
                                keep point/y
                            ]
                        ]
                    )
                ] _
            ]

            do-attributes node attributes

            append-node container node
        ]

        paths: make object! [
            add-move: func [
                path [block!]
                offset [map!]
                target [pair!]

                /local command
            ][
                target: to pair! reduce [
                    offset/x: target/x + offset/x
                    offset/y: target/y + offset/y
                ]

                command: compose/deep [
                    move [
                        (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-line: func [
                path [block!]
                offset [map!]
                target [pair!]

                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                target: to pair! reduce [
                    offset/x: target/x + offset/x
                    offset/y: target/y + offset/y
                ]

                command: compose/deep [
                    line [
                        (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-hline: func [
                path [block!]
                offset [map!]
                target [number!]

                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                target:
                offset/x: target + offset/x

                command: compose/deep [
                    hline [
                        (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-vline: func [
                path [block!]
                offset [map!]
                target [number!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                target:
                offset/y: target + offset/y

                command: compose/deep [
                    vline [
                        (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-arc: func [
                path [block!]
                offset [map!]
                radius [pair!]
                angle [number!]
                large-arc? [logic!]
                sweep? [logic!]
                target [pair!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x: target/x + offset/x
                offset/y: target/y: target/y + offset/y

                command: compose/deep [
                    arc [
                        (radius) (angle) (large-arc?) (sweep?) (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-curve: func [
                path [block!]
                offset [map!]
                control-1 [pair!]
                control-2 [pair!]
                target [pair!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                control-1/x: control-1/x + offset/x
                control-1/y: control-1/y + offset/y

                control-2/x: control-2/x + offset/x
                control-2/y: control-2/y + offset/y

                offset/x: target/x: target/x + offset/x
                offset/y: target/y: target/y + offset/y

                command: reduce [
                    'curve compose [
                        (control-1) (control-2) (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-curv: func [
                path [block!]
                offset [map!]
                control [pair!]
                target [pair!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                control/x: control/x + offset/x
                control/y: control/y + offset/y

                offset/x: target/x: target/x + offset/x
                offset/y: target/y: target/y + offset/y

                command: reduce [
                    'curv compose [
                        (control) (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-qcurve: func [
                path [block!]
                offset [map!]
                control [pair!]
                target [pair!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                control/x: control/x + offset/x
                control/y: control/y + offset/y

                offset/x: target/x: target/x + offset/x
                offset/y: target/y: target/y + offset/y

                command: reduce [
                    'qcurve compose [
                        (control) (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-qcurv: func [
                path [block!]
                offset [map!]
                target [pair!]
                /local command
            ][
                if empty? path/2/d [
                    throw make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                offset/x: target/x: target/x + offset/x
                offset/y: target/y: target/y + offset/y

                command: compose/deep [
                    qcurv [
                        (target)
                    ]
                ]

                append path/2/d command

                command
            ]

            add-close: func [
                path [block!]
            ][
                if empty? path/2/d [
                    do make error [
                        "SVG Path must begin with a MOVE command"
                    ]
                ]

                append path/2/d reduce [
                    'close make block! 0
                ]

                [close]
            ]
        ]

        add-path: func [
            container [block!]
            attributes [map! none!]
            commands [block!]
            /local path node offset
        ][
            node: compose/deep [
                path #[
                    d []
                ] _
            ]

            path: node/path/d

            do-attributes node attributes

            offset: make map! [
                x: 0 y: 0
            ]

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
                    target/x: target/x - offset/x
                    target/y: target/y - offset/y

                    target
                ]

                move: func [
                    target [pair!]
                ][
                    paths/add-move node offset target
                ]

                line: func [
                    target [pair!]
                ][
                    paths/add-line node offset target
                ]

                hline: func [
                    target [number!]
                ][
                    paths/add-hline node offset target
                ]

                vline: func [
                    target [number!]
                ][
                    paths/add-vline node offset target
                ]

                arc: func [
                    radius [pair!]
                    angle [number!]
                    large-arc? [logic!]
                    sweep? [logic!]
                    target [pair!]
                ][
                    paths/add-arc node offset radius angle large-arc? sweep? target
                ]

                curve: func [
                    control-1 [pair!]
                    control-2 [pair!]
                    target [pair!]
                ][
                    paths/add-curve node offset control-1 control-2 target
                ]

                curv: func [
                    control [pair!]
                    target [pair!]
                ][
                    paths/add-curv node offset control target
                ]

                qcurve: func [
                    control [pair!]
                    target [pair!]
                ][
                    paths/add-qcurve node offset control target
                ]

                qcurv: func [
                    target [pair!]
                ][
                    paths/add-qcurv node offset target
                ]

                close: func [] [
                    paths/add-close node
                ]
            ]

            neaten/pairs node/2/d

            append-node container node
        ]

        add-linear-gradient: func [
            document [block!]
            id [issue!]
            spec [block!]

            /local node
        ][
            node: compose/deep [
                linearGradient #[
                    id (to string! id)
                ] []
            ]

            do-with spec [
                start: func [
                    point [pair!]
                ][
                    if not zero? point/x [
                        put node/2 'x1 to percent! point/x / 100
                    ]

                    if not zero? point/y [
                        put node/2 'y1 to percent! point/y / 100
                    ]

                    point
                ]

                end: func [
                    point [pair!]
                ][
                    if 1 <> point/x [
                        put node/2 'x2 to percent! point/x / 100
                    ]

                    if not zero? point/y [
                        put node/2 'y2 to percent! point/y / 100
                    ]

                    point
                ]

                user-space-on-use: func [] [
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
                    add-stop node offset opacity color
                ]

                colors: func [
                    colors [block!]
                ][
                    add-stops node colors
                ]
            ]

            append-node document/3 node
            ; document/3 = <defs>
        ]

        add-radial-gradient: func [
            document [block!]
            id [issue!]
            stops [block!]

            /local node
        ][
            node: compose/deep [
                radialGradient #[
                    id (to string! id)
                ] []
            ]

            do-with stops [
                center: func [
                    point [pair!]
                ][
                    if 50 <> point/x [
                        put node/2 'cx to percent! point/x / 100
                    ]

                    if 50 <> point/y [
                        put node/2 'cy to percent! point/y / 100
                    ]

                    point
                ]

                radius: func [
                    length [number!]
                ][
                    if not percent? length [
                        length: to percent! length / 100
                    ]

                    if length <> 50% [
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

                user-space-on-use: func [] [
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
                    add-stop node offset opacity color
                ]

                colors: func [
                    colors [block!]
                ][
                    add-stops node colors
                ]
            ]

            append-node document/3 node
            ; document/3 = <defs>
        ]

        add-stop: func [
            gradient [block!]
            offset [number! none!]
            opacity [number! none!]
            color [tuple! word! issue! none!]
        ][
            append-node gradient compose/deep [
                stop #[
                    offset (
                        if offset [
                            mold offset
                        ]
                    )

                    stop-opacity (
                        if opacity [
                            to decimal! opacity
                        ]
                    )

                    stop-color (to-color color)
                ] _
            ]
        ]

        add-stops: func [
            gradient [block!]
            colors [block!]

            /local offset end interval
        ][
            assert [
                not tail? next colors
            ]

            offset: 0%
            end: 100%

            interval: to percent! divide end - offset -1 + length-of colors

            append-node gradient collect-each color colors [
                keep compose/deep [
                    stop #[
                        offset (round/to offset 0.01%)
                        stop-color (to-color color)
                    ] _
                ]

                offset: offset + interval
            ]

            gradient
        ]

        animate-attribute: func [
            container [block!]
            attribute [word!]
            duration [time! integer! decimal!]
            values [block!]

            /local node
        ][
            if not find container/2 attribute [
                put container/2 attribute first values
            ]

            node: compose/deep [
                animate #[
                    attributeName (attribute)
                    values (combine/with values ";")
                    dur (duration)
                    repeatCount "indefinite"
                ] _
            ]

            append-node container node
        ]

        animate: func [
            node [block!]
            spec [block!]
        ][
            if not block? node/3 [
                node/3: make block! 0
            ]

            do-with spec [
                animate: func [
                    attribute [word!]
                    duration [time! integer! decimal!]
                    values [block!]
                ][
                    creator/animate-attribute node attribute duration values
                ]
            ]

            node
        ]

        create: func [
            size [pair!]
            body [block!]
            /with
            attributes [map!]
            /local document
        ][
            document: compose/deep [
                svg #[
                    xmlns http://www.w3.org/2000/svg
                    version 1.1
                    width (to integer! size/x)
                    height (to integer! size/y)
                    viewBox [
                        0 0 (to integer! size/x) (to integer! size/y)
                    ]
                ][
                    defs _ []
                ]
            ]

            creator/do-attributes document attributes

            do-with body [
                document: copy document

                line: func [
                    attributes [map! none!]
                    from [pair!]
                    to [pair!]
                ][
                    creator/add-path document attributes [
                        move from
                        line to - from
                    ]
                ]

                path: func [
                    attributes [map! none!]
                    commands [block!]
                ][
                    creator/add-path document attributes commands
                ]

                rectangle: func [
                    attributes [map! none!]
                    offset [pair!]
                    size [pair!]
                    /rounded
                    radius [number! pair! block!]
                ][
                    creator/add-rectangle/:rounded document attributes offset size radius
                ]

                circle: func [
                    attributes [map! none!]
                    center [pair!]
                    radius [number!]
                ][
                    creator/add-circle document attributes center radius
                ]

                ellipse: func [
                    attributes [map! none!]
                    center [pair!]
                    radius [pair!]
                ][
                    creator/add-ellipse document attributes center radius
                ]

                polygon: func [
                    attributes [map! none!]
                    points [block!]
                ][
                    creator/add-polygon document attributes points
                ]

                linear-gradient: func [
                    id [issue!]
                    spec [block!]
                ][
                    creator/add-linear-gradient document id spec
                ]

                radial-gradient: func [
                    id [issue!]
                    spec [block!]
                ][
                    creator/add-radial-gradient document id spec
                ]

                animate: func [
                    node [block!]
                    spec [block!]
                ][
                    creator/animate node spec
                ]
            ]

            neaten/triplets document/3

            if empty? document/3/3 [
                remove/part document/3 3
                ; remove DEFS if empty
            ]

            document
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
            attributes [map! none!]
            kids [block! string! none!]
            encoding [object!]

            /local out rule attribute part mark
        ][
            assert [
                find/match words-of encoding [
                    value precision pretty? parents
                ]
            ]

            mark: encoding/value

            either find/case ['text] :name [
                if not string? kids [
                    do make error! rejoin [
                        "Error in SVG Object: "
                        mold reduce [
                            name _ kids
                        ]
                    ]
                ]

                append encoding/value sanitize kids
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

                    if map? attributes [
                        foreach [attribute value] attributes [
                            if not none? value [
                                keep attribute

                                keep switch/default type-of value [
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
                                                paint/encode paint/from-hex value
                                            ][
                                                rejoin [
                                                    "url(#" form value ")"
                                                ]
                                            ]
                                        ]
                                    ]

                                    #(decimal!) [
                                        switch/default attribute [
                                            x x1 x2
                                            y y1 y2
                                            cx cy
                                            dx dy
                                            r rx ry
                                            fr fx fy
                                            width height [
                                                numbers/encode/precision value encoding/precision
                                            ]

                                            dur [
                                                join numbers/encode value "s"
                                            ]
                                        ][
                                            numbers/encode value
                                        ]
                                    ]

                                    #(integer!) [
                                        switch/default attribute [
                                            dur [
                                                join form value #"s"
                                            ]
                                        ][
                                            form value
                                        ]
                                    ]

                                    #(tuple!) [
                                        paint/encode value
                                    ]

                                    #(url!) [
                                        case [
                                            not find/match value "id:#" [
                                                form value
                                            ]

                                            find [id] attribute [
                                                form skip value 3
                                            ]

                                            #else [
                                                rejoin [
                                                    "url(" skip value 3 #")"
                                                ]
                                            ]
                                        ]
                                    ]

                                    #(block!) [
                                        ; path & transform attributes; others?

                                        case [
                                            all [
                                                'path = name
                                                'd = attribute
                                            ][
                                                paths/encode/precise value encoding/precision
                                            ]

                                            parse value [
                                                some [
                                                    word! [paren! | block!]
                                                ]
                                            ][
                                                transforms/encode value
                                            ]

                                            all [
                                                find [
                                                    transform gradientTransform
                                                ] attribute

                                                parse value [
                                                    word! some number!
                                                ]
                                            ][
                                                transforms/encode reduce [
                                                    value/1 to paren! next value
                                                ]
                                            ]

                                            #else [
                                                lists/encode/with-comma value
                                            ]
                                        ]
                                    ]

                                    #(time!) [
                                        join numbers/encode to decimal! value #"s"
                                    ]
                                ][
                                    form value
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

                    foreach [name attributes kids] kids [
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
                        "</" replace form name #"|" #":" ">"
                    ]
                ]
            ]

            mark
        ]

        encode: func [
            "Convert SVG Model to SVG"

            svg-block [block!]
            "SVG Model"

            /precise
            "Constrain numbers to a specified precision"

            precision [number!]
            "Precision value (see ROUND function's SCALE parameter)"

            /pretty
            "Use indents on the resultant XML output"

            /local encoding
        ][
            encoding: make object! compose/deep [
                value: make string! 1024

                precision: any [
                    (precision)
                    0.001
                ]

                pretty?: did pretty

                parents: make block! 8
            ]

            either parse svg-block [
                'svg map! [block! | none!]
            ][
                render-node 'svg svg-block/2 svg-block/3 encoding
            ][
                do make error! "Not an SVG document"
            ]

            encoding/value
        ]
    ]

    encode: :encoder/encode
]

load-svg: get in svg 'decode
to-svg: get in svg 'encode
