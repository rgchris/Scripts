Red [
    Title: "SVG Tools"
    Date: 27-Jan-2020
    Author: "Christopher Ross-Gill"
    Rights: http://opensource.org/licenses/Apache-2.0
    Version: 0.3.2
    History: [
        0.3.2 27-Jan-2020 "Better handling of text whitespace; bold/italic"
        0.3.1 24-Jan-2020 "PATH model rewrite; VIEW wrapper to view an SVG"
        0.3.0 23-Jan-2020 "Reorganise PATH handling; render whole/partial object; further refactoring"
        0.2.2 13-Sep-2019 "Some functions for manipulating paths; refactoring"
        0.2.1 26-Aug-2019 "Set Stroke/Fill off by default; handle numbers with units; open paths"
        0.2.0 25-Aug-2019 "Text support in TO-DRAW"
        0.1.0 23-Dec-2018 "Rudimentary Shape Support"
    ]
    Notes: {
        v0.3.2
        There are still many ways in which this could be more efficient, but for now the focus is
        merely having everything work. PUSH per-shape is expensive, and I'd much prefer to reuse
        font objects.

        There's still more functionality to figure out too: gradient fills, <use>, <textpath> to
        name but a few.

        Note: View/VID-related functions are now contained within the SVG/VID sub-object:

            view svg/vid/quick-layout load-svg read %my-svg.svg

        Red Draw Docs: https://github.com/red/docs/blob/master/en/draw.adoc
        Baking transforms: https://stackoverflow.com/questions/5149301

        Paths:
        MDN Overview: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
        SVG (1.1): https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
        SVG (2--incomplete as-of 22-Jan-2020): https://www.w3.org/TR/SVG/paths.html#PathDataBNF

        Length: evaluate https://github.com/MadLittleMods/svg-curve-lib
    }
]

#macro ['_] func [s e] [none]

do either exists? %altxml.red [%altxml.red] [
    https://raw.githubusercontent.com/rgchris/Scripts/master/experimental/altxml.red
]

do either exists? %rsp.red [%rsp.red] [
    https://raw.githubusercontent.com/rgchris/Scripts/master/red/rsp.red
]

neaten: func [
    block [block! paren!]
    /pairs
    /triplets
    /flat
    /words
    /first
][
    case [
        words [
            forall block [
                new-line block to logic! all [
                    find [word! set-word! lit-word!] type?/word block/1
                    not find/same [off] block/1
                ]
            ]
        ]

        first [
            new-line new-line/all block false true
        ]

        <else> [
            new-line/all/skip block not flat case [
                pairs [2]
                triplets [3]
                <else> [1]
            ]
        ]
    ]

    block
]

