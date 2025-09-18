Rebol [
    Title: "Extract URLs"
    Author: "Christopher Ross-Gill"
    Date: 31-Jul-2010
    Version: 2.0.0
    File: %extract-urls.r

    Purpose: "Identifies and extracts URLs from plain text"

    Home: https://www.ross-gill.com/page/Beyond_Regular_Expressions
    Rights: public-domain

    Type: module
    Name: r2c.extract-urls
    Exports: [
        extract-urls
    ]

    Comment: [
        http://daringfireball.net/2010/07/improved_regex_for_matching_urls
        {
        Inspired by a blog post outlining an effort to match URLs in plain text,
        primarily with the purpose of linkifying text when converting to HTML.
        }

        https://reb4.me/r/link-up
        "Originally paired with a style that added links for Rebol/View."
    ]
]

extract-urls: use [
    url has-protocol
    space punct chars paren
][
    space: charset "^/^- ()<>^"'"
    ; for 'smart' quotes, need unicode (Rebol 3)

    punct: charset "!'#$%&`*+,-./:;=?@[/]^^{|}~"
    ; regex 'punct without ()<>

    chars: complement union space punct

    paren: [
        #"("
        some [
            chars | punct
            |
            #"("
            some [
                chars | punct
            ]
            #")"
        ]
        #")"
    ]

    url: [
        (has-protocol: no)
        [
            lower-alpha
            some [
                alpha | digit | #"_" | #"-"
            ]
            #":"
            [
                1 3 #"/"
                |
                lower-alpha
                |
                digit
                |
                #"%"
            ]
            (has-protocol: yes)
            |
            "www"
            0 3 digit
            #"."
            |
            some [
                lower-alpha | digit
            ]
            #"."
            2 4 lower-alpha
        ]

        some [
            opt [
                some punct
            ]

            some [
                chars | paren
            ]

            opt #"/"
        ]
    ]

    func [
        "Separates URLs from plain text"

        text [string!]
        "Text to be split"

        /local mark extent link
    ][
        collect [
            assert [
                parse/all/case text [
                    mark:
                    any [
                        extent:
                        copy link url
                        (
                            if mark <> extent [
                                keep copy/part mark extent
                            ]

                            if not has-protocol [
                                insert link http://
                            ]

                            keep to url! link
                        )
                        |
                        some [
                            chars | punct
                        ]
                        some space
                        |
                        skip
                    ]
                    extent:
                    (
                        if mark <> extent [
                            keep copy/part mark extent
                        ]
                    )
                ]
            ]
        ]
    ]
]
