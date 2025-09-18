Rebol [
    Title: "Sanitize"
    Author: "Christopher Ross-Gill"
    Date: 10-Oct-2012
    Version: 0.9.0
    File: %sanitize.r

    Purpose: "Replace HTML/XML delimiters with respective escape codes"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.sanitize
    Exports: [
        sanitize
    ]

    Needs: [
        shim
        r2c:utf-8
    ]
]

sanitize: use [
    ascii html*
][
    ascii: exclude charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
    html*: exclude ascii charset {&<>"}

    sanitize: func [
        text [any-string!]
        /local char
    ][
        parse/all text: as-binary copy text [
            any [
                text:
                some html*
                text:
                |
                [
                    #"&"
                    (text: change/part text "&amp;" 1)
                    |
                    #"<"
                    (text: change/part text "&lt;" 1)
                    |
                    #">"
                    (text: change/part text "&gt;" 1)
                    |
                    #"^""
                    (text: change/part text "&quot;" 1)
                    |
                    #"^M"
                    (remove text)
                    |
                    utf-8/character/match
                    (
                        text: change/part as-binary text rejoin [
                            "&#" utf-8/character/value ";"
                        ] utf-8/character/mark
                    )
                    |
                    skip
                    (text: change/part text "&#65533;" 1)
                ]
                :text
            ]
        ]

        head text
    ]
]
