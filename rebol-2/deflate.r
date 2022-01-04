Rebol [
    Title: "Deflate"
    Date: 4-Jan-2022
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/
    File: %deflate.r
    Version: 0.2.0
    Purpose: "DEFLATE compression including ZLIB/GZIP envelopes"
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.deflate
    Exports: [
        deflate
        crc32-checksum-of adler32-checksum-of
    ]

    History: [
        04-Jan-2022 0.2.0 "Added DEFLATE wrapper around COMPRESS"
        25-May-2015 0.1.0 "Rudimentary CRC Routine"
    ]

    Notes: [
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
