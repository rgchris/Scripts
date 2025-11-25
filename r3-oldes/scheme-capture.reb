Rebol [
    Title: "Capture Port"
    Author: "Christopher Ross-Gill"
    Date: 1-Nov-2022
    Version: 0.1.0
    File: %scheme-capture.reb

    Purpose: "A drop-in replacement for I/O ports for capturing output"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.scheme-capture
    Exports: [
        capture-output
    ]

    ; Needs: [
    ;     r3:rgchris:uuid
    ; ]

    Comment: [
        "Some issues persist, largely related to the buffer size"
    ]
]


prin:
lib/prin: func [
    "Outputs a value with no line break."

    value [any-type!]
    "The value to print"
][
    write system/ports/output reform value
    ()
]

print:
lib/print: func [
    "Outputs a value followed by a line break."

    value [any-type!]
    "The value to print"
][
    write system/ports/output reform value
    write system/ports/output newline
    ()
]

probe:
lib/probe: func [
    "Debug print a molded value and returns that same value."

    value [any-type!]
    "The output is truncated to size defined in: system/options/probe-limit"

    /constrain
    limit [integer!]
][
    limit: any [
        limit
        system/options/probe-limit
    ]

    print either 0 < limit [
        ellipsize (mold/part :value limit + 1) limit
    ][
        mold :value
    ]

    :value
]

sys/make-scheme [
    name: 'capture
    title: "Capture Scheme"

    actor: [
        open: func [
            port
        ][
            port/extra: make binary! 65536
            port
        ]

        write: func [
            port
            value
        ][
            append port/extra value
            value
        ]

        read: func [
            port [port!]
            /string
        ][
            either string [
                to string! port/extra
            ][
                port/extra
            ]
        ]

        query: func [
            port [port!]
            field [word!]
        ][
            switch field [
                window-cols [
                    120
                ]
            ]
        ]

        close: func [port] [
            port/extra: #(none)
        ]
    ]
]

capture-output: func [
    body [block!]

    /local output-port capture-port has-error content result
][
    ; capture-port: open/write/new target: rejoin [
    ;     %/tmp/capture uuid/to-text uuid/generate %.tmp.bin
    ; ]

    capture-port: open capture://
    output-port: system/ports/output

    system/ports/output: capture-port

    ; catch an error because we'll need to close the file port
    ;
    has-error: error? set/any 'result try [
        apply func [] body []
    ]

    system/ports/output: output-port

    content: read/string capture-port
    close capture-port

    either has-error [
        do :result
    ][
        content
    ]
]
