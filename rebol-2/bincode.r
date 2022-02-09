Rebol [
    Title: "Bincode"
    Author: "Christopher Ross-Gill"
    Date: 1-Feb-2022
    Home: https://github.com/rgchris/Scripts
    File: %bincode.r
    Version: 0.0.2
    Rights: http://opensource.org/licenses/Apache-2.0
    Purpose: {
        (Un)Pack primitive values from a binary source
    }

    Type: 'module
    Name: 'rgchris.bincode
    Exports: [
        advance consume accumulate
    ]

    History: [
        01-Feb-2022 0.0.2 "Initial set of export types"
        22-Jan-2022 0.0.1 "Initial set of import types"
    ]

    Notes: [
        http://mathcenter.oxford.emory.edu/site/cs170/ieee754/
        "The IEEE 754 Format"

        http://sandbox.mc.edu/~bennet/cs110/flt/index.html
        "Floating-Point Conversion Examples"

        http://www.rebol.org/view-script.r?script=ieee.r
        "Rebol to IEEE-32 FLOAT v0.0.2 Piotr Gapinski"
    ]
]

do %do-with.r

assert-all: func [
    conditions
][
    assert reduce [
        'all conditions
    ]
]

as-signed-32: func [
    value [number!]
][
    if decimal? value [
        value: to integer! value
    ]

    debase/base to-hex value 16
]

load-unsigned-32: func [
    source [binary!]
    /le
    /local value
][
    value: copy/part source 4

    if le [
        reverse value
    ]

    value: to integer! value

    if negative? value [
        value: 4294967296.0 + value
    ]

    value
]

as-unsigned-32: func [
    [catch]
    value [number!]
][
    case [
        value < 0 [
            throw make error! "Number overflow"
        ]

        value <= 2147483647 [
            as-signed-32 to integer! value
        ]

        value <= 4294967295 [
            as-signed-32 to integer! value - 4294967296
        ]

        <else> [
            throw make error! "Number overflow"
        ]
    ]
]

load-signed-64: func [
    source [binary!]
    /le
    /local has-sign value
][
    assert [
        8 <= length? source
    ]

    source: copy/part source 8

    if le [
        reverse source
    ]

    if has-sign: not zero? source/1 and 128 [
        source: complement source
    ]

    value:
    add 4294967296.0 * to integer! take/part source 4
    add 65536.0 * to integer! take/part source 2
    to integer! source

    either has-sign [
        -1 - value
    ][
        value
    ]
]

load-float-32: func [
    source [binary!]
    /local value part
][
    assert [
        4 = length? source
    ]

    value: to integer! source

    part: reduce [
        ; exp: 8 frac: 23
        ; 127 = 2 ** (exp - 1) - 1
        ; 8388608 = 2 ** frac
        ;

        ; -1 ^^ sign
        ;
        power -1 shift source/1 7

        ; 1 + fraction
        ;
        add 1 value and 8388607 / 8388608

        ; exp - bias
        ;
        subtract 255 and shift value 23 127
    ]

    case [
        [1 -127] = next part [
            0.0
        ]

        ; ... NaN / Inf handlers here ...

        <else> [
            part/1 * part/2 * power 2 part/3
        ]
    ]
]

