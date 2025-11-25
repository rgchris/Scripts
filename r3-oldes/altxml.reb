Rebol [
    Title: "XML Parser/Object Model"
    Author: "Christopher Ross-Gill"
    Date: 22-Oct-2009
    Version: 0.4.1
    File: %altxml.reb

    Purpose: "XML handler for Rebol 3"

    Home: https://www.ross-gill.com/page/XML_and_REBOL
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.altxml
    Exports: [
        xml load-xml decode-xml
    ]

    Needs: [
        r3:rgchris:core
        ; r3:rgchris:dom
    ]

    History: [
        07-Apr-2014 0.4.1
        "Fixed loop when handling unterminated empty tags"

        14-Apr-2013 0.4.0
        "Added /PATH method"

        16-Feb-2013 0.3.0
        "Switch to using PATH! type to represent Namespaces"

        22-Oct-2009 0.2.0
        "Conversion from Rebol 2"
        (r2c:altxml)
    ]
]

xml: context private [
    digit: charset [
        "0123456789"
    ]

    hex-digit: charset [
        "0123456789ABCDEFabcdef"
    ]

    word-first: charset [
        {:ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz}
        #"^(c0)" - #"^(d6)"
        #"^(d8)" - #"^(f6)"
        #"^(f8)" - #"^(02ff)"
        #"^(0370)" - #"^(037d)"
        #"^(037f)" - #"^(1fff)"
        #"^(200c)" - #"^(200d)"
        #"^(2070)" - #"^(218f)"
        #"^(2c00)" - #"^(2fef)"
        #"^(3001)" - #"^(d7ff)"
        #"^(f900)" - #"^(fdcf)"
        #"^(fdf0)" - #"^(fffd)"
    ]

    word-any: charset [
        {-.0123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz}
        #"^(b7)"
        #"^(c0)" - #"^(d6)"
        #"^(d8)" - #"^(f6)"
        #"^(f8)" - #"^(037d)"
        #"^(037f)" - #"^(1fff)"
        #"^(200c)" - #"^(200d)" 
        #"^(203f)" - #"^(2040)"
        #"^(2070)" - #"^(218f)"
        #"^(2c00)" - #"^(2fef)"
        #"^(3001)" - #"^(d7ff)"
        #"^(f900)" - #"^(fdcf)"
        #"^(fdf0)" - #"^(fffd)"
        ; #"^(10000)" - #"^(effff)"
    ]

    word: [
        word-first any word-any
    ]

    entities: #[
        "lt" 60 "gt" 62 "amp" 38 "quot" 34 "apos" 39 "nbsp" 160
    ]
    ;
    ; nbsp is not in the XML spec but is still commonly found in XML
][
    text: context private [
        char: _

        entity: [
            #"&" [  ; should be #"&"
                #"#" [
                    #"x"
                    copy char 2 4 hex-digit
                    #";"
                    (char: to integer! to issue! char)
                    |
                    copy char 2 5 digit
                    #";"
                    (char: to integer! char)
                ]
                |
                copy char word
                #";"
                (
                    char: any [
                        entities/:char 63
                    ]
                )
            ]
            (char: to char! char)
        ]
    ][
        encode: func [text] [
            parse text: copy text [
                some [
                    change #"<" "&lt;"
                    |
                    change #"^"" "&quot;"
                    |
                    change #"&" "&amp;"
                    |
                    skip
                ]
            ]

            head text
        ]

        decode: func [
            text [string! none!]
        ][
            either text [
                if parse text [
                    any [
                        remove entity
                        insert char
                        |
                        skip
                    ]
                ][
                    text
                ]
            ][
                copy ""
            ]
        ]
    ]

    names: context [
        encode: func [
            name [ref! tag!]
        ][
            rejoin [
                either head? name [
                    ""
                ][
                    append to string! name
                ]

                to string! name
            ]
        ]

        decode: func [
            name [string!]
            /attr
        ][
            name: to either attr [ref!] [tag!] name

            name: any [
                remove find name #":"
                name
            ]
        ]
    ]

    pack: use [
        encoding path emit encode form-name element attribute tag attr data
    ][
        path: copy []

        emit: func [data [string! block!]] [
            repend encoding data
        ]

        attribute: [
            set attr ref!
            set data [
                any-string! | number! | logic!
            ]
            (
                emit [
                    " " names/encode attr {="} text/encode form data {"}
                ]
            )
        ]

        element: [
            set tag tag!
            (
                insert path tag: names/encode tag

                emit [
                    "<" tag
                ]
            )
            [
                none!
                (
                    emit " />"
                    remove path
                )
                |
                set data string!
                (
                    emit [
                        ">" text/encode form data "</" tag ">"
                    ]

                    remove path
                )
                |
                and block! into [
                    any attribute
                    [
                        end
                        (
                            emit " />"
                            remove path
                        )
                        |
                        (
                            emit ">"
                        )
                        some element
                        end
                        (
                            emit [
                                "</" take path ">"
                            ]
                        )
                    ]
                ]
            ]
            |
            %.txt
            set data string!
            (emit text/encode form data)
            |
            attribute
        ]

        func [
            tree [block!]
        ][
            encoding: copy ""

            if parse tree element [
                encoding
            ]
        ]
    ]

    xml!: context [
        this:
        name:
        space:
        value:
        tree:
        branch:
        position: _

        find-element: func [
            element [tag! ref! datatype! word!]
            /local hit
        ][
            parse value [
                any [
                    hit:
                    element
                    break
                    |
                    (hit: _)
                    skip
                ]
            ]

            hit
        ]

        get-by-tag: func [
            tag [tag! ref!]
            /local rule hits hit
        ][
            collect [
                parse tree rule: [
                    some [
                        opt [
                            hit:
                            tag
                            skip
                            (keep make-node hit)
                            :hit
                        ]

                        skip [
                            and block! into rule | skip
                        ]
                    ]
                ]
            ]
        ]

        get-by-id: func [
            id
            /local rule at hit
        ][
            parse tree rule: [
                some [
                    hit:
                    tag!
                    and block! into [
                        thru @id id
                        to end
                    ]
                    return (hit: make-node hit)
                    |
                    skip [
                        and block! into rule | skip
                    ]
                ]
            ]

            hit
        ]

        text: func [
            /preformatted
            /local rule text part
        ][
            case/all [
                string? value [
                    text: copy value
                ]

                block? value [
                    parse value rule: [
                        any [
                            [%.txt | tag!]
                            set part string!
                            (
                                append any [
                                    text
                                    text: copy ""
                                ] part
                            )
                            |
                            skip
                            and block! into rule
                            |
                            2 skip
                        ]
                    ]
                ]

                string? text [
                    either preformatted [
                        text
                    ][
                        trim/auto text
                    ]
                ]
            ]
        ]

        get: func [
            name [ref! tag!]
            /local hit pos
        ][
            if parse tree [
                tag!
                and block! into [
                    any [
                        pos:
                        name
                        [
                            block!
                            (hit: make-node pos)
                            |
                            set hit skip
                        ]
                        to end
                        |
                        [
                            tag! | ref! | file!
                        ]
                        skip
                    ]
                ]
            ][
                hit
            ]
        ]

        sibling: func [/before /after] [
            case [
                all [
                    after
                    parse after: skip position 2 [
                        [file! | tag!] to end
                    ]
                ][
                    make-node after
                ]

                all [
                    before
                    parse before: skip position -2 [
                        [file | tag!] to end
                    ]
                ][
                    make-node before
                ]
            ]
        ]

        parent: has [branch] ["Need Branch" none]

        children: has [hits hit] [
            hits: copy []
            parse case [
                block? value [
                    value
                ]

                string? value [
                    reduce [
                        %.txt value
                    ]
                ]

                none? value [
                    []
                ]
            ][
                any [
                    ref!
                    skip
                ]

                any [
                    hit:
                    [tag! | file!]
                    skip
                    (append hits make-node hit)
                ]
            ]
            hits
        ]

        path: func [
            path [block! path!]
            /local result selector kids
        ][
            if not parse path [
                some [
                    '* [tag! | ref!]
                    |
                    tag! | ref! | integer!
                ]

                opt [
                    '* | '? | 'text
                ]
            ][
                do make error! "Invalid Path Spec"
            ]

            result: :this

            if not parse path [
                opt [
                    tag!
                    (
                        if not result/name == path/1 [
                            result: none
                        ]
                    )
                ]

                any [
                    selector:

                    '* [
                        tag! | ref!
                    ]
                    (
                        kids: collect [
                            foreach kid compose [
                                (
                                    any [
                                        result []
                                    ]
                                )
                            ][
                                keep kid/get-by-tag selector/2
                            ]
                        ]

                        result: collect [
                            foreach kid kids [
                                keep kid/get-by-tag selector/2
                            ]
                        ]
                    )
                    |
                    [tag! | ref!]
                    (
                        remove-each kid result: collect [
                            foreach kid compose [
                                (
                                    any [
                                        result []
                                    ]
                                )
                            ][
                                keep kid/attributes
                                keep kid/children
                            ]
                        ][
                            not selector/1 == kid/name
                        ]
                    )
                    |
                    integer!
                    (
                        result: pick compose [
                            (
                                any [
                                    result []
                                ]
                            )
                        ] selector/1
                    )
                ]

                opt [
                    '* (
                        case [
                            block? result [
                                result: collect [
                                    foreach kid result [
                                        keep kid/children
                                    ]
                                ]
                            ]

                            object? result [
                                result: result/children
                            ]
                        ]
                    )
                    |
                    '? (
                        case [
                            block? result [
                                result: collect [
                                    foreach kid result [
                                        keep kid/value
                                        ; keep/only kid/value
                                    ]
                                ]
                            ]

                            object? result [
                                result: result/value
                            ]
                        ]
                    )
                    |
                    'text (
                        case [
                            block? result [
                                result: collect [
                                    foreach kid result [
                                        keep kid/text
                                    ]
                                ]
                            ]

                            object? result [
                                result: result/text
                            ]
                        ]
                    )
                ]
            ][
                do make error! rejoin [
                    "Error at: " mold selector
                ]
            ]

            result
        ]

        attributes: has [
            hits hit
        ][
            hits: copy []

            parse either block? value [value] [[]] [
                any [
                    hit:
                    ref!
                    skip
                    (append hits make-node hit)
                ]
                to end
            ]

            hits
        ]

        clone: does [
            make-node tree
        ]

        append-child: func [
            name
            data
            /attr

            /local pos
        ][
            case [
                none? position/2 [
                    value:
                    tree/2:
                    position/2: copy []
                ]

                string? position/2 [
                    value:
                    tree/2:
                    position/2: compose [
                        %.txt (position/2)
                    ]

                    new-line value true
                ]
            ]

            either attr [
                parse position/2 [
                    any [
                        ref! skip
                    ]
                    pos:
                ]
            ][
                pos: tail position/2
            ]

            insert pos reduce [
                name data
            ]

            new-line pos true
        ]

        append-text: func [text] [
            case [
                none? position/2 [
                    value:
                    tree/2:
                    position/2: text
                ]

                string? position/2 [
                    append position/2 text
                ]

                %.txt = pick tail position/2 -2 [
                    append last position/2 text
                ]

                block? position/2 [
                    append-child %.txt text
                ]
            ]
        ]

        append-attr: func [name value] [
            append-child/attr name value
        ]

        flatten: does [
            pack tree
        ]
    ]

    doc: make xml! [
        branch: make block! 10

        document: true

        new: does [
            clear branch

            tree: position: reduce [
                'document _
            ]
        ]

        open-tag: func [
            tag
        ][
            insert/only branch position
            tag: names/decode tag
            tree: position: append-child tag none
        ]

        close-tag: func [tag] [
            tag: names/decode tag

            while [tag <> position/1] [
                probe reform [
                    "No End Tag:" position/1
                ]

                if empty? branch [
                    do make error! "End tag error!"
                ]

                take branch
            ]

            tree: position: take branch
        ]
    ]

    make-node: func [
        here
        /base
    ][
        here: make either base [doc] [xml!] [
            position: here
            name: here/1
            space: all [
                not head? name
                copy/part head name name
            ]

            value: here/2
            tree: reduce [name value]
            name: copy name
        ]

        here/this: here
    ]

    grammar: context [
        space: use [
            space
        ][
            space: charset "^-^/^M "

            [some space]
        ]

        name-opt-namespace: [
            word opt [
                #":" word
            ]
        ]

        entity: [
            #"&" [
                word
                |
                #"#" [
                    1 5 digit | #"x" 1 4 hex-digit
                ]
            ] #";"
            |
            #"&"
        ]

        data: use [
            char value
        ][
            char: charset [
                "^-^/^M"
                #"^(20)" - #"^(25)"
                #"^(27)" - #"^(3B)"
                #"^(3D)" - #"^(FFFE)"
            ]

            [
                copy value [
                    opt space [
                        char | entity
                    ]

                    any [
                        char | entity | space
                    ]
                ]
                (doc/append-text text/decode value)
            ]
        ]

        attribute: use [
            attr value
        ][
            [
                opt space
                copy attr name-opt-namespace
                opt space
                "="
                opt space [
                    {"} copy value to {"}
                    |
                    {'} copy value to {'}
                ]
                skip
                (
                    attr: names/decode/attr attr
                    doc/append-attr attr text/decode value
                )
            ]
        ]

        element: use [
            tag value
        ][
            [
                #"<" [
                    copy tag name-opt-namespace
                    (doc/open-tag tag)
                    any attribute
                    opt space [
                        "/>"
                        (doc/close-tag tag)
                        |
                        #">" content "</"
                        copy tag name-opt-namespace
                        (doc/close-tag tag)
                        opt space
                        #">"
                    ]
                    |
                    #"!" [
                        "--" copy value to "-->"
                        3 skip
                        ; (doc/append-child %.cmt value)
                        |
                        "[CDATA[" copy value to "]]>"
                        3 skip
                        ; (doc/append-child %.bin value)
                        (doc/append-text value)
                    ]
                ]
            ]
        ]

        header: [
            any [
                space
                |
                "<" [
                    "?xml" thru "?>"
                    |
                    "!" [
                        "--" thru "-->"
                        |
                        thru ">"
                    ]
                    |
                    "?" thru "?>"
                ]
            ]
        ]

        content: [
            any [
                data | element | space
            ]
        ]

        document: [
            header
            element
            to end
        ]
    ]

    unpack: func [
        "Transform an XML document to a REBOL block"

        document [any-string!]
        "An XML string/location to transform"

        /dom
        "Returns an object with DOM-like methods to traverse the XML tree"

        /local root
    ][
        case/all [
            any [
                file? document
                url? document
            ][
                document: read/string document
            ]

            binary? document [
                document: to string! document
            ]
        ]

        root: doc/new

        parse/case document grammar/document

        doc/tree: any [
            root/document
            []
        ]

        doc/value: doc/tree/2

        either dom [
            make-node/base doc/tree
        ][
            doc/tree
        ]
    ]
]

decode-xml: get in xml/text 'decode

load-xml: get in xml 'unpack
