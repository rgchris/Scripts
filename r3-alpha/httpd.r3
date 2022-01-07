Rebol [
    Title: "Web Server Scheme"
    Author: "Christopher Ross-Gill"
    Date: 23-Feb-2017
    File: %httpd.r3
    Home: https://github.com/rgchris/Scripts
    Version: 0.3.0
    Purpose: "An elementary Web Server scheme for creating fast prototypes"
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.httpd

    History: [
        02-Feb-2019 0.3.5 "File argument for REDIRECT permits relative redirections"
        14-Dec-2018 0.3.4 "Add REFLECT handler (supports OPEN?); Redirect defaults to 303"
        16-Mar-2018 0.3.3 "Add COMPRESS? option (not GZIP compatible in R3 Alpha)"
        14-Mar-2018 0.3.2 "Closes connections (TODO: support Keep-Alive)"
        11-Mar-2018 0.3.1 "Reworked to support KILL?"
        23-Feb-2017 0.3.0 "Adapted from Rebol 2"
        06-Feb-2017 0.2.0 "Include HTTP Parser/Dispatcher"
        12-Jan-2017 0.1.0 "Original Version"
    ]

    Usage: {
        For a simple server that just returns HTTP envelope with "Hello":
 
            wait srv: open [scheme: 'httpd 8000 [render "Hello"]]

        Then point a browser at http://127.0.0.1:8000
    }
]

net-utils: reduce [
    comment [
        'net-log proc [message [block! text!]] [
            print either block? message [spaced message] [message]
        ]
    ]
    'net-log none
]

as-string: func [
    binary [binary!]
    /local mark
][
    mark: binary

    while [mark: invalid-utf? mark] [
        mark: change/part mark #{EFBFBD} 1
    ]

    to string! binary
]

increment: func ['name [word!]][
    also get name set name add get name 1
]

