Rebol [
    Title: "Decode/Encode Slugs"
    Author: "Christopher Ross-Gill"
    Date: 18-Oct-2011
    Version: 0.1.0
    File: %slugs.r

    Purpose: "Encode/Decode URL-friendly slugs"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.wordify
    Exports: [
        slugs
    ]

    History: [
        18-Oct-2011 0.1.0
        "Original Version"
    ]

    Usage: [
        "testing-internationalizaetion" ==
        slugs/encode "Testing Iñtërnâtiônàlizætiøn"
    ]
]

slugs: context private [
    alphanum: charset [
        #"0" - #"9"
        #"a" - #"z"
        #"A" - #"Z"
    ]

    digit: charset [
        #"0" - #"9"
    ]

    alpha: charset [
        #"A" - #"Z"
        #"a" - #"z"
    ]

    punct: charset [
        "!()"
        ; "*!',()"
    ]

    encoder: context [
        chars:
        text:
        slug:
        extras: _

        emit: func [
            value
        ][
            append slug value
        ]

        codes: [
            copy chars some alphanum
            (emit chars)
            |
            [#" " | #"-" | #"/" | #"_" | "‑" | "–" | "—" | "⁻" | "₋" | " "]
            (emit #"-")
            |
            ["⁰" | "₀"]
            (emit #"0")
            |
            ["¹" | "₁"]
            (emit #"1")
            |
            ["²" | "₂"]
            (emit #"2")
            |
            ["³" | "₃"]
            (emit #"3")
            |
            ["⁴" | "₄"]
            (emit #"4")
            |
            ["⁵" | "₅"]
            (emit #"5")
            |
            ["⁶" | "₆"]
            (emit #"6")
            |
            ["⁷" | "₇"]
            (emit #"7")
            |
            ["⁸" | "₈"]
            (emit #"8")
            |
            ["⁹" | "₉"]
            (emit #"9")
            |
            "Ä"
            (emit "Ae")
            |
            ["À" | "Á" | "Â" | "Ã" | "Å" | "Ā"]
            (emit #"A")
            |
            "ä"
            (emit "ae")
            |
            ["ₐ" | "ª" | "à" | "á" | "â" | "ã" | "å" | "ā"]
            (emit #"a")
            |
            ["Ç" | "Ć"]
            (emit #"C")
            |
            ["ç" | "ć"]
            (emit #"c")
            |
            "Ð"
            (emit #"D")
            |
            "đ"
            (emit #"d")
            |
            ["È" | "É" | "Ê" | "Ë"]
            (emit #"E")
            |
            ["ₑ" | "è" | "é" | "ê" | "ë"]
            (emit #"e")
            |
            "ƒ"
            (emit #"f")
            |
            "ğ"
            (emit #"g")
            |
            "Ğ"
            (emit #"G")
            |
            ["I" | "Ì" | "Í" | "Î"]
            (emit "I")
            |
            ["ì" | "í" | "î" | "ī" | "ı"]
            (emit #"i")
            |
            "Ï"
            (emit "Ii")
            |
            "ï"
            (emit "ii")
            |
            "Ñ"
            (emit #"N")
            |
            ["ⁿ" | "ñ"]
            (emit #"n")
            |
            "№"
            (emit "Nr")
            |
            ["Ö" | "Œ"]
            (emit "Oe")
            |
            ["Ò" | "Ó" | "Ô" | "Õ" | "Ø"]
            (emit #"O")
            |
            ["ö" | "œ"]
            (emit "oe")
            |
            ["ₒ" | "ð" | "ò" | "ó" | "ô" | "õ" | "ø"]
            (emit #"o")
            |
            ["Ş" | "Š"]
            (emit "S")
            |
            ["ş" | "š"]
            (emit "s")
            |
            "ß"
            (emit "ss")
            |
            ["Ú" | "Ù" | "Û"]
            (emit #"U")
            |
            ["ù" | "ú" | "û"]
            (emit #"u")
            |
            "Ü"
            (emit "Ue")
            |
            "ü"
            (emit "ue")
            |
            "×"
            (emit #"x")
            |
            ["Ý" | "Ÿ"]
            (emit #"Y")
            |
            ["ý" | "ÿ"]
            (emit #"y")
            |
            "Ž"
            (emit #"Z")
            |
            "ž"
            (emit #"z")
            |
            extras
            |
            skip
        ]

        loose: [
            copy chars some punct
            (emit chars)
            |
            "."
            (emit "_")
            |
            ["⁰" | "₀"]
            (emit "(0)")
            |
            ["¹" | "₁"]
            (emit "(1)")
            |
            ["²" | "₂"]
            (emit "(2)")
            |
            ["³" | "₃"]
            (emit "(3)")
            |
            ["⁴" | "₄"]
            (emit "(4)")
            |
            ["⁵" | "₅"]
            (emit "(5)")
            |
            ["⁶" | "₆"]
            (emit "(6)")
            |
            ["⁷" | "₇"]
            (emit "(7)")
            |
            ["⁸" | "₈"]
            (emit "(8)")
            |
            ["⁹" | "₉"]
            (emit "(9)")
            |
            "¼"
            (emit "(1-4)")
            |
            "½"
            (emit "(1-2)")
            |
            "¾"
            (emit "(3-4)")
            |
            "Æ"
            (emit "(AE)")
            |
            "æ"
            (emit "(ae)")
            |
            "©"
            (emit "(c)")
            |
            "°"
            (emit "(deg)")
            |
            "º"
            (emit "(o)")
            |
            "®"
            (emit "(r)")
            |
            "™"
            (emit "(tm)")
        ]

        tight: [
            ["⁰" | "₀"]
            (emit #"0")
            |
            ["¹" | "₁"]
            (emit #"1")
            |
            ["²" | "₂"]
            (emit #"2")
            |
            ["³" | "₃"]
            (emit #"3")
            |
            ["⁴" | "₄"]
            (emit #"4")
            |
            ["⁵" | "₅"]
            (emit #"5")
            |
            ["⁶" | "₆"]
            (emit #"6")
            |
            ["⁷" | "₇"]
            (emit #"7")
            |
            ["⁸" | "₈"]
            (emit #"8")
            |
            ["⁹" | "₉"]
            (emit #"9")
            |
            "¼"
            (emit "1-4")
            |
            "½"
            (emit "1-2")
            |
            "¾"
            (emit "3-4")
            |
            "Æ"
            (emit "AE")
            |
            "æ"
            (emit "ae")
            |
            "©"
            (emit #"c")
            |
            "º"
            (emit #"o")
            |
            "°"
            (emit "deg")
            |
            "®"
            (emit #"r")
            |
            "™"
            (emit "tm")
        ]

        rule: [
            any codes
        ]

        clean-up: use [
            mk ex tm
        ][
            [
                (tm: [end skip])
                mk:
                any #"-"
                ex:
                (remove/part mk ex)
                :mk

                some [
                    mk:
                    some #"-"
                    end
                    (clear mk)
                    :mk
                    |
                    #"-"
                    mk:
                    some "-"
                    ex:
                    (remove/part mk ex)
                    :mk
                    |
                    skip
                    tm:
                ]

                :tm
                end
            ]
        ]
    ]

    decoder: context [
        char:
        slug:
        text:
        in-word: _

        emit: func [
            value
        ][
            append text value
        ]

        punct: charset [
            "*!',()"
        ]

        codes: [
            copy char some alpha
            (
                emit either in-word [
                    char
                ][
                    uppercase/part char 1
                ]

                in-word: yes
            )
            |
            copy char some digit
            (
                emit char
                in-word: yes
            )
            |
            (in-word: no)
            "(1)"
            (emit "¹")
            |
            "(2)"
            (emit "²")
            |
            "(3)"
            (emit "³")
            |
            "(1-4)"
            (emit "¼")
            |
            "(1-2)"
            (emit "½")
            |
            "(3-4)"
            (emit "¾")
            |
            "(AE)"
            (emit "Æ")
            |
            "(ae)"
            (emit "æ")
            |
            "(c)"
            (emit "©")
            |
            "(deg)"
            (emit "°")
            |
            "(o)"
            (emit "º")
            |
            "(r)"
            (emit "®")
            |
            "(tm)"
            (emit "™")
            |
            (in-word: no)
            "_"
            (emit #".")
            |
            "-"
            (emit #" ")
            |
            copy char punct
            (emit char)
            |
            skip
        ]

        decode: [
            any codes
        ]
    ]
][
    encode: func [
        text [string!]
        /case
        /loose
    ][
        encoder/slug: copy ""
        encoder/extras: either loose [
            encoder/loose
        ][
            encoder/tight
        ]

        all [
            parse/all/case text encoder/rule

            parse/all encoder/slug encoder/clean-up

            either case [
                encoder/slug
            ][
                lowercase encoder/slug
            ]
        ]
    ]

    decode: func [
        slug [string!]
    ][
        decoder/text: copy ""
        decoder/in-word: no

        parse/all/case slug decoder/decode

        decoder/text
    ]
]
