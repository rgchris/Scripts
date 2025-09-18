Rebol [
    Title: "UTF-8 Encode/Decode"
    Author: "Christopher Ross-Gill"
    Date: 29-Jul-2021
    Version: 0.1.0
    File: %utf-8.r

    Purpose: "UTF-8 encoder/decoder/tools for Rebol 2"

    Home: https://github.com/rgchris/Scripts
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.utf-8
    Exports: [
        utf-8
    ]

    Comment: [
        http://www.unicode.org/reports/tr15/
        "Unicode Normalization Forms"

        https://www.rfc-editor.org/rfc/rfc3629#section-4
        "Syntax of UTF-8 Byte Sequences"

        https://www.fileformat.info/info/unicode/category/index.htm
        "Unicode Character Categories"

        https://stackoverflow.com/a/5202027/292969
        "Purpose of non-characters U+FDD0 - U+FDEF"

        http://unicodebook.readthedocs.io/unicode_encodings.html
        "Unicode Encodings"

        http://bjoern.hoehrmann.de/utf-8/decoder/dfa/
        "UTF-8 Decoder"
    ]
]

utf-8: make object! [
    charsets: make object! [
        ; charsets are stored as compressed binary that can be converted as follows:
        ; make bitset! as-binary decompress value
        ;
        whitespace: #{
            789C6360606060644005E8FC51300A860A184DBBA481FFEC40A201CC6C184877
            8C8281018C001B58020B01060000
        }

        other-control: 64#{
            eJz7////fwYEaABy/wMAVkAIeRQAAAA=
        }

        punctuation-connector: 64#{
            eJztzqENACAQBMGjAyTlfqmUQoJAYhHM6BWbHBXgR9XSXz8AAAAAAAAA20jmNagF
            +UkCiugfAAA=
        }

        punctuation-dash: 64#{
            eJzt1LENgDAMBMBEQoiCghGyCRmN0SGUiAoQBumucOPiv7FT2pT0H90+a2wJnpKD
            82twfrw5ugC3LO0jjvn6F5+OVxh9kwAAAAAAAPRt5OFsVV4twheUFRHlAffWIQAA
        }

        punctuation-close: 64#{
            eJzt2T0KgDAMgNFWXHRycXcUT5EjONj7eBYn6VE8lVVUHET8KYryPUgbCA3p0qVK
            OcGwqGwK/E/+9gAPSt4e4Itk3sRz49hF6LnnVbZYUnFR2/MtSmP0lA43y+4PdV87
            vt+SXjpsm87rMAAAAAAAAAAAADhCdmralU2qVbVZXf3tRz2wHglM7R8AAA==
        }

        punctuation-final: 64#{
            eJxjYMAKOLALj4JRMAqGGVACYpaBdsQoIA9oqDAoMAEAd4sAncUFAAA=
        }

        punctuation-initial: 64#{
            eJxjYMACOLAJjoJRMAqGIZgJxEwD7YhRQB4QEWIQYAQARI8A28UFAAA=
        }

        punctuation-other: 64#{
            eJzt2rtOwzAUBuDTi9oOQNnKgNqwM1QMiAHRrLwFj9AVCSkWM+KViMSEWBkYEOqI
            hIQiMVChqqZN2sR2LnbStB34v8Gx44N9eslgTomIvl7orkK0Twu35DJaD3uFhSd+
            Ww0Gl357QHRKH2HEuRgevBw+yFqS1YIrd+a56RLoU0W9ZclDdYlYvAaLPgQjQjSj
            naQIj3eksRX2eg1pYpK4QStXOho879uRl62Mz5adq4TgYXPePjTNlu6nT7nqDSf5
            OzepxBPxFtexuhYv963P4M724tf3/NPZ0IZg7l0exh+gxyfnmW749y8/LLTBXnCx
            UqY39SUEAAAAAACA/83VRozEQcuWJ5P/qZXOi7rBzh2hz8TI6SCWm6eMZ/O17O1w
            ugYAAACA3JzqvC501f1htd34rFjbPymwumF5NA8WXAoUg1mZaRgvzsx29qvbSlxY
            Up0KN7s5kirRyD+MuClHEibXrF/VsLbfRlXw0ZHwuwsi+a+rBdIb07E4tDXhU86l
            8byOyXupGQw1y2lPYkkL1KMuE4rnb+IzwzVHwKULvzUMNsbCh2zMkwNK3nBFPX0I
            lKihDwEAAIBsrnrDWlxZO9/velfBjI9sdX0IAAAAAKwf23YCAFAMa287A1gT9w8i
            4lM+LD0AAA==
        }

        punctuation-open: 64#{
            eJzt2b0KwyAQwPFrsRA6dUh2ly55ig59gUB9n4whT+FYfMoq+VpCilEaKP8f3HFw
            KCeIiyLeKSQpxsD/KY8e4Ie4w3GeIemh1lORzcXHOfOee5lqLrWPh4nf4u3cVIaT
            3dKHSvfy77cSe9212DT3zOMAAAAAAAAAAADgu3a7ZV0vUq+2l7/9Tn0AJOYJau0f
            AAA=
        }

        punctuation: 64#{
            eJztmj1OwzAUx19pBZX4KBtMNGwMDJ0QA4Ku3KJH4AaxmBg4CEdgzDEYEOrIBJUY
            qETVR+K0qeM4sZOmFMT/J/n7n+dXy47kvhARvX3SfYPoMayehIlu28EdrYa+qP7s
            ROabsZ1rWRwSndFrorhQ5fsy56sik6IZl+xHNm0O9Kihd3nppm4io7cgZl67oqgF
            7ZgUIz6IimRlvGSku5kSTowTtEu5Y4ENy1F2hQrpy/wwaZ/PKwOD+GZL+rTlZrqX
            PxToHb55z00aWUdGs3Ks2+J6l74AZg7TO39FZ2BgXKpl6ND8zK4f5WUwCFPA5U2M
            OdnF0S8r2Ba18JJuZk8LR/hRNil80+Wxxx/hKjS8nFl+ahMCAAAAAAAAAPjfBFbF
            UG20++lB859a+YwW1XjmA6UuVOX0KuPbSGuH483i6XC7BgAAAAAAZoL8IW7GUaBP
            3t7Njiqx/YcqASLH8GgZRFxUiPyKOt1wNi7cZpZxQU3nzytTpfOohFPV8EydQ3kZ
            CXKuJCK9OZ50WUfmi3Dn8Fj57oIo/fSGg486YzpVm32LfMrp4O1emLib68GNxZz1
            JmYy0FpUhb+oP6tnhi1XwDmXMncUOyOSQzY2x7pFzRMuSdcuATXyWz7MAAAAAP4w
            gd7hzUrRKfdd7zII5ytbyy4BAAAAAACrR6zbAQBANURn3R6AFRF8AxlEa+csPQAA
        }
    ]

    =00-7F: charset [#"^(00)" - #"^(7F)"]

    =C2-DF: charset [#"^(C2)" - #"^(DF)"]

    =E0: #"^(E0)"
    =ED: #"^(ED)"
    =E1-EC-EE-EF: charset [
        #"^(E1)" - #"^(EC)"
        #"^(EE)" - #"^(EF)"
    ]

    =F0: #"^(F0)"
    =F1-F3: charset [#"^(F1)" - #"^(F3)"]
    =F4: #"^(F4)"

    =80-8F: charset [#"^(80)" - #"^(8F)"]
    =80-9F: charset [#"^(80)" - #"^(9F)"]
    =80-BF: charset [#"^(80)" - #"^(BF)"]
    =90-BF: charset [#"^(90)" - #"^(BF)"]
    =A0-BF: charset [#"^(A0)" - #"^(BF)"]

    character: make object! [
        value: _
        mark: _

        match: use [
            L2 L3 L4 E2 E3
        ][
            ; First byte in a two-byte series
            ;
            L2: [
                128 192 256 320 384 448
                512 576 640 704 768 832 896 960
                1024 1088 1152 1216 1280 1344 1408 1472
                1536 1600 1664 1728 1792 1856 1920 1984
            ]

            ; First byte in a three-byte series
            ;
            L3: [
                0 4096 8192 12288 16384 20480 24576 28672
                32768 36864 40960 45056 49152 53248 57344 61440
            ]

            ; First byte in a four-byte series
            ;
            L4: [
                0 262144 524288 786432 1048576
            ]

            ; Second-last byte
            ;
            E2: [
                0 64 128 192 256 320 384 448
                512 576 640 704 768 832 896 960
                1024 1088 1152 1216 1280 1344 1408 1472
                1536 1600 1664 1728 1792 1856 1920 1984
                2048 2112 2176 2240 2304 2368 2432 2496
                2560 2624 2688 2752 2816 2880 2944 3008
                3072 3136 3200 3264 3328 3392 3456 3520
                3584 3648 3712 3776 3840 3904 3968 4032
            ]

            ; Third-last byte
            ;
            E3: [
                0 4096 8192 12288 16384 20480 24576 28672
                32768 36864 40960 45056 49152 53248 57344 61440
                65536 69632 73728 77824 81920 86016 90112 94208
                98304 102400 106496 110592 114688 118784 122880 126976
                131072 135168 139264 143360 147456 151552 155648 159744
                163840 167936 172032 176128 180224 184320 188416 192512
                196608 200704 204800 208896 212992 217088 221184 225280
                229376 233472 237568 241664 245760 249856 253952 258048
            ]

            insert/dup L2 #[none] 193
            insert/dup L3 #[none] 223
            insert/dup L4 #[none] 239
            insert/dup E2 #[none] 127
            insert/dup E3 #[none] 127

            [
                mark: (mark: as-binary mark)

                [
                    =00-7F
                    (value: mark/1)
                    |
                    =C2-DF =80-BF
                    (value: mark/2 xor 128 or L2/(mark/1))
                    |
                    [=E0 =A0-BF =80-BF | =ED =80-9F =80-BF | =E1-EC-EE-EF 2 =80-BF]
                    (value: mark/3 xor 128 or E2/(mark/2) or L3/(mark/1))
                    |
                    [=F0 =90-BF 2 =80-BF | =F1-F3 3 =80-BF | =F4 =80-8F 2 =80-BF]
                    (value: mark/4 xor 128 or E2/(mark/3) or E3/(mark/2) or L4/(mark/1))
                ]

                mark: (mark: as-binary mark)
            ]
        ]
    ]

    decode: func [
        encoding [string! binary!]
        /strict
        /local value
    ][
        assert [
            not tail? encoding
        ]

        value: [_ _]
        ; constant block, reused

        value/1: _

        parse/all as-binary encoding [
            character/match
            (
                value/1: character/value
                value/2: character/mark
            )
        ]

        if not value/1 [
            if not strict [
                value/1: 65533
                ; Unknown character
            ]

            value/2: next as-binary encoding
        ]

        value
    ]

    stream: func [
        encoding [string! binary!]
        handler [function!]

        /local continue? value
    ][
        continue?: not tail? encoding

        while [
            continue?
        ][
            set [value encoding] decode encoding

            continue?: all [
                handler value
                not tail? encoding
            ]
        ]
    ]

    encode: func [
        "Encode a code point in UTF-8 format"

        char [integer!]
        "Unicode code point"
    ][
        as-string to binary! reduce case [
            char <= 127 [
                [char]
            ]

            ; U+0080 - U+07FF
            ;
            char <= 2047 [
                [
                    192 or shift char and 1984 6
                    char and 63 or 128
                ]
            ]

            ; invalid U+D800 - U+DFFF ; UTF-16 Surrogates
            ;
            all [
                char >= 55296
                char <= 57343
            ][
                [239 191 189]
            ]

            ; U+0800 - U+FFFF
            ;
            char <= 65535 [
                [
                    224 or shift char and 61440 12
                    128 or shift char and 4032 6
                    char and 63 or 128
                ]
            ]

            ; U+010000 - U+10FFFF
            ;
            char <= 1114111 [
                [
                    240 or shift char and 1835008 18
                    128 or shift char and 258048 12
                    128 or shift char and 4032 6
                    char and 63 or 128
                ]
            ]

            <else> [
                ; Unknown codepoint
                ;
                [239 191 189]
            ]
        ]
    ]

    sanitize: func [
        encoding [string! binary!]
        /local char value
    ][
        value: make type? encoding length? encoding

        while [
            not tail? encoding
        ][
            set [char encoding] decode encoding
            value: insert value encode char
        ]

        head value
    ]

    length?: func [
        encoding [string! binary!]
        /local count
    ][
        count: 0

        assert [
            parse/all encoding [
                any [
                    =00-7F
                    (++ count)
                    |
                    =C2-DF =80-BF
                    (++ count)
                    |
                    [=E0 =A0-BF =80-BF | =E1-EC-EE-EF 2 =80-BF | =ED =80-9F =80-BF]
                    (++ count)
                    |
                    [=F0 =90-BF 2 =80-BF | =F1-F3 3 =80-BF | =F4 =80-8F 2 =80-BF]
                    (++ count)
                    |
                    skip
                    (++ count)
                    ; possibly add an error in here
                ]
            ]
        ]

        count
    ]

    pages: [
        cp-1252 [
            1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
            16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
            32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
            48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63
            64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
            80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95
            96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111
            112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127
            8364 129 8218 402 8222 8230 8224 8225 710 8240 352 8249 338 141 381 143
            144 8216 8217 8220 8221 8226 8211 8212 732 8482 353 8250 339 157 382 376
            160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175
            176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191
            192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207
            208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223
            224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239
            240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255
        ]

        mac-roman [
            1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
            16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
            32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
            48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63
            64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
            80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95
            96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111
            112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127
            196 197 199 201 209 214 220 225 224 226 228 227 229 231 233 232
            234 235 237 236 238 239 241 243 242 244 246 245 250 249 251 252
            8224 176 162 163 167 8226 182 223 174 169 8482 180 168 8800 198 216
            8734 177 8804 8805 165 181 8706 8721 8719 960 8747 170 186 937 230 248
            191 161 172 8730 402 8776 8710 171 187 8230 160 192 195 213 338 339
            8211 8212 8220 8221 8216 8217 247 9674 255 376 8260 8364 8249 8250 64257 64258
            8225 183 8218 8222 8240 194 202 193 203 200 205 206 207 204 211 212
            63743 210 218 219 217 305 710 732 175 728 729 730 184 733 731 711
        ]
    ]
]
