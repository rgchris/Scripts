Rebol [
    Title: "Octal Notation"
    Author: "Christopher Ross-Gill"
    Date: 16-Jun-2020
    Version: 0.1.0
    File: %octal.reb

    Purpose: "Encode/Decode Octal Values"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.octal
    Exports: [
        octal
    ]

    Comment: [
        https://www.jstor.org/stable/983079?seq=35#metadata_info_tab_contents
        "Octal Numeration"
    ]
]

octal: context [
    sum: func [
        numbers [block!]
    ][
        assert [
            parse numbers: copy numbers [
                some [
                    number! | money!
                ]
            ]
        ]

        while [
            not tail? next numbers
        ][
            numbers/1: numbers/1 + take/last numbers
        ]

        take numbers
    ]

    numerals: [
        #{E18EBE} #{E18F93} #{E18F9D} #{E18F8B}
        #{E18EB5} #{E18EAE} #{E18FAE} #{E18FB0}
    ]

    tables: collect [
        foreach suffix [
            "" "ty" "der" "tyder" "sen" "tysen" "dersen" "tydersen" "kaly"
            "tykaly" "tyderkaly" "senkaly" "tysenkaly" "dersenkaly" "tydersenkaly" "?"
        ][
            keep/only collect [
                foreach prefix ["un" "du" "the" "fo" "pa" "se" "ki"] [
                    keep rejoin [prefix suffix]
                ]
            ]
        ]
    ]

    powers: #(
        uint32! [
            1 8 64 512 4096 32768 262144 2097152 16777216
        ]
    )

    encode: func [
        value [integer!]
    ][
        rejoin reverse collect [
            loop 9 [
                value: value - keep remainder value 8
                value: value / 8

                if zero? value [
                    break
                ]
            ]

            if not zero? value [
                make error! "Value too large"
            ]
        ]
    ]

    decode: func [
        value [string!]
    ][
        value: reverse copy value

        sum collect [
            repeat exp length-of value [
                keep multiply powers/:exp -48 + value/:exp
            ]
        ]
    ]

    to-cardinal: func [
        value [integer! string!]

        /local part joiner
    ][
        value: reverse case [
            integer? value [
                encode value
            ]

            string? value [
                copy value
            ]
        ]

        joiner: ""

        uppercase/part rejoin reverse collect [
            either value = "0" [
                keep "aught"
            ][
                repeat exp length-of value [
                    if part: pick tables/:exp -48 + value/:exp [
                        keep joiner
                        keep part

                        joiner: "-"
                    ]
                ]
            ]
        ] 1
    ]
]
