Rebol [
    Title: "Deflate De/Compression"
    Author: "Christopher Ross-Gill"
    Date: 1-Jul-2025
    Version: 0.5.0
    File: %deflate.r

    Purpose: "Deflate de/compression (including ZLIB/GZIP envelopes)"

    Home: https://github.com/rgchris/Scripts
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.deflate
    Exports: [
        crc32 adler32 flate
        deflate inflate
    ]

    History: [
        1-Jul-2025 0.5.0
        "Rework to a pull-streaming, iterative model"

        9-May-2022 0.4.0
        "Rework bitreader; fixes bug related to current position"

        7-Apr-2022 0.3.2
        "Tweaks to return correct end of compressed stream"

        4-Jan-2022 0.3.0
        "Added INFLATE algorithm and wrapper"

        4-Jan-2022 0.2.0
        "Added DEFLATE wrapper around COMPRESS"

        25-May-2015 0.1.0
        "Rudimentary CRC Routine"
    ]

    Notes: [
        https://www.rfc-editor.org/rfc/rfc1951
        https://en.wikipedia.org/wiki/Deflate
        "Deflate"

        https://github.com/madler/zlib/tree/master/contrib/puff
        https://github.com/madler/zlib/blob/master/inflate.c
        "Reference Implementations"

        https://www.zlib.net/
        https://github.com/foliojs/tiny-inflate
        https://github.com/jibsen/tinf
        https://pyokagan.name/blog/2019-10-18-zlibinflate/
        https://github.com/nodeca/pako
        https://blog.za3k.com/understanding-gzip-2/
        https://github.com/davidm/lua-compress-deflatelua
        "Other Implementaions"
    ]
]