svg: make object! [
    ; quickie number parsing
    ; number*: charset "-.0123456789eE"
    name*: complement charset {^-^/^L^M "',;}
    spacers*: charset "^-^/^L^M "
    digit*: charset "0123456789"
    hex*: charset "0123456789abcdefABCDEF"
    lower-alpha*: charset [#"a" - #"z"]

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

    as-number: func [
        value [string! integer! float! percent!]
    ][
        if string? value [
            value: load value
        ]

        switch type?/word value [
            ; default rounding is bad, it has a destructive
            ; influence on relative path values
            ;
            float! percent! [
                round/to value 0.001
            ]

            integer! [
                value
            ]
        ]
    ]

    is-value-from: func [
        value [string!]
        list [block!]
    ][
        if find list value [
            load value
        ]
    ]

    colors: #(
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
    )

    underscore: to word! "_"
    set :underscore none

    lit-underscore: to lit-word! underscore

    fail-mark: _

    fail-if-not-end: [
        end
        |
        fail-mark: (
            do make error! rejoin [
                "Parse Error: " copy/part mold fail-mark 30
            ]
        )
    ]

    paths: make object! [
        comment {
            MDN Overview: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
            SVG (1.1): https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
            SVG (2--incomplete as-of 22-Jan-2020): https://www.w3.org/TR/SVG/paths.html#PathDataBNF

            Length: evaluate https://github.com/MadLittleMods/svg-curve-lib
        }

        command: _
        relative?: _
        implicit?: _
        offset: _
        origin: _
        params: _
        stack: make block! 8
        precision: 0.001

        mark: value: _

        commands: #(
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
        )

        fail: func [message [string!]] [
            do make error! rejoin [
                message ": (" any [command #"_"] ") "
                mold copy/part mark 30
            ]
        ]

        ; Unit Products
        ;
        flag: [
            [
                #"0"
                (append stack false)
                |
                #"1"
                (append stack true)
            ]
            |
            (fail "Could not consume flag")
        ]

        nonnegative-number: [
            copy value unsigned*
            (append stack as-number value)
            |
            (fail "Could not consume non-negative number")
        ]

        number: [
            copy value number*
            (append stack as-number value)
            |
            mark: (fail "Could not consume number")
        ]

        ; Parameter Templates

        coordinate: [
            number
        ]

        coordinate-pair: [
            coordinate
            opt comma*
            coordinate
        ]

        coordinate-pair-double: [
            coordinate-pair
            opt comma*
            coordinate-pair
        ]

        coordinate-pair-triple: [
            coordinate-pair
            opt comma*
            coordinate-pair
            opt comma*
            coordinate-pair
        ]

        elliptical-arc-sequence: [
            nonnegative-number
            opt comma*
            nonnegative-number
            opt comma*
            number
            comma*
            flag
            opt comma*
            flag
            opt comma*
            coordinate-pair
        ]

        ; Commands

        move-to: [
            [#"M" | #"m"]
            (params: coordinate-pair)
        ]

        close-path: [
            [#"Z" | #"z"]
            (params: [])
        ]

        line-to: [
            [#"L" | #"l"]
            (params: coordinate-pair)
        ]

        horizontal-line-to: [
            [#"H" | #"h"]
            (params: coordinate)
        ]

        vertical-line-to: [
            [#"V" | #"v"]
            (params: coordinate)
        ]

        curve-to: [
            [#"C" | #"c"]
            (params: coordinate-pair-triple)
        ]

        smooth-curve-to: [
            [#"S" | #"s"]
            (params: coordinate-pair-double)
        ]

        quadratic-bezier-curve-to: [
            [#"Q" | #"q"]
            (params: coordinate-pair-double)
        ]

        smooth-quadratic-bezier-curve-to: [
            [#"T" | #"t"]
            (params: coordinate-pair)
        ]

        elliptical-arc: [
            [#"A" | #"a"]
            (params: elliptical-arc-sequence)
        ]

        ; Structure

        keep-params: [
            (
                switch command [
                    move [
                        if relative? [
                            stack/1: round/to stack/1 + offset/1 precision
                            stack/2: round/to stack/2 + offset/2 precision
                        ]

                        origin/1: offset/1: stack/1
                        origin/2: offset/2: stack/2
                    ]

                    hline [
                        if relative? [
                            stack/1: round/to stack/1 + offset/1 precision
                        ]

                        offset/1: stack/1
                    ]

                    vline [
                        if relative? [
                            stack/1: round/to stack/1 + offset/2 precision
                        ]

                        offset/2: stack/1
                    ]

                    line qcurv [
                        if relative? [
                            stack/1: round/to stack/1 + offset/1 precision
                            stack/2: round/to stack/2 + offset/2 precision
                        ]

                        offset/1: stack/1
                        offset/2: stack/2
                    ]

                    curv qcurve [
                        if relative? [
                            stack/1: round/to stack/1 + offset/1 precision
                            stack/2: round/to stack/2 + offset/2 precision
                            stack/3: round/to stack/3 + offset/1 precision
                            stack/4: round/to stack/4 + offset/2 precision
                        ]

                        offset/1: stack/3
                        offset/2: stack/4
                    ]

                    curve [
                        if relative? [
                            stack/1: round/to stack/1 + offset/1 precision
                            stack/2: round/to stack/2 + offset/2 precision
                            stack/3: round/to stack/3 + offset/1 precision
                            stack/4: round/to stack/4 + offset/2 precision
                            stack/5: round/to stack/5 + offset/1 precision
                            stack/6: round/to stack/6 + offset/2 precision
                        ]

                        offset/1: stack/5
                        offset/2: stack/6
                    ]

                    arc [
                        if relative? [
                            stack/6: round/to stack/6 + offset/1 precision
                            stack/7: round/to stack/7 + offset/2 precision
                        ]

                        offset/1: stack/6
                        offset/2: stack/7
                    ]

                    close [
                        offset/1: origin/1
                        offset/2: origin/2
                    ]
                ]
            )

            keep (command)
            keep (take/part stack tail stack)
        ]

        expand: [
            (
                command: _
                relative?: _
                implicit?: _
                offset: copy [0 0]
                origin: copy [0 0]
                clear stack
            )

            opt space*

            collect opt [
                mark:
                set command move-to
                opt space*
                params
                (
                    command: commands/:command
                    implicit?: false
                    relative?: lit-word? command
                    command: to word! command
                )
                keep-params

                any [
                    opt space*
                    set command [
                        move-to
                        |
                        close-path
                        |
                        line-to
                        |
                        horizontal-line-to
                        |
                        vertical-line-to
                        |
                        curve-to
                        |
                        smooth-curve-to
                        |
                        quadratic-bezier-curve-to
                        |
                        smooth-quadratic-bezier-curve-to
                        |
                        elliptical-arc
                    ]
                    opt space* params
                    (
                        command: commands/:command
                        implicit?: false
                        relative?: lit-word? command
                        command: to word! command
                    )
                    keep-params
                    |
                    opt space* end
                    |
                    opt comma* params
                    (
                        implicit?: true
                        if command = 'move [
                            command: 'line
                        ]
                    )
                    keep-params
                ]
            ]

            fail-if-not-end
        ]

        ; Interpret

        command-name: [
            'move | 'line | 'hline | 'vline | 'arc | 'curve | 'qcurve | 'curv | 'qcurv | 'close
        ]

        draw-params: #(
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
        )

        draw-path-to-path: func [
            path [block!]
            /local here command offset origin params relative? implicit? value
        ][
            command: _

            offset: [0 0]
            origin: [0 0]

            implicit?: false
            relative?: false

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
                                implicit?: false
                                relative?: lit-word? here/1
                                params: select draw-params here/1
                            )
                            |
                            (
                                implicit?: true
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

                            keep reduce [command part]
                        )
                    ]
                ][
                    do make error! rejoin ["Could not parse path (at #" copy/part here 8 ")"]
                ]
            ]
        ]

        next-command: func [
            here [block!]
            /local params part implicit?
        ][
            if head? here [
                current/command: none
                current/position: 0x0
                implicit?: false
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
                            implicit?: false
                            params: command-params/:current-command
                        )
                        |
                        (
                            implicit?: true
                            params: either none? current/command [
                                [fail]
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

                <else> [
                    do make error! rejoin [
                        "Could not parse path (at #" index? here ")"
                    ]
                ]
            ]
        ]
    ]

    unit-to-number: func [
        number [string!]
        /local value unit
    ][
        if parse number [
            copy value number*
            copy unit opt [
                "%" | "px" | "mm" | "cm" | "in" | "pt"
            ]
        ][
            switch unit [
                "" "px" [
                    as-number value
                ]

                "%" [
                    1% * to float! value
                ]

                ; not yet supported
                ; "mm" "cm" "in" "pt" [none]
            ]
        ]
    ]

    parse-numeric-list: func [
        list [string!]
        /local part
    ][
        parse list [
            collect any [
                part:
                space*
                opt #","
                opt space*
                |
                #","
                opt space*
                |
                copy part number*
                keep (as-number part)
            ]

            fail-if-not-end
        ]
    ]

    parse-path: func [
        path [string!]
        /local out
    ][
        if out: parse/case path paths/expand [
            neaten/words out
        ]
    ]

    load-style: func [
        style [string!]
        /local key value
    ][
        ; quickie parsing for now
        style: split style charset ":;"

        if even? index? tail style [
            remove back tail style
        ]

        make map! collect [
            foreach [key value] style [
                keep to word! trim/head/tail key
                keep trim/head/tail value
            ]
        ]
    ]

    parse-transformation: func [
        transformation [string!]
        /local type part value
    ][
        collect [
            parse transformation [
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
                        keep/only to paren! parse-numeric-list part
                    )
                ]

                fail-if-not-end
            ]
        ]
    ]

    parse-font-name: func [
        names [string!]
        /local name
    ][
        collect [
            if not parse names [
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
                        {"}
                        copy name some [
                            some name*
                            |
                            " " | "," | "'"
                        ]
                        {"}
                        |
                        "'"
                        copy name some [
                            some name*
                            |
                            " " | "," | {"}
                        ]
                        "'"
                    ]
                    (keep name)
                    opt space* [
                        ","
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

    handle-attributes: func [
        node [object!]
        /local attribute handler value style part
    ][
        attributes: make map! collect [
            ; Should support these
            ; https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Presentation
            ;
            foreach attribute node/attributes [
                keep either attribute/namespace [
                    to word! rejoin [
                        form attribute/namespace
                        "|"
                        form attribute/name
                    ]
                ][
                    attribute/name
                ]

                keep/only switch/default attribute/name [
                    viewbox [
                        if all [
                            value: parse-numeric-list attribute/value
                            parse value [
                                4 integer!
                            ]
                        ][
                            value
                        ]
                    ]

                    id [
                        to issue! replace/all attribute/value " " "_"
                    ]

                    class [
                        collect [
                            foreach part split attribute/value " " [
                                if not empty? trim/head/tail part [
                                    attempt [
                                        keep to word! part
                                    ]
                                ]
                            ]
                        ]
                    ]

                    fill stroke stop-color [
                        either parse/case trim/head/tail attribute/value [
                            ["transparent" | "none"]
                            end
                            (value: 'transparent)
                            |
                            copy value [some lower-alpha*]
                            end
                            (
                                value: to word! value

                                if not tuple? select colors value [
                                    value: none
                                ]
                            )
                            |
                            copy value [
                                "#" [
                                    8 hex* | 6 hex* | 3 hex*
                                ]
                            ]
                            end
                            (value: hex-to-rgb load value)
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
                                parse value [
                                    some digit* change comma* "."
                                    some digit* change comma* "."
                                    some digit*
                                ]
                                value: attempt [
                                    to tuple! value
                                ]
                            )
                            ; |  ; handle-URL
                            ; "url(" ")"
                        ][
                            value
                        ][
                            attribute/value
                            black
                        ]
                    ]

                    d [
                        parse-path attribute/value
                    ]

                    points [
                        parse-numeric-list attribute/value
                    ]

                    cx cy dx dy fr fx fy r rx ry x x1 x2 y y1 y2 z
                    width height offset rotate scale
                    stroke-width stroke-miterlimit [
                        any [
                            is-value-from attribute/value [
                                "auto"
                            ]

                            unit-to-number attribute/value
                        ]
                    ]

                    fill-rule clip-rule [
                        is-value-from attribute/value [
                            "nonzero" "evenodd"
                        ]
                    ]

                    stroke-dasharray [
                        either attribute/value = "none" [
                            none
                        ][
                            parse-numeric-list attribute/value
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

                            unit-to-number attribute/value
                        ]
                    ]

                    font-family [
                        parse-font-name attribute/value
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
                        parse-transformation attribute/value
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
                        unit-to-number attribute/value
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
                        load-style attribute/value
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

        if map? attributes/style [
            ; Style attributes have greater precedence:
            ; https://www.w3.org/TR/2008/REC-CSS2-20080411/cascade.html#q12
            foreach attribute words-of attributes/style [
                value: attributes/style/:attribute

                if value: switch/default attribute [
                    ; this is largely a repeat of the above, need to hang out to DRY.

                    fill stroke [
                        either parse/case trim/head/tail value [
                            ["transparent" | "none"]
                            end
                            (value: 'transparent)
                            |
                            copy value [
                                some lower-alpha*
                            ]
                            end
                            if (
                                value: to word! value
                                tuple? select colors value
                            )
                            |
                            copy value [
                                "#" [
                                    8 hex* | 6 hex* | 3 hex*
                                ]
                            ]
                            end
                            (value: hex-to-rgb load value)
                            |
                            "rgb(" copy part to ")" skip
                            (value: to tuple! parse-numeric-list part)
                        ][
                            value
                        ][
                            probe attributes/style/:attribute
                            value: black
                        ]
                    ]

                    stroke-dasharray [
                        parse-numeric-list value
                    ]

                    stroke-width stroke-miterlimit font-size [
                        unit-to-number value
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
                        parse-font-name value
                    ]

                    font-size [
                        any [
                            is-value-from value [
                                "xx-small" "x-small" "small" "medium" "large" "x-large" "xx-large" "xxx-large"
                                "larger" "smaller"
                            ]

                            unit-to-number value
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
                        parse-transformation value
                    ]
                ][
                    value
                ][
                    remove/key attributes/style attribute
                    attributes/(attribute): value
                ]
            ]

            if empty? attributes/style [
                remove/key attributes 'style
            ]
        ]

        attributes
    ]

    open-tags: _

    handle-kid: func [
        node [object!]
        /local attributes kids kid
    ][
        neaten/words collect [
            keep switch/default node/name [
                g [
                    'group
                ]
            ][
                node/name
            ]

            keep attributes: handle-attributes node

            keep/only either empty? kids: neaten/triplets collect [
                kids: node/children

                while [not tail? kids] [
                    kid: kids/1

                    switch/default kid/type [
                        element [
                            insert open-tags kid/name
                            keep handle-kid kid
                            remove open-tags
                        ]

                        text [
                            keep quote 'text
                            keep underscore
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

                        whitespace [
                            if all [
                                find open-tags 'text
                                not head? kids
                                not tail? next kids
                            ][
                                keep quote 'text
                                keep _
                                keep copy " "
                            ]
                        ]
                    ][
                        probe kids/1/type
                    ]

                    kids: next kids
                ]
            ][
                underscore
            ][
                kids
            ]
        ]
    ]

    load-svg: func [
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

        neaten/words collect [
            keep 'svg
            keep handle-attributes svg

            keep/only either empty? kids: collect [
                foreach kid svg/children [
                    if kid/type = 'element [
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
                underscore
            ][
                kids
            ]
        ]
    ]

    ; Draw
    ;
    vid: context [
        as-pair: func [
            x [number!]
            y [number!]
        ][
            make pair! reduce [round/to x 1 round/to y 1]
        ]

        adjust-font-size: func [
            parent [map!]
            size [word! integer! float!]
        ][
            switch/default size [
                xx-small [8]
                x-small [9]
                small [10]
                medium [12]
                large [14]
                x-large [16]
                xx-large [18]
                xxx-large [24]

                larger [
                    round/to parent/size + 1 1
                ]

                smaller [
                    round/to parent/size - 1 1
                ]
            ][
                either number? size [
                    ; round/to size * 72.0 / 96 1
                    round/to size * 75.0 / 96 1
                ][
                    do make error! rejoin [
                        "Invalid Font-Size value: " mold size
                    ]
                ]
            ]
        ]

        to-draw-path: func [
            path [block!]
            /local command params open?
        ][
            comment {
                SVG Path/D: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
                (with links to various W3 specs)
                Draw (Red): https://github.com/red/docs/blob/master/en/draw.adoc#shape-commands
                (was): https://doc.red-lang.org/en/draw.html#_shape_commands
                Draw (Rebol 3): http://www.rebol.com/r3/docs/view/draw-shapes.html
                Draw (Rebol 2): http://www.rebol.com/docs/draw-ref.html#section-74
            
                Some incongruities:
                SVG calls it PATH with D attribute, Draw calls it SHAPE.

                In SVG, MOVE may have one or more coordinate pairs. The first moves the pen
                without a mark, the following are implicit LINE commands. This is an error in
                Red (does work in Rebol 2).

                SVG Path commands are fixed arity, however Draw's ARC has optional LARGE and
                SWEEP keywords.
            }

            neaten/words collect [
                open?: true

                foreach [command params] path [
                    keep command

                    switch command [
                        move [
                            keep as-pair params/1 params/2
                            open?: true
                        ]

                        line qcurv [
                            keep as-pair params/1 params/2
                        ]

                        hline vline [
                            keep round params/1
                        ]

                        arc [
                            keep as-pair params/6 params/7
                            keep round params/1
                            keep round params/2
                            keep params/3

                            if find [true #[true]] params/5 [
                                keep 'sweep
                            ]

                            if find [true #[true]] params/4 [
                                keep 'large
                            ]
                        ]

                        curve [
                            keep as-pair params/1 params/2
                            keep as-pair params/3 params/4
                            keep as-pair params/5 params/6
                        ]

                        curv qcurve [
                            keep as-pair params/1 params/2
                            keep as-pair params/3 params/4
                        ]

                        close [
                            open?: false
                        ]
                    ]
                ]

                ; prevents Red's auto-closing behaviour
                ;
                if open? [
                    keep [
                        move -1x-1
                    ]
                ]
            ]
        ]

        numbers-to-points: func [
            numbers [block!]
            /local mark
        ][
            parse numbers [
                collect [
                    some [
                        mark: number! number!
                        keep (as-pair mark/1 mark/2)
                    ]
                ]
            ]
        ]

        default-style: #(
            pen: off
            fill-pen: off
            line-width: 0
        )

        default-font: #(
            name: system
            size: 12
            style: #[none]
            angle: 0
            color: 0.0.0
        )

        viewport-of: func [
            svg-block [block!]
        ][
            either parse svg-block [
                'svg map! block!
            ][
                if all [
                    number? select svg-block/2 'width
                    number? select svg-block/2 'height
                ][
                    as-pair round svg-block/2/width round svg-block/2/height
                ]
            ][
                make error! "Not an SVG drawing: No Viewport"
            ]
        ]

        viewbox-of: func [
            svg-block [block!]
        ][
            either parse svg-block [
                'svg map! block!
            ][
                if all [
                    block? select svg-block/2 'viewbox
                    parse svg-block/2/viewbox [
                        4 number!
                    ]
                ][
                    as-pair
                        round (svg-block/2/viewbox/3 - svg-block/2/viewbox/1)
                        round (svg-block/2/viewbox/4 - svg-block/2/viewbox/2)
                ]
            ][
                make error! "Not an SVG drawing: No Viewbox"
            ]
        ]

        dimensions-of: func [
            svg-block [block!]
        ][
            any [
                viewbox-of svg-block
                viewport-of svg-block
            ]
        ]

        facets-of: func [
            facets [map!]
            /local facet
        ][
            neaten/pairs collect [
                foreach facet words-of facets/style [
                    if facets/style/:facet [
                        keep to word! facet
                        keep facets/style/:facet
                    ]
                ]
            ]
        ]

        font!: make object! [
            name: _
            size: _
            style: _
            angle: 0
            color: _
            parent: _
        ]

        font-facets-of: func [
            facets [map!]
        ][
            make font! body-of facets/font
        ]

        change-font-style-flag: func [
            font [map!]
            flag [word!]
            status [logic!]
        ][
            either status [
                if not block? font/style [
                    font/style: make block! 2
                ]

                if not find font/style flag [
                    append font/style flag
                ]
            ][
                if all [
                    block? font/style
                    flag: find font/style flag
                ][
                    remove flag
                ]

                if empty? font/style [
                    font/style: none
                ]
            ]
        ]

        handle-facets: func [
            inherited [map!]
            attributes [map!]
            /local facets value facet keepers function params
        ][
            facets: make map! reduce [
                'style copy inherited/style
                'font copy/deep inherited/font
            ]

            ; display attributes
            ;
            foreach [facet keepers] [
                stroke [
                    facets/style/pen: switch/default type?/word value [
                        word! [
                            any [
                                select colors value
                                'off
                            ]
                        ]

                        tuple! issue! [
                            value
                        ]
                    ][
                        'off
                    ]
                ]

                fill [
                    facets/style/fill-pen: switch/default type?/word value [
                        word! [
                            any [
                                select colors value
                                'off
                            ]
                        ]

                        tuple! issue! [
                            value
                        ]
                    ][
                        probe value
                        'off
                    ]
                ]

                stroke-width [
                    facets/style/line-width: value
                ]

                stroke-linejoin [
                    facets/style/line-join: value
                ]

                transform [
                    ; need to expand on this for multiple transforms
                    ;
                    foreach [function params] value [
                        switch function [
                            matrix [
                                facets/style/matrix: reduce [
                                    to block! params
                                ]
                            ]

                            translate [
                                facets/style/translate: as-pair params/1 params/2
                            ]

                            scale [
                                facets/style/scale: to block! :params
                            ]
                        ]
                    ]
                ]

                ; stroke-dasharray
            ][
                value: any [
                    select attributes facet
                    select default-style facet
                ]

                if value keepers
            ]

            ; font attributes
            ;
            foreach [facet keepers] [
                fill [
                    facets/font/color: case [
                        tuple? facets/style/fill-pen [
                            facets/style/fill-pen
                        ]

                        issue? facets/style/fill-pen [
                            hex-to-rgb facets/style/fill-pen
                        ]
                    ]
                ]

                font-family [
                    facets/font/name: any [
                        case [
                            block? value [
                                first value
                            ]

                            string? value [
                                value
                            ]

                            word? value [
                                switch/default value [
                                    serif cursive fantasy [
                                        'serif
                                    ]

                                    sans-serif [
                                        'sans-serif
                                    ]

                                    monospace [
                                        'monospace
                                    ]
                                ]
                            ]
                        ]

                        'system
                    ]
                ]

                font-size [
                    facets/font/size: adjust-font-size inherited/font value
                ]

                font-style [
                    switch value [
                        normal [
                            change-font-style-flag facets/font 'italic off
                        ]

                        italic [
                            change-font-style-flag facets/font 'italic on
                        ]
                    ]
                ]

                font-weight [
                    switch value [
                        normal 100 200 300 400 500 lighter [
                            change-font-style-flag facets/font 'bold off
                        ]

                        bold 600 700 800 900 bolder [
                            change-font-style-flag facets/font 'bold on
                        ]
                    ]
                ]

                text-anchor [
                    switch value [
                        start middle end []
                    ]
                ]
            ][
                if value: select attributes facet keepers
            ]

            facets
        ]

        text-sizer: make face! [
            type: 'text-sizer
        ]

        width-of: func [
            text [string!]
            font [none! object!]
        ][
            first size-text make text-sizer compose [
                text: (text)
                font: (any [font font!])
            ]

            ; ; crashing for some reason
            ; text-sizer/text: text
            ; text-sizer/font: any [font font!] ; either probe font [make font! font][font!]
            ; first size-text text-sizer
        ]

        text-offset: 0x0

        text-to-draw: func [
            svg-block [block!]
            inherited [map!]
            /at position [pair!]
            /local node attributes style kids reset
        ][
            if at [
                text-offset: :position
            ]

            neaten/words collect [
                foreach [node attributes kids] svg-block [
                    switch/default node [
                        'text [
                            keep reduce [
                                ; 'font probe style: font-facets-of inherited

                                'font neaten/first to paren! reduce [
                                    'make 'object! neaten/pairs body-of style: font-facets-of inherited
                                ]

                                'text subtract text-offset as-pair 0 style/size kids
                            ]

                            text-offset/x: text-offset/x + width-of kids style
                        ]

                        tspan [
                            case [
                                number? attributes/x [
                                    text-offset/x: round/to attributes/x 1
                                ]

                                number? attributes/dx [
                                    text-offset/x: text-offset/x + round/to attributes/dx 1
                                ]
                            ]

                            case [
                                number? attributes/y [
                                    text-offset/y: round/to attributes/y 1
                                ]

                                number? attributes/dy [
                                    text-offset/y: text-offset/y + round/to attributes/dy 1
                                ]
                            ]

                            keep 'push

                            keep/only compose [
                                (facets-of style: handle-facets inherited attributes)
                                (text-to-draw kids style)
                            ]
                        ]

                        a textpath [
                            keep compose [
                                (facets-of style: handle-facets inherited attributes)
                                (text-to-draw kids style)
                            ]
                        ]
                    ][
                        probe reduce [
                            "Unsupported text node:" node
                        ]
                    ]
                ]
            ]
        ]

        nodes-to-draw: func [
            nodes [block!]
            inherited [map!]
            /local node attributes kids pushed?
        ][
            neaten/words collect [
                foreach [node attributes kids] nodes [
                    switch/default node [
                        svg [
                            keep compose [
                                (facets-of style: handle-facets inherited attributes)
                                (nodes-to-draw kids style)
                            ]
                        ]

                        defs [
                            ; to follow
                        ]

                        clippath [
                            ; to follow
                        ]

                        group a [
                            keep 'push
                            keep/only compose [
                                (facets-of style: handle-facets inherited attributes)
                                (nodes-to-draw kids style)
                            ]
                        ]

                        text [
                            ; Here be dragons
                            ;
                            position: 0x0

                            case [
                                number? attributes/x [
                                    position/x: to integer! attributes/x
                                ]

                                number? attributes/dx [
                                    position/x: position/x + to integer! attributes/dx
                                ]
                            ]

                            case [
                                number? attributes/y [
                                    position/y: to integer! attributes/y
                                ]

                                number? attributes/dy [
                                    position/y: position/y + to integer! attributes/dy
                                ]
                            ]

                            keep/only compose [
                                (facets-of style: handle-facets inherited attributes)
                                (text-to-draw/at kids style position)
                            ]
                        ]

                        rect [
                            keep 'push
                            keep/only neaten/words collect [
                                keep facets-of handle-facets inherited attributes
                                keep 'box
                                keep as-pair attributes/x attributes/y
                                keep as-pair attributes/x + attributes/width attributes/y + attributes/height

                                ; only one radius dimension allowed...
                                ;
                                if any [
                                    attributes/rx
                                    attributes/ry
                                ][
                                    keep any [
                                        attributes/rx
                                        attributes/ry
                                    ]
                                ]
                            ]
                        ]

                        circle [
                            keep 'push
                            keep/only neaten/words compose [
                                (facets-of handle-facets inherited attributes)
                                circle
                                (as-pair attributes/cx attributes/cy)
                                (attributes/r)
                            ]
                        ]

                        ellipse [
                            keep 'push
                            keep/only neaten/words compose [
                                (facets-of handle-facets inherited attributes)
                                circle
                                (as-pair attributes/cx attributes/cy)
                                (attributes/rx)
                                (attributes/ry)
                            ]
                        ]

                        line [
                            keep 'push
                            keep/only neaten/words compose [
                                (facets-of handle-facets inherited attributes)
                                line
                                (as-pair attributes/x1 attributes/y1)
                                (as-pair attributes/x2 attributes/y2)
                            ]
                        ]

                        polyline [
                            keep 'push
                            keep/only neaten/words compose [
                                (facets-of handle-facets inherited attributes)
                                line (numbers-to-points attributes/points)
                            ]
                        ]

                        polygon [
                            keep 'push
                            keep/only neaten/words compose [
                                (facets-of handle-facets inherited attributes)
                                polygon (numbers-to-points attributes/points)
                            ]
                        ]

                        path [
                            keep 'push
                            keep/only neaten/words compose/deep [
                                (facets-of handle-facets inherited attributes)
                                shape [(to-draw-path attributes/d)]
                            ]
                        ]

                        use [
                            keep [
                                text 0x0 "`USE` TO FOLLOW"
                            ]
                        ]

                        style []
                    ][
                        probe to-tag node
                        probe attributes
                    ]
                ]
            ]
        ]

        to-draw: func [
            nodes [block!]
            "Block hewn from LOAD-SVG function"

            /with style [map! none!]
            "Style inherited from parent"

            ; /local drawing
        ][
            comment {
                Challenges facing TO-DRAW include:

                * SVG elements inherit style from their parents where Draw
                  elements inherit the current style, hence PUSH must be used
                  to isolate an element to prevent subsequent sibling elements
                  from inheriting its style
                * New font objects must be created for every change in style
                  facets pertaining to text
                * Elements in SVG <def> also inherit from parents and when such
                  elements are applied within a Draw block must retain all
                  style from its parent. e.g. all kids of <def fill="yellow">
                  will still be yellow when placed inside a <g fill="purple">
            }

            compose [
                fill-pen off
                pen off
                line-width 0
                (
                    nodes-to-draw nodes make map! reduce [
                        'style any [
                            style
                            default-style
                        ]

                        'font default-font
                    ]
                )
            ]
        ]

        quick-layout: func [
            svg-block [block!] "SVG to wrap"
        ][
            probe 'quick-layout

            copy/deep compose/deep [
                title "SVG Viewer"
                backdrop coal
                panel 400x400 [
                    backdrop silver
                    origin 0x0 space 0x0

                    box loose (
                        any [
                            dimensions-of svg-block
                            500x500
                        ]
                    )

                    draw compose/deep [
                        scale 1 1 [
                            (
                                ; probe copy/deep load mold/all ; ugh, getting access violation errors without this
                                to-draw svg-block
                            )
                        ]
                    ]

                    on-drag [
                        face/offset: min 0x0 max face/offset face/parent/size - face/size
                    ]
                ]

                do [
                    self/actors: make object! [
                        on-resize: func [
                            face event
                            /local fixed sizes gutters
                        ][
                            face/pane/1/size: face/size - 20
                        ]

                        on-key-up: func [
                            face event
                        ][
                            switch event/key [
                                #"w" #"W" [
                                    unview/all
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; Transform/Render

    form-number: func [
        number [number!]
    ][
        switch type?/word number [
            integer! percent! [
                form number
            ]

            float! [
                number: form number
                case [
                    parse number [thru ".0" end] [
                        clear find number ".0"
                    ]

                    find/match number "0." [
                        remove number
                    ]

                    find/match number "-0." [
                        remove next number
                    ]
                ]
                number
            ]
        ]
    ]

    form-color: func [
        value [tuple!]
    ][
        case [
            3 = length? value [
                rejoin [
                    "rgb(" value/1 #"," value/2 #"," value/3 ")"
                ]
            ]

            4 = length? value [
                rejoin [
                    "rgba(" value/1 #"," value/2 #"," value/3 #"," form-number value/4 / 256 ")"
                ]
            ]
        ]
    ]

    round-params: func [
        command [word!]
        params [block!]
        precision [integer! float!]
        /local param
    ][
        params: copy params

        foreach param switch command [
            vline hline [
                [1]
            ]

            move line qcurv [
                [1 2]
            ]

            curv qcurve [
                [1 2 3 4]
            ]

            curve [
                [1 2 3 4 5 6]
            ]

            arc [
                [1 2 3 6 7]
            ]

        ][
            poke params param round/to pick params param precision
        ]

        params
    ]

    form-path: func [
        path [block!]
        /precise precision [number!]
        /local out emit command params value type last offset origin
    ][
        precision: any [
            precision paths/precision
        ]

        offset: copy [0 0]
        origin: copy [0 0]
        last: _

        out: make string! 16 * length? path  ; approx. pre-allocation

        emit: func [values] [
            append out collect [
                foreach value reduce values [
                    switch type?/word value [
                        char! [
                            keep value
                            last: 'word
                        ]

                        logic! [
                            if find [integer float] last [
                                keep " "
                            ]

                            keep pick [1 0] value
                            last: 'logic
                        ]

                        word! [
                            value: value = 'true

                            if find [integer float] last [
                                keep " "
                            ]

                            keep pick [1 0] value
                            last: 'logic
                        ]

                        float! integer! [
                            value: form-number round/to value precision

                            case [
                                ; can always append negative numbers without padding
                                find/match value "-" [
                                    keep value
                                ]

                                find/match value "." [
                                    if find [integer] last [
                                        keep #" "
                                    ]

                                    keep value
                                ]

                                find [integer float] last [
                                    keep " "
                                    keep value
                                ]

                                <else> [
                                    keep value
                                ]
                            ]

                            last: either find value "." [
                                'float
                            ][
                                'integer
                            ]
                        ]
                    ]
                ]
            ]
        ]

        foreach [command params] path [
            ; note that FORM-PATH creates an SVG path with relative coordinates

            if not command = 'close [
                params: round-params command params precision
            ]

            switch command [
                move [
                    emit [
                        #"m"
                        params/1 - offset/1
                        params/2 - offset/2
                    ]

                    origin/1: offset/1: params/1
                    origin/2: offset/2: params/2
                ]

                hline [
                    emit [
                        #"h"
                        params/1 - offset/1
                    ]

                    offset/1: params/1
                ]

                vline [
                    emit [
                        #"v"
                        params/1 - offset/2
                    ]

                    offset/2: params/1
                ]

                line qcurv [
                    emit [
                        select [line #"l" qcurv #"t"] command
                        params/1 - offset/1 params/2 - offset/2
                    ]

                    offset/1: params/1
                    offset/2: params/2
                ]

                curv qcurve [
                    emit [
                        select [curv #"s" qcurve #"q"] command
                        params/1 - offset/1 params/2 - offset/2
                        params/3 - offset/1 params/4 - offset/2
                    ]

                    offset/1: params/3
                    offset/2: params/4
                ]

                curve [
                    emit [
                        #"c"
                        params/1 - offset/1 params/2 - offset/2
                        params/3 - offset/1 params/4 - offset/2
                        params/5 - offset/1 params/6 - offset/2
                    ]

                    offset/1: params/5
                    offset/2: params/6
                ]

                arc [
                    emit [
                        #"a"
                        params/1 params/2
                        params/3
                        params/4 params/5
                        params/6 - offset/1 params/7 - offset/2
                    ]

                    offset/1: params/6
                    offset/2: params/7
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

    ; experimental, unfinished
    ; would be nice to support TRANSFORM attribute *and* a general ability
    ; to arbitrarily transform shapes, e.g. move shape 100x100 or resize shape 150%
    ;
    apply-transform: func [
        point [pair! block!]
        matrix [block!]
    ][
        point: collect [
            switch type?/word point [
                pair! [
                    keep to float! point/x
                    keep to float! point/y
                ]

                block! [
                    parse point [
                        2 [
                            point: [
                                integer!
                                (keep to float! point/1)
                                |
                                float!
                                (keep point/1)
                            ]
                        ]
                    ]
                ]
            ]
        ]

        if all [
            parse point [2 float!]
            parse matrix [6 number!]
        ][
            reduce [
                (x * matrix/1) + (y * matrix/3) + matrix/5
                (x * matrix/2) + (y * matrix/4) + matrix/6
            ]
        ]
    ]

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

    listify: func [list [block! paren!] /with-comma] [
        with-comma: either with-comma [","] [" "]

        rejoin back change collect [
            forall list [
                keep with-comma

                keep case [
                    number? list/1 [
                        form-number list/1
                    ]

                    issue? list/1 [
                        sanitize mold list/1
                    ]

                    none? list/1 [
                        do make error! rejoin [
                            "Should not be NONE! here: " mold list
                        ]
                    ]

                    <else> [
                        sanitize form list/1
                    ]
                ]
            ]
        ] ""
    ]

    render-precision: 0.001

    render-node: func [
        name [word!]
        attributes [map! none!]
        kids [block! none!]
        /precise
        precision [number!]
        /pretty
        /local out rule attribute part mark
    ][
        open-tags: make block! 8
        render-precision: any [
            precision
            0.001
        ]

        out: make string! 1024

        rule: [
            mark:
            set name word!
            [
                set attributes map!
                |
                lit-underscore
                (attributes: #())
            ]
            [
                ahead set kids block!
                |
                (kids: none)
            ]
            (
                if not any [
                    head? mark  ; first child indenting handled by parent
                    find open-tags 'text
                ][
                    append out newline
                    if pretty [
                        append/dup out "  " length? open-tags
                    ]
                ]

                append out build-tag collect [
                    keep name: switch/default name [
                        group ['g]
                    ][
                        name
                    ]

                    foreach attribute words-of attributes [
                        if not none? attributes/:attribute [
                            keep either find form attribute #"|" [
                                to path! replace form attribute #"|" #"/"
                            ][
                                attribute
                            ]

                            keep case [
                                all [
                                    name = 'path
                                    attribute = 'd
                                    block? attributes/:attribute
                                ][
                                    form-path/precise attributes/:attribute render-precision
                                ]

                                all [
                                    attribute = 'id
                                    issue? attributes/:attribute
                                ][
                                    to string! attributes/:attribute
                                ]

                                all [
                                    ; tranform attribute, others?
                                    block? attributes/:attribute
                                    parse attributes/:attribute [
                                        some [word! paren!]
                                    ]
                                ][
                                    listify/with-comma collect [
                                        parse attributes/:attribute [
                                            some [
                                                copy part [word! paren!]
                                                (
                                                    keep rejoin [
                                                        form part/1 "(" listify part/2 ")"
                                                    ]
                                                )
                                            ]
                                        ]
                                    ]
                                ]

                                all [
                                    attribute = 'transform
                                    parse attributes/:attribute [
                                        copy part [word! some number!]
                                    ]
                                ][
                                    rejoin [
                                        form part/1 "(" form next part ")"
                                    ]
                                ]

                                block? attributes/:attribute [
                                    listify/with-comma attributes/:attribute
                                ]

                                float? part: attributes/:attribute [
                                    if find [x x1 x2 y y1 y2 cx cy dx dy r rx ry width height] attribute [
                                        part: round/to part render-precision
                                    ]

                                    form-number part
                                ]

                                tuple? attributes/:attribute [
                                    form-color attributes/:attribute
                                ]

                                <else> [
                                    attributes/:attribute
                                ]
                            ]
                        ]
                    ]

                    if any [
                        none? kids
                        empty? kids
                    ][
                        keep [/]
                    ]
                ]
            )
            [
                none! | 'none | lit-underscore () | into []
                ; already closed this tag, we're done
                |
                (
                    if not find open-tags 'text [
                        append out newline
                        if pretty [
                            append/dup out "  " 1 + length? open-tags
                        ]
                    ]

                    insert open-tags name
                )
                into [some rule]
                (
                    name: take open-tags

                    if not find open-tags 'text [
                        append out newline
                        if pretty [
                            append/dup out "  " length? open-tags
                        ]
                    ]

                    append out rejoin [
                        "</" name ">"
                    ]
                )
            ]
            |
            ahead lit-word! 'text
            [none! | 'none | lit-underscore]
            set kids string!
            (append out sanitize kids)
            |
            mark:
            (
                do make error! rejoin [
                    "Could not parse document, at: "
                    mold neaten/flat copy/part mark 12
                ]
            )
        ]

        if parse reduce [name attributes kids] rule [
            out
        ]
    ]

    render: func [
        "Convert SVG Model to SVG"
        svg-block [block!] "SVG Model"
        /precise "Constrain numbers to a specified precision"
        precision [number!] "Precision value (see ROUND function's SCALE parameter)"
        /pretty "Use indents on the resultant XML output"
    ][
        render-precision: any [
            precision
            0.001
        ]

        open-tags: make block! 8

        either parse svg-block [
            'svg map! [block! | none!]
        ][
            rejoin [
                render-node/precise/pretty 'svg svg-block/2 svg-block/3 render-precision
            ]
        ][
            do make error! "Not an SVG document"
        ]
    ]

    ; more things to consider:
    ; https://stackoverflow.com/questions/5149301/baking-transforms-into-svg-path-element-commands
    ; wrt. 'apply-transform
]

load-svg: get in svg 'load-svg
to-svg: get in svg 'render

convert-svg: func [
    source [file!]
    /local target content
][
    target: append copy source %.red

    save/header target content: load-svg read source make object! [
        Title: "SVG Converter"
        Date: now/date
    ]

    content
]
