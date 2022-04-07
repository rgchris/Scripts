Rebol [
    Title: "Deflate De/Compression"
    Date: 4-Jan-2022
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/
    File: %deflate.r
    Version: 0.3.2
    Purpose: "DEFLATE de/compression including ZLIB/GZIP envelopes"
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.deflate
    Exports: [
        deflate inflate
        crc32-checksum-of adler32-checksum-of
    ]

    History: [
        07-Apr-2022 0.3.2 "Tweaks to return correct end of compressed stream"
        04-Jan-2022 0.3.0 "Added INFLATE algorithm and wrapper"
        04-Jan-2022 0.2.0 "Added DEFLATE wrapper around COMPRESS"
        25-May-2015 0.1.0 "Rudimentary CRC Routine"
    ]

    Notes: [
        "Tiny Inflate" 'tiny-inflate
        https://github.com/foliojs/tiny-inflate
        https://github.com/jibsen/tinf
        https://gist.github.com/rgchris/d3fb5f6a6ea6d27ea3817c0e697ac25d

        "Other"
        https://www.zlib.net/

        gzip-platform [
            ; no yellow dots
            1 "Amiga" #{01}
            2 "Mac" #{07}
            3 "Windows" #{00}
            4 "Linux/Unix" #{03}
        ]
    ]
]

crc32-checksum-of: use [
    table value
][
    table: collect [
        repeat n 256 [
            value: n - 1

            loop 8 [
                value: either equal? 1 value and 1 [
                    -306674912 xor shift/logical value 1
                    ;
                    ; 0xEDB88320
                ][
                    shift/logical value 1
                ]
            ]

            keep value
        ]
    ]

    func [
        stream [binary!]
    ][
        value: -1

        foreach byte stream [
            value: (shift/logical value 8) xor pick table value and 255 xor byte + 1
        ]

        debase/base to-hex value xor -1 16
    ]
]

adler32-checksum-of: func [
    stream [binary!]
    /local a b remaining cap
][
    a: 1
    b: 0

    cap: 8'388'608  ; 8MB
    remaining: length? stream

    while [remaining > 0] [
        loop min remaining cap [
            a: a + stream/1
            b: a + b

            stream: next stream
        ]

        a: mod a 65521
        b: mod b 65521

        remaining: length? stream
    ]

    b: shift/left b 16

    debase/base to-hex a or b 16
]

deflate: func [
    "Compress data using DEFLATE: https://en.wikipedia.org/wiki/DEFLATE"

    data [binary! string!]
    "Series to compress"

    /envelope
    "Add an envelope with header plus checksum/size information"

    format
    "'zlib (adler32, no size), 'gzip (crc32, uncompressed size), 'legacy"

    /local compressed
][
    compressed: compress data

    switch format [
        #[none] [
            remove remove head clear skip tail compressed -8
        ]

        zlib [
            head clear skip tail compressed -4
        ]

        gzip [
            change skip tail compressed -8 reverse crc32-checksum-of as-binary data

            rejoin [
                #{1F8B08000000000000} #{FF}
                next next compressed
            ]
        ]

        legacy [
            compressed
        ]
    ]
]

