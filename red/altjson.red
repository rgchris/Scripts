Red [
    Title: "JSON Decoder/Encoder for Red"
    Author: "Christopher Ross-Gill"
    Date: 27-Nov-2018
    Home: http://www.ross-gill.com/page/JSON_and_Rebol
    File: %altjson.red
    Version: 0.4.3
    Purpose: "Convert a Red block to a JSON string"
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: 'module
    Name: 'rgchris.altjson
    Exports: [load-json to-json]
    History: [
        08-Jul-2019 0.4.3 "Functions as a replacement codec"
        27-Nov-2018 0.4.2 "Handles unset GET-WORD! values"
        24-Feb-2018 0.4.1 "Red Compiler Friendly"
        24-Feb-2018 0.4.0 "New TO-JSON engine, /PRETTY option"
        12-Sep-2017 0.3.6.1 "Red Compatibilities"
        18-Sep-2015 0.3.6 "Non-Word keys loaded as strings"
        17-Sep-2015 0.3.5 "Added GET-PATH! lookup"
        16-Sep-2015 0.3.4 "Reinstate /FLAT refinement"
        21-Apr-2015 0.3.3 {
            - Merge from Reb4.me version
            - Recognise set-word pairs as objects
            - Use map! as the default object type
            - Serialize dates in RFC 3339 form
        }
        14-Mar-2015 0.3.2 "Converts Json input to string before parsing"
        07-Jul-2014 0.3.0 "Initial support for JSONP"
        15-Jul-2011 0.2.6 "Flattens Flickr '_content' objects"
        02-Dec-2010 0.2.5 "Support for time! added"
        28-Aug-2010 0.2.4 "Encodes tag! any-type! paired blocks as an object"
        06-Aug-2010 0.2.2 "Issue! composed of digits encoded as integers"
        22-May-2005 0.1.0 "Original Version"
    ]
    Notes: {
        - Converts date! to RFC 3339 Date String
        - Flattens Flickr '_content' objects
        - Handles Surrogate Pairs
        - Supports JSONP
    }
]