sys/make-scheme [
    title: "HTTP Server"
    name: 'httpd

    spec: make system/standard/port-spec-head [
        port-id:
        actions: none
    ]

    wake-client: use [instance] [
        instance: 0

        func [
            event [event!]
            /local client
        ][
            client: event/port

            switch/default event/type [
                read [
                    increment instance
                    ; print rejoin ["[" instance "]"]

                    case [
                        not client/locals/parent/locals/open? [
                            close client
                            client/locals/parent
                        ]

                        find client/data #{0D0A0D0A} [
                            transcribe client
                            dispatch client
                        ]

                        default [
                            read client
                        ]
                    ]
                ]

                wrote [
                    case [
                        send-chunk client [
                            client
                        ]

                        client/locals/response/kill? [
                            close client
                            close client/locals/parent
                            ; wake-up client/locals/parent make event! [
                            ;     type: 'close
                            ;     port: client/locals/parent
                            ; ]
                        ]

                        client/locals/response/close? [
                            close client
                        ]

                        default [
                            client
                        ]
                    ]
                ]

                close [
                    close client
                ]
            ][
                net-utils/net-log [
                    "Unexpected Client Event:"
                    uppercase form event/type
                ]

                client
            ]
        ]
    ]

    init: func [
        server [port!]
        /local spec port-id
    ][
        spec: server/spec

        case [
            url? spec/ref []

            block? spec/actions []

            parse spec/ref [
                set-word! lit-word!
                integer! block!
            ][
                spec/port-id: spec/ref/3
                spec/actions: spec/ref/4
            ]

            <else> [
                do make error! "Server lacking core features."
            ]
        ]

        server/locals: make object! [
            handler:
            subport:
            open?: none
            clients: make block! 1024
        ]

        server/locals/handler: func [
            request [object!]
            response [object!]

            /local render redirect print
        ] compose [
            render: get in response 'render
            redirect: get in response 'redirect
            print: get in response 'print

            (
                case [
                    function? get in server 'awake [
                        body-of get in server 'awake
                    ]

                    block? server/awake [
                        server/awake
                    ]

                    block? server/spec/actions [
                        server/spec/actions
                    ]

                    <else> [
                        default-response
                    ]
                ]
            )
        ]

        server/locals/subport: make port! [
            scheme: 'tcp
        ]

        server/locals/subport/spec/port-id: spec/port-id

        server/locals/subport/locals: make object! [
            instance: 0
            request:
            response: none
            wire: make binary! 4096
            parent: :server
        ]

        server/locals/subport/awake: func [
            event [event!]
            /local client
        ][
            switch/default event/type [
                accept [
                    client: first event/port
                    client/awake: :wake-client

                    read client
                    event
                ]
            ][
                false
            ]
        ]

        server
    ]

    actor: [
        open: func [
            server [port!]
        ][
            net-utils/net-log [
                "Server running on port id" server/spec/port-id
            ]

            start server
            open server/locals/subport            
            server/locals/open?: yes

            server
        ]

        reflect: func [
            server [port!]
            property [word!]
        ][
            switch/default property [
                open? [
                    server/locals/open?
                ]

                default 
            ][
                fail [
                    "HTTPd port does not reflect this property:"
                    uppercase mold property
                ]
            ]
        ]

        close: func [
            server [port!]
        ][
            server/awake:
            server/locals/subport/awake: none

            server/locals/open?: no
            close server/locals/subport
            stop server

            insert system/ports/system/data server
            ; ^^^ would like to know why...
            server
        ]
    ]

    default-response: [
        probe request/action
    ]

    start: func [port [port!]][
        append system/ports/wait-list port
    ]

    stop: func [port [port!]][
        remove find system/ports/wait-list port
    ]

    request-prototype: make object! [
        raw: none
        version: 1.1
        method: "GET"
        action:
        headers:
        http-headers:
        oauth:
        target:
        binary:
        content:
        length:
        timeout: none
        type: 'application/x-www-form-urlencoded
        server-software: rejoin [
            ; system/script/header/title " v" system/script/header/version " "
            "Rebol/" system/product " v" system/version
        ]
        server-name:
        gateway-interface: none
        server-protocol: "http"
        server-port:
        request-method:
        request-uri:
        path-info:
        path-translated:
        script-name:
        query-string:
        remote-host:
        remote-addr:
        auth-type:
        remote-user:
        remote-ident:
        content-type:
        content-length:
        error: none
    ]

    response-prototype: make object! [
        status: 404
        content: "Not Found"
        location: none
        type: "text/html"
        length: 0
        kill?: false
        close?: true
        compress?: false

        render: func [
            response [string! binary!]
        ][
            status: 200
            content: response
        ]

        print: func [
            response [string!]
        ][
            status: 200
            content: response
            type: "text/plain"
        ]

        redirect: func [
            target [url! file!]
            /as
            code [integer!]
        ][
            status:
            code: default [303]
            content: "Redirecting..."
            type: "text/plain"
            location: target
        ]
    ]

    transcribe: use [
        spaces-or-tabs request-action request-path request-query
        header-prototype header-feed header-name header-part
    ][
        request-action: [
            "HEAD" | "GET" | "POST" | "PUT" | "DELETE"
]

        request-path: use [chars] [
            chars: complement charset [#"^@" - #" " #"?"]
            [some chars]
        ]

        request-query: use [chars] [
            chars: complement charset [#"^@" - #" "]
            [some chars]
        ]

        header-feed: [newline | crlf]

        header-part: use [chars] [
            chars: complement charset [#"^(00)" - #"^(1F)"]
            [some chars any [header-feed some " " some chars]]
        ]

        header-name: use [chars] [
            chars: charset ["_-0123456789" #"a" - #"z" #"A" - #"Z"]
            [some chars]
        ]

        spaces-or-tabs: use [space] [
            space: charset " ^-"
            [some space]
        ]

        header-prototype: make object! [
            Accept: "*/*"
            Connection: "close"
            User-Agent: rejoin [
                "Rebol/" system/product " " system/version
            ]

            Content-Length:
            Content-Type:
            Authorization:
            Range:
            Referer: none
        ]

        transcribe: func [
            client [port!]
            /local request name value pos
        ][
            client/locals/request: make request-prototype [
                either parse raw: client/data [
                    copy method request-action
                    some #" "
                    copy request-uri [
                        copy target request-path
                        opt [
                            "?"
                            copy query-string request-query
                        ]
                    ]
                    some #" "
                    "HTTP/" copy version ["1.0" | "1.1"]
                    header-feed
                    (headers: make block! 10)
                    some [
                        copy name header-name ":" any " "
                        copy value header-part header-feed
                        (
                            name: as-string name
                            value: as-string value
                            append headers reduce [to set-word! name value]
                            switch name [
                                "Content-Type" [content-type: value]
                                "Content-Length" [length: content-length: value]
                            ]
                        )
                    ]
                    header-feed
                    content:
                    to end
                    (
                        binary: copy :content
                        content: does [
                            content: as-string binary
                        ]
                    )
                ][
                    version: to string! :version
                    request-method:
                    method: to string! :method
                    path-info:
                    target: as-string :target
                    action: reform [method target]
                    request-uri: as-string request-uri
                    server-port: query/mode client 'local-port
                    remote-addr: query/mode client 'remote-ip

                    http-headers: new-line/skip headers true 2
                    headers: make header-prototype http-headers

                    type: if string? headers/Content-Type [
                        copy/part type: headers/Content-Type any [
                            find type ";"
                            tail type
                        ]
                    ]

                    length:
                    content-length: any [
                        attempt [to integer! length]
                        0
                    ]

                    net-utils/net-log action
                ][
                    net-utils/net-log error: "Could Not Parse Request"
                ]
            ]
        ]
    ]

    dispatch: use [
        status-codes build-header
    ][
        status-codes: [
            200 "OK"
            201 "Created"
            204 "No Content"

            301 "Moved Permanently"
            302 "Moved temporarily"
            303 "See Other"
            307 "Temporary Redirect"

            400 "Bad Request"
            401 "No Authorization"
            403 "Forbidden"
            404 "Not Found"
            411 "Length Required"

            500 "Internal Server Error"
            503 "Service Unavailable"
        ]

        build-header: function [
            response [object!]
        ][
            append make binary! 1024 rejoin collect [
                if not find status-codes response/status [
                    response/status: 500
                ]

                if any [
                    not any [
                        binary? response/content
                        string? response/content
                    ]

                    empty? response/content
                ][
                    response/content: " "
                ]

                keep [
                    "HTTP/1.1 "
                    response/status " "
                    select status-codes response/status
                ]

                keep [
                    crlf
                    "Content-Type: "
                    response/type
                ]

                keep [
                    crlf
                    "Content-Length: "
                    length? response/content
                ]

                if response/compress? [
                    keep [
                        crlf
                        "Content-Encoding: "
                        "gzip"
                    ]
                ]

                if response/location [
                    keep [
                        crlf
                        "Location: "
                        response/location
                    ]
                ]

                if response/close? [
                    keep [
                        crlf
                        "Connection: "
                        "close"
                    ]
                ]

                keep [
                    crlf
                    "Cache-Control: "
                    "no-cache"
                ]

                keep [
                    crlf crlf
                ]
            ]
        ]

        func [
            client [port!]
            /local response continue? outcome
        ][
            client/locals/response:

            response: make response-prototype []

            if not all [
                object? client/locals/request
                client/locals/parent/locals/handler client/locals/request response
            ][
                ; don't crash on bad request
                ;
                response/status: 500
                response/type: "text/html"
                response/content: "Bad request."
            ]

            if response/compress? [
                response/content: compress response/content 'gzip
            ]

            if error? outcome: try [
                write client build-header response
            ][
                either all [
                    outcome/code = 5020
                    outcome/id = 'write-error
                    find [32 104] outcome/arg2
                ][
                    net-utils/net-log [
                        "Response headers not sent to client:"
                            "reason #" outcome/arg2
                    ]
                ][
                    do :outcome
                ]
            ]

            insert client/locals/wire response/content
        ]
    ]

    send-chunk: func [
        port [port!]
        /local outcome
    ][
        ;
        ; !!! Trying to send data > 32'000 bytes at once would trigger R3's
        ; internal chunking (which was buggy, see above).  Chunks > 32'000
        ; bytes were thus manually chunked for some time, but it should be
        ; increased to see if that bug still exists.
        ;
        case [
            empty? port/locals/wire [
                none
            ]

            error? outcome: try [
                write port take/part port/locals/wire 32'000
            ][
                ;; only mask some errors:
                either all [
                    outcome/code = 5020
                    outcome/id = 'write-error
                    find [32 104] outcome/arg2
                ][
                    net-utils/net-log [
                        "Part or whole of response not sent to client:"
                        "reason #" outcome/arg2
                    ]

                    clear port/locals/wire
                    none
                ][
                    do make error! :outcome
                ]
            ]

            <else> [
                :outcome  ; is port
            ]
        ]
    ]
]
