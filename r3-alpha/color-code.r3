Rebol [
    Title: "Color Code"
    Author: "Christopher Ross-Gill"
    Date: 21-Oct-2013
    File: %color-code.r3
    Version: 2.1.2
    Purpose: "Colorize Rebol (and derivative) source code based on datatype"
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.color-code
    Exports: [script? load-header color-code]
    History: [
        29-Aug-2016 2.1.2 "Remove functions from headers." "Christopher Ross-Gill"
        21-Oct-2013 2.1.1 "Custom header handling; revised sanitization process." "Christopher Ross-Gill"
        23-Oct-2009 2.1.0 "Rewritten as QM module." "Christopher Ross-Gill"
        29-May-2003 1.0.0 "Fixed deep parse rule bug." "Carl Sassenrath"
    ]
]

; cross-posted from %rsp.r3
sanitize: use [ascii html* extended][
    html*: exclude ascii: charset ["^/^-" #"^(20)" - #"^(7E)"] charset {&<>"}
    extended: complement charset [#"^(00)" - #"^(7F)"]

    func [text [any-string!] /local char][
        parse form text [
            copy text any [
                text: some html*
                | change #"<" "&lt;" | change #">" "&gt;" | change #"&" "&amp;"
                | change #"^"" "&quot;" | remove #"^M"
                | remove copy char extended (char: rejoin ["&#" to integer! char/1 ";"]) insert char
                | change skip "&#65533;"
            ]
        ]
        any [text copy ""]
    ]
]

script?: use [space id mark type][
    space: charset " ^-"
    id: [
        any space mark: 
        any ["[" mark: (mark: back mark) any space]
        copy type ["Rebol" | "Red" opt "/System" | "World" | "Topaz" | "Freebell"] (
            type: first find [ ; normalize capitalization
                "Rebol" "Red" "Red/System" "World" "Topaz" "Freebell"
            ] type
        )
        any space
        "[" to end
    ]

    func [source [string! binary!] /language][
        if all [
            parse source [
                some [
                    id break |
                    (mark: none)
                    thru newline opt #"^M"
                ]
            ]
            mark
        ][either language [type][mark]]
    ]
]

load-next: func [string [string!] /local out][
    out: transcode/next to binary! string
    out/2: skip string subtract length? string length? to string! out/2
    out
]

load-header: func [[catch] source [string! binary!] /local header][
    source: to string! source
    unless header: script? source [make error! "Source does not contain header."]
    header: find next header "["
    unless header: attempt [load-next header][make error! "Header is incomplete."]
    reduce [construct/with header/1 system/standard/script header/2]
]

color-code: use [out emit emit-var emit-header rule value][
    out: none
    emit: func [data][
        data: reduce compose [(data)]
        until [append out take data empty? data]
    ]

    emit-var: func [value start stop /local type out][
        either none? :value [type: "cmt"][
            if path? :value [value: first :value]

            type: either word? :value [
                any [
                    all [find [Rebol Red Topaz Freebell World] :value "rebol"]
                    all [value? :value any-function? get :value "function"]
                    all [value? :value datatype? get :value "datatype"]
                    "word"
                ]
            ][
                any [replace to string! type?/word :value "!" ""]
            ]
        ]

        out: sanitize copy/part start stop

        emit either type [
            [{<var class="dt-} type {">} out {</var>}]
        ][
            out
        ]
    ]

    rule: use [str new rule hx][
        hx: charset "0123456789abcdefABCDEF"

        rule: [
            some [
                str:
                some [" " | tab] new: (emit copy/part str new) |
                [crlf | newline] (emit "^/") |
                #";" [thru newline | to end] new:
                    (emit-var none str new) |
                [#"[" | #"("] (emit first str) rule |
                [#"]" | #")"] (emit first str) break |
                [8 hx | 4 hx | 2 hx] #"h" new:
                    (emit-var 0 str new) |
                skip (
                    set [value new] load-next str
                    emit-var :value str new
                ) :new
            ]
        ]

        [
            rule [end | str: to end (emit sanitize str)]
        ]
    ]

    func [
        "Return color source code as HTML."
        text [string!] "Source code text"
    ][
        out: make binary! 3 * length? text

        unless text: script? detab text [
            make error! "Not a Rebol or Red script."
        ]

        unless head? text [
            emit [
                {<var class="dt-preamble">}
                sanitize copy/part head text text
                "</var>"
            ] 
        ]

        parse text [rule]

        insert out {<pre class="code rebol">}
        to string! append out {</pre>}
    ]
]