tiny-inflate: make object! [
    TINF-OK: 0
    TINF-DATA-ERROR: -3

    new-tree: func [] [
        reduce [
            'table array/initial 16 0  ; table of code length counts
            'translations array/initial 288 0  ; code -> symbol translation
        ]
    ]

    new-encoding: func [
        source
        target
    ][
        make object! compose [
            source: (source)
            index: 0
            tag: 0
            bit-count: 0

            target: (target)
            length: 0

            sym-tree: new-tree  ; dynamic length/symbol tree
            dst-tree: new-tree  ; dynamic distance tree

            debug: false
        ]
    ]

    ; -- uninitialized global data (static structures) --
    ; ---------------------------------------------------
    ;
    static-sym-tree: new-tree
    static-dst-tree: new-tree

    ; extra bits and base tables for length codes
    ;
    length-bits: array/initial 30 0
    length-base: array/initial 30 0  ; Uint16Array

    ; extra bits and base tables for distance codes
    ;
    distance-bits: array/initial 30 0
    distance-base: array/initial 30 0  ; Uint16Array

    ; special ordering of code length codes */
    ;
    code-length-code-index: [
        16 17 18 0 8 7 9 6
        10 5 11 4 12 3 13 2
        14 1 15
    ]

    ; used by decode-trees, avoids allocations every call
    ;
    code-tree: new-tree
    lengths: array/initial 288 + 32 0

    ; -- utility functions --
    ; -----------------------

    ; build extra bits and base tables
    ;
    build-bits-base: func [
        bits [block!]
        base
        delta [integer!]
        start

        /local sum
    ][
        sum: start

        ; build bits table
        ;
        change bits array/initial delta 0

        repeat offset 30 - delta [
            poke bits offset + delta to integer! any [
                attempt [
                    (offset - 1) / delta
                ]

                0
            ]
        ]

        ; build base table
        ;
        repeat offset 30 [
            poke base offset sum
            sum: sum + shift/left 1 bits/:offset
        ]

        ()
    ]

    ; build the fixed huffman trees
    ;
    build-fixed-trees: func [
        sym-tree
        dst-tree
    ][
        ; build fixed-length tree
        ;
        change sym-tree/table [
            0 0 0 0 0 0 0 24 152 112
        ]

        repeat offset 24 [
            poke sym-tree/translations offset 255 + offset
        ]

        repeat offset 144 [
            poke sym-tree/translations 24 + offset offset - 1
        ]

        repeat offset 8 [
            poke sym-tree/translations 24 + 144 + offset 279 + offset
        ]

        repeat offset 112 [
            poke sym-tree/translations 24 + 144 + 8 + offset 143 + offset
        ]

        ; build fixed distance tree
        ;
        change dst-tree/table [
            0 0 0 0 0 32
        ]

        repeat offset 32 [
            poke dst-tree/translations offset offset - 1
        ]

        ()
    ]

    ; given an array of code lengths, build a tree
    ;
    offsets: array/initial 16 0

    build-tree: func [
        tree
        lengths
        start [integer!]
        count [integer!]
        /local sum
    ][
        ; clear code length count table
        ;
        change tree/table array/initial 16 0

        ; scan symbol lengths, and sum code length counts
        ;
        repeat offset count [
            poke tree/table 1 + lengths/(start + offset) 1 + tree/table/(1 + lengths/(start + offset))
        ]

        change tree/table 0

        ; compute offset table for distribution sort
        ;
        sum: 0

        repeat offset 16 [
            poke offsets offset sum
            sum: sum + pick tree/table offset
        ]

        ; create code->symbol translation table (symbols sorted by code)
        ;
        repeat offset count [
            if lengths/(start + offset) > 0 [
                poke tree/translations 1 + offsets/(1 + lengths/(start + offset)) offset - 1
                poke offsets 1 + lengths/(start + offset) 1 + offsets/(1 + lengths/(start + offset))
            ]
        ]

        ()
    ]

    ; -- decode functions --
    ; ----------------------

    ; get one bit from source stream
    ;
    get-bit: func [
        encoding

        /local bit
    ][
        ; check if tag is empty
        ;
        if zero? encoding/bit-count [
            ; load next tag
            ;
            encoding/tag: encoding/source/1
            encoding/bit-count: 8
            encoding/source: next encoding/source
        ]

        encoding/bit-count: encoding/bit-count - 1

        ; shift bit out of tag
        ;
        bit: encoding/tag and 1

        encoding/tag: shift/logical encoding/tag 1

        bit
    ]

    ; read a <length> bit value from a stream and add base
    ;
    read-bits: func [
        encoding
        length [integer!]
        base [integer!]

        /local value
    ][
        either zero? length [
            base
        ][
            while [
                encoding/bit-count < 24
            ][
                encoding/tag: encoding/tag or shift/left any [encoding/source/1 0] encoding/bit-count
                encoding/source: next encoding/source
                encoding/bit-count: encoding/bit-count + 8
            ]

            value: encoding/tag and shift/logical 65535 16 - length

            encoding/tag: shift/logical encoding/tag length
            encoding/bit-count: encoding/bit-count - length

            value + base
        ]
    ]

    ; given a data stream and a tree, decode a symbol
    ;
    decode-symbol: func [
        encoding
        tree
        /local sum current length tag
    ][
        while [
            encoding/bit-count < 24
        ][
            encoding/tag: encoding/tag or shift/left any [encoding/source/1 0] encoding/bit-count
            encoding/source: next encoding/source
            encoding/bit-count: encoding/bit-count + 8
        ]

        sum: 0
        current: 0
        length: 0
        tag: encoding/tag

        ; get more bits while code value is above sum
        ;
        until [
            current: 2 * current + (tag and 1)
            tag: shift/logical tag 1
            length: length + 1

            sum: sum + pick tree/table length + 1
            current: current - pick tree/table length + 1

            current < 0
        ]

        encoding/tag: tag
        encoding/bit-count: encoding/bit-count - length

        pick tree/translations sum + current + 1
    ]

    ; given a data stream, decode dynamic trees from it
    ;
    decode-trees: func [
        encoding
        sym-tree
        dst-tree

        /local
        lengths-count distances-count code-lengths-count
        count length
        code-length symbol prev
    ][
        ; get 5 bits HLIT (257-286)
        ;
        lengths-count: read-bits encoding 5 257

        ; get 5 bits HDIST (1-32)
        ;
        distances-count: read-bits encoding 5 1

        ; get 4 bits HCLEN (4-19)
        ;
        code-lengths-count: read-bits encoding 4 4

        change lengths array/initial 19 0

        ; read code lengths for code length alphabet
        ;
        repeat offset code-lengths-count [
            ; get 3 bits code length (0-7)
            ;
            code-length: read-bits encoding 3 0

            poke lengths code-length-code-index/:offset + 1 code-length
        ]

        ; build code length tree
        ;
        build-tree code-tree lengths 0 19

        ; decode code lengths for the dynamic trees
        ;
        count: 1

        while [
            count < (lengths-count + distances-count + 1)
        ][
            symbol: decode-symbol encoding code-tree

            switch/default symbol [
                16 [
                    ; copy previous code length 3-6 times (read 2 bits)
                    ;
                    prev: pick lengths count - 1
                    length: read-bits encoding 2 3

                    while [
                        length > 0
                    ][
                        poke lengths count prev

                        count: count + 1
                        length: length - 1
                    ]
                ]

                17 [
                    ; repeat code length 0 for 3-10 times (read 3 bits)
                    ;
                    length: read-bits encoding 3 3

                    while [
                        length > 0
                    ][
                        poke lengths count 0

                        count: count + 1
                        length: length - 1
                    ]
                ]

                18 [
                    ; repeat code length 0 for 11-138 times (read 7 bits)
                    ;
                    length: read-bits encoding 7 11

                    while [
                        length > 0
                    ][
                        poke lengths count 0

                        count: count + 1
                        length: length - 1
                    ]
                ]
            ][
                ; values 0-15 represent the actual code lengths
                ;
                poke lengths count symbol
                count: count + 1
            ]
        ]

        ; build dynamic trees
        ;
        build-tree sym-tree lengths 0 lengths-count
        build-tree dst-tree lengths lengths-count distances-count

        ()
    ]

    ; -- block inflate functions --
    ; -----------------------------

    ; given a stream and two trees, inflate a block of data
    ;
    inflate-block-data: func [
        encoding
        sym-tree
        dst-tree

        /local
        symbol length distance offset
    ][
        until [
            symbol: decode-symbol encoding sym-tree

            case [
                symbol == 256 [
                    TINF-OK
                ]
                
                symbol < 256 [
                    append encoding/target to char! symbol

                    false
                ]

                <else> [
                    symbol: 1 + symbol - 257
                    ; + 1 for 1-based indexing

                    ; possibly get more bits from length code
                    ;
                    length: read-bits encoding length-bits/:symbol length-base/:symbol

                    distance: 1 + decode-symbol encoding dst-tree
                    ; + 1 for 1-based indexing

                    ; possibly get more bits from distance code
                    ;
                    offset: length? encoding/target

                    offset: offset - read-bits encoding distance-bits/:distance distance-base/:distance

                    ; copy match
                    ;
                    repeat char length [
                        append encoding/target to char! pick encoding/target offset + char
                    ]

                    false
                ]
            ]
        ]
    ]

    ; inflate an uncompressed block of data
    ;
    inflate-uncompressed-block: func [
        encoding

        /local length inverse-length
    ][
        ; unread from bitbuffer
        ;
        while [
            encoding/bit-count > 8
        ][
            encoding/source: back encoding/source
            encoding/bit-count: encoding/bit-count - 8
        ]

        ; get length
        ;
        length: 256 * encoding/source/2 + encoding/source/1

        ; get one's complement of length
        ;
        inverse-length: 256 * encoding/source/4 + encoding/source/3

        ; check length
        ;
        either inverse-length xor 65535 == length [
            encoding/source: skip encoding/source 4

            assert [
                length <= length? encoding/source
            ]

            ; copy block
            ;
            loop length [
                append encoding/target to char! encoding/source/1
                encoding/source: next encoding/source
            ]

            ; make sure we start next block on a byte boundary
            ;
            encoding/bit-count: 0

            TINF-OK
        ][
            TINF-DATA-ERROR
        ]
    ]

    ; inflate stream from source to target
    ;
    uncompress: func [
        source target
        /debug

        /local
        encoding type-block is-unpacked is-last-block
    ][
        encoding: new-encoding source target

        if any [
            debug
            512 > length? source
        ] [
            encoding/debug: true
        ]

        until [
            ; read final block flag
            ;
            is-last-block: 1 == get-bit encoding

            ; read block type (2 bits)
            ;
            type-block: read-bits encoding 2 0

            ; decompress block
            ;
            is-unpacked: switch/default type-block [
                0 [
                    ; Decompress an uncompressed block
                    ;
                    inflate-uncompressed-block encoding
                ]

                1 [
                    ; Decompress a block with fixed huffman trees
                    ;
                    inflate-block-data encoding static-sym-tree static-dst-tree
                ]

                2 [
                    ; decompress block with dynamic huffman trees
                    ;
                    decode-trees encoding encoding/sym-tree encoding/dst-tree

                    inflate-block-data encoding encoding/sym-tree encoding/dst-tree
                ]
            ][
                TINF-DATA-ERROR
            ]

            if is-unpacked <> TINF-OK [
                make error! "DEFLATE stream integrity error"
            ]

            is-last-block
        ]

        ; reset source position
        ;
        while [
            encoding/bit-count > 8
        ][
            encoding/source: back encoding/source
            encoding/bit-count: encoding/bit-count - 8
        ]

        reduce [
            encoding/target encoding/source
        ]
    ]

    ; -- initialization --
    ; --------------------

    ; build fixed huffman trees
    ;
    build-fixed-trees static-sym-tree static-dst-tree

    ; build extra bits and base tables
    ;
    build-bits-base length-bits length-base 4 3
    build-bits-base distance-bits distance-base 2 1

    ; fix a special case
    ;
    length-bits/29: 0
    length-base/29: 258
]