crc32: context [
    table: collect [
        use [value] [
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
    ]

    ; need version that can accumulate from multiple binaries
    ;
    checksum-of: func [
        stream [binary!]
        /local value
    ][
        value: -1

        foreach byte stream [
            value: (shift/logical value 8) xor pick table value and 255 xor byte + 1
        ]

        debase/base to-hex value xor -1 16
    ]
]

adler32: context [
    checksum-of: func [
        stream [binary!]
        /local a b remaining cap
    ][
        a: 1
        b: 0

        cap: 2'048
        remaining: length? stream

        while [remaining > 0] [
            loop min remaining cap [
                a: a + stream/1
                b: a + b

                stream: next stream
            ]

            a: modulo a 65521
            b: modulo b 65521

            remaining: length? stream
        ]

        b: shift/left b 16

        debase/base to-hex a or b 16
    ]
]

flate: context private [
    ; helper used to increment a value at OFFSET in BLOCK
    ;
    increment: func [
        block [block!]
        offset [integer!]
    ][
        poke block offset 1 + pick block offset
    ]

    extra: make object! [
        length: make object! [
            bits: [
                0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2
                3 3 3 3 4 4 4 4 5 5 5 5 0 6
            ]
            ; Extra bits for length codes 257..285

            base: [
                3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35
                43 51 59 67 83 99 115 131 163 195 227 258 323
            ]
            ; Size base for length codes 257..285
        ]

        distance: make object! [
            bits: [
                0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6
                7 7 8 8 9 9 10 10 11 11
                12 12 13 13
            ]
            ; Extra bits for distance codes 0..29

            base: [
                1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193
                257 385 513 769 1025 1537 2049 3073 4097 6145
                8193 12289 16385 24577
            ]
            ; Offset base for distance codes 0..29
        ]
    ]

    consume-one: func [
        "Read next bit"
        decoder [object!]
        /local value
    ][
        ; Deflate reads bits from a stream sequentially little-end first
        ;
        case [
            not zero? decoder/offset [
                value: decoder/stored
            ]

            tail? decoder/source [
                do make error! "Out of Input"
            ]

            <else> [
                value: decoder/source/1
                ; load eight bits

                decoder/source: next decoder/source
                decoder/offset: decoder/offset + 8
            ]
        ]

        decoder/stored: shift value 1
        decoder/offset: decoder/offset - 1

        value and 1
    ]

    consume: func [
        [catch]
        "Read next <need>-bit value from an input stream"

        decoder [object!]
        need [integer!]

        /local value
    ][
        value: decoder/stored
        ; bit accumulator (can use up to 20 bits)

        while [
            decoder/offset < need
        ][
            either tail? decoder/source [
                throw make error! "Out of Input"
            ][
                value: value or shift/left decoder/source/1 decoder/offset
                ; load next byte

                decoder/source: next decoder/source
                decoder/offset: decoder/offset + 8
            ]
        ]

        decoder/stored: shift value need
        decoder/offset: decoder/offset - need
        ; drop need bits and update STORED, always zero to seven bits left

        value and (
            -1 + shift/left 1 need
        )
        ; return need bits, zeroing the bits above that
    ]

    trees: make object! [
        ; special ordering of code length codes
        ;
        code-lengths-sequence: [
            17 18 19 1 9 8 10 7 11 6 12 5 13 4 14 3 15 2 16
            ; one-based index :)
        ]

        ; recyclable arrays used for building/decoding trees
        ;
        offsets: array/initial 15 0
        ; used by BUILD for sorting symbols by length, reused each call

        lengths: array/initial 288 + 32 0
        ; used by DECODE to unpack Huffman coded lengths, reused each call

        zero-out: func [
            "Clear out arrays from current index forward"
            block [block!]
        ][
            forall block [
                change block 0
            ]

            block
        ]

        new: func [
            "Initiate a Huffman Tree"
        ][
            reduce [
                'counts array/initial 16 0
                ; table of code length counts

                'symbols array/initial 288 0
                ; code -> symbol translation
            ]
        ]

        build: func [
            "Build a Huffman tree for given lengths"

            tree [block!]
            lengths [block!]
            count [integer!]

            /local offset
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

        decode: func [
            "Decode dynamic Huffman trees from an input stream"
            decoder [object!]

            /local
            lengths-count distances-count code-lengths-count total-count
            reps code-length symbol last-symbol
        ][
            zero-out lengths
            ; reset lengths

            lengths-count: 257 + consume decoder 5
            ; get 5 bits HLIT (257-286)

            distances-count: 1 + consume decoder 5
            ; get 5 bits HDIST (1-32)

            code-lengths-count: 4 + consume decoder 4
            ; get 4 bits HCLEN (4-19)

            repeat offset code-lengths-count [
                code-length: consume decoder 3
                ; get 3 bits code length (0-7)

                poke lengths code-lengths-sequence/:offset code-length
            ]
            ; read code lengths for code length alphabet

            build code-lengths lengths 19
            ; build code length tree

            last-symbol: 0
            total-count: lengths-count + distances-count
            ; decode code lengths for the dynamic trees

            repeat offset total-count [
                symbol: decode-symbol decoder code-lengths

                switch/default symbol [
                    16 [
                        ; copy previous code length 3-6 times (read 2 bits)
                        ;
                        reps: 3 + consume decoder 2

                        lengths: change/dup lengths last-symbol reps
                    ]

                    17 [
                        ; repeat code length 0 for 3-10 times (read 3 bits)
                        ;
                        reps: 3 + consume decoder 3
                        last-symbol: 0

                        lengths: change/dup lengths 0 reps
                    ]

                    18 [
                        ; repeat code length 0 for 11-138 times (read 7 bits)
                        ;
                        reps: 11 + consume decoder 7
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

                assert [
                    offset <= total-count
                    ; sanity check--it is possible for there to be more codes than specified
                ]
            ]
            ; hackish use of REPEAT assumes OFFSET is not reset each iteration

            lengths: head zero-out lengths
            ; clear any remaining length values

            decoder/symbols: build decoder/dynamic-symbols lengths lengths-count
            decoder/distances: build decoder/dynamic-distances skip lengths lengths-count distances-count
            ; build dynamic trees

            ()
        ]

        fixed-symbols: build new collect [
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
        ; build fixed symbol + lengths huffman tree

        fixed-distances: build new array/initial 32 5 32
        ; build fixed distances huffman tree

        code-lengths: new
        ; tree used to build dynamic tree
    ]

    decode-symbol: func [
        "Decode a symbol from an input stream using given huffman tree"

        decoder [object!]
        tree [block!]

        /local
        value sum code
    ][
        sum:
        code: 0

        foreach count next tree/counts [
            code: code - count + consume-one decoder
            sum: sum + count

            if code < 0 [
                value: sum + code + 1
                break
            ]

            code: shift/left code 1
        ]
        ; get more bits while code value is above sum

        either value [
            tree/symbols/:value
        ][
            do make error! "Ran out of codes"
        ]
    ]
][
    deflate: self

    decoders: context [
        prototype: [
            source:
            state:
            buffer:
            value:
            symbols:
            distances:
            dynamic-symbols:
            dynamic-distances: none
            stored: 0
            offset: 0
            need: 0
            length:
            distance:
            error: none
            window: 32768
            last?: no
        ]

        new: func [
            encoding [binary!]
            /backfill
            /local decoder
        ][
            decoder: make object! prototype

            decoder/source: encoding
            decoder/state: #next-block
            decoder/dynamic-symbols: trees/new
            decoder/dynamic-distances: trees/new
            decoder/buffer: make binary! max decoder/window 65536
            ; DEFLATE needs to retain 32768 bytes of output
            ; we'll flush when we have that twice

            decoder/window: 1048576 
            ; decoder/window: 2048

            if backfill [
                insert/dup decoder/buffer 0 32768
            ]

            decoder
        ]

        next: func [
            decoder [object!]
            /local continue? need buffer symbol length aperture mark
        ][
            continue?: yes

            need: decoder/window
            buffer: tail decoder/buffer

            while [
                continue?
            ][
                switch/default decoder/state [
                    #next-block [
                        decoder/last?: 1 == consume-one decoder

                        switch/default consume decoder 2 [
                            0 [
                                decoder/state: #get-uncompressed-length
                            ]

                            1 [
                                decoder/symbols: trees/fixed-symbols
                                decoder/distances: trees/fixed-distances

                                decoder/state: #consume-compressed
                            ]

                            2 [
                                trees/decode decoder

                                decoder/state: #consume-compressed
                            ]
                        ][
                            decoder/error: "Invalid Block Type"
                            continue?: no
                        ]
                    ]

                    #get-uncompressed-length [
                        either all [
                            ; verify that the length values complement
                            ;
                            decoder/source/1 xor decoder/source/3 == 255
                            decoder/source/2 xor decoder/source/4 == 255
                        ][
                            decoder/length: decoder/source/1 + shift/left decoder/source/2 8
                            decoder/source: skip decoder/source 4
                            decoder/state: #consume-uncompressed

                            decoder/offset: 0
                            ; decoder/stored: 0
                            ; make sure we start next block on a byte boundary
                        ][
                            decoder/error: "Unverified DEFLATE stream length"
                            continue?: no
                        ]
                    ]

                    #consume-uncompressed [
                        length: min need decoder/length
                        need: need - length
                        decoder/length: decoder/length - length

                        assert [
                            length <= length? decoder/source
                        ]

                        buffer: insert/part buffer decoder/source decoder/source: skip decoder/source length

                        if zero? decoder/length [
                            decoder/state: #end-block
                        ]
                    ]

                    #consume-compressed [
                        mark: buffer

                        loop need [
                            either 256 > symbol: decode-symbol decoder decoder/symbols [
                                buffer: insert buffer to char! symbol
                            ][
                                break
                            ]
                        ]

                        need: need - offset? mark buffer

                        case [
                            256 == symbol [
                                decoder/state: #end-block
                            ]

                            256 < symbol [
                                symbol: symbol - 256
                                ; - 257 + 1 for 1-based indexing in bits/base tables

                                decoder/length: extra/length/base/:symbol + consume decoder extra/length/bits/:symbol
                                ; fetch optional length extra bits

                                symbol: 1 + decode-symbol decoder decoder/distances
                                ; + 1 for 1-based indexing in bits/base tables

                                decoder/distance: extra/distance/base/:symbol + consume decoder extra/distance/bits/:symbol
                                ; fetch optional distance extra bits

                                decoder/state: #consume-backfill
                            ]
                        ]
                    ]

                    #consume-backfill [
                        ; could offer backfill of null bytes here
                        ;
                        either decoder/distance > index? buffer [
                            decoder/error: "Not enough backfill"
                            continue?: no
                        ][
                            length: min need decoder/length
                            need: need - length
                            decoder/length: decoder/length - length

                            aperture: min length decoder/distance
                            ; if we only go back three (distance) but need ten (length)
                            ; then we need to repeat that three three times plus
                            ; a partial one (ten - nine) times

                            mark: skip buffer negate decoder/distance
                            ; set the decoded value at the point before the match

                            ; use /dup to repeat copy the source faster
                            ;
                            if length > aperture [
                                buffer: insert/dup buffer copy mark to integer! length / aperture
                                length: remainder length aperture
                            ]

                            buffer: insert/part buffer mark length

                            if zero? decoder/length [
                                decoder/state: #consume-compressed
                            ]
                        ]
                    ]

                    #end-block [
                        either decoder/last? [
                            decoder/state: #done
                            continue?: no
                        ][
                            decoder/state: #next-block
                        ]
                    ]

                    #done [
                        continue?: no
                    ]
                ][
                    continue?: no
                    decoder/error: rejoin [
                        "Unexpected state: " decoder/state
                    ]
                ]

                if zero? need [
                    continue?: no
                ]
            ]

            case [
                decoder/error [
                    throw do decoder/value: try [
                        make error! decoder/error
                    ]
                ]

                #done == decoder/state [
                    decoder/value: if need < decoder/window [
                        remove/part decoder/buffer skip buffer need - decoder/window
                        head buffer
                        ; use the buffer as the last response
                    ]
                ]

                <else> [
                    remove/part decoder/buffer skip buffer negate max decoder/window 32768
                    decoder/value: copy skip tail buffer need - decoder/window
                ]
            ]
        ]
    ]

    decode: func [
        "Decompress Deflate formatted data"

        encoding
        "Series containing compressed stream"

        target
        "Series to append decompressed data"

        /debug
        "Display informational messages for debugging"

        /local decoder part
    ][
        decoder: decoders/new encoding

        target: any [
            target make binary! 32768
        ]

        while [
            part: decoders/next decoder
        ][
            append target part
        ]

        reduce [
            target decoder/source
        ]
    ]
]

