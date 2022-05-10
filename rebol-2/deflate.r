Rebol [
    Title: "Deflate De/Compression"
    Date: 9-May-2022
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/
    File: %deflate.r
    Version: 0.4.0
    Purpose: "DEFLATE de/compression including ZLIB/GZIP envelopes"
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.deflate
    Exports: [
        deflate inflate
        crc32-checksum-of adler32-checksum-of
    ]

    History: [
        09-May-2022 0.4.0 "Rework bitreader; fixes bug related to current position"
        07-Apr-2022 0.3.2 "Tweaks to return correct end of compressed stream"
        04-Jan-2022 0.3.0 "Added INFLATE algorithm and wrapper"
        04-Jan-2022 0.2.0 "Added DEFLATE wrapper around COMPRESS"
        25-May-2015 0.1.0 "Rudimentary CRC Routine"
    ]

    Notes: [
        "Puff"
        https://github.com/madler/zlib/tree/master/contrib/puff

        "Tiny Inflate"
        https://github.com/foliojs/tiny-inflate
        https://github.com/jibsen/tinf

        "Other"
        https://www.zlib.net/
        https://github.com/nodeca/pako
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

    format [word!]
    "ZLIB (adler32, no size); GZIP (crc32, uncompressed size); LEGACY"

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

ctx-inflate: make object! [
    OK: 0
    DATA-ERROR: -3
    MAXBITS: 15

    ; extra bits and base tables for length and distance codes
    ;
    extra: [
        length [
            ; Extra bits for length codes 257..285
            ;
            bits [
                0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2
                3 3 3 3 4 4 4 4 5 5 5 5 0 6
            ]

            ; Size base for length codes 257..285
            ;
            base [
                3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35
                43 51 59 67 83 99 115 131 163 195 227 258 323
            ]
        ]

        distance [
            ; Extra bits for distance codes 0..29
            ;
            bits [
                0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6
                7 7 8 8 9 9 10 10 11 11
                12 12 13 13
            ]

            ; Offset base for distance codes 0..29
            ;
            base [
                1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193
                257 385 513 769 1025 1537 2049 3073 4097 6145
                8193 12289 16385 24577
            ]
        ]
    ]

    ; special ordering of code length codes
    ; 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
    ; + 1
    ;
    special-offsets: [
        17 18 19 1 9 8 10 7 11 6 12 5 13 4 14 3 15 2 16
    ]

    ; used by build-tree, avoids allocations every call
    ;
    offsets: array/initial 15 0

    ; used by decode-trees, avoids allocations every call
    ;
    lengths: array/initial 288 + 32 0

    ; helper used to clear out fixed arrays
    ;
    zero-out: func [
        block [block!]
    ][
        forall block [
            change block 0
        ]

        block
    ]

    ; helper used to increment a value at OFFSET in BLOCK
    ;
    increment: func [
        block [block!]
        offset [integer!]
    ][
        poke block offset 1 + pick block offset
    ]

    new-tree: func [] [
        reduce [
            'counts array/initial 16 0
            ; table of code length counts

            'symbols array/initial 288 0
            ; code -> symbol translation
        ]
    ]

    new-encoding: func [
        source [binary!]
        target [binary!]
    ][
        make object! compose [
            source: (source)
            buffer: 0
            offset: 0

            target: (target)
            length: 0

            dynamic-symbol: new-tree
            dynamic-distance: new-tree

            debug: false
        ]
    ]

    ; given an array of code lengths, build a tree
    ;
    build-tree: func [
        tree [block!]
        lengths [block!]
        count [integer!]

        /local
        offset
    ][
        ; clear code length count table
        ;
        zero-out tree/counts

        ; scan symbol lengths, and sum code length counts
        ;
        repeat code count [
            increment tree/counts 1 + lengths/:code
        ]

        ; compute offset table for distribution sort
        ;
        offset: 1

        repeat length 15 [
            poke offsets length offset
            offset: offset + pick next tree/counts length
        ]

        ; create code -> symbol translation table (symbols sorted by code)
        ;
        repeat code count [
            if not zero? lengths/:code [
                poke tree/symbols offsets/(lengths/:code) code - 1
                increment offsets lengths/:code
            ]
        ]

        tree
    ]

    ; Trees
    ;
    trees: make object! [
        ; build fixed length huffman tree
        ;
        fixed-symbol: build-tree new-tree collect [
            repeat code 288 [
                case [
                    code < 145 [
                        keep 8
                    ]

                    code < 257 [
                        keep 9
                    ]

                    code < 281 [
                        keep 7
                    ]

                    <else> [
                        keep 8
                    ]
                ]
            ]
        ] 288

        ; build fixed distance huffman tree
        ;
        fixed-distance: build-tree new-tree array/initial 32 5 32

        ; tree used to build dynamic tree
        ;
        code-lengths: new-tree
    ]

    ; read a <length> bit value from a stream and add <base>
    ;
    read-bits: func [
        encoding [object!]
        need [integer!]
        base [integer!]

        /local
        value
    ][
        value: encoding/buffer  ; bit accumulator (can use up to 20 bits)

        while [
            encoding/offset < need
        ][
            either tail? encoding/source [
                make error! "Out of Input"  ; longjmp
            ][
                value: value or shift/left encoding/source/1 encoding/offset  ; load eight bits
                encoding/source: next encoding/source
                encoding/offset: encoding/offset + 8
            ]
        ]

        ; drop need bits and update buffer, always zero to seven bits left
        ;
        encoding/buffer: shift value need
        encoding/offset: encoding/offset - need

        ; return need bits, zeroing the bits above that
        ;
        value and (
            -1 + shift/left 1 need
        ) + base
    ]

    decode-symbol: func [
        encoding [object!]
        tree [block!]

        /local
        value sum code
    ][
        ; possibly faster updating ENCODING/BUFFER and /OFFSET vs. READ-BITS

        sum:
        code: 0

        ; get more bits while code value is above sum
        ;
        foreach count next tree/counts [
            code: code - count + read-bits encoding 1 0
            sum: sum + count

            if code < 0 [
                value: sum + code + 1
                break
            ]

            code: shift/left code 1
        ]

        either value [
            tree/symbols/:value
        ][
            make error! "Ran out of codes"
        ]
    ]

    ; given a data stream, decode dynamic trees from it
    ;
    decode-trees: func [
        encoding

        /local
        lengths-count distances-count code-lengths-count total-count
        reps code-length symbol last-symbol
    ][
        ; reset lengths
        ;
        zero-out lengths

        lengths-count: read-bits encoding 5 257
        ; get 5 bits HLIT (257-286)

        distances-count: read-bits encoding 5 1
        ; get 5 bits HDIST (1-32)

        code-lengths-count: read-bits encoding 4 4
        ; get 4 bits HCLEN (4-19)

        ; read code lengths for code length alphabet
        ;
        repeat offset code-lengths-count [
            code-length: read-bits encoding 3 0
            ; get 3 bits code length (0-7)

            poke lengths special-offsets/:offset code-length
        ]

        ; build code length tree
        ;
        build-tree trees/code-lengths lengths 19

        ; decode code lengths for the dynamic trees
        ;
        total-count: lengths-count + distances-count
        last-symbol: 0

        ; hackish use of REPEAT assuming OFFSET is not reset each iteration
        ;
        repeat offset total-count [
            symbol: decode-symbol encoding trees/code-lengths

            switch/default symbol [
                16 [
                    ; copy previous code length 3-6 times (read 2 bits)
                    ;
                    reps: read-bits encoding 2 3

                    lengths: change/dup lengths last-symbol reps
                ]

                17 [
                    ; repeat code length 0 for 3-10 times (read 3 bits)
                    ;
                    reps: read-bits encoding 3 3
                    last-symbol: 0

                    lengths: change/dup lengths 0 reps
                ]

                18 [
                    ; repeat code length 0 for 11-138 times (read 7 bits)
                    ;
                    reps: read-bits encoding 7 11
                    last-symbol: 0

                    lengths: change/dup lengths 0 reps
                ]
            ][
                ; values 0-15 represent the actual code lengths
                ;
                reps: 1
                last-symbol: symbol

                lengths: change lengths symbol
            ]

            offset: offset + reps - 1
            ; REPEAT automatically increments by 1

            ; sanity check--it is possible for there to be more codes than specified
            ;
            assert [
                offset <= total-count
            ]
        ]

        ; clear any remaining length values
        ;
        lengths: head zero-out lengths

        ; build dynamic trees
        ;
        build-tree encoding/dynamic-symbol lengths lengths-count
        build-tree encoding/dynamic-distance skip lengths lengths-count distances-count

        ()
    ]

    ; given a stream and two trees, inflate a block of data
    ;
    inflate-compressed-block: func [
        encoding
        symbol-tree
        distance-tree

        /local
        symbol length distance offset aperture mark
    ][
        until [
            symbol: decode-symbol encoding symbol-tree

            case [
                symbol < 256 [
                    append encoding/target to char! symbol

                    if encoding/debug [
                        print [
                            'literal mold back back tail to-hex symbol
                        ]
                    ]

                    no
                ]

                symbol == 256 [
                    if encoding/debug [
                        print [
                            'end
                        ]
                    ]

                    OK
                    ; yes, done
                ]

                <else> [
                    assert [
                        not empty? encoding/target
                    ]

                    symbol: symbol - 256
                    ; - 257 + 1 for 1-based indexing

                    ; fetch optional length extra bits
                    ;
                    length: read-bits encoding extra/length/bits/:symbol extra/length/base/:symbol

                    distance: 1 + decode-symbol encoding distance-tree
                    ; + 1 for 1-based indexing

                    ; fetch optional distance extra bits
                    ;
                    offset: read-bits encoding extra/distance/bits/:distance extra/distance/base/:distance

                    if encoding/debug [
                        print [
                            'match 'reps length 'back offset
                        ]
                    ]

                    ; could offer backfill of null bytes here
                    ;
                    assert [
                        offset <= length? encoding/target
                    ]

                    aperture: min length offset

                    ; set the decoded value at the point before the match
                    ;
                    mark: skip tail encoding/target negate offset

                    ; copy match
                    ;
                    if length > aperture [
                        insert/dup tail encoding/target copy mark to integer! length / aperture
                        length: remainder length aperture
                    ]

                    append encoding/target copy/part mark length

                    ; loop length [
                    ;     mark: append encoding/target to char! first mark: next mark
                    ; ]

                    no
                ]
            ]
        ]
    ]

    ; inflate an uncompressed block of data
    ;
    inflate-uncompressed-block: func [
        encoding

        /local
        length inverse-length

        ; https://github.com/madler/zlib/blob/master/inflate.c#L898
    ][
        ; unread from bitbuffer
        ;
        while [
            encoding/offset > 8
        ][
            encoding/source: back encoding/source
            encoding/offset: encoding/offset - 8
        ]

        ; get length
        ;
        length: 256 * encoding/source/2 + encoding/source/1

        ; get one's complement of length
        ;
        inverse-length: 256 * encoding/source/4 + encoding/source/3

        if encoding/debug [
            print [
                'uncompressed length
            ]
        ]

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
            encoding/offset: 0

            OK
        ][
            DATA-ERROR
        ]
    ]

    ; inflate stream from source to target
    ;
    uncompress: func [
        source
        target
        /debug

        /local
        encoding type-block is-unpacked is-last-block mark
    ][
        encoding: new-encoding source target

        if any [
            debug
            ; 512 > length? source
        ][
            encoding/debug: true
        ]

        until [
            mark: length? encoding/target

            ; read final block flag
            ;
            is-last-block: 1 == read-bits encoding 1 0

            ; read block type (2 bits)
            ;
            type-block: read-bits encoding 2 0

            if encoding/debug [
                print [
                    switch type-block [
                        0 [<stored>]
                        1 [<fixed>]
                        2 [<dynamic>]
                    ]
                ]
            ]

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
                    inflate-compressed-block encoding trees/fixed-symbol trees/fixed-distance
                ]

                2 [
                    ; decompress block with dynamic huffman trees
                    ;
                    decode-trees encoding
                    inflate-compressed-block encoding encoding/dynamic-symbol encoding/dynamic-distance
                ]
            ][
                DATA-ERROR
            ]

            if encoding/debug [
                print [
                    switch/default is-unpacked [
                        0 ['ok]
                        -3 ['error]
                    ][
                        'unknown
                    ]

                    pick [end continue] is-last-block

                    'from mark
                    'to length? encoding/target

                    newline

                    switch/default type-block [
                        0 [</stored>]
                        1 [</fixed>]
                        2 [</dynamic>]
                    ][
                        'unknown
                    ]

                    newline
                ]
            ]

            if is-unpacked <> OK [
                make error! "DEFLATE stream integrity error"
            ]

            is-last-block
        ]

        reduce [
            encoding/target encoding/source
        ]
    ]
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
            first ctx-inflate/uncompress data copy #{}
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
                    set [data remaining] ctx-inflate/uncompress data make binary! 1024
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
                    set [data remaining] ctx-inflate/uncompress data make binary! size
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
