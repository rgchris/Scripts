Rebol [
    Title: "UTF-8 Encode/Decode"
    Author: "Christopher Ross-Gill"
    Date: 29-Jul-2021
    Version: 0.1.0
    File: %utf-8.reb

    Purpose: "UTF-8 encoder/decoder/tools for Rebol 3"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.utf-8
    Exports: [
        utf-8
    ]

    Needs: [
        r3:rgchris:core
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

utf-8: context [
    utf-8: self

    done: use [mark] [
        [mark: return (mark)]
    ]

    charsets: make object! [
        ; charsets are stored as compressed binary that can be converted as follows:
        ; make bitset! decompress value 'zlib
        ;
        whitespace: #{
            789C6360606068604005E8FC51300A860A681868070C31F0FF01906004331907
            D421A36040400300579703E2
        }

        other-control: #{
            789CFBFFFFFF7F0604600472FF030053C507FA
        }

        punctuation-connector: #{
            789CEDCEA10D00201004C17B0525502EA59320905804337AC5264705F851CDF4
            D70F000000000000C03692760D6A012F8100AB
        }

        punctuation-dash: #{
            789CEDD9B10D80201005503414968EC0088EE4280C6E215A1A2A251292F78ADF
            40725770D7104211C338D29D73DF26682577AEEF211DBD1BE0932995D8F2FB2D
            BE3CA73057AF010000000000F09FFD8ABCD68E46FADBA78D78024F6C047A
        }

        punctuation-close: #{
            789CEDD9BF0A802010C061938668AEBDB9A770690FCAF7F1117A8CF029D3A8A6
            8812E91FBF0F3C05F1B85B5C4E0847F920D265E17F8AA70BB851F674015F24D7
            4D464EDCBA5545CE194AF7DBD1B799E8EB29726BCD72F49DBDE2BF2C958F720C
            7AAC9B2E662D00000000000000000038E5682A67DCB51D8DA8776FD51CE7D9FE
            300143BF0952
        }

        punctuation-final: #{
            789C6360C00A04B00B8F8251300A8619700162858176C428200F88A830B03800
            00113800F1
        }

        punctuation-initial: #{
            789C6360C00204B0098E8251300A86219809C40E03ED8851401ED0F060E06800
            00DFBE01E2
        }

        punctuation-other: #{
            789CEDDAB14EC2401807F0EF2C010742D934D10476174D1C4C3482BBEF200FE0
            A093249AD0C127D0DD67F0119AF8000E0EAE1DD96464C09EB4057ABD5EE995B6
            A0F1FF1BAE77BD8FEF3E9101EE4A447477404716D136CD5C90C1A81C5B391277
            FCB61B0C9EFC7697E89A761611676278F0E7F0C9B294CC0EAEDCF56A4B2BA04E
            967CAB121DCA2962F12958F84FD02244333A5445987C181987058F7B91898E72
            8166A6725270ABC86C0AF2DBBF3FEF5415C10DC76BBF1DBDD4F5E42943BEE1AA
            3F731D2B5E8839BBB6E45CBCD8B77E0963BA167FB9E59FEE9A16047DF7D1A115
            0B787B763FE89CBF5FF1939516B8092E9584E9757D08010000000000E07F8BED
            ADC4D4C44153DA01526F6A2533C36EB0F250E847B62E0793586DA6349ECEDBCB
            97C3AF6B00000000C8CCED7AE742D5FE17B35FE3B3E2D9FEE50AD99D3CA5A9CD
            BE475B2BBFB21C89C999DECAFEE9B614B738521D0837FBD9EA2A4ACDF65AC356
            CFB2E899F59E1C36F2DBF014BCF6283C7741147D75377B75D4A2637198F630C6
            80F3C8D83BC7E4E3C40A1A29E9527F89A912B4C32E130ECF4F1D2186DB699903
            0F7EAB19AC8D59F35E8BAB030A5E30A7717A0814A8B7E902000000FEBED869C5
            FCB13A36CAF65C6F1ECCD18D6C97570400000000E8FB657B7200A08B8D365D01
            94C4F80152B449C6
        }

        punctuation-open: #{
            789CEDD9B10A83301080E16B89D0B10EEEE254FA147D0405F33E997D0A870E92
            A76CAE5527916A420BF27F70C7C191E302D92212384D721D03C773FBF7023FC4
            1BDEA6D2643EB5998A64FA108FC433F7F2C35CEA35CF7EFB88C2DAA9EC435CE2
            978A777722A564F5AEC3BE7BA6DD060000000000000000005F38ADB732DB88B4
            8B6DF7CEFA279A972FA3170A09
        }

        punctuation: #{
            789CED9A414EE33014869F49456781689140541A46E50833123B900A37E90158
            74C7483352B3E004739239426E30DC802CBBA33BBA4079C449D338B1133BA199
            82F83F29F6B3FDFCFC62D951E21722A2BB27FAE1137D8BC5E3F8A29BA17744DD
            B027DAF79D24E934B5F327C94644B774BAD1B852D5BF2429BFD49914419A7324
            6DDA1C3820BF5CD52B16CB26347D0B62EDB52B8AB6A0EF268D012F64B69999DC
            E1D5B4A038310E306CE48E05F6F53A43557BD2E91F6DCA6799B06F503E0C139F
            4237D307D54D5EB92232AFB989AF3B3258E7E3B22DDEEED4D7C0CCF1F5CC8F72
            0FEC1BA7EA2D2C29DBB3BB477918C8DBF4B8B989316F56B1BCB39A65B1157E15
            8BBEA6C092482693DA275D1533FE17CF825F788E29A3FCAF4508000000000000
            00E073A39DAD68F4D5C2B07400673ED4AA66908BE9C80B452E1C5DCE5F34DF06
            A572DC1ED40F87AF6B000000000060A6E63D9883340AF4C40F7FF55625B67FD2
            264014B6E86361FD1EEDB7EED90D95C685DBC8495CB0A41765C25CA9FCD9CCAF
            16F44C95FD40A65E60EE228A8BE36B596D99A479B8B37FAFFC774154EC7D6D73
            D0C0982ED4A2ED678C391783B7B3F8E255A507871673D62F319381F35C14512E
            5F868A8EDC9D2EFC4E52476567849F496373ACBBD31DD59C955D056C91E9AE1D
            000000003E3EDA575AF6222E96CDFEEB7D0B2274D53CEFCE090000000000E0CE
            3B3B930300B82296BBF6007484F70AE2C66513
        }

        combining-characters: #{
            789C6360A02DF88F020069050DF3
        }
    ]

    =00-7F: charset [0 - 127]

    =C2-DF: charset [194 - 223]

    =E0: #"^(E0)"
    =ED: #"^(ED)"
    =E1-EC-EE-EF: charset [225 - 236 238 - 239]

    =F0: #"^(F0)"
    =F1-F3: charset [241 - 243]
    =F4: #"^(F4)"

    =80-8F: charset [128 - 143]
    =80-9F: charset [128 - 159]
    =80-BF: charset [128 - 191]
    =90-BF: charset [144 - 191]
    =A0-BF: charset [160 - 191]

    character: make object! [
        value: _
        mark: _

        unknown: 65533

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

            insert/dup L2 #(none) 193
            insert/dup L3 #(none) 223
            insert/dup L4 #(none) 239
            insert/dup E2 #(none) 127
            insert/dup E3 #(none) 127

            [
                mark:

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

                mark:
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

        either string? encoding [
            value/1: to integer! encoding/1
            value/2: next encoding
        ][
            parse encoding [
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

                value/2: next encoding
            ]
        ]

        value
    ]

    encode: func [
        "Encode a code point in UTF-8 format"

        char [integer!]
        "Unicode code point"
    ][
        to binary! reduce case [
            char <= 127 [
                [char]
            ]

            ; Rebol 3 Bypass!
            ;
            char <= 65535 [
                to char! char
            ]

            ; U+0080 - U+07FF
            ;
            char <= 2047 [
                [
                    192 or shift char and 1984 -6
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
                    224 or shift char and 61440 -12
                    128 or shift char and 4032 -6
                    char and 63 or 128
                ]
            ]

            ; U+010000 - U+10FFFF
            ;
            char <= 1114111 [
                [
                    240 or shift char and 1835008 -18
                    128 or shift char and 258048 -12
                    128 or shift char and 4032 -6
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

    length-of: func [
        encoding [binary!]
        /local count
    ][
        count: 0

        assert [
            parse encoding [
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
                    ; possibly add error handling
                ]
            ]
        ]

        count
    ]

    new: func [
        value [binary!]
    ][
        reduce [
            'utf-8 value
        ]
    ]

    step: func [
        encoding [block!]
    ][
        case [
            tail? encoding/2 [
                _
            ]

            parse encoding/2 [
                character/match
                done
            ][
                encoding/2: character/mark
                character/value
            ]

            <else> [
                encoding/2: next encoding/2
                character/unknown
            ]
        ]
    ]

    sanitize: func [
        encoding [binary!]
        /local value char
    ][
        value: make binary! lib/length-of encoding

        encoding: new encoding

        while [
            char: step encoding
        ][
            ; set [char encoding] decode encoding
            ; value: insert value encode char
            value: insert value encode char
        ]

        head value
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