deflate: func [
    "Compress data using DEFLATE"

    data [binary! string!]
    "Series to compress"

    /envelope
    "Add an envelope with header plus checksum/size information"

    format [word!]
    "ZLIB (adler32, no size); GZIP (crc32, uncompressed size); LEGACY"
][
    
    switch format [
        #[none] [
            head clear skip tail remove remove compress data -8
        ]

        zlib [
            head clear skip tail compress data -4
        ]

        gzip [
            rejoin [
                #{1F8B08000000000000} #{FF}
                head change skip tail remove remove compress data -8 reverse crc32/checksum-of as-binary data
            ]
        ]

        legacy [
            compress data
            ; adds length field required for Rebol 2/Rebol 3 Alpha DECOMPRESS
        ]
    ]
]

inflate: func [
    [catch]
    "Decompress DEFLATE data"

    data [binary!]
    "Series to decompress"

    /max
    "NOT IMPLEMENTED"

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
            first flate/decode data copy #{}
        ]

        zlib [
            case [
                8 > length? data [
                    throw make error!
                    "ZLIB wrapper too small"
                ]

                data/1 and 15 <> 8 [
                    throw make error!
                    "ZLIB sequence does not contain DEFLATE-compressed data"
                ]

                data/1 > 120 [
                    throw make error!
                    "ZLIB window size too large"
                ]

                error? try [
                    data: skip data pick [2 6] zero? data/2 and 32
                    set [data remaining] flate/decode data make binary! 1024
                ][
                    throw make error!
                    "Inflate error"
                ]

                not find/match remaining adler32/checksum-of data [
                    throw make error!
                    "Inflate ZLIB checksum fail"
                ]

                <else> [
                    data
                ]
            ]
        ]

        gzip [
            case [
                not parse/all data [
                    #{1F8B08}
                    7 skip
                    data:
                    8 skip
                    to end
                    (data: as-binary data)
                ][
                    throw make error!
                    "Missing GZIP header"
                ]

                not integer? size: to integer! reverse copy skip tail data -4 [
                    throw make error!
                    "Inflate: Should not happen"
                ]

                error? try [
                    set [data remaining] flate/decode data make binary! size
                ][
                    throw make error!
                    "Inflate error"
                ]

                not find/match remaining reverse crc32/checksum-of data [
                    throw make error!
                    "Inflate GZIP checksum fail"
                ]

                #else [
                    data
                ]
            ]
        ]

        legacy [
            as-binary decompress data
        ]
    ]
]
