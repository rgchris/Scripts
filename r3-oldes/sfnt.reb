Rebol [
    Title: "SFNT Font Programs"
    Author: "Christopher Ross-Gill"
    Date: 29-Nov-2025
    Version: 0.0.2
    File: %sfnt.reb

    Purpose: "Evaluate SFNT (TTF/OTF/WOFF) font programs"

    Home: https://github.com/rgchris/Scripts
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.sfnt
    Exports: [
        sfnt
    ]

    Needs: [
        r3:rgchris:bincode
        r3:rgchris:deflate
    ]

    History: [
        29-Nov-2025 0.0.2
        "Rebol 3 modifications"

        22-Jan-2021 0.0.1
        "Proof of concept"
    ]

    Comment: [
        "WOFF 2 Requires Brotli"

        https://docs.microsoft.com/en-us/typography/opentype/spec/otff
        https://developer.apple.com/fonts/TrueType-Reference-Manual/
        "Microsoft OpenType/Apple TrueType spec"

        https://www.w3.org/TR/WOFF/#OverallStructure
        "WOFF/WOFF2 spec"

        https://docs.fileformat.com/font/ttc/
        "TrueType Collections"

        https://github.com/opentypejs/opentype.js
        https://github.com/steambap/freetype-js
        https://tchayen.github.io/posts/ttf-file-parsing
        https://www.codeproject.com/articles/2293/retrieving-font-name-from-ttf-file
        http://www.4real.gr/technical-documents-ttf-subset.html
        "Encoding/Decoding"

        https://iamvdo.me/en/blog/css-font-metrics-line-height-and-vertical-align
        https://pearsonified.com/golden-ratio-typography-intro/
        https://kltf.de/kltf_otproduction.shtml#metrics
        https://github.com/googlefonts/gf-docs/tree/main/VerticalMetrics
        https://glyphsapp.com/learn/vertical-metrics
        https://simoncozens.github.io/fonts-and-layout/opentype.html
        "Metrics Background"
    ]
]

