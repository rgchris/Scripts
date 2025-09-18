Rebol [
    Title: "PNG Tools for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 6-Dec-2023
    Version: 0.1.0
    File: %png.r

    Purpose: "Tools to work with the PNG graphics format"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.png
    Exports: [
        png
    ]

    Needs: [
        shim
        r2c:bincode
        r2c:deflate
    ]

    History: [
        6-Dec-2023 0.0.1
        "Minimal constructor"

        4-Dec-2020 0.0.0
        "PNG Pixel: proof of concept"
    ]

    Comment: [
        http://libpng.org/
        "PNG Home Page"

        https://pyokagan.name/blog/2019-10-14-png/
        "Writing a (simple) PNG decoder might be easier than you think"
    ]
]

png: context [
    magic-number: #{
        89504E47 0D0A1A0A
    }

    chunk-end: #{
        00000000 49454E44 AE426082
    }

    add-tuples: func [
        a [tuple!]
        b [tuple!]
    ][
        make tuple! reduce [
            mod add a/1 b/1 256
            mod add a/2 b/2 256
            mod add a/3 b/3 256
            mod add a/4 b/4 256
        ]
    ]

    subtract-tuples: func [
        a [tuple!]
        b [tuple!]
    ][
        make tuple! reduce [
            mod subtract a/1 b/1 256
            mod subtract a/2 b/2 256
            mod subtract a/3 b/3 256
            mod subtract a/4 b/4 256
        ]
    ]

    average-of: func [
        a [tuple!]
        b [tuple!]
    ][
        make tuple! reduce [
            to integer! divide add a/1 b/1 2
            to integer! divide add a/2 b/2 2
            to integer! divide add a/3 b/3 2
            to integer! divide add a/4 b/4 2
        ]
    ]

    paeth-of: func [
        img offset
        /inspect
        /local a b c p pa pb pc
    ][
        either offset/x = 0 [
            a: 0.0.0.0
        ][
            a: pick img offset - 1x0
        ]

        either offset/y = 0 [
            b: 0.0.0.0
            c: 0.0.0.0
        ][
            b: pick img offset - 0x1

            either offset/x = 0 [
                c: 0.0.0.0
            ][
                c: pick img offset - 1x1
            ]
        ]

        if inspect [
            print [a b c]
        ]

        to tuple! map-each index [1 2 3 4] [
            p: a/:index + b/:index - c/:index

            pa: abs p - a/:index
            pb: abs p - b/:index
            pc: abs p - c/:index

            case [
                all [
                    pa <= pb
                    pa <= pc
                ][
                    a/:index
                ]

                pb <= pc [
                    b/:index
                ]

                #else [
                    c/:index
                ]
            ]
        ]
    ]

    header: make object! [
        unpack: func [value [binary!]] [
            assert [
                13 == length-of value
            ]

            consume value [
                neaten/flat reduce [
                    as-pair unsigned-32 unsigned-32

                    unsigned-8

                    switch/default unsigned-8 [
                        0 ['grayscale]
                        2 ['rgb]
                        3 ['palette]
                        4 ['grayscale-alpha]
                        6 ['rgb-alpha]
                    ][
                        'unknown
                    ]

                    switch/default unsigned-8 [
                        0 ['deflate]
                    ][
                        'unknown
                    ]

                    switch/default unsigned-8 [
                        0 ['adaptive]
                    ][
                        'unknown
                    ]

                    switch/default unsigned-8 [
                        0 ['_]
                        1 ['adam7]
                    ][
                        'unknown
                    ]
                ]
            ]
        ]
    ]

    unpack: func [
        [catch]
        value [binary!]
        /local length name mark chunk-end chunk check
    ][
        neaten/pairs collect [
            if not find/match/case value magic-number [
                throw make error! "Expected PNG binary"
            ]

            if not parse/all/case value [
                8 skip

                some [
                    mark:
                    copy length 4 skip
                    copy name 4 skip

                    (length: unsigned-32/decode as-binary length)

                    copy chunk length skip

                    chunk-end:
                    copy check 4 skip
                    ; (crc32 copy/part mark chunk-end)
                    ; sanity check here

                    (
                        keep name

                        keep/only case [
                            zero? length [
                                '_
                            ]

                            name == "IDAT" [
                                inflate/envelope as-binary chunk 'zlib
                                ; decompress chunk 'zlib
                            ]

                            name == "IHDR" [
                                header/unpack as-binary chunk
                            ]

                            name == "tEXt" [
                                parse/all to string! chunk "^@"
                            ]

                            <else> [
                                as-binary chunk
                            ]
                        ]
                    )
                ]

                [
                    end
                    |
                    (throw make error! "Invalid PNG file")
                ]
            ][
                throw make error! "Invalid PNG File"
            ]
        ]
    ]

    as-image: func [
        [catch]
        value [binary!]

        /local package image gamma filter offset size col row ref
    ][
        case [
            error? package: try [
                unpack value
            ][
                throw :package
            ]

            not find/match/case package [
                "IHDR"
            ][
                do make error! "Invalid PNG file (no IHDR)"
            ]

            not parse package/2 [
                pair!
                integer!
                ['grayscale | 'rgb | 'palette | 'grayscale-alpha | 'rgb-alpha]
                'deflate
                'adaptive
                [not 'unknown word! | '_ | none!]
            ][
                throw make error! "Invalid PNG header"
            ]
        ]

        also image: make image! package/2/1

        switch/default package/2/3 [
            rgb-alpha [
                offset: 0x0
                size: package/2/1
                gamma: 1

                foreach [name chunk] package [
                    switch name [
                        "gAMA" [
                            gamma: divide unsigned-32/decode chunk 100000
                        ]

                        "iCCP" [
                            ; to follow
                        ]

                        "IDAT" [
                            chunk: copy chunk

                            repeat row size/y [
                                offset/y: row - 1
                                ref: 0.0.0.0
                                filter: take chunk

                                repeat col size/x [
                                    offset/x: col - 1

                                    ref: add-tuples to tuple! array/initial 4 does [take chunk] switch filter [
                                        0 [0.0.0.0]
                                        1 [ref]
                                        2 [pick image offset - 0x1]
                                        3 [average-of ref pick image offset - 0x1]
                                        4 [paeth-of image offset]
                                    ]

                                    poke image offset ref
                                ]
                            ]

                            assert [
                                empty? chunk
                            ]
                        ]

                        "IEND" [
                            break
                        ]

                        ; "tEXt" "iCCP" [
                        ;     ; probe chunk
                        ; ]
                    ]
                ]

                ; repeat offset length-of image [
                ;     image/:offset/4: 255 - image/:offset/4
                ;     ; brings in line with legacy Rebol inverted alpha
                ; ]

                assert [
                    image/size - 1x1 = offset
                ]
            ]
        ][
            throw make error! "Image type not supported"
        ]
    ]

    chunkify: func [
        header [string!]
        content [block! binary!]
        /compress
    ][
        header: as-binary form header

        content: rejoin compose [
            #{} (content)
        ]

        if compress [
            content: deflate/envelope content 'zlib
        ]

        reduce [
            unsigned-32/encode length-of content

            header
            content

            crc32/checksum-of rejoin [
                header content
            ]
        ]
    ]

    create: func [
        body [block!]

        /local image
    ][
        rejoin collect [
            keep magic-number

            do-with body [
                add-chunk: func [
                    header [string!]
                    content [block! binary!]
                    /compress
                ][
                    keep apply :chunkify [
                        header content compress
                    ]
                ]

                header: func [
                    size [pair!]
                    bpp [integer!]
                    type [integer!]
                ][
                    keep chunkify "IHDR" [
                        unsigned-32/encode size/x
                        unsigned-32/encode size/y

                        unsigned-8/encode bpp
                        unsigned-8/encode type

                        #{000000}
                        ; Compression (Deflate), Filter (), Interlace (no)
                    ]
                ]

                add-text: func [
                    label [string!]
                    content [string!]
                ][
                    keep chunkify "tEXt" [
                        label null trim/head/tail trim/auto copy content
                    ]
                ]
            ]

            keep chunk-end
            ; IEND chunk
        ]
    ]
]
