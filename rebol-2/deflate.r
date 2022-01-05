Rebol [
    Title: "Deflate De/Compression"
    Date: 4-Jan-2022
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/
    File: %deflate.r
    Version: 0.3.0
    Purpose: "DEFLATE de/compression including ZLIB/GZIP envelopes"
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.deflate
    Exports: [
        deflate inflate
        crc32-checksum-of adler32-checksum-of
    ]

    History: [
        04-Jan-2022 0.3.0 "Added INFLATE algorithm and wrapper"
        04-Jan-2022 0.2.0 "Added DEFLATE wrapper around COMPRESS"
        25-May-2015 0.1.0 "Rudimentary CRC Routine"
    ]

    Notes: [
        "Tiny Inflate" 'tinf
        https://github.com/foliojs/tiny-inflate
        https://github.com/jibsen/tinf

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
    /local a b
][
    a: 1
    b: 0

    forall stream [
        a: a + stream/1
        b: a + b
    ]

    a: mod a 65521
    b: shift/left mod b 65521 16

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

tinf: make object! [
    [
        Title: "Tiny Inflate"
        Date: 10-Dec-2021
        Author: "Christopher Ross-Gill"
        Version: 1.0.3
        Type: 'module
        Name: 'rgchris.inflate
        Exports: [inflate]
        History: [
            10-Dec-2021 1.0.3 https://github.com/foliojs/tiny-inflate
            10-Dec-2021 1.0.3 "Original transcription from JavaScript"
        ] 
    ]

    TINF-OK: 0
    TINF-DATA-ERROR: -3

    new-tree: func [] [
        reduce [
            'table array/initial 16 0  ; table of code length counts
            'trans array/initial 288 0  ; code -> symbol translation
        ]
    ]

    new-data: func [
        source
        target
    ][
        make object! compose [
            source: (source)
            index: 0
            tag: 0
            bitcount: 0

            target: (target)
            length: 0

            ltree: new-tree  ; dynamic length/symbol tree
            dtree: new-tree  ; dynamic distance tree
        ]
    ]


    ; -- uninitialized global data (static structures) --
    ; ---------------------------------------------------

    sltree: new-tree
    sdtree: new-tree

    ; extra bits and base tables for length codes
    ;
    length-bits: array/initial 30 0
    length-base: array/initial 30 0  ; Uint16Array

    ; extra bits and base tables for distance codes
    ;
    dist-bits: array/initial 30 0
    dist-base: array/initial 30 0  ; Uint16Array

    ; special ordering of code length codes */
    ;
    clcidx: [
        16 17 18 0 8 7 9 6
        10 5 11 4 12 3 13 2
        14 1 15
    ]

    ; used by tinf-decode-trees, avoids allocations every call
    ;
    code-tree: new-tree
    lengths: array/initial 288 + 32 0

    ; -- utility functions --
    ; -----------------------

    ; build extra bits and base tables
    ;
    tinf-build-bits-base: func [
        bits [block!]
        base
        delta [integer!]
        first
        /local sum
    ][
        sum: first

        ; build bits table
        ;
        change bits array/initial delta 0

        repeat i 30 - delta [
            poke bits i + delta to integer! any [
                attempt [(i - 1) / delta]
                0
            ]
        ]

        ; build base table
        ;
        repeat i 30 [
            poke base i sum
            sum: sum + shift/left 1 bits/:i
        ]

        ()
    ]

    ; build the fixed huffman trees
    ;
    tinf-build-fixed-trees: func [
        lt
        dt
    ][
        ; build fixed-length tree
        ;
        change lt/table [
            0 0 0 0 0 0 0 24 152 112
        ]

        repeat i 24 [
            poke lt/trans i 255 + i
        ]

        repeat i 144 [
            poke lt/trans 24 + i i - 1
        ]

        repeat i 8 [
            poke lt/trans 24 + 144 + i 279 + i
        ]

        repeat i 112 [
            poke lt/trans 24 + 144 + 8 + i 143 + i
        ]

        ; build fixed distance tree
        ;
        change dt/table [
            0 0 0 0 0 32
        ]

        repeat i 32 [
            poke dt/trans i i - 1
        ]

        ()
    ]

    ; given an array of code lengths, build a tree
    ;
    offs: array/initial 16 0

    tinf-build-tree: func [
        t
        lengths
        off
        num
        /local sum
    ][
        ; clear code length count table
        ;
        change t/table array/initial 16 0

        ; scan symbol lengths, and sum code length counts
        ;
        repeat i num [
            poke t/table 1 + lengths/(off + i) 1 + t/table/(1 + lengths/(off + i))
        ]

        change t/table 0

        ; compute offset table for distribution sort
        ;
        sum: 0

        repeat i 16 [
            poke offs i sum
            sum: sum + pick t/table i
        ]

        ; create code->symbol translation table (symbols sorted by code)
        ;
        repeat i num [
            if lengths/(off + i) > 0 [
                poke t/trans 1 + offs/(1 + lengths/(off + i)) i - 1
                poke offs 1 + lengths/(off + i) 1 + offs/(1 + lengths/(off + i))
            ]
        ]

        ()
    ]

    ; -- decode functions --
    ; ----------------------

    ; get one bit from source stream
    ;
    tinf-getbit: func [
        d
        /local bit
    ][
        ; check if tag is empty
        ;
        if zero? d/bitcount [
            ; load next tag
            ;
            d/tag: d/source/1
            d/bitcount: 8
            d/source: next d/source
        ]

        d/bitcount: d/bitcount - 1

        ; shift bit out of tag
        bit: d/tag and 1
        d/tag: shift/logical d/tag 1

        bit
    ]

    ; read a num bit value from a stream and add base
    ;
    tinf-read-bits: func [
        d
        num [integer!]
        base
        /local val
    ][
        either zero? num [
            base
        ][
            while [
                d/bitcount < 24
            ][
                d/tag: d/tag or shift/left any [d/source/1 0] d/bitcount
                d/source: next d/source
                d/bitcount: d/bitcount + 8
            ]

            val: d/tag and shift/logical 65535 16 - num
            d/tag: shift/logical d/tag num
            d/bitcount: d/bitcount - num

            val + base
        ]
    ]

    ; given a data stream and a tree, decode a symbol
    ;
    tinf-decode-symbol: func [
        d
        t
        /local sum cur len tag
    ][
        while [
            d/bitcount < 24
        ][
            d/tag: d/tag or shift/left any [d/source/1 0] d/bitcount
            d/source: next d/source
            d/bitcount: d/bitcount + 8
        ]

        sum: 0
        cur: 0
        len: 0
        tag: d/tag


        ; get more bits while code value is above sum
        ;
        until [
            cur: 2 * cur + (tag and 1)
            tag: shift/logical tag 1
            len: len + 1

            sum: sum + pick t/table len + 1
            cur: cur - pick t/table len + 1

            cur < 0
        ]

        d/tag: tag
        d/bitcount: d/bitcount - len

        pick t/trans sum + cur + 1
    ]

    ; given a data stream, decode dynamic trees from it
    ;
    tinf-decode-trees: func [
        d
        lt
        dt
        /local
        hlit hdist hclen
        num length
        clen sym prev
    ][
        ; get 5 bits HLIT (257-286)
        ;
        hlit: tinf-read-bits d 5 257

        ; get 5 bits HDIST (1-32)
        ;
        hdist: tinf-read-bits d 5 1

        ; get 4 bits HCLEN (4-19)
        ;
        hclen: tinf-read-bits d 4 4

        change lengths array/initial 19 0

        ; read code lengths for code length alphabet
        ;
        repeat i hclen [
            ; get 3 bits code length (0-7)
            ;
            clen: tinf-read-bits d 3 0
            poke lengths clcidx/:i + 1 clen
        ]

        ; build code length tree
        tinf-build-tree code-tree lengths 0 19

        ; decode code lengths for the dynamic trees
        num: 1

        while [num < (hlit + hdist + 1)] [
            sym: tinf-decode-symbol d code-tree

            switch/default sym [
                16 [
                    ; copy previous code length 3-6 times (read 2 bits)
                    ;
                    prev: pick lengths num - 1
                    length: tinf-read-bits d 2 3

                    while [length > 0] [
                        poke lengths num prev

                        num: num + 1
                        length: length - 1
                    ]
                ]

                17 [
                    ; repeat code length 0 for 3-10 times (read 3 bits)
                    ;
                    length: tinf-read-bits d 3 3

                    while [length > 0] [
                        poke lengths num 0

                        num: num + 1
                        length: length - 1
                    ]
                ]

                18 [
                    ; repeat code length 0 for 11-138 times (read 7 bits)
                    ;
                    length: tinf-read-bits d 7 11

                    while [length > 0] [
                        ; probe num

                        poke lengths num 0

                        num: num + 1
                        length: length - 1
                    ]
                ]
            ][
                ; values 0-15 represent the actual code lengths
                poke lengths num sym
                num: num + 1
            ]
        ]

        ; build dynamic trees
        ;
        tinf-build-tree lt lengths 0 hlit
        tinf-build-tree dt lengths hlit hdist

        ()
    ]

    ; -- block inflate functions --
    ; -----------------------------

    ; given a stream and two trees, inflate a block of data
    ;
    tinf-inflate-block-data: func [
        d lt dt
        /local sym length dist offs
    ][
        until [
            sym: tinf-decode-symbol d lt

            case [
                sym == 256 [
                    TINF-OK
                ]
                
                sym < 256 [
                    append d/target to char! sym
                    false
                ]

                <else> [
                    sym: sym - 257

                    ; possibly get more bits from length code
                    ;
                    length: tinf-read-bits d length-bits/(sym + 1) length-base/(sym + 1)

                    dist: tinf-decode-symbol d dt

                    ; possibly get more bits from distance code
                    ;
                    offs: (length? d/target) - tinf-read-bits d dist-bits/(dist + 1) dist-base/(dist + 1)

                    ; copy match
                    ;
                    repeat i length [
                        append d/target to char! pick d/target i + offs
                    ]

                    false
                ]
            ]
        ]
    ]

    ; inflate an uncompressed block of data
    ;
    tinf-inflate-uncompressed-block: func [
        d
        /local length invlength
    ][
        ; unread from bitbuffer
        ;
        while [d.bitcount > 8] [
            d/source: back d/source
            d/bitcount: d/bitcount - 8
        ]

        ; get length
        ;
        length: 256 * d/source/2 + d/source/1

        ; get one's complement of length
        ;
        invlength = 256 * d/source/4 + d/source/3

        ; check length
        ;
        either length <> (65535 and complement invlength) [
            TINF-DATA-ERROR
        ][
            d/source: skip d/source 4

            ; copy block
            ;
            repeat i length [
                append d/target to char! d/source/1
                d/source: next d/source
            ]

            ; make sure we start next block on a byte boundary
            d/bitcount: 0

            TINF-OK
        ]
    ]

    ; inflate stream from source to dest
    ;
    tinf-uncompress: func [
        source dest
        /local d bfinal btype res
    ][
        d: new-data source dest

        until [
            ; read final block flag
            ;
            bfinal: tinf-getbit d

            ; read block type (2 bits)
            ;
            btype: tinf-read-bits d 2 0

            ; decompress block
            ;
            switch/default btype [
                0 [
                    ; decompress uncompressed block
                    ;
                    res: tinf-inflate-uncompressed-block d
                ]

                1 [
                    ; decompress block with fixed huffman trees
                    ;
                    res: tinf-inflate-block-data d sltree sdtree
                ]

                2 [
                    ; decompress block with dynamic huffman trees
                    ;
                    tinf-decode-trees d d/ltree d/dtree

                    res: tinf-inflate-block-data d d/ltree d/dtree
                ]
            ][
                res: TINF-DATA-ERROR
            ]

            if res <> TINF-OK [
                make error! "Data Error"
            ]

            bfinal
        ]

        reduce [
            d/target d/source
            ;
            ; d/source appears to be in advance of the end of the
            ; compression component where the end is not at the tail
            ; of the input--must find out if anything can be done
            ; (see "back back" below in the checksum tests)
        ]
    ]

    ; -- initialization --
    ; --------------------

    ; build fixed huffman trees
    ;
    tinf-build-fixed-trees sltree sdtree

    ; build extra bits and base tables
    ;
    tinf-build-bits-base length-bits length-base 4 3
    tinf-build-bits-base dist-bits dist-base 2 1

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

    /local remaining size
][
    switch format [
        #[none] [
            first tinf/tinf-uncompress data copy #{}
        ]

        zlib [
            case [
                not data: find/match data #{789C} [
                    throw make error! "Missing ZLIB header"
                ]

                error? try [
                    set [data remaining] tinf/tinf-uncompress data copy #{}
                ][
                    throw make error! "Inflate error"
                ]

                not find/match back back remaining adler32-checksum-of data [
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
                    set [data remaining] tinf/tinf-uncompress data make binary! size
                ][
                    throw make error! "Inflate error"
                ]

                not find/match back back remaining reverse crc32-checksum-of data [
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