inflate: func [
    [catch]
    "Decompress DEFLATE data: https://en.wikipedia.org/wiki/DEFLATE"

    data [binary!]
    "Series to decompress"

    /max
    bound
    "Error out if result is larger than this"

    /envelope
    "Expect (and verify) envelope with header/CRC/size information"

    format [word!]
    "ZLIB, GZIP, or LEGACY"

    /local remaining size flags
][
    switch format [
        #[none] [
            first tiny-inflate/uncompress data copy #{}
        ]

        ; wrappers
        ;
        zlib [
            case [
                8 > length? data [
                    throw make error! "ZLIB wrapper too small"
                ]

                data/1 and 15 <> 8 [
                    throw make error! "ZLIB sequence does not contain DEFLATE-compressed data"
                ]

                data/1 > 120 [
                    throw make error! "ZLIB window size too large"
                ]

                error? try [
                    data: skip data pick [2 6] zero? data/2 and 32
                    set [data remaining] tiny-inflate/uncompress data make binary! 1024
                ][
                    throw make error! "Inflate error"
                ]

                not find/match remaining adler32-checksum-of data [
                    throw make error! "Inflate ZLIB checksum fail"
                ]

                <else> [
                    data
                ]
            ]
        ]

        gzip [
            case [
                not parse/all data [
                    #{1F8B08} 7 skip data: 8 skip to end
                    (data: as-binary data)
                ][
                    throw make error! "Missing GZIP header"
                ]
                
                not integer? size: to integer! reverse copy skip tail data -4 [
                    throw make error! "Inflate: Should not happen"
                ]

                error? try [
                    set [data remaining] tiny-inflate/uncompress data make binary! size
                ][
                    throw make error! "Inflate error"
                ]

                not find/match remaining reverse crc32-checksum-of data [
                    throw make error! "Inflate GZIP checksum fail"
                ]

                <else> [
                    data
                ]
            ]
        ]

        legacy [
            as-binary decompress data
        ]
    ]
]