sfnt: make object! [
    required: [
        comment [
            "From "
            ; A TrueType font program may be used as part of either a font
            ; or a CIDFont. Although the basic font file format is the same
            ; in both cases, there are different requirements for what
            ; information must be present in the font program. The
            ; following TrueType tables are always required: "head,"
            ; "hhea," "loca," "maxp," "cvt_," "prep," "glyf," "hmtx," and
            ; "fpgm." If used with a simple font dictionary, the font
            ; program must additionally contain a "cmap" table defining one
            ; or more encodings, as discussed in "Encodings for TrueType
            ; Fonts" on page 332. If used with a CIDFont dictionary, the
            ; "cmap" table is not needed, since the mapping from character
            ; codes to glyph descriptions is provided separately.
            ;
            ; 'cmap "Character to glyph mapping"
            ; 'head "Font header"
            ; 'hhea "Horizontal header"
            ; 'hmtx "Horizontal metrics"
            ; 'maxp "Maximum profile"
            ; 'name "Naming table"
            ; 'OS-2 "OS/2 and Windows specific metrics"
            ; 'post "PostScript information"
        ]

        truetype [
            "cmap" "head" "hhea" "hmtx" "maxp" "name" "OS/2" "post" "glyf" "loca"
        ]

        cff [
            "cmap" "head" "hhea" "hmtx" "maxp" "name" "OS/2" "post" "CFF "  ; "CFF2"
        ]
    ]

    catalog: [
        platforms #[
            0 unicode
            1 mac
            2 deprecated  ; ISO
            3 windows
            4 deprecated  ; Custom
        ]

        encodings #[
            unicode #[
                0 unicode-1-0
                1 unicode-1-1
                2 iso-10646
                3 unicode-bmp
                4 unicode-full
            ]

            mac #[
                0 roman
                1 japanese
                2 chinese
                3 korean
                4 arabic
                5 hebrew
                6 greek
                7 russian
                8 rsymbol
                9 devanagari
                10 gurmukhi
                11 gujarati
                12 oriya
                13 bengali
                14 tamil
                15 telugu
                16 kannada
                17 malayalam
                18 sinhalese-traditional
                19 burmese
                20 khmer
                21 thai
                22 laotian
                23 georgian
                24 armenian
                25 chinese-simplified
                26 tibetan
                27 mongolian
                28 geez
                29 slavic
                30 vietnamese
                31 sindhi
            ]

            windows #[
                00 symbol
                01 unicode-bmp
                ; 02 shift-jis
                ; 03 prc
                ; 04 big5
                ; 05 wansung
                ; 06 johab
                ; 07 reserved
                ; 08 reserved
                ; 09 reserved
                10 unicode-full
            ]

            deprecatedk _
        ]

        languages #[
            mac #[
                0 en
                1 fr
                2 de
                3 it
                4 nl
                5 sv
                6 es
                7 da
                8 pt
                9 no
                10 he
                11 ja
                12 ar
                13 fi
                14 el
                15 is
                16 mt
                17 tr
                18 hr
                19 zh  ; traditional
                20 ur
                21 hi
                22 th
                23 ko
                24 lt
                25 pl
                26 hu
                27 et
                28 lv
                29 se
                30 fo
                31 fa
                32 ru
                33 zh  ; simplified
                34 nl  ; flemish
                35 ga
                36 sq
                37 ro-ro
                38 cs
                39 ks
                40 sl
                41 yi
                42 sr
                43 mk
                44 gb
                45 uk
                46 be
                47 uz
                48 kk
                49 az  ; cyrillic
                50 az  ; arabic
                51 hy
                52 ka
                53 ro-md
                54 ky
                55 tg
                56 tk
                57 mn  ; mongolian
                58 mn  ; cyrillic
                59 ps
                60 ku
                61 ks
                62 sd
                63 bo
                64 ne
                65 sa
                66 mr
                67 bn
                68 as
                69 gu
                70 pa
                71 or
                72 mk
                73 kn
                74 ta
                75 te
                76 si
                77 my
                78 km
                79 lo
                80 vi
                81 id
                82 tl
                83 ms  ; roman
                84 ms  ; arabic
                85 am
                86 ti
                87 om
                88 so
                89 sw
                90 rw
                91 rn
                92 ny
                93 mg
                94 eo
                128 cy
                129 eu
                130 ca
                131 la
                132 qu
                133 gn
                134 ay
                135 tt
                136 ug
                137 dz
                138 jv
                139 su
                140 gl
                141 af
                142 br
                143 iu
                144 gd
                145 gv
                146 ga
                147 to
                148 el
                149 kl
                150 az  ; roman
            ]

            windows #[
                1078 af
                1052 sq
                1156 de-alsatian
                1118 am
                5121 ar-algeria
                15361 ar-bahrain
                3073 ar-egypt
                2049 ar-iraq
                11265 ar-jordan
                13313 ar-kuwait
                12289 ar-lebanon
                4097 ar-libya
                6145 ar-morocco
                8193 ar-oman
                16385 ar-qatar
                1025 ar-saudi-arabia
                10241 ar-syria
                7169 ar-tunisia
                14337 ar-uae
                9217 ar-yemen
                1067 hy-armenia
                1101 as
                2092 az-cyrillic
                1068 az-latin
                1133 ba
                1069 eu
                1059 be
                2117 bn-bangladesh
                1093 bn-india
                8218 bs-cyrillic
                5146 bs-latin
                1150 br
                1026 bg
                1027 ca
                3076 zh-hk
                5124 zh-mo
                2052 zh-cn
                4100 zh-sg
                1028 zh-tw
                1155 co
                1050 hr
                4122 hr-ba
                1029 cs
                1030 da
                1164 prs
                1125 dv
                2067 nl-be
                1043 nl-ml
                3081 en-au
                10249 en-bz
                4105 en-ca
                9225 en
                16393 en-in
                6153 en-ie
                8201 en-jm
                17417 en-my
                5129 en-nz
                13321 en-ph
                18441 en-sg
                7177 en-za
                11273 en-tt
                2057 en-gb
                1033 en-us
                12297 en-zimbabwe
                1061 et
                1080 fo
                1124 fil
                1035 fi
                2060 fr-be
                3084 fr-ca
                1036 fr
                5132 fr-lu
                6156 fr-mc
                4108 fr-ch
                1122 fy
                1110 gl
                1079 ka
                3079 de-at
                1031 de-de
                5127 de-li
                4103 de-lu
                2055 de-ch
                1032 el
                1135 kl
                1095 gu
                1128 ha
                1037 he
                1081 hi
                1038 hu
                1039 is
                1136 ig
                1057 id
                1117 iu-canada
                2141 iu-latin-canada
                2108 ga
                1076 isixhosa-south-africa
                1077 isizulu-south-africa
                1040 it-it
                2064 it-ch
                1041 ja
                1099 kn
                1087 kk
                1107 km
                1158 kiche-guatemala
                1159 rw
                1089 kiswahili-kenya
                1111 konkani-india
                1042 ko
                1088 ky
                1108 lo
                1062 lv
                1063 lt
                2094 lower-sorbian-germany
                1134 lb
                1071 mk
                2110 ms-bn
                1086 ms-my
                1100 ml-in
                1082 mt
                1153 mi
                1146 mapudungun-chile
                1102 mr
                1148 mohawk-mohawk
                1104 mn-mn
                2128 mn-cn
                1121 ne
                1044 nb
                2068 nn
                1154 oc
                1096 or
                1123 ps
                1045 pl
                1046 pt-brazil
                2070 pt-portugal
                1094 pa
                1131 qu-bolivia
                2155 qu-ecuador
                3179 qu-peru
                1048 ro-ro
                1047 rm
                1049 ru
                9275 se-inari-finland
                4155 se-lule-norway
                5179 se-lule-sweden
                3131 se-northern-finland
                1083 se-northern-norway
                2107 se-northern-sweden
                8251 se-skolt-finland
                6203 se-southern-norway
                7227 se-southern-sweden
                1103 sa
                7194 sr-cyrillic-bosnia-and-herzegovina
                3098 sr-cyrillic-serbia
                6170 sr-latin-bosnia-and-herzegovina
                2074 sr-latin-serbia
                1132 sesotho-sa-leboa-south-africa
                1074 setswana-south-africa
                1115 si
                1051 sk
                1060 sl
                11274 es-ar
                16394 es-bo
                13322 es-cl
                9226 es-co
                5130 es-cr
                7178 es-do
                12298 es-ec
                17418 es-sv
                4106 es-gt
                18442 es-hn
                2058 es-mx
                3082 es
                19466 es-ni
                6154 es-pa
                15370 es-py
                10250 es-pe
                20490 es-pr
                1034 es
                21514 es-us
                14346 es-uy
                8202 es-ve
                2077 sv-fi
                1053 sv-se
                1114 syriac-syria
                1064 tg
                2143 tamazight-latin-algeria
                1097 ta
                1092 tt
                1098 te
                1054 th
                1105 bo
                1055 tr
                1090 tk
                1152 ug
                1058 uk
                1070 upper-sorbian-germany
                1056 ur
                2115 uz-cyrillic-uzbekistan
                1091 uz-latin-uzbekistan
                1066 vi
                1106 cy
                1160 wo
                1157 yakut-russia
                1144 yi-prc
                1130 yo
            ]
        ]

        names #[
            00 copyright
            01 family
            02 variant
            03 id
            04 full-name
            05 version
            06 ps-name
            07 trademark
            08 vendor
            09 designer
            10 description
            11 url
            12 designer-url
            13 license
            14 license-url
            16 typographical-family
            17 typographical-variant
            18 compatible-name
            19 sample
            20 ps-id
            21 wws-family
            22 wws-variant
            23 palette-light
            24 palette-dark
            25 ps-prefix
            200 generator  ; reserved but used by FontSquirrel
            256 ss01
            257 ss02
            258 ss03
            259 ss04
            260 ss05
            261 ss06
            262 ss07
            263 ss08
            264 ss09
            265 ss10
            266 ss11
            267 ss12
            268 ss13
            269 ss14
            270 ss15
            271 ss16
            272 ss17
            273 ss18
            274 ss19
            275 ss20
        ]

        characters #[
            mac-roman #[
                128 #{C384} 129 #{C385} 130 #{C387} 131 #{C389}
                132 #{C391} 133 #{C396} 134 #{C39C} 135 #{C3A1}
                136 #{C3A0} 137 #{C3A2} 138 #{C3A4} 139 #{C3A3}
                140 #{C3A5} 141 #{C3A7} 142 #{C3A9} 143 #{C3A8}
                144 #{C3AA} 145 #{C3AB} 146 #{C3AD} 147 #{C3AC}
                148 #{C3AE} 149 #{C3AF} 150 #{C3B1} 151 #{C3B3}
                152 #{C3B2} 153 #{C3B4} 154 #{C3B6} 155 #{C3B5}
                156 #{C3BA} 157 #{C3B9} 158 #{C3BB} 159 #{C3BC}
                160 #{E280A0} 161 #{C2B0} 162 #{C2A2} 163 #{C2A3}
                164 #{C2A7} 165 #{E28899} 166 #{C2B6} 167 #{C39F}
                168 #{C2AE} 169 #{C2A9} 170 #{E284A2} 171 #{C2B4}
                172 #{C2A8} 173 #{E289A0} 174 #{C386} 175 #{C398}
                176 #{E2889E} 177 #{C2B1} 178 #{E289A4} 179 #{E289A5}
                180 #{C2A5} 181 #{C2B5} 182 #{E28882} 183 #{E28891}
                184 #{E2888F} 185 #{CF80} 186 #{E288AB} 187 #{C2AA}
                188 #{C2BA} 189 #{CEA9} 190 #{C3A6} 191 #{C3B8}
                192 #{C2BF} 193 #{C2A1} 194 #{C2AC} 195 #{E2889A}
                196 #{C692} 197 #{E28988} 198 #{CE94} 199 #{C2AB}
                200 #{C2BB} 201 #{E28BAF} 202 #{C2A0} 203 #{C380}
                204 #{C383} 205 #{C395} 206 #{C592} 207 #{C593}
                208 #{E28093} 209 #{E28094} 210 #{E2809C} 211 #{E2809D}
                212 #{E28098} 213 #{E28099} 214 #{C3B7} 215 #{E2978A}
                216 #{C3BF} 217 #{C5B8} 218 #{E28184} 219 #{C2A4}
                220 #{E280B9} 221 #{E280BA} 222 #{EFAC81} 223 #{EFAC82}
                224 #{E280A1} 225 #{C2B7} 226 #{E2809A} 227 #{E2809E}
                228 #{E280B0} 229 #{C382} 230 #{C38A} 231 #{C381}
                232 #{C38B} 233 #{C388} 234 #{C38D} 235 #{C38E}
                236 #{C38F} 237 #{C38C} 238 #{C393} 239 #{C394}
                241 #{C392} 242 #{C39A} 243 #{C39B} 244 #{C399}
                245 #{C4B1} 246 #{CC82} 247 #{CC83} 248 #{C2AF}
                249 #{CB98} 250 #{CB99} 251 #{CB9A} 252 #{C2B8}
                253 #{CB9D} 254 #{CB9B} 255 #{CB87}
            ]
        ]
    ]

    has-flag: func [
        flags [integer!]
        flag [integer!]
    ][
        flag and flags == flag
    ]

    as-fixed: func [
        ; aka 16.16?
        value [integer!]
    ][
        round/to value / 65536 0.001
    ]

    as-date: func [
        value [number!]

        /local date days
    ][
        assert [
            not error? try [
                days: to integer! value / 86400
            ]
        ]

        ; 24 * 60 * 60 = 86400
        ; seconds in a day
        ;
        date: 1-Jan-1904 + days
        date/time: to time! (
            to integer! mod value 86400
        )

        date
    ]

    as-fword: func [
        value [integer!]
    ][
        value
    ]

    as-f2dot14: func [
        value [integer!]
    ][
        add shift value -14 divide 16#3FFF and value 16#4000
    ]

    as-string: func [
        value [binary! integer!]
    ][
        to string! value
    ]

    ; discern-flags: func [
    ;     flags [integer!]
    ; ][
    ;     ; for HEAD table
    ;     ;
    ;     neaten collect [
    ;         case/all [
    ;             has-flag flags 1 [keep 'y-baseline]
    ;             has-flag flags 2 [keep 'lsb-at-x]
    ;             has-flag flags 4 [keep 'instructions-may-depend-on-point-size]
    ;             has-flag flags 8 [keep 'ppem-use-integer]
    ;             has-flag flags 16 [keep 'instructions-may-alter-advance-width]
    ;             has-flag flags 32 [keep 'bit5]
    ;             has-flag flags 64 [keep 'bit6]
    ;             has-flag flags 128 [keep 'bit7]
    ;             has-flag flags 256 [keep 'bit8]
    ;             has-flag flags 512 [keep 'bit9]
    ;             has-flag flags 1024 [keep 'bit10]
    ;             has-flag flags 2048 [keep 'bit11]
    ;             has-flag flags 4096 [keep 'bit12]
    ;             has-flag flags 8192 [keep 'cleartype-optimized]
    ;             has-flag flags 16384 [keep 'last-resort]
    ;             has-flag flags 32768 [keep 'should-be-zero-oops]
    ;         ]
    ;     ]
    ; ]

    discern-style: func [
        flags [integer!]
    ][
        neaten/flat collect [
            case/all [
                has-flag flags 1 [keep 'bold]
                has-flag flags 2 [keep 'italic]
                has-flag flags 4 [keep 'underline]
                has-flag flags 8 [keep 'outline]
                has-flag flags 16 [keep 'shadow]
                has-flag flags 32 [keep 'condensed]
                has-flag flags 64 [keep 'extended]
            ]
        ]
    ]

    discern-restrictions: func [
        restrictions [integer!]
    ][
        if not empty? restrictions: neaten collect [
            switch/default restrictions and 14 [
                0 []
                2 [keep 'no-embed]
                4 [keep 'read-only-embed]
                8 [keep 'editable-embed]
            ][
                keep 'invalid-embedding-instruction
            ]

            if has-flag restrictions 16#100 [
                keep 'no-subsets
            ]

            if has-flag restrictions 16#200 [
                keep 'no-outlines
            ]

            if not zero? restrictions and 16#FCF1 [
                keep 'invalid-restrictions
            ]
        ][
            restrictions
        ]
    ]

    as-version: func [
        value [integer!]
    ][
        add shift value -16 0.1 * shift value and 16#F000 -12
    ]

    as-utf-8: func [
        value [binary!]
    ][
        ; R2 legacy, *probs don't need?*
        ;
        to string! head accumulate make binary! length? value [
            while [
                not tail? value
            ][
                utf-8 consume value 'unsigned-16
            ]
        ]
    ]

    roman-to-utf-8: func [
        value [binary!]
        /local char
    ][
        ; R2 legacy, *review*
        ;
        to string! head accumulate make binary! 2 * length? value [
            while [
                not tail? value
            ][
                either 128 > char: consume value 'byte [
                    unsigned-8 char
                ][
                    accumulate select catalog/characters/mac-roman char
                ]
            ]
        ]
    ]

    ; need tests for this
    ;
    calc-checksum: func [
        value [binary!]
        /local sum
    ][
        sum: 0

        while [
            4 < length? value
        ][
            sum: modulo add sum consume value 'unsigned-32 16#100000000
        ]

        if not tail? value [
            value: head change copy #{00000000} value

            sum: modulo add sum consume value 'unsigned-32 16#100000000
        ]

        ; to-unsigned-32
        sum
    ]

    prototype: make object! [
        font: make object! [
            type:
            container:
            info:
            index:
            tables:
            source: _
        ]

        info: make object! [
            table-count:

            search-range:
            entry-selector:
            range-shift:

            length:
            reserved:
            size:
            version:
            meta-offset:
            meta-length:
            meta-size:
            private-offset:
            private-needs: _
        ]

        tables: make object! [
            cmap: make object! [
                type: 'cmap
                version:
                tables:
                charset:
                format:
                length:
                language:
                seg-count:
                search-range:
                entry-selector:
                range-shift:
                glyph-index-map: _
            ]

            head:
            hhea:
            hmtx:
            maxp:
            name:
            os-2:
            post:
            loca:
            glyf:
            cff1:
            cff2:
            cvt:
            fpgm:
            prep:
            gasp:
            kern:
            gdef:
            gpos:
            gsub: _
        ]
    ]

    init-tables: func [
        font [object!]

        /local offset source mark
    ][
        foreach [
            table label prototype
        ][
            cmap "cmap" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/cmap
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6cmap.html
                ;
                type: 'cmap

                version: unsigned-16
                count: unsigned-16

                assert [
                    ; other cmap versions can exist, however they are unsupported
                    ; by Microsoft which would inhibit their usage
                    ;
                    zero? version
                ]

                tables: neaten collect [
                    loop count [
                        keep make map! reduce [
                            'platform unsigned-16
                            'encoding unsigned-16
                            'offset unsigned-32
                        ]
                    ]
                ]

                charset: _

                foreach table tables [
                    ; pick the first compatible table
                    ;
                    if any [
                        ; Unicode
                        ;
                        if table/platform == 0 [
                            find [0 1 2 3 4] table/encoding
                        ]

                        ; Windows
                        ;
                        if table/platform == 3 [
                            find [1 10] table/encoding
                        ]
                    ][
                        if not charset [
                            charset: :table
                        ]
                    ]
                ]

                assert [
                    not none? charset
                ]

                set-offset skip mark charset/offset

                format: unsigned-16

                assert [
                    format == 4
                ]

                length: unsigned-16
                language: unsigned-16
                seg-count: shift unsigned-16 -1  ; / 2
                search-range: unsigned-16
                entry-selector: unsigned-16
                range-shift: unsigned-16

                glyph-index-map: use [
                    codes char glyph-index
                ][
                    ; range-ends
                    ;
                    codes: collect [
                        loop seg-count [
                            keep neaten/flat reduce [
                                0 unsigned-16 _ _ _
                            ]
                        ]
                    ]

                    ; reserved padding
                    ;
                    assert [
                        consume #{0000}
                    ]

                    ; range-starts
                    ;
                    forskip codes 5 [
                        codes/1: unsigned-16
                    ]

                    ; range-deltas
                    ;
                    forskip codes 5 [
                        codes/3: signed-16
                    ]

                    ; id-range-offsets
                    ;
                    forskip codes 5 [
                        codes/4: unsigned-16

                        if not zero? codes/4 [
                            codes/5: skip back back get-offset codes/4
                        ]
                    ]

                    ; remove historical search bounds
                    ;
                    clear skip tail codes -5

                    neaten/by codes 5

                    collect [
                        foreach [lower upper delta range-offset from] codes [
                            repeat offset upper + 1 - lower [
                                char: lower - 1 + offset

                                keep char

                                either zero? range-offset [
                                    keep char + delta and 16#ffff
                                ][
                                    set-offset skip from offset - 1 * 2

                                    if not zero? glyph-index: unsigned-16 [
                                        glyph-index: glyph-index + delta and 16#ffff
                                    ]

                                    keep glyph-index
                                ]

                                ; keep char
                            ]
                        ]

                        clear codes
                        codes: _
                    ]
                ]

                make map! sort/skip glyph-index-map 2
            ]

            head "head" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/head
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html
                ;
                type: 'head

                version: as-fixed signed-32
                revision: as-fixed signed-32
                checksum: consume 4
                magic-number: consume #{5F0F3CF5}

                flags: unsigned-16
                units-per-em: unsigned-16

                created: as-date signed-64
                modified: as-date signed-64

                range: reduce [
                    'min as-pair as-fword signed-16 as-fword signed-16
                    'max as-pair as-fword signed-16 as-fword signed-16
                ]

                style: discern-style unsigned-16
                smallest: unsigned-16
                direction: signed-16
                location-format: signed-16
                glyph-data-format: signed-16
            ]

            hhea "hhea" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/hhea
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html
                ;
                type: 'hhea

                version: as-fixed signed-32
                ascent: as-fword signed-16
                descent: signed-16
                line-gap: as-fword signed-16
                advance-width-max: as-fword unsigned-16
                min-left-side-bearing: as-fword signed-16
                min-right-side-bearing: as-fword signed-16
                x-max-extent: as-fword signed-16
                caret-slope-rise: signed-16
                caret-slope-run: signed-16
                caret-offset: as-fword signed-16

                ; Skip 4 reserved places...
                ;
                advance 8

                metric-data-format: signed-16
                h-metrics-count: unsigned-16
            ]

            maxp "maxp" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/maxp
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6maxp.html
                ;
                type: 'maxp

                version: as-version signed-32
                glyphs: unsigned-16
                maximum: reduce [
                    'points unsigned-16
                    'contours unsigned-16
                    'composite-points unsigned-16
                    'composite-contours unsigned-16
                    'zones unsigned-16
                    'twilight-points unsigned-16
                    'storage unsigned-16
                    'function-defs unsigned-16
                    'instruction-defs unsigned-16
                    'stack-elements unsigned-16
                    'size-of-instructions unsigned-16
                    'component-elements unsigned-16
                    'component-depth unsigned-16
                ]
            ]

            hmtx "hmtx" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/hmtx
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hmtx.html
                ;
                type: 'hmtx

                horizontal-metrics: collect [
                    loop font/tables/hhea/h-metrics-count [
                        keep/only reduce [
                            unsigned-16 signed-16
                        ]
                    ]
                ]

                left-side-bearings: collect [
                    loop font/tables/maxp/glyphs - font/tables/hhea/h-metrics-count [
                        keep as-fword signed-16
                    ]
                ]

                neaten/by horizontal-metrics 4
                neaten/by left-side-bearings 8
            ]

            name "name" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/name
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6name.html
                ;
                type: 'name

                version: unsigned-16
                count: unsigned-16
                offset: unsigned-16

                fields: use [
                    field-names
                ][
                    field-names: neaten collect [
                        loop count [
                            keep make object! [
                                ; for prominence
                                ;
                                name:
                                value: _

                                platform-id: unsigned-16
                                encoding-id: unsigned-16
                                language-id: unsigned-16
                                name: unsigned-16
                                length: unsigned-16
                                offset: unsigned-16

                                platform: any [
                                    select catalog/platforms platform-id
                                    'unknown
                                ]

                                ; anglocentric shortlists here, for debug use only
                                ;
                                encoding: any [
                                    switch platform [
                                        unicode [
                                            select catalog/encodings/unicode encoding-id
                                        ]

                                        mac [
                                            select catalog/encodings/mac encoding-id
                                        ]

                                        windows [
                                            select catalog/encodings/windows encoding-id
                                        ]
                                    ]

                                    'unknown
                                ]

                                name: any [
                                    select catalog/names name

                                    to word! rejoin [
                                        "field-" name
                                    ]
                                ]

                                language: any [
                                    switch platform [
                                        mac [
                                            select catalog/languages/mac language-id
                                        ]

                                        windows [
                                            select catalog/languages/windows language-id
                                        ]
                                    ]

                                    language-id
                                ]
                            ]
                        ]
                    ]

                    ; this probably won't work
                    ;
                    if version = 1 [
                        advance 4 * unsigned-16
                    ]

                    collect [
                        foreach field field-names [
                            set-offset skip mark offset + field/offset

                            if not zero? field/length [
                                keep/only neaten/flat reduce [
                                    field/platform
                                    field/encoding
                                    field/language
                                    field/name

                                    switch/default field/encoding [
                                        unicode-1-0
                                        unicode-bmp [
                                            as-utf-8 consume field/length
                                        ]

                                        roman [
                                            roman-to-utf-8 consume field/length
                                        ]
                                    ][
                                        as-string consume field/length
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]

                neaten fields
            ]

            os-2 "OS/2" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/os2
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6OS2.html
                ;
                type: 'os-2

                version: unsigned-16
                average-width: signed-16
                weight-class: unsigned-16
                width-class: unsigned-16
                restrictions: discern-restrictions unsigned-16

                subscript: reduce [
                    'size as-pair signed-16 signed-16
                    'offset as-pair signed-16 signed-16
                ]

                superscript: reduce [
                    'size as-pair signed-16 signed-16
                    'offset as-pair signed-16 signed-16
                ]

                strikeout: reduce [
                    'size signed-16
                    'offset signed-16
                ]

                family-class: signed-16

                panose: reduce [
                    'family-type unsigned-8
                    'serif-style unsigned-8
                    'weight unsigned-8
                    'proportion unsigned-8
                    'contrast unsigned-8
                    'stroke-variation unsigned-8
                    'arm-style unsigned-8
                    'letter-form unsigned-8
                    'mid-line unsigned-8
                    'x-height unsigned-8
                ]

                unicode-range: consume 16

                vendor: as-string consume 4
                selection: unsigned-16

                characters: reduce [
                    'first unsigned-16
                    'last unsigned-16
                    'default _
                    'break _
                    'max-content _
                ]

                typography: reduce [
                    'ascender signed-16
                    'descender signed-16
                    'line-gap signed-16
                    'x-height _
                    'cap-height _
                ]

                windows: reduce [
                    'ascender unsigned-16
                    'descender unsigned-16
                ]

                code-pages: if version > 0 [
                    reduce [
                        consume 4
                        consume 4
                    ]
                ]

                if version > 1 [
                    typography/x-height: signed-16
                    typography/cap-height: signed-16

                    characters/default: unsigned-16
                    characters/break: unsigned-16
                    characters/max-content: unsigned-16
                ]

                optical-point-size: if version > 3 [
                    reduce [
                        'lower unsigned-16
                        'upper unsigned-16
                    ]
                ]
            ]

            post "post" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/post
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6post.html
                ;
                type: 'post

                version: as-version signed-32

                italic-angle: as-fixed signed-32

                underline: reduce [
                    'position as-fword signed-16
                    'thickness as-fword signed-16
                ]

                is-fixed-pitch: unsigned-32

                memory: reduce [
                    'type-42 reduce [
                        unsigned-32 unsigned-32
                    ]

                    'type-1 reduce [
                        unsigned-32 unsigned-32
                    ]
                ]

                names: if version < 3 [
                    neaten/pairs collect [
                        switch/default version [
                            1.0 []

                            2.0 [
                                use [
                                    count id
                                ][
                                    count: unsigned-16

                                    foreach id collect [
                                        loop count [
                                            if 257 < id: unsigned-16 [
                                                keep id - 258
                                            ]
                                        ]
                                    ][
                                        keep id
                                        keep as-string consume unsigned-8
                                    ]
                                ]
                            ]

                            2.5 []
                        ][
                            do make error! reform [
                                "Unsupported Version Number"
                            ]
                        ]
                    ]
                ]
            ]

            loca "loca" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/loca
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6loca.html
                ;
                type: 'loca

                offsets: collect [
                    switch/default font/tables/head/location-format [
                        0 [
                            loop font/tables/maxp/glyphs + 1 [
                                keep shift unsigned-16 1
                            ]
                        ]

                        1 [
                            loop font/tables/maxp/glyphs + 1 [
                                keep unsigned-32
                            ]
                        ]
                    ][
                        do make error! "Invalid head/indexToLocFormat"
                    ]
                ]

                end: take/last offsets

                ; probe reduce [
                ;     end
                ;     font/index/("glyf")
                ; ]
                ;
                ; assert [
                ;     equal? end any [
                ;         font/index/("glyf")/3
                ;         font/index/("glyf")/2
                ;     ]
                ; ]

                neaten/by offsets 8
            ]

            glyf "glyf" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/glyf
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6glyf.html
                ;
                type: 'glyf

                glyphs: array length? font/tables/loca/offsets

                new-line glyphs true
                new-line tail glyphs true

                start: index? mark
                source: tail mark
            ]

            kern "kern" [
                ; https://docs.microsoft.com/en-us/typography/opentype/spec/kern
                ; https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6kern.html
                ;
                type: 'kern

                version:
                table: _

                switch/default version: unsigned-16 [
                    ; Microsoft version detected
                    ;
                    0 [
                        use [count] [
                            table: collect [
                                loop unsigned-16 [
                                    assert [
                                        unsigned-16 == 0
                                        ; only subtable format 0 supported
                                    ]

                                    advance 4
                                    ; skip subtable length, coverage

                                    count: unsigned-16

                                    advance 6
                                    ; skip search-range, entry-selector, range-shift

                                    loop count [
                                        keep unsigned-16
                                        keep unsigned-16
                                        keep as-fword signed-16
                                    ]
                                ]
                            ]

                            neaten/by table 9
                        ]
                    ]

                    ; Apple version detected
                    ;
                    1 [
                        probe 'mac-kerning
                    ]
                ][
                    version: 'unsupported
                ]
            ]

            cff1 "CFF " [
                version: reduce [
                    unsigned-8 unsigned-8
                ]

                size: unsigned-8
                offset: unsigned-8
            ]

            ; gasp "gasp"
        ][
            if offset: select font/index label [
                assert [
                    block? offset
                ]

                source:
                mark: skip head font/source offset/1

                switch font/container [
                    opentype [
                        ; sanity check
                        ;
                        assert [
                            offset/2 <= length? source
                        ]
                    ]

                    woff [
                        if offset/2 < offset/3 [
                            source: inflate/envelope source 'zlib
                        ]

                        ; sanity check
                        ;
                        assert [
                            offset/2 <= length? mark

                            any [
                                offset/3 == offset/2
                                offset/3 == length? source
                            ]
                        ]

                        mark: source
                    ]
                ]

                consume source [
                    set in font/tables table make object! bind prototype 'consume
                ]
            ]
        ]

        equal? font/tables/hhea/h-metrics-count font/tables/maxp/glyphs

        font/source: tail font/source
        font
    ]

    glyph: make object! [
        select: func [
            font [object!]
            character [char! integer!]

            /local glyph
        ][
            if char? character [
                character: to integer! character
            ]

            either glyph: lib/select/skip font/tables/cmap/glyph-index-map character 2 [
                any [
                    pick font/tables/glyf/glyphs glyph + 1
                    unpack font glyph + 1
                ]
            ][
                do make error! "Character not in font"
            ]
        ]

        unpack: func [
            font [object!]
            number [integer!]

            /local
            source count contours point-count points
            flags position offset arg1 arg2 subglyph
        ][
            assert [
                object? get in font/tables 'loca
                object? get in font/tables 'glyf
                number <= length? font/tables/loca/offsets
            ]

            source: at head font/tables/glyf/source font/tables/glyf/start + pick font/tables/loca/offsets number

            poke font/tables/glyf/glyphs number neaten collect [
                consume source [
                    count: signed-16

                    keep as-pair signed-16 signed-16
                    keep as-pair signed-16 signed-16
                    ; x-min y-min x-max y-max

                    case [
                        count > 0 [
                            contours: collect [
                                loop count [
                                    keep unsigned-16
                                ]
                            ]

                            ; instructions
                            ;
                            keep/only collect [
                                loop unsigned-16 [
                                    keep unsigned-8
                                ]
                            ]

                            point-count: 1 + last contours

                            points: neaten collect [
                                repeat point point-count [
                                    flags: unsigned-8

                                    keep/only reduce [
                                        as-pair 0 0 flags
                                    ]

                                    if has-flag flags 8 [
                                        ; flag 8 repeat-flag

                                        loop unsigned-8 [
                                            point: point + 1
                                            ; short circuit REPEAT

                                            keep/only reduce [
                                                0x0 flags
                                            ]
                                        ]
                                    ]
                                ]
                            ]

                            assert [
                                point-count == length? points
                            ]

                            position: as-pair 0 0
                            ; used to track current cumulative position

                            foreach point points [
                                either has-flag point/2 2 [
                                    ; flag 2 x-short-vector

                                    point/1/x: unsigned-8

                                    if not has-flag point/2 16 [
                                        ; flag 16 positive-x-short-vector

                                        point/1/x: negate point/1/x
                                    ]
                                ][
                                    either has-flag point/2 16 [
                                        ; flag 16 x-is-same

                                        point/1/x: 0
                                    ][
                                        point/1/x: signed-16
                                    ]
                                ]

                                position/x:
                                point/1/x: point/1/x + position/x
                            ]

                            foreach point points [
                                either has-flag point/2 4 [
                                    ; flag 4 y-short-vector

                                    point/1/y: unsigned-8

                                    if not has-flag point/2 32 [
                                        ; flag 32 positive-y-short-vector

                                        point/1/y: negate point/1/y
                                    ]
                                ][
                                    either has-flag point/2 32 [
                                        ; flag 32 y-is-same

                                        point/1/y: 0
                                    ][
                                        point/1/y: signed-16
                                    ]
                                ]

                                position/y:
                                point/1/y: point/1/y + position/y
                            ]

                            ; keep/only points

                            offset: -1

                            keep/only neaten collect [
                                foreach contour contours [
                                    contour: contour - offset
                                    offset: offset + contour

                                    keep/only neaten/by take/part points contour 6
                                ]

                                assert [
                                    empty? points
                                    ; not really necessary, but should add up
                                ]
                            ]
                        ]

                        zero? count [
                            keep/only make block! 0
                        ]

                        ; composite glyphs
                        ;
                        <else> [
                            arg1:
                            arg2: _

                            until [
                                flags: unsigned-16

                                subglyph: reduce [
                                    'xx 1 'xy 0 'yx 0 'yy 0
                                    'tx 0 'ty 0 'p1 -1 'p2 -1
                                    'ix unsigned-16
                                ]

                                either has-flag flags 1 [
                                    ; flag 1 arg-1-and-2-are-words

                                    arg1: signed-16
                                    arg2: signed-16
                                ][
                                    arg1: unsigned-8
                                    arg2: unsigned-8
                                ]

                                either has-flag flags 2 [
                                    ; flag 2 args-are-xy-values

                                    subglyph/tx: arg1
                                    subglyph/tx: arg2
                                ][
                                    subglyph/p1: arg1
                                    subglyph/p2: arg2
                                ]

                                case [
                                    has-flag flags 8 [
                                        ; flag 8 we-have-a-scale

                                        subglyph/xx:
                                        subglyph/yy: as-f2dot14 unsigned-16
                                    ]

                                    has-flag flags 64 [
                                        ; flag 64 we-have-an-x-and-y-scale

                                        subglyph/xx: as-f2dot14 unsigned-16
                                        subglyph/yy: as-f2dot14 unsigned-16
                                    ]

                                    has-flag flags 128 [
                                        ; flag 128 we-have-a-two-by-two

                                        subglyph/xx: as-f2dot14 unsigned-16
                                        subglyph/yx: as-f2dot14 unsigned-16
                                        subglyph/xy: as-f2dot14 unsigned-16
                                        subglyph/yy: as-f2dot14 unsigned-16
                                    ]
                                ]

                                zero? flags and 32
                                ; flag 32 more-components
                            ]

                            ; instructions
                            ;
                            if has-flag flags 256 [
                                ; flag 256 we-have-instructions

                                keep/only collect [
                                    loop unsigned-16 [
                                        keep unsigned-8
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        unpack-all: func [
            font [object!]
        ][
            assert [
                object? get in font/tables 'glyf
            ]

            repeat number length? font/tables/glyf/glyphs [
                unpack font number
            ]

            neaten font/tables/glyf/glyphs
        ]

        as-path: func [
            font [object!]
            glyph [block!]

            /local offset control height
        ][
            offset: [
                ; back _
                here _
                next _
            ]

            ; height: glyph/2/y ; - glyph/1/y
            height: font/tables/os-2/windows/ascender

            neaten/pairs collect [
                foreach contour glyph/4 [
                    offset/here: last contour
                    offset/next: first contour

                    keep 'move

                    keep/only collect [
                        case [
                            odd? offset/here/2 [
                                keep as-pair
                                offset/here/1/x
                                height - offset/here/1/y
                            ]

                            odd? offset/next/2 [
                                keep as-pair
                                offset/next/1/x
                                height - offset/next/1/y
                            ]

                            ; If both first and last points are off-curve, start at their middle.
                            ;
                            <else> [
                                keep as-pair
                                offset/here/1/x + offset/next/1/x / 2
                                height - (offset/here/1/y + offset/next/1/y / 2)
                            ]
                        ]
                    ]

                    forall contour [
                        ; offset/back: offset/here
                        offset/here: contour/1
                        offset/next: any [
                            pick contour 2
                            first head contour
                        ]

                        either odd? offset/here/2 [
                            keep 'line
                            keep/only reduce [
                                as-pair
                                offset/here/1/x
                                height - offset/here/1/y
                            ]
                        ][
                            control: offset/next/1

                            if even? offset/next/2 [
                                control: control + offset/here/1 / 2
                            ]

                            keep 'qcurve
                            keep/only neaten/flat reduce [
                                as-pair
                                offset/here/1/x
                                height - offset/here/1/y

                                as-pair
                                to integer! control/x
                                round height - control/y
                            ]
                        ]
                    ]

                    keep [
                        close []
                    ]
                ]
            ]
        ]

        draw: func [
            glyph [block!]
            /controls
        ][
            ; probe copy/part glyph 2

            layout compose/deep [
                box
                ; 1200x600
                (as-pair glyph/2/x - glyph/1/x * 0.3 glyph/2/y - glyph/1/y * 0.3)
                #"^w" [unview]
                effect [
                    draw [
                        transform 0x0 0 0.3 -0.3 (as-pair 0 - glyph/1/x * 0.3 glyph/2/y * 0.3)
                        (
                            collect [
                                ; Bounding Box
                                ;
                                if controls [
                                    keep compose [
                                        pen 255.0.0
                                        line-width 10
                                        box (glyph/1) (glyph/2)
                                    ]
                                ]

                                ; Glyph
                                ;
                                keep compose/deep [
                                    pen off
                                    fill-pen 0.0.0

                                    shape [
                                        (sfnt/glyph/as-path glyph/4)
                                    ]
                                ]

                                ; Points on Glyph
                                ;
                                if controls [
                                    keep [
                                        fill-pen 204.0.0
                                    ]

                                    foreach contour glyph/4 [
                                        foreach point contour [
                                            keep reduce [
                                                'circle point/1 pick [3 10] zero? point/2
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        )
                    ]
                ]
            ]
        ]
    ]

    align-otf-table-entry: func [
        entry [block!]
    ][
        append entry _
        append entry take entry
    ]

    init-opentype: func [
        source [binary!]
        /local font
    ][
        font: make prototype/font [
            container: 'opentype

            tables: make prototype/tables []
        ]

        consume source [
            font/type: consume 4

            font/info: make prototype/info [
                table-count: unsigned-16
                search-range: unsigned-16
                entry-selector: unsigned-16
                range-shift: unsigned-16
            ]

            font/index: neaten/pairs collect [
                loop font/info/table-count [
                    keep reduce [
                        as-string consume 4

                        neaten/flat align-otf-table-entry reduce [
                            consume 4
                            ; checksum

                            unsigned-32
                            ; offset

                            unsigned-32
                            ; length
                        ]
                    ]
                ]
            ]
        ]

        case [
            not font/type: switch font/type [
                #{00010000}
                #{74727565}
                #{74797031} [
                    'truetype
                ]

                #{4f54544f} [
                    'cff
                ]
            ][
                do make error! "Unsupporte"
            ]

            equal? required/(font/type) intersect/case required/(font/type) font/index
        ]

        font/source: source

        font
    ]

    init-woff: func [
        source [binary!]
        /local font
    ][
        assert [
            consume source #{774f4646}
            ; magic number
        ]

        font: make prototype/font [
            container: 'woff

            tables: make prototype/tables []
        ]

        consume source [
            font/type: consume 4

            font/info: make prototype/info [
                length: unsigned-32
                table-count: unsigned-16
                reserved: unsigned-16
                size: unsigned-32

                version: reduce [
                    unsigned-16 unsigned-16
                ]

                meta: reduce [
                    'offset unsigned-32
                    'length unsigned-32
                    'size unsigned-32
                ]

                private-offset: unsigned-32
                private-needs: unsigned-32
            ]

            font/index: neaten/pairs collect [
                loop font/info/table-count [
                    keep reduce [
                        as-string consume 4

                        neaten/flat reduce [
                            unsigned-32
                            ; offset

                            unsigned-32
                            ; length

                            unsigned-32
                            ; needs

                            consume 4
                            ; checksum
                        ]
                    ]
                ]
            ]
        ]

        assert [
            font/type: switch font/type [
                #{00010000}
                #{74727565}
                #{74797031} [
                    'truetype
                ]

                #{4f54544f} [
                    'cff
                ]
            ]

            equal? required/(font/type) intersect/case required/(font/type) font/index
        ]

        font/source: source

        font
    ]

    load-otf: func [
        [catch]
        source [binary!]
    ][
        switch/default copy/part source 4 [
            #{00010000}
            #{74727565}
            #{74797031}
            #{4f54544f} [
                init-tables init-opentype source
            ]

            #{774f4646} [
                init-tables init-woff source
            ]

            #{74746366} [
                do make error! "TTC Unsupported"
            ]

            #{774f4632} [
                do make error! "WOFF2 Unsupported"
            ]
        ][
            ; probe copy/part source 4
            do make error! "Unknown SFNT signature"
        ]
    ]

    to-xml: func [
        source [file!]
        /local output error status
    ][
        output: make string! 4096
        error: make string! 128

        status: call/wait/output/error rejoin [
            "ttx -o - " replace/all to string! source " " "\ "
        ] output error

        assert [
            either zero? status [
                true
            ][
                print error
                false
            ]
        ]

        output
    ]
]
