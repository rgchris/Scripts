Rebol [
    Title: "Bincode"
    Author: "Christopher Ross-Gill"
    Date: 22-Jun-2025
    Version: 0.1.0
    File: %bincode.r

    Purpose: "(Un)Pack primitive values from a binary source"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.bincode
    Exports: [
        binary-shift
        signed-8 unsigned-8
        signed-16 unsigned-16
        signed-24 unsigned-24
        signed-32 unsigned-32
        signed-64 float-16
        float-32 float-64
        advance consume accumulate
    ]

    Needs: [
        shim
        r2c:do-with
        r2c:utf-8
    ]

    History: [
        22-Jun-2025 0.1.0
        "Added FLIP-BITS (U8), PARSE, FORM, FORM-SCIENTIFIC, and AS-FRACTION (F64)"

        25-Jan-2024 0.0.6
        "Float Formatter"

        02-Jan-2024 0.0.5
        "Cleaned Up Float-32 Decoder"

        03-Jun-2022 0.0.4
        "Added UTF-8 handlers"

        19-Apr-2022 0.0.3
        "Refactoring of datatype components"

        01-Feb-2022 0.0.2
        "Initial set of export types"

        22-Jan-2022 0.0.1
        "Initial set of import types"
    ]

    Comment: [
        https://grouper.ieee.org/groups/msc/ANSI_IEEE-Std-754-2019/
        https://web.archive.org/web/20230609105818/http://mathcenter.oxford.emory.edu/site/cs170/ieee754/
        https://learn.microsoft.com/en-us/office/troubleshoot/excel/floating-point-arithmetic-inaccurate-result
        https://steve.hollasch.net/cgindex/coding/ieeefloat.html
        "The IEEE 754 Format"

        http://sandbox.mc.edu/~bennet/cs110/flt/index.html
        "Floating-Point Conversion Examples"

        http://www.rebol.org/view-script.r?script=ieee.r
        "Rebol to IEEE-32 FLOAT v0.0.2 Piotr Gapinski"
    ]
]

