Rebol [
    Title: "Web Form Encoder/Decoder for Rebol 3"
    Author: "Christopher Ross-Gill"
    Date: 6-Sep-2015
    Home: http://www.ross-gill.com/page/Web_Forms_and_REBOL
    File: %altwebform.r3
    Version: 0.10.2
    Purpose: "Convert a Rebol block to a URL-Encoded Web Form string"
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.altwebform
    Exports: [url-decode url-encode load-webform to-webform]
    History: [
        06-Sep-2015 0.10.2 "Tidy/Detab"
        06-Sep-2015 0.10.1 "Add Ruby-style paths to encoding"
        06-Jul-2013  0.9.5 "Fix encoding/decoding of _ character"
        01-Mar-2013  0.9.4 "Detach URL-DECODE and URL-ENCODE"
        27-Feb-2013  0.9.2 "Correct encoding of UTF-8 values"
        18-Nov-2009  0.1.0 "Original Version"
    ]
    Usage: [
        load-webform "a=3&aa.a=1&b.c=1&b.c=2"
        to-webform [a "3" aa [a "1"] b [c ["1" "2"]]]
    ]
]

url-decode: use [as-is hex space][
    as-is: charset ["-.~" #"0" - #"9" #"A" - #"Z" #"a" - #"z"]
    hex: charset [#"0" - #"9" #"a" - #"f" #"A" - #"F"]

    func [
        "Decode percent-encoded text from URLs and Web Forms"
        text [any-string!] "Text to Decode"
        /wiki "Assumes `_` character is used to represent spaces"
    ][
        space: either wiki [#"_"][#"+"]
        either parse text: to binary! text [
            copy text any [
                  some as-is | remove space insert " "
                | [#"_" | #"+" | #"." | #","]
                | change "%0D%0A" "^/" ; de-crlf
                | remove ["%" copy text 2 hex] (text: debase/base text 16) insert text
            ]
        ][to string! text][none]
    ]
]

url-encode: use [as-is space percent-encode][
    as-is: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]
    percent-encode: func [text][
        insert next text enbase/base copy/part text 1 16 change text "%"
    ]

    func [
        "Encode text using percent-encoding for URLs and Web Forms"
        text [any-string!] "Text to encode"
        /wiki "Use `_` character to represent spaces"
    ][
        space: either wiki [#"_"][#"+"]
        either parse text: to binary! text [
            copy text any [
                  text: some as-is | end | change " " space
                | [#"_" | #"."] (either wiki [percent-encode text][text])
                | skip (percent-encode text)
            ]
        ][to string! text][""]
    ]
]

load-webform: use [result path string pair as-path term][
    result: copy []

    as-path: func [name [string!]][
        to path! to block! replace/all name #"." #" "
    ]

    path: use [aa an wd][
        aa: charset [#"a" - #"z" #"A" - #"Z" #"_"]
        an: charset [#"-" #"0" - #"9" #"a" - #"z" #"A" - #"Z" #"_"]
        wd: [aa 0 40 an] ; one alpha, any alpha/numeric/dash/underscore
        [wd 0 6 [#"." wd]]
    ]

    string: use [ch hx][
        ch: charset ["-._~" #"0" - #"9" #"A" - #"Z" #"a" - #"z"]
        hx: charset [#"0" - #"9" #"a" - #"f" #"A" - #"F"]
        [any [ch | #"+" | #"%" 2 hx]] ; any [unreserved | percent-encoded]
    ]

    term: [#"&" | end]

    pair: use [name value tree][
        [
            copy name path [
                #"=" copy value string term | term (value: true)
            ] (
                tree: :result
                name: as-path name
                if string? value [value: url-decode value]

                until [
                    tree: any [
                        find/tail tree name/1
                        insert tail tree name/1
                    ]

                    name: next name

                    switch type?/word tree/1 [
                        none! [unless tail? name [insert/only tree tree: copy []]]
                        string! [change/only tree tree: reduce [tree/1]]
                        block! [tree: tree/1]
                    ]

                    if tail? name [append tree value]
                ]
            )
        ]
    ]

    func [
        [catch] "Loads data from a URL-Encoded Web Form string"
        webform [string! none!] "Form to decode"
    ][
        webform: any [webform ""]
        result: copy []

        either parse webform [opt [#"&" | #"?"] any pair][
            result
        ][
            do make error! "Not a URL Encoded Web Form"
        ]
    ]
]

to-webform: use [
    webform form-key emit ruby-style?
    here lookup reference path value block array key object
][
    path: []

    form-key: does [
        rejoin collect [
            keep first path
            foreach key next path [
                keep reduce either ruby-style? [["[" key "]"]][["." key]]
            ]
        ]
    ]

    emit: func [data [string! logic!]][
        repend webform ["&" url-encode form-key "=" url-encode data]
    ]

    lookup: [
        here:
        (reference: none)
        set reference [get-word! | get-path!]
        (change/only here get here/1)
        :here
    ]

    value: [
          number! (emit form here/1)
        | [logic! | 'true | 'false] (emit to string! here/1)
        | [none! | 'none]
        | [set-word! | lit-word! | get-word!] (emit to string! to word! here/1)
        | date! (emit replace mold here/1 "/" "T")
        | tag! (emit mold here/1)
        | [any-string! | word! | tuple! | money! | time! | pair! | issue!]
          (emit to string! here/1)
    ]

    array: [
        (append path "")
        any [
            opt lookup value
            | skip (do make error! join "Invalid value: " copy/part mold any [reference here/1] 40)
        ] end
        (remove back tail path)
    ]

    key: [word! | set-word! | tag!]

    object: [
        and [some [key skip] end]
        some [
            here: key (
                append path to string! either set-word? here/1 [
                    to word! here/1
                ][
                    here/1
                ]
            )
            opt lookup [value | block] (remove back tail path)
        ] end
    ]

    block: [
        here: and [
              any-block! (change/only here copy here/1)
            | [object! | map!] (change/only here body-of here/1)
        ][
            into [object | array]
        ]
    ]

    func [
        "Serializes block data as URL-Encoded Web Form string"
        data [block! map! object!] "Block or object to encode"
        /prefix "Includes the `?` character used to precede URL query strings"
        /ruby-style "Encodes structured keys using `a[b][c]` notation"
    ][
        clear path
        webform: copy ""
        data: either block? data [copy data][body-of data]
        ruby-style?: :ruby-style

        if parse copy data object [
            either all [
                prefix not tail? next webform
            ][
                back change webform "?"
            ][
                remove webform
            ]
        ]
    ]
]