as-float-32: func [
    value [number!]
    /local sign exponent fraction
][
    either zero? value [
        #{00000000}
    ][
        sign: either negative? value [#{80}] [#{00}]
        value: abs value
        exponent: to integer! log-2 value

        if 1 > fraction: value * power 2 negate exponent [
            ; not clear why this adjustment is necessary,
            ; I presume it's an issue where a decimal fraction is not
            ; well represented in base-2
            ;
            ; print [<adjusted> num]
            exponent: exponent - 1
            fraction: value * power 2 negate exponent
        ]

        assert-all [
            2 >= fraction
            exponent + 127 < 255
        ]

        fraction: as-signed-32 round fraction - 1 * 8388608
        exponent: as-signed-32 round shift/left exponent + 127 23

        sign or fraction or exponent
    ]
]

load-float-64: func [
    source [binary!]
    /local value part
][
    assert [
        8 = length? source
    ]

    ; Can handle the oversized precision integer as two
    ; smaller numbers: add (val1 and 0x0fffff) val2
    ;
    value: consume source [
        reduce [
            source/1 signed-32 unsigned-32
        ]
    ]

    part: reduce [
        ; exp: 11 frac: uint 52 (20 + 32)
        ; bias: 1023 = 2 ** (exp - 1) - 1
        ; 1048576 = 2 ** frac  ; first part
        ;
        ; -1 ^^ sign
        ;
        power -1 shift value/1 7

        ; 1 + fraction
        ;
        add 1 value/2 and 1048575 * 4294967296.0 + value/3 / power 2 52

        ; exp - bias
        ;
        subtract 2047 and shift value/2 20 1023
    ]

    case [
        [1 -1023] = next part [
            0.0
        ]

        ; ... NaN / Inf handlers here ...

        <else> [
            part/1 * part/2 * power 2 part/3
        ]
    ]
]

as-float-64: func [
    value [number!]
    /local sign exponent fraction
][
    either zero? value [
        #{0000000000000000}
    ][
        sign: either negative? value [#{80}] [#{00}]
        value: abs value
        exponent: to integer! log-2 value

        if 1 > fraction: value * power 2 negate exponent [
            ; not clear why this adjustment is necessary,
            ; I presume it's an issue where a decimal fraction is not
            ; well represented in base-2?
            ;
            exponent: exponent - 1
            fraction: value * power 2 negate exponent
        ]

        assert-all [
            1 <= fraction
            2 > fraction
            exponent + 1023 < 2047
        ]

        fraction: fraction - 1 * power 2 52
        exponent: as-signed-32 round shift/left exponent + 1023 20

        sign or exponent or rejoin [
            as-signed-32 to integer! fraction / 4294967296
            as-unsigned-32 mod fraction 4294967296
        ]
    ]
]

advance: func [
    "Adjust word assigned to a binary value"

    'series [word!]
    "Word assigned to source binary"

    offset [integer!]
    "Offset from current binary index"

    /local
    source
][
    either all [
        binary? source: get :series
        offset <= length? source
    ][
        set :series skip source offset
        yes
    ][
        no
    ]
]

consume: func [
    [catch]
    "Extract a value of specified type from a binary series"

    'series [word!]
    "Word assigned to source binary"

    type [word! integer! binary! block!]
    "Value type or batch of value types"

    /local
    source part value length
][
    assert [
        binary? source: get :series
    ]

    switch type?/word type [
        integer! [
            length: type
            type: 'part
        ]

        binary! [
            length: length? type
            part: type
            type: 'match
        ]

        word! [
            length: switch/default type [
                int
                byte
                char
                signed-8
                unsigned-8 [
                    1
                ]

                short
                signed-16
                signed-16-le
                unsigned-16
                unsigned-16-le [
                    2
                ]

                long
                float-32
                signed-32
                signed-32-le
                unsigned-32
                unsigned-32-le [
                    4
                ]

                long-long
                double
                float-64
                signed-64
                signed-64-le
                unsigned-64
                unsigned-64-le [
                    8
                ]

                utf-8 [
                    case [
                        tail? source [0]
                        source/1 < 127 [1]
                        source/1 < 194 [0]
                        source/1 < 224 [2]
                        source/1 < 240 [3]
                        source/1 < 245 [4]
                        <else> [0]
                    ]
                ]
            ][
                throw make error! rejoin [
                    uppercase form type ": not supported"
                ]
            ]
        ]

        block! [
            length: 0
            part: type
            type: 'batch
        ]
    ]

    assert [
        integer? length
    ]

    switch/default type [
        int
        signed-8 [
            advance :series 1

            shift shift/left source/1 24 24
        ]

        byte
        unsigned-8 [
            advance :series 1

            source/1
        ]

        char [
            advance :series 1

            to char! source/1
        ]

        short
        signed-16 [
            advance :series 2

            ; value << 16 >> 16
            ;
            shift shift/left add source/2 shift/left source/1 8 16 16
        ]

        signed-16-le [
            advance :series 2

            shift shift/left add source/1 shift/left source/2 8 16 16
        ]

        unsigned-16 [
            advance :series 2

            add source/2 shift/left source/1 8
        ]

        unsigned-16-le [
            advance :series 2

            add source/1 shift/left source/2 8
        ]

        long
        signed-32 [
            advance :series 4

            add source/4
            add shift/left source/3 8
            add shift/left source/2 16
            shift/left source/1 24
        ]

        signed-32-le [
            advance :series 4

            add source/1
            add shift/left source/2 8
            add shift/left source/3 16
            shift/left source/4 24
        ]

        unsigned-32 [
            advance :series 4
            load-unsigned-32 source
        ]

        unsigned-32-le [
            advance :series 4
            load-unsigned-32/le source
        ]

        ; does not handle NaN/INF at this point
        ;
        float-32 [
            load-float-32 consume :series 4
        ]

        long-long
        signed-64 [
            load-signed-64 consume :series 8
        ]

        signed-64-le [
            advance :series 8

            load-signed-64/le source
        ]

        float-64 [
            load-float-64 consume :series 8
        ]

        utf-8 [
            switch/default length [
                0 []
            ]
        ]

        match [
            if find/match source part [
                advance :series length
                part
            ]
        ]

        part [
            assert [
                advance :series length
            ]

            copy/part source length
        ]

        batch [
            do-with part [
                le: true
                be: false

                signed-8: func [] [
                    consume :series 'signed-8
                ]

                unsigned-8: func [] [
                    consume :series 'unsigned-8
                ]

                signed-16: func [
                    /le
                ][
                    consume :series either le ['signed-16-le] ['signed-16]
                ]

                unsigned-16: func [
                    /le
                ][
                    consume :series either le ['unsigned-16-le] ['unsigned-16]
                ]

                signed-32: func [
                    /le
                ][
                    consume :series either le ['signed-32-le] ['signed-32]
                ]

                unsigned-32: func [
                    /le
                ][
                    consume :series either le ['unsigned-32-le] ['unsigned-32]
                ]

                float-32: func [] [
                    consume :series 'float-32
                ]

                signed-64: func [
                    /le
                ][
                    consume :series either le ['signed-64-le] ['signed-64]
                ]

                float-64: func [] [
                    consume :series 'float-64
                ]

                consume: func [
                    value [binary! integer!]
                ][
                    consume :series value
                ]

                advance: func [
                    value [integer!]
                ][
                    advance :series value
                ]

                get-offset: func [] [
                    get :series
                ]

                set-offset: func [
                    position [binary!]
                ][
                    set :series position
                ]
            ]
        ]
    ][
        throw make error! "Consumable type not yet supported"
    ]
]

accumulate: func [
    [catch]
    "Append values to a binary series"

    target [binary!]
    "Binary to append to"

    value
    "Value or batch of values to append"

    /as type [word!]
    "Use a specific value type"

    /local
    mark
][
    mark: tail target

    case [
        block? value [
            type: 'batch
        ]

        type = 'batch [
            throw make error! "Batch Accumulation by block! only"
        ]

        not type [
            switch/default type?/word value [
                integer! [
                    type: 'signed-32
                ]

                decimal! [
                    type: 'float-64
                ]

                money! [
                    type: 'float-64
                    value: to decimal! value
                    ; future BCD?
                ]

                char! [
                    type: 'unsigned-8
                ]

                binary! [
                    type: 'part
                ]

                string! [
                    type: 'part
                    value: as-binary value
                ]

                issue! url! email! tag! [
                    type: 'part
                    value: as-binary form value
                ]

                tuple! [
                    type: 'part
                    value: to binary! part
                ]
            ][
                throw make error! "Cannot accumulate value"
            ]
        ]
    ]

    switch type [
        int
        signed-8 [
            case [
                not number? value [
                    throw make error! "ACCUMULATE SIGNED-8 expected number"
                ]

                value < -128 [
                    throw make error! "Signed-8 out of range"
                ]

                value < 0 [
                    insert mark to char! 256 + value
                ]

                value < 128 [
                    insert mark to char! value
                ]

                <else> [
                    throw make error! "SIGNED-8 value out of range"
                ]
            ]
        ]

        byte char
        unsigned-8 [
            case [
                not number? value [
                    throw make error! "ACCUMULATE UNSIGNED-8 expected number"
                ]

                value < 0 [
                    throw make error! "UNSIGNED-8 value out of range"
                ]

                value < 256 [
                    insert mark to char! value
                ]

                <else> [
                    throw make error! "UNSIGNED-8 value out of range"
                ]
            ]
        ]

        short
        signed-16
        signed-16-le [
            case [
                not number? value [
                    throw make error! "ACCUMULATE SIGNED-16(-LE) expected number"
                ]

                value < -32768 [
                    throw make error! "Signed-16 out of range"
                ]

                value < 0 [
                    value: remove remove as-signed-32 65536 - value

                    if type = 'signed-16-le [
                        reverse value
                    ]

                    insert mark value
                ]

                value < 32768 [
                    value: remove remove as-signed-32 value

                    if type = 'signed-16-le [
                        reverse value
                    ]

                    insert mark value
                ]

                <else> [
                    throw make error! "SIGNED-16 value out of range"
                ]
            ]
        ]

        unsigned-16
        unsigned-16-le [
            case [
                not number? value [
                    throw make error! "ACCUMULATE UNSIGNED-16 expected number"
                ]

                value < 0 [
                    throw make error! "UNSIGNED-16 value out of range"
                ]

                value < 65536 [
                    value: remove remove as-signed-32 value

                    if type = 'unsigned-16-le [
                        reverse value
                    ]

                    insert mark value
                ]

                <else> [
                    throw make error! "UNSIGNED-16 value out of range"
                ]
            ]
        ]

        long
        signed-32
        signed-32-le [
            case [
                not number? value [
                    throw make error! "ACCUMULATE SIGNED-32 expected number"
                ]

                value < -2147483648 [
                    throw make error! "SIGNED-32 value out of range"
                ]

                value <= 2147483647 [
                    value: as-signed-32 value

                    if type = 'signed-32-le [
                        reverse value
                    ]

                    insert mark value
                ]

                <else> [
                    throw make error! "SIGNED-32 value out of range"
                ]
            ]
        ]

        unsigned-32
        unsigned-32-le [
            case [
                not number? value [
                    throw make error! "ACCUMULATE UNSIGNED-32 expected number"
                ]

                value < 0 [
                    throw make error! "UNSIGNED-32 value out of range"
                ]

                value < 4294967296 [
                    value: as-unsigned-32 value

                    if type = 'unsigned-32-le [
                        reverse value
                    ]

                    insert mark value
                ]

                <else> [
                    throw make error! "UNSIGNED-32 value out of range"
                ]
            ]
        ]

        float-32 [
            either number? value [
                insert mark as-float-32 value
            ][
                throw make error! "ACCUMULATE FLOAT-32 expected number"
            ]
        ]

        long-long
        signed-64
        signed-64-le [
            throw make error! "64-bit numbers not yet supported"
        ]

        float-64 [
            either number? value [
                insert mark as-float-64 value
            ][
                throw make error! "ACCUMULATE FLOAT-64 expected number"
            ]
        ]

        part [
            either binary? value [
                insert mark value
            ][
                throw make error! "ACCUMULATE PART expected binary"
            ]
        ]

        batch [
            assert [
                block? value
            ]

            do-with value [
                signed-8: func [
                    value [number!]
                ][
                    accumulate/as target value 'signed-8
                ]

                unsigned-8: func [
                    value [number!]
                ][
                    accumulate/as target value 'unsigned-8
                ]

                signed-16: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['signed-16-le] ['signed-16]
                ]

                unsigned-16: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['unsigned-16-le] ['unsigned-16]
                ]

                signed-32: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['signed-32-le] ['signed-32]
                ]

                unsigned-32: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['unsigned-32-le] ['unsigned-32]
                ]

                float-32: func [
                    value [number!]
                ][
                    accumulate/as target value 'float-32
                ]

                signed-64: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['signed-64-le] ['signed-64]
                ]

                float-64: func [
                    value [number!]
                ][
                    accumulate/as target value 'float-64
                ]

                accumulate: func [
                    value
                ][
                    accumulate target value
                ]

                get-mark: func [] [
                    tail target
                ]

                accumulate-to: func [
                    mark [binary!]
                ][
                    target: mark
                ]
            ]
        ]
    ]

    mark
]
