Rebol [
    Title: "Scheme: Error"
    Author: "Christopher Ross-Gill"
    Date: 1-Nov-2022
    Version: 0.1.0
    File: %scheme-error.r

    Purpose: "Scheme to write to STDERR"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.scheme.error

    Needs: [
        shim
    ]

    Comment: [
        https://unix.stackexchange.com/a/400864
        "Echo to STDERR"
    ]
]

if not in system/schemes 'error [
    system/schemes: make system/schemes [
        error: make system/standard/port [
            scheme: 'error
            port-id: 0
            passive: _
            cache-size: 5

            proxy: system/standard/port-proxy

            handler: context [
                port-flags: system/standard/port-flags/pass-thru

                init: func [port url] []

                open: func [port] [
                    port/state/flags: port/state/flags or port-flags
                ]

                close: func [port] []

                insert: func [port values] [
                    call/wait/input {echo "$(</dev/stdin)" >&2} port/state/outbuffer: reform values
                    wait .3
                    port/state/outbuffer
                ]
            ]
        ]
    ]
]
