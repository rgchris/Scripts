Rebol [
    Title: "Clean"
    Author: "Christopher Ross-Gill"
    Date: 18-Apr-2018
    Version: 0.1.2
    File: %clean.reb

    Purpose: "Converts errant CP-1252 codepoints within a UTF-8 binary"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.clean
    Exports: [
        clean
    ]

    History: [
        18-Apr-2018 0.1.2
        "Adapted for Rebol 3"

        14-Aug-2013 0.1.1
        "Working Version"
    ]
]

clean: use [
    codepoints ascii utf-b utf-2 utf-3 utf-4 here cleaner
][
    codepoints: #[
        128 #{E282AC} 130 #{E2809A} 131 #{C692} 132 #{E2809E} 133 #{E280A6} 134 #{E280A0}
        135 #{E280A1} 136 #{CB86} 137 #{E280B0} 138 #{C5A0} 139 #{E280B9} 140 #{C592}
        142 #{C5BD} 145 #{E28098} 146 #{E28099} 147 #{E2809C} 148 #{E2809D} 149 #{E280A2}
        150 #{E28093} 151 #{E28094} 152 #{CB9C} 153 #{E284A2} 154 #{C5A1} 155 #{E280BA}
        156 #{C593} 158 #{C5BE}
        ; CP-1252 specific range--not in ISO 8859-1
    ]

    ascii: charset [0 - 127]
    utf-b: charset [128 - 191]
    utf-2: charset [194 - 223]
    utf-3: charset [224 - 239]
    utf-4: charset [240 - 244]

    here: _

    cleaner: [
        some ascii
        |
        ; simplistic representation of UTF-8
        ;
        utf-2 utf-b | utf-3 2 utf-b | utf-4 3 utf-b
        |
        change here: skip (
            case [
                did select codepoints here/1 [
                    codepoints/(here/1)
                ]

                here/1 > 191 [
                    reduce [
                        195 here/1 and 191
                    ]
                ]

                here/1 > 158 [
                    reduce [
                        194 here/1
                    ]
                ]

                #else [
                    [239 191 189]
                ]
            ]
        )
    ]

    clean: func [
        "Converts errant CP-1252 codepoints within a UTF-8 binary"

        text [binary!]
        "Binary to convert"
    ][
        parse/case text [
            any cleaner
        ]

        to string! text
    ]
]