json-loader: make object! [
    tree: here: mark: current-value: is-flat: none

    branch: make block! 10

    emit: func [value][here: insert/only here value]
    new-child: quote (insert/only branch insert/only here here: make block! 10)
    to-parent: quote (here: take branch)
    neaten-one: quote (new-line/all head here true)
    neaten-two: quote (new-line/all/skip head here true 2)

    ; upper ranges borrowed from AltXML
    word-initial: charset [
        "!&*=?ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz|~"
        #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(02FF)"
        #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)"
        #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
        #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
    ]

    word-chars: charset [
        "!&'*+-.0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz|~"
        #"^(B7)" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)"
        #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)"
        #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
        #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
    ]

    to-word: function [text [string!]][
        all [
            parse text [word-initial any word-chars]
            to word! text
        ]
    ]

    space-chars: charset " ^-^/^M"

    space: [any space-chars]

    comma: [space #"," space]

    number-digit: charset "0123456789"
    number-exponent: [[#"e" | #"E"] opt [#"+" | #"-"] some number-digit]
    number-rule: [opt #"-" some number-digit opt [#"." some number-digit] opt number-exponent]

    as-number: func [value [string!]][
        case [
            not parse value [opt "-" some number-digit][to float! value]
            not integer? try [value: to integer! value][to issue! value]
            value [value]
        ]
    ]

    number: [copy current-value number-rule (current-value: as-number current-value)]

    string-chars: complement charset {\"}
    string-hex: charset "0123456789ABCDEFabcdef"
    string-lookup: #(#"^"" "^"" #"\" "\" #"/" "/" #"b" "^H" #"f" "^L" #"r" "^M" #"n" "^/" #"t" "^-")
    string-escapes: charset words-of string-lookup

    hex-to-integer: func [part [string!]][
        to integer! debase/base part 16
    ]

    string-decode-surrogate: func [high [string!] low [string!]][
        #"^(10000)"
            + (shift/left 03FFh and hex-to-integer high 10)
            + (03FFh and hex-to-integer low)
    ]

    string-part: string-pair-high: string-pair-low: none

    string-rule: [
        string-mark:
        some string-chars string-to: (append/part current-value string-mark string-to)
        |
        #"\" [
            string-escapes (
                append current-value select string-lookup string-mark/2
            )
            |
            #"u" copy string-pair-high [#"d" [#"8" | #"9" | #"a" | #"b"] 2 string-hex]
            "\u" copy string-pair-low [#"d" [#"c" | #"d" | #"e" | #"f"] 2 string-hex]
            (append current-value string-decode-surrogate string-pair-high string-pair-low)
            |
            #"u" copy string-part 4 string-hex (
                append current-value to char! hex-to-integer string-part
            )
        ]
    ]

    string: [
        #"^"" (current-value: make string! 1024)
        any [string-from: string-rule]
        #"^""
    ]

    array-elements: [space opt [value any [comma value]] space]
    array: [#"[" new-child array-elements #"]" neaten-one to-parent]

    _content: [#"{" space {"_content"} space #":" space value space "}"] ; Flickr

    object-name: [
        string space #":" space (
            emit either is-flat [
                to tag! current-value
            ][
                any [
                    to-word current-value
                    current-value
                ]
            ]
        )
    ]

    object-members: [
        space opt [
            object-name value
            any [comma object-name value]
        ] space
    ]

    object-as-map: [
        (unless is-flat [here: change back here make map! pick back here 1])
    ]

    object-rule: [#"{" new-child object-members #"}" neaten-two to-parent object-as-map]

    ident-initial: charset ["$_" #"a" - #"z" #"A" - #"Z"]
    ident-chars: union ident-initial charset [#"0" - #"9"]

    ident: [ident-initial any ident-chars]

    value: [
          "null" (emit none)
        | "true" (emit true)
        | "false" (emit false)
        | number (emit current-value)
        | string (emit current-value)
        | _content
        | array
        | object-rule
    ]

    json-rule: [space opt value space]
    padded-json-rule: [space ident space #"(" value #")" space opt #";" space]

    load-json: func [json [string!] flat [logic!] padded [logic!]][
        is-flat: :flat
        tree: here: make block! 16

        either parse json either padded [padded-json-rule][json-rule][
            take tree
        ][
            do make error! "Not a valid JSON string"
        ]
    ]
]

json-emitter: make object! [
    json: is-pretty: value: none

    emit: func [data][repend json data]
    emit-part: func [from [string!] to [string!]][
        append/part json from to
    ]

    stack: make block! 16 ; check for recursion

    indent: ""
    colon: ":"
    circular: {["..."]}
    unknown: {"\uFFFD"}

    increase: func [indent [string!]][
        either is-pretty [
            append indent "    "
        ][
            indent
        ]
    ]

    decrease: func [indent [string!]][
        either is-pretty [
            head clear skip tail indent -4
        ][
            indent
        ]
    ]

    emit-array: func [
        elements [block!]
    ][
        emit #"["
        unless tail? elements [
            increase indent
            while [not tail? elements][
                emit indent
                emit-value pick elements 1
                unless tail? elements: next elements [
                    emit #","
                ]
            ]
            emit decrease indent
        ]
        emit #"]"
    ]

    emit-object: func [
        members [block!]
    ][
        emit #"{"
        unless tail? members [
            increase indent
            while [not tail? members][
                emit indent
                emit-string pick members 1
                emit colon
                emit-value pick members 2
                unless tail? members: skip members 2 [
                    emit #","
                ]
            ]
            emit decrease indent
        ]
        emit #"}"
    ]

    string-escapes: #(#"^/" "\n" #"^M" "\r" #"^-" "\t" #"^"" "\^"" #"\" "\\")
    string-chars: intersect string-chars: charset [#" " - #"~"] difference string-chars charset words-of string-escapes

    emit-char: func [char [char!]][
        emit ["\u" skip tail form to-hex to integer! char -4]
    ]

    emit-string: function [
        value [any-type!]
        /local mark extent
    ][
        value: switch/default type?/word value [
            string! [value]
            get-word! set-word! [to string! to word! value]
            binary! [enbase value]
        ][
            to string! value
        ]

        emit #"^""
        parse value [
            any [
                  mark: some string-chars extent: (emit-part mark extent)
                | skip (
                    case [
                        find string-escapes first mark [
                            emit select string-escapes first mark
                        ]
                        mark/1 < 65536 [
                            emit-char first mark
                        ]
                        mark/1 [ ; surrogate pairs
                            emit-char mark/1 - 65536 / 1024 + 55296
                            emit-char mark/1 - 65536 // 1024 + 56320
                        ]
                        /else [emit "\uFFFD"]
                    ]
                )
            ]
        ]
        emit #"^""
    ]

    emit-date: func [value [date!] /local second][
        emit #"^""
        emit [
            pad/left/with value/year 4 #"0"
            #"-" pad/left/with value/month 2 #"0"
            #"-" pad/left/with value/day 2 #"0"
        ]
        if value/time [
            emit [
                #"T" pad/left/with value/hour 2 #"0"
                #":" pad/left/with value/minute 2 #"0"
                #":"
            ]
            emit pad/left/with to integer! value/second 2 #"0"
            any [
                ".0" = second: find form round/to value/second 0.000001 #"."
                emit second
            ]
            emit either any [
                none? value/zone
                zero? value/zone
            ][#"Z"][
                [
                    either value/zone/hour < 0 [#"-"][#"+"]
                    pad/left/with absolute value/zone/hour 2 #"0"
                    #":" pad/left/with value/zone/minute 2 #"0"
                ]
            ]
        ]
        emit #"^""
    ]

    issue-digit: charset "0123456789"
    issue-number: [opt #"-" some issue-digit]

    emit-issue: function [value [issue!]][
        value: next mold value
        either parse value issue-number [
            emit value
        ][
            emit-string value
        ]
    ]

    emit-value: func [value [any-type!]][
        if any [
            get-word? :value
            get-path? :value
        ][
            set/any 'value take reduce reduce [value]
        ]

        switch :value [
            none blank null _ [value: none]
            true yes [value: true]
            false no [value: false]
        ]

        switch/default type?/word :value [
            block! [
                either find/only/same stack value [
                    emit circular
                ][
                    insert/only stack value
                    either parse value [some [set-word! skip] | some [tag! skip]][
                        emit-object value
                    ][
                        emit-array value
                    ]
                    remove stack
                ]
            ]

            object! map! [
                either find/same stack value [
                    emit circular
                ][
                    emit-object body-of value
                ]
            ]

            string! binary! file! email! url! tag! pair! time! tuple! money!
            word! lit-word! get-word! set-word! refinement! [
                emit-string value
            ]

            issue! [
                emit-issue value
            ]

            date! [
                emit-date value
            ]

            integer! float! decimal! [
                emit to string! value
            ]

            logic! [
                emit to string! value
            ]

            none! unset! [
                emit "null"
            ]

            paren! path! get-path! set-path! lit-path! [
                emit-array value
            ]
        ][
            emit unknown
        ]

        json
    ]

    to-json: func [value [any-type!] pretty [logic!]][
        is-pretty: :pretty
        indent: pick ["^/" ""] is-pretty
        colon: pick [": " ":"] is-pretty

        clear stack
        json: make string! 1024
        emit-value value
    ]
]

load-json: func [
    "Convert a JSON string to Red data"
    json [string!] "JSON string"
    /flat "Objects are imported as tag-value pairs"
    /padded "Loads JSON data wrapped in a JSONP envelope"
][
    json-loader/load-json json flat padded
]

to-json: func [
    "Convert a Red value to JSON string"
    value [any-type!] "Red value to convert"
    /pretty "Format Output"
][
    json-emitter/to-json :value pretty
]

put system/codecs 'json context [
    Title:     "JSON codec"
    Name:      'JSON
    Mime-Type: [application/json]
    Suffixes:  [%.json]
    encode: func [data [any-type!] where [file! url! none!]] [
        to-json data
    ]
    decode: func [text [string! binary! file!]] [
        if file? text [text: read text]
        if binary? text [text: to string! text]
        load-json text
    ]
]