signed-8: make object! [
    encode: func [
        [catch]
        value [number!]
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < -128 [
                throw make error! "SIGNED-8 target value out of range"
            ]

            value < 128 [
                remove remove remove debase/base to-hex value 16
            ]

            <else> [
                throw make error! "SIGNED-8 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
    ][
        shift shift/left encoding/1 24 24
    ]
]

unsigned-8: make object! [
    encode: func [
        value [number!]
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < 0 [
                throw make error! "UNSIGNED-8 target value out of range"
            ]

            value < 256 [
                remove remove remove debase/base to-hex value 16
            ]

            <else> [
                throw make error! "UNSIGNED-8 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
    ][
        assert [
            not tail? encoding
        ]

        encoding/1
    ]

    flip-bits: func [
        value [integer!]
    ][
        value: (shift value and 240 4) or shift/left value and 15 4
        value: (shift value and 204 2) or shift/left value and 51 2
        (shift value and 170 1) or shift/left value and 85 1
    ]
]

signed-16: make object! [
    encode: func [
        [catch]
        value [number!]
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < -32768 [
                throw make error! "SIGNED-16 target value out of range"
            ]

            value < 32768 [
                remove remove debase/base to-hex value 16
            ]

            <else> [
                throw make error! "SIGNED-16 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le

        /local value
    ][
        assert [
            2 <= length? encoding
        ]

        value: either le [
            add encoding/1 shift/left encoding/2 8
        ][
            add encoding/2 shift/left encoding/1 8
        ]

        ; value << 16 >> 16
        ;
        shift shift/left value 16 16
    ]
]

unsigned-16: make object! [
    encode: func [
        value [number!]
        /le
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < 0 [
                throw make error! "UNSIGNED-16 target value out of range"
            ]

            value > 65535 [
                throw make error! "UNSIGNED-16 target value out of range"
            ]

            le [
                reverse remove remove debase/base to-hex value 16
            ]

            <else> [
                remove remove debase/base to-hex value 16
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le
    ][
        assert [
            2 <= length? encoding
        ]

        value: either le [
            add encoding/1 shift/left encoding/2 8
        ][
            add encoding/2 shift/left encoding/1 8
        ]
    ]
]

signed-24: make object! [
    encode: func [
        [catch]
        value [number!]
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < -8388607 [
                throw make error! "SIGNED-24 target value out of range"
            ]

            value < 8388608 [
                remove debase/base to-hex value 16
            ]

            <else> [
                throw make error! "SIGNED-24 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le

        /local value
    ][
        assert [
            3 <= length? encoding
        ]

        value: either le [
            add add encoding/1 shift/left encoding/2 8 shift/left encoding/3 16
        ][
            add add encoding/3 shift/left encoding/2 8 shift/left encoding/1 16
        ]

        ; value << 16 >> 16
        ;
        shift shift/left value 24 24
    ]
]

unsigned-24: make object! [
    encode: func [
        value [number!]
        /le
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            value < 0 [
                make error! "UNSIGNED-24 target value out of range"
            ]

            value > 16777215 [
                make error! "UNSIGNED-24 target value out of range"
            ]

            le [
                reverse remove debase/base to-hex value 16
            ]

            <else> [
                remove debase/base to-hex value 16
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le
    ][
        assert [
            3 <= length? encoding
        ]

        value: either le [
            add add encoding/1 shift/left encoding/2 8 shift/left encoding/3 16
        ][
            add add encoding/3 shift/left encoding/2 8 shift/left encoding/1 16
        ]
    ]
]

signed-32: make object! [
    encode: func [
        value [number!]
    ][
        if decimal? value [
            value: to integer! value
        ]

        case [
            not number? value [
            ]

            value < -2147483648 [
                throw make error! "SIGNED-32 target value out of range"
            ]

            value <= 2147483647 [
                debase/base to-hex value 16
            ]

            <else> [
                throw make error! "SIGNED-32 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le

        /local value
    ][
        value: copy/part encoding 4

        if le [
            reverse value
        ]

        to integer! value
    ]
]

unsigned-32: make object! [
    encode: func [
        [catch]
        value [number!]
    ][
        case [
            value < 0 [
                throw make error! "UNSIGNED-32 target value out of range"
            ]

            value <= 2147483647 [
                debase/base to-hex to integer! value 16
            ]

            value <= 4294967295 [
                debase/base to-hex to integer! value - 4294967296 16
            ]

            <else> [
                throw make error! "UNSIGNED-32 target value out of range"
            ]
        ]
    ]

    decode: func [
        encoding [binary!]
        /le

        /local value
    ][
        value: copy/part encoding 4

        if le [
            reverse value
        ]

        value: to integer! value

        if negative? value [
            value: 4294967296 + value
        ]

        value
    ]
]

signed-64: make object! [
    ; need encode
    ; float support handles up to 2 * 53 - 1 reliably, enough for many operations

    decode: func [
        encoding [binary!]
        /le

        /local
        has-sign value
    ][
        assert [
            8 <= length? encoding
        ]

        encoding: copy/part encoding 8

        if le [
            reverse encoding
        ]

        if has-sign: not zero? encoding/1 and 128 [
            encoding: complement encoding
        ]

        value:
        add 4294967296.0 * to integer! take/part encoding 4
        add 65536.0 * to integer! take/part encoding 2
        to integer! encoding

        either has-sign [
            -1 - value
        ][
            value
        ]
    ]
]

float-16: make object! [
    encode: func [
        value [number!]

        /local
        sign exponent fraction
    ][
        case [
            zero? value [
                copy #{0000}
            ]

            switch value [
                NaN$1 [
                    value: #{7E00}
                ]

                -NaN$1 [
                    value: #{FE00}
                ]

                INF$1 [
                    value: #{7C00}
                ]

                -INF$1 [
                    value: #{FC00}
                ]
            ][
                copy value
            ]

            <else> [
                sign: either negative? value [#{00008000}] [#{00000000}]
                value: absolute value

                ; separate mandissa / exponent
                ;
                exponent: to integer! log-2 value

                if 1 > fraction: value * power 2 negate exponent [
                    ; not clear why this adjustment is necessary,
                    ; I presume it's an issue where a decimal fraction is not
                    ; well represented in base-2
                    ;
                    exponent: exponent - 1
                    fraction: value * power 2 negate exponent
                ]

                case [
                    exponent < -14 [
                        exponent: 0
                        fraction: round value * 16777216
                        ; 1024 * 16384
                    ]

                    exponent > 15 [
                        exponent: 0
                        fraction: switch sign [
                            #{00008000} [252]
                            #{00000000} [124]
                        ]
                    ]

                    <else> [
                        exponent: exponent + 15
                        fraction: round fraction - 1 * 1024
                    ]
                ]

                fraction: signed-32/encode fraction
                exponent: signed-32/encode shift/left exponent 10

                remove remove sign or fraction or exponent
            ]
        ]
    ]

    decode: func [
        encoding [binary!]

        /local
        value sign exponent mantissa
    ][
        assert [
            value: consume encoding 'unsigned-16
        ]

        switch/default value [
            0
            32768 [
                0.0
            ]

            31744 [
                INF$1
            ]

            64512 [
                -INF$1
            ]
        ][
            sign: power -1 shift value 15
            exponent: 31 and shift value 10
            mantissa: 1023 and value

            switch/default exponent [
                0 [
                    sign * multiply mantissa / 1024 6.103515625E-5
                    ; power 2 -14
                ]

                31 [
                    NaN$1
                ]
            ][
                sign * multiply mantissa / 1024 + 1 power 2 exponent - 15
            ]
        ]
    ]
]

float-32: make object! [
    encode: func [
        value [number!]

        /local
        sign exponent fraction
    ][
        case [
            zero? value [
                copy #{00000000}
            ]

            switch value [
                NaN$1 [
                    value: #{7FC00000}
                ]

                -NaN$1 [
                    value: #{FFC00000}
                ]

                INF$1 [
                    value: #{7F800000}
                ]

                -INF$1 [
                    value: #{FF800000}
                ]
            ][
                copy value
            ]

            <else> [
                sign: either negative? value [#{80}] [#{00}]
                value: absolute value
                exponent: to integer! log-2 value

                ; separate mandissa / exponent
                ;
                if 1 > fraction: value * power 2 negate exponent [
                    ; not clear why this adjustment is necessary,
                    ; I presume it's an issue where a decimal fraction is not
                    ; well represented in base-2
                    ;
                    ; print [<adjusted> num]
                    exponent: exponent - 1
                    fraction: value * power 2 negate exponent
                ]

                assert [
                    2 >= fraction
                    exponent + 127 < 255
                ]

                fraction: signed-32/encode round fraction - 1 * 8388608
                exponent: signed-32/encode round shift/left exponent + 127 23

                sign or fraction or exponent
            ]
        ]
    ]

    decode: func [
        encoding [binary!]

        /local
        value sign exponent mantissa
    ][
        assert [
            value: consume encoding 'signed-32
        ]

        switch/default value [
            0
            -2147483648 [
                0.0
            ]

            2139095040 [
                INF$1
            ]

            -8388608 [
                -INF$1
            ]
        ][
            sign: power -1 shift value 31
            exponent: 255 and shift value 23
            mantissa: 8388607 and value

            either exponent == 255 [
                NaN$1
            ][
                sign * multiply mantissa / 8388608 + 1 power 2 exponent - 127
            ]
        ]
    ]
]

float-64: make object! [
    encode: func [
        value [number!]

        /local
        sign exponent fraction
    ][
        either zero? value [
            copy #{0000000000000000}
        ][
            sign: either negative? value [-2147483648] [0]
            value: absolute value
            exponent: to integer! log-2 value

            if negative? fraction: (value * power 2 negate exponent) - 1 [
                ; not clear why this adjustment is necessary,
                ; I presume it's an issue where a decimal fraction is not
                ; well represented in base-2?
                ;
                exponent: exponent - 1
                fraction: (value * power 2 negate exponent) - 1
            ]

            assert [
                not negative? fraction
                1 >= fraction
                exponent + 1023 < 2047
            ]

            fraction: fraction * power 2 52
            exponent: shift/left exponent + 1023 20

            rejoin [
                signed-32/encode sign or exponent or to integer! fraction / 4294967296
                unsigned-32/encode fraction // 4294967296
            ]
        ]
    ]

    decode: func [
        encoding [binary!]

        /local
        upper lower sign exponent mantissa
    ][
        ; assert [
        ;     8 = length? encoding
        ; ]

        ; Can handle the oversized precision integer as two
        ; smaller numbers: add (val1 and 0x0fffff << 32) val2
        ;
        upper: consume encoding 'signed-32
        lower: consume encoding 'signed-32

        either zero? lower or upper [
            0.0
        ][
            if negative? lower [
                lower: 4294967296 + lower
            ]

            sign: power -1 shift upper 31
            exponent: 2047 and shift upper 20  ; 0x07ff
            mantissa: upper and 1048575 * 4294967296 + lower

            either exponent == 2047 [
                either zero? mantissa [
                    either positive? sign [
                        INF$1
                    ][
                        -INF$1
                    ]
                ][
                    #NaN
                ]
            ][
                sign * multiply mantissa / 4503599627370496 + 1 power 2 exponent - 1023
            ]
        ]
    ]

    parse: use [
        digit one-nine
    ][
        digit: charset "0123456789"
        one-nine: charset "123456789"

        func [
            value [integer! decimal!]
            /local sign integer fraction exponent work part
        ][
            ; note, does not handle 0.0
            ;
            case [
                zero? value [
                    [#[false] 0 "0" ""]
                ]

                system/words/parse/all mold value [
                    ; sign
                    ;
                    [
                        #"-"
                        (sign?: yes)
                        |
                        (sign?: no)
                    ]

                    ; number
                    ;
                    [
                        ; between zero and one
                        ;
                        #"0" #"." [
                            copy exponent some #"0"
                            (exponent: -1 - length? exponent)
                            |
                            (exponent: -1)
                        ]
                        copy integer one-nine
                        [
                            copy fraction some digit
                            |
                            (fraction: copy "")
                        ]
                        |

                        copy integer one-nine [
                            ; decimal form
                            ;
                            copy exponent some digit
                            [
                                #"."
                                [
                                    #"0"
                                    end
                                    (fraction: copy "")
                                    |
                                    copy fraction some digit
                                ]
                                |
                                (fraction: copy "")
                            ]
                            (
                                system/words/parse/all join exponent fraction [
                                    copy fraction some [
                                        any #"0"
                                        some one-nine
                                    ]
                                    any #"0"
                                    |
                                    (fraction: copy "")
                                ]
                                exponent: length? exponent
                            )
                            |

                            ; exponent form (can be single-digit decimal)
                            ;
                            [
                                #"."
                                [
                                    copy fraction [
                                        #"0" some digit
                                    ]
                                    |
                                    #"0"
                                    end
                                    (fraction: copy "")
                                    |
                                    copy fraction some digit
                                ]
                                |
                                (fraction: copy "")
                            ]
                            [
                                #"E"
                                copy exponent [
                                    opt [
                                        #"-" | #"+"
                                    ]

                                    some digit
                                ]
                                (exponent: load exponent)
                                |
                                (exponent: 0)
                            ]
                        ]
                    ]
                ][
                    ; handling E+15 values or numbers with truncated values (like PI)
                    ;
                    if any [
                        15 == exponent
                        13 < length? fraction
                    ][
                        work: multiply absolute value power 10 15 - exponent

                        part: work // 10.0
                        clear find work: mold work - part / 10 #"."

                        append work to integer! part

                        assert [
                            system/words/parse/all work [
                                copy integer one-nine

                                [
                                    copy fraction some [
                                        any #"0"
                                        some one-nine
                                    ]
                                    |
                                    (fraction: "")
                                ]

                                any #"0"
                            ]
                        ]
                    ]

                    reduce [
                        sign? exponent integer fraction
                        ; zero? value // 1.0
                    ]
                ]

                <else> [
                    probe reduce [
                        sign? exponent integer fraction
                    ]

                    make error! rejoin [
                        "Could not parse decimal: " mold mold value
                    ]
                ]
            ]
        ]
    ]

    form: use [
        one-nine
        form
    ][
        one-nine: charset "123456789"

        form: func [
            "Render a decimal! value sans scientific notation"
            value [integer! decimal!]
            /with-decimal
            /debug

            /local parts part work
        ][
            debug: either debug [
                :probe
            ][
                func [value] [value]
            ]

            case [
                zero? value [
                    copy pick ["0.0" "0"] did with-decimal
                ]

                integer? value [
                    rejoin [
                        mold value pick [".0" ""] did with-decimal
                    ]
                ]

                <else> [
                    debug parts: parse debug value

                    case [
                        parts/2 == length? parts/4 [
                            rejoin [
                                pick [#"-" ""] parts/1
                                parts/3
                                parts/4
                                pick [".0" ""] did with-decimal
                            ]
                        ]

                        ; between zero and one
                        ;
                        negative? parts/2 [
                            rejoin [
                                pick [#"-" ""] parts/1
                                "0."
                                (head insert/dup copy "" #"0" negate parts/2 + 1)
                                parts/3
                                parts/4
                            ]
                        ]

                        ; large number
                        ;
                        parts/2 >= length? parts/4 [
                            rejoin [
                                pick [#"-" ""] parts/1
                                parts/3
                                parts/4
                                (head insert/dup copy "" #"0" parts/2 - length? parts/4)
                                pick [".0" ""] did with-decimal
                            ]
                        ]

                        ; guaranteed decimal
                        ;
                        <else> [
                            rejoin [
                                pick [#"-" ""] parts/1
                                parts/3
                                copy/part parts/4 parts/2
                                #"."
                                skip parts/4 parts/2
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

    form-scientific: func [
        value [integer! decimal!]
        /to figures [integer!]
        /local parts
    ][
        parts: parse value

        if to [
            case [
                figures > length? parts/4 [
                    insert/dup tail parts/4 #"0" figures - 1 - length? parts/4
                ]

                figures < length? parts/4 [
                    parts/4: system/words/form round (to-integer copy/part parts/4 figures) / 10
                ]
            ]
        ]

        rejoin [
            pick [#"-" ""] parts/1

            parts/3

            either empty? parts/4 [
                ""
            ][
                join #"." parts/4
            ]

            either zero? parts/2 [
                ""
            ][
                join #"E" parts/2
            ]
        ]
    ]

    exponent-of: func [
        value [decimal!]
    ][
        second parse value
    ]

    as-fraction: func [
        value [number!]
        /precision
        error [decimal!]

        /local sign number lower upper middle
    ][
        error: any [
            error 1E-10
        ]

        number: to integer! value
        value: value - number

        case [
            error > value [
                as-pair number 1
            ]

            1 - error < value [
                as-pair number + 1 1
            ]

            <else> [
                lower: 0x1
                upper: 1x1

                until [
                    middle: lower + upper

                    case [
                        value + error * middle/2 < middle/1 [
                            upper: middle
                            false
                        ]

                        value - error * middle/2 > middle/1 [
                            lower: middle
                            false
                        ]

                        <else> [
                            middle/1: number * middle/2 + middle/1
                            middle
                        ]
                    ]
                ]
            ]
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
    assert [
        binary? source: get :series
    ]

    either offset <= length? source [
        set :series skip source offset
        yes
    ][
        no
    ]
]

consume: func [
    [catch]
    "Extract a value of primitive type from a binary series"

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

                signed-24
                signed-24-le
                unsigned-24
                unsigned-24-le [
                    3
                ]

                long
                signed-32
                signed-32-le
                unsigned-32
                unsigned-32-le
                single
                float-32 [
                    4
                ]

                long-long
                signed-64
                signed-64-le
                unsigned-64
                unsigned-64-le
                double
                float-64 [
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
                    uppercase mold type ": not supported"
                ]
            ]
        ]

        block! [
            length: 0
            part: type
            type: 'batch
        ]
    ]

    throw-on-error [
        assert [
            integer? length
        ]
    ]

    if length > length? source [
        throw make error! "Tried to CONSUME too much data"
    ]

    switch/default type [
        int
        signed-8 [
            advance :series 1
            signed-8/decode source
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
            signed-16/decode source
        ]

        signed-16-le [
            advance :series 2
            signed-16/decode/le source
        ]

        unsigned-16 [
            advance :series 2
            unsigned-16/decode source
        ]

        unsigned-16-le [
            advance :series 2
            unsigned-16/decode/le source
        ]

        signed-24 [
            advance :series 3
            signed-24/decode source
        ]

        signed-24-le [
            advance :series 3
            signed-24/decode/le source
        ]

        unsigned-24 [
            advance :series 3
            unsigned-24/decode source
        ]

        unsigned-24-le [
            advance :series 3
            unsigned-24/decode/le source
        ]

        long
        signed-32 [
            advance :series 4
            signed-32/decode source
        ]

        signed-32-le [
            advance :series 4
            signed-32/decode/le source
        ]

        unsigned-32 [
            advance :series 4
            unsigned-32/decode source
        ]

        unsigned-32-le [
            advance :series 4
            unsigned-32/decode/le source
        ]

        ; does not handle NaN/INF at this point
        ;
        single
        float-32 [
            float-32/decode consume :series 4
        ]

        long-long
        signed-64 [
            signed-64/decode consume :series 8
        ]

        signed-64-le [
            advance :series 8
            signed-64/decode/le source
        ]

        double
        float-64 [
            float-64/decode consume :series 8
        ]

        utf-8 [
            utf-8/character/value: _

            parse/all source utf-8/character/match

            either utf-8/character/value [
                advance :series length
                utf-8/character/value
            ][
                throw make error! "Invalid UTF-8 Sequence"
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
            throw-on-error [
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

                    signed-24: func [
                        /le
                    ][
                        consume :series either le ['signed-24-le] ['signed-24]
                    ]

                    unsigned-24: func [
                        /le
                    ][
                        consume :series either le ['unsigned-24-le] ['unsigned-24]
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

                    utf-8: func [[catch]] [
                        throw-on-error [
                            consume :series 'utf-8
                        ]
                    ]

                    some: func [
                        charset [bitset!]
                        /local mark part
                    ][
                        if parse/all get :series [
                            copy part some charset
                            mark:
                            to end
                        ][
                            set :series as-binary mark
                            as-binary part
                        ]
                    ]

                    parse: func [
                        rules [block!]
                        /local part mark
                    ][
                        if parse/all get :series [
                            copy part rules
                            mark:
                            to end
                        ][
                            set :series as-binary mark
                            part
                        ]
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
                    value: as-binary mold value
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
            either number? value [
                throw-on-error [
                    value: signed-8/encode value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE SIGNED-8 expected number"
            ]
        ]

        byte char
        unsigned-8 [
            either number? value [
                throw-on-error [
                    value: unsigned-8/encode value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE UNSIGNED-8 expected number"
            ]
        ]

        short
        signed-16
        signed-16-le [
            either number? value [
                throw-on-error [
                    value: signed-16/encode value
                ]

                if type == 'signed-16-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE SIGNED-16(-LE) expected number"
            ]
        ]

        unsigned-16
        unsigned-16-le [
            either number? value [
                throw-on-error [
                    value: unsigned-16/encode value
                ]

                if type == 'unsigned-16-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE UNSIGNED-16(-LE) expected number"
            ]
        ]

        signed-24
        signed-24-le [
            either number? value [
                throw-on-error [
                    value: signed-24/encode value
                ]

                if type == 'signed-24-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE SIGNED-24(-LE) expected number"
            ]
        ]

        unsigned-24
        unsigned-24-le [
            either number? value [
                throw-on-error [
                    value: unsigned-24/encode value
                ]

                if type == 'unsigned-24-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE UNSIGNED-24(-LE) expected number"
            ]
        ]

        long
        signed-32
        signed-32-le [
            either number? value [
                throw-on-error [
                    value: signed-32/encode value
                ]

                if type == 'signed-32-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE SIGNED-32 expected number"
            ]
        ]

        unsigned-32
        unsigned-32-le [
            either number? value [
                throw-on-error [
                    value: unsigned-32/encode value
                ]

                if type == 'unsigned-32-le [
                    reverse value
                ]

                insert mark value
            ][
                throw make error! "ACCUMULATE UNSIGNED-32 expected number"
            ]
        ]

        float-32 [
            either number? value [
                insert mark float-32/encode value
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
                insert mark float-64/encode value
            ][
                throw make error! "ACCUMULATE FLOAT-64 expected number"
            ]
        ]

        utf-8 [
            either integer? value [
                insert mark utf-8/encode value
            ][
                throw make error! "ACCUMULATE UTF-8 expected integer"
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

                signed-24: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['signed-24-le] ['signed-24]
                ]

                unsigned-24: func [
                    value [number!]
                    /le
                ][
                    accumulate/as target value either le ['unsigned-24-le] ['unsigned-24]
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

                utf-8: func [
                    value [integer!]
                ][
                    accumulate/as target value 'utf-8
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
