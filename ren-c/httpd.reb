Rebol [
    Title: "Web Server Scheme for Ren-C"
    Author: "Christopher Ross-Gill"
    Date: 23-Feb-2017
    File: %httpd.reb
    Version: 0.3.0
    Purpose: "An elementary Web Server scheme for creating fast prototypes"
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: httpd
    History: [
        23-Feb-2017 0.3.0 "Adapted from Rebol 2"
        06-Feb-2017 0.2.0 "Include HTTP Parser/Dispatcher"
        12-Jan-2017 0.1.0 "Original Version"
    ]
]

net-utils: reduce ['net-log _]

as-string: func [binary [binary!] /local mark][
    mark: binary
    while [mark: invalid-utf8? mark][
        mark: change/part mark #{EFBFBD} 1
    ]
    to string! binary
]

sys/make-scheme [
    title: "HTTP Server"
    name: 'httpd

    spec: make system/standard/port-spec-head [port-id: does: _]

    default-response: [probe request/action]

    init: func [server [port!] /local spec port-id does][
        spec: server/spec

        case [
            url? spec/ref []
            block? spec/does []
            parse spec/ref [
                set-word! lit-word!
                integer! block!
            ][
                spec/port-id: spec/ref/3
                spec/does: spec/ref/4
            ]
            /else [
                do make error! "Server lacking core features."
            ]
        ]

        server/locals: make object! [
            handler: subport: _
        ]

        server/locals/handler: procedure [
            request [object!]
            response [object!]
        ] case [
            function? get in server 'awake [body-of get in server 'awake]
            block? server/awake [server/awake]
            block? server/spec/does [server/spec/does]
            true [default-response]
        ]

        server/locals/subport: make port! [scheme: 'tcp]
        server/locals/subport/spec/port-id: spec/port-id
        server/locals/subport/locals: make object! [
            request: response: _
            wire: make binary! 4096
            parent: :server
        ]

        server/locals/subport/awake: func [event [event!] /local client server] compose [
            ; server: (:server)
            if event/type = 'accept [
                client: first event/port
                client/awake: :wake-client
                read client
            ]

            ; event
            false
        ]

        server
    ]

    start: func [port [port!]][
        append system/ports/wait-list port
    ]

    stop: func [port [port!]][
        remove find system/ports/wait-list port
        close port
    ]

    actor: [
        open: func [server [port!]][
            ; print ["Server running on port:" server/spec/port-id]
            start server/locals/subport
            open server/locals/subport
        ]

        close: func [server [port!]][
            stop server/locals/subport
        ]
    ]

    request-prototype: make object! [
        version: 1.1
        method: "GET"
        action: headers: http-headers: _
        oauth: target: binary: content: length: timeout: _
        type: 'application/x-www-form-urlencoded
        server-software: rejoin [
;           system/script/header/title " v" system/script/header/version " "
            "Rebol/" system/product " v" system/version
        ]
        server-name: gateway-interface: _
        server-protocol: "http"
        server-port: request-method: request-uri:
        path-info: path-translated: script-name: query-string:
        remote-host: remote-addr: auth-type:
        remote-user: remote-ident: content-type: content-length: _
        error: _
    ]

    response-prototype: make object! [
        status: 404
        content: "Not Found"
        location: _
        type: "text/html"
        length: 0
        kill?: false
        close?: true
    ]

    wake-client: use [instance][
        instance: 0

        func [event [event!] /local client request response this][
            client: event/port

            switch/default event/type [
                read [
                    ++ instance
                    ; print rejoin ["[" instance "]"]

                    either find client/data #{0D0A0D0A} [
                        transcribe client
                        dispatch client
                    ][
                        read client
                    ]
                ]
                wrote [
                    unless send-chunk client [
                        if client/locals/response/kill? [
                            close client
                            stop client/locals/parent
                        ]
                    ]
                    client
                ]
                close [close client]
            ][
                ; probe event/type
            ]
        ]
    ]

    transcribe: use [
        space request-action request-path request-query
        header-prototype header-feed header-name header-part
    ][
        request-action: ["HEAD" | "GET" | "POST" | "PUT" | "DELETE"]

        request-path: use [chars][
            chars: complement charset [#"^@" - #" " #"?"]
            [some chars]
        ]

        request-query: use [chars][
            chars: complement charset [#"^@" - #" "]
            [some chars]
        ]

        header-feed: [newline | crlf]

        header-part: use [chars][
            chars: complement charset [#"^(00)" - #"^(1F)"]
            [some chars any [header-feed some " " some chars]]
        ]

        header-name: use [chars][
            chars: charset ["_-0123456789" #"a" - #"z" #"A" - #"Z"]
            [some chars]
        ]

        space: use [space][
            space: charset " ^-"
            [some space]
        ]

        header-prototype: context [
            Accept: "*/*"
            Connection: "close"
            User-Agent: rejoin ["Rebol/" system/product " " system/version]
            Content-Length: Content-Type: Authorization: Range: _
        ]

        transcribe: func [
            client [port!]
            /local request name value pos
        ][
            client/locals/request: make request-prototype [
                either parse client/data [
                    copy method request-action space
                    copy request-uri [
                        copy target request-path opt [
                            "?" copy query-string request-query
                        ]
                    ] space
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
                    header-feed content: to end (
                        binary: copy :content
                        content: does [content: as-string binary]
                    )
                ][
                    version: to string! :version
                    request-method: method: to string! :method
                    path-info: target: as-string :target
                    action: reform [method target]
                    request-uri: as-string request-uri
                    server-port: query/mode client 'local-port
                    remote-addr: query/mode client 'remote-ip

                    headers: make header-prototype http-headers: new-line/all/skip headers true 2

                    type: if string? headers/Content-Type [
                        copy/part type: headers/Content-Type any [
                            find type ";"
                            tail type
                        ]
                    ]

                    length: content-length: any [
                        attempt [length: to integer! length]
                        0
                    ]

                    net-utils/net-log action
                ][
                    ; action: target: request-method: query-string: binary: content: request-uri: _
                    net-utils/net-log error: "Could Not Parse Request"
                ]
            ]
        ]
    ]

    dispatch: use [status-codes][
        status-codes: [
            200 "OK" 201 "Created" 204 "No Content"
            301 "Moved Permanently" 302 "Moved temporarily" 303 "See Other" 307 "Temporary Redirect"
            400 "Bad Request" 401 "No Authorization" 403 "Forbidden" 404 "Not Found" 411 "Length Required"
            500 "Internal Server Error" 503 "Service Unavailable"
        ]

        func [client [port!] /local response continue?][
            ; probe client/locals/wire
            client/locals/response: response: make response-prototype []
            client/locals/parent/locals/handler client/locals/request response
            write client append make binary! 0 collect [
                case/all [
                    not find status-codes response/status [
                        response/status: 500
                    ]
                    any [
                        not find [binary! string!] to word! type-of response/content
                        empty? response/content
                    ][
                        response/content: " "
                    ]
                ]

                keep reform ["HTTP/1.0" response/status select status-codes response/status]
                keep reform ["^/Content-Type:" response/type]
                keep reform ["^/Content-Length:" length? response/content]
                if response/location [
                    keep reform ["^/Location:" response/location]
                ]
                keep "^/^/"
            ]

            insert client/locals/wire response/content
        ]
    ]

    send-chunk: function [port [port!]][
           ;; Trying to send data > 32'000 bytes at once will trigger R3's internal
           ;; chunking (which is buggy, see above). So we cannot use chunks > 32'000
           ;; for our manual chunking.
           ;;
           ;; But let increase chunk size
           ;; to see if that bug exists again!
        either empty? port/locals/wire [_][
            if error? err: trap [
                    write port take/part port/locals/wire 2'000'000'000
            ][
                probe err
                ;; only mask some errors:
                unless all [
                    err/code = 5020
                    err/id = 'write-error
                    find [32 104] err/arg2
                ] [fail err]
            ]
        ]
    ]
]
