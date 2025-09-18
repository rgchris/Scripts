Rebol [
    Title: "Scheme: Capture"
    Author: "Christopher Ross-Gill"
    Date: 1-Nov-2022
    Version: 0.1.0
    File: %scheme-capture.r

    Purpose: "A drop-in scheme that captures output"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.scheme.capture

    Needs: [
        shim
        r2c:uuid
    ]

    Comment: [
        "Some issues persist, largely related to the buffer size"
    ]
]

if not in system/schemes 'capture [
    system/schemes: make system/schemes [
        capture: make system/standard/port compose [
            scheme: 'capture
            port-id: 0
            passive: _
            cache-size: 5

            proxy: system/standard/port-proxy

            handler: make object! [
                port-flags: system/standard/port-flags/pass-thru

                init: func [port url] [
                    port/user-data: rejoin [
                        %/tmp/capture- uuid/form uuid/generate %.bin
                    ]

                    port/sub-port: make port! port/user-data
                ]

                open: func [
                    port
                ][
                    port/state/flags: port/state/flags or port-flags
                    system/words/open/write/new/direct port/sub-port
                ]

                close: func [
                    port
                ][
                    system/words/close port/sub-port
                    port/locals: read port/user-data

                    use [folder files] [
                        folder: system/words/open %/tmp/
                    ][
                        files: copy folder

                        if files: find files %tmp-capture.bin [
                            remove skip folder -1 + index? files
                        ]

                        system/words/close folder
                    ]
                ]

                insert: func [
                    port
                    values
                ][
                    system/words/insert port/sub-port values
                ]
            ]
        ]
    ]
]

capture-output: func [
    body [block!]

    /local output-port capture-port content target
][
    output-port: system/ports/output

    capture-port: make port! target: rejoin [
        %/tmp/capture- uuid/form uuid/generate %.bin
    ]

    open/write/new/direct capture-port

    system/ports/output: capture-port
    apply func [] body []
    system/ports/output: output-port

    close capture-port
    content: read target
    delete target
    content
]
