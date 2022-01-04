Rebol [
    Title: "REST-Friendly HTTP Protocol"
    Date: 28-Sep-2021
    Author: "Christopher Ross-Gill"
    Home: http://www.ross-gill.com/page/REST_Protocol
    File: %rest.r
    Version: 0.2.1
    Purpose: {
        An elementary HTTP protocol allowing more versatility when developing Web
        Services clients.
    }

    Rights: http://opensource.org/licenses/Apache-2.0

    Type: 'module
    Name: 'rgchris.rest

    History: [
        28-Sep-2021 0.2.1 "Refactored for readability"
        27-Jan-2018 0.2.0 "Tolerance of HTTP/2 Requests; Added Multipart (inc. OAuth)"
        12-Jan-2017 0.1.4 "Tidy up of OAuth portion"
        30-Oct-2012 0.1.3 "Use CURL in place of native TCP; Added OAuth"
        21-Aug-2010 0.1.2 "Submitted to Rebol.org"
        09-Nov-2008 0.1.1 "Minor changes"
        15-Aug-2006 0.1.0 "Original REST Version"
    ]
]

do %altwebform.r
do %curl.r

_: none

unless in system/schemes 'rest [
    system/schemes: make system/schemes [
        REST: _
    ]
]

system/schemes/rest: make system/standard/port [
    scheme: 'rest
    port-id: 80
    passive: _
    cache-size: 5
    proxy: make object! [
        host: _
        port-id: _
        user: _
        pass: _
        type: _
        bypass: _
    ]
]

system/schemes/rest/handler: use [
    support prepare transcribe execute
][
    support: make object! [
        to-numeric-timestamp: func [date [date!]] [
            timestamp: form any [
               ; Rebol 2 will never support integer date differences after 19-Jan-2038
               ;
               attempt [to integer! difference date 1-Jan-1970/0:0:0]
               date - 1-Jan-1970/0:0:0 * 86400.0
           ]

            clear find/last timestamp "."

            timestamp
        ]
    ]

    prepare: use [
        request-prototype header-prototype
        oauth-credentials oauth-prototype
        build-multipart
        sign
    ][
        request-prototype: make object! [
            version: 1.1
            action: "GET"
            headers: _
            query: _
            oauth: _
            bearer: _
            target: _
            content: _
            length: _
            timeout: _
            multipart: _
            type: 'application/x-www-form-urlencoded
        ]

        header-prototype: make object! [
            Expect: _
            Accept: "*/*"
            Connection: "close"
            User-Agent: rejoin [
                "Rebol/" system/product " " system/version
            ]

            Content-Length: _
            Content-Type: _
            Authorization: _
            Range: _
            Transfer-Encoding: _
        ]

        oauth-credentials: make object! [
            consumer-key: _
            consumer-secret: _
            oauth-token: _
            oauth-token-secret: _
            oauth-callback: _
        ]

        oauth-prototype: make object! [
            oauth_callback: _
            oauth_consumer_key: _
            oauth_token: _
            oauth_nonce: _
            oauth_signature_method: "HMAC-SHA1"
            oauth_timestamp: _
            oauth_version: 1.0
            oauth_verifier: _
            oauth_signature: _
        ]

        compose-multipart-request: use [
            break-lines make-boundary prototype
        ][
            break-lines: func [
                data [string!]
                /at size [integer!]
            ][
                size: any [size 72]

                rejoin remove collect [
                    while [not tail? data] [
                        keep "^/"
                        keep copy/part data size
                        data: skip data size
                    ]
                ]
            ]

            make-boundary: does [
                rejoin [
                    "--__Rebol__" form system/product
                    "__" replace/all form system/version "." "_"
                    "__" enbase/base checksum/secure form now/precise 16
                    "__"
                ]
            ]

            prototype: make object! [
                Content-Disposition: _
                Content-Type: _
                Content-Transfer-Encoding: _
            ]

            func [
                "Compose a multipart body from a request object."
                request [object!] "The request object"
                /local key value type filename content boundary here
            ][
                boundary: make-boundary

                request/headers/Content-Type: rejoin [
                    {multipart/form-data; boundary="} skip boundary 2 {"}
                ]

                request/content: rejoin remove collect [
                    ; keep "^M^/"

                    parse request/content [
                        some [
                            set key set-word!
                            [
                                set value [
                                    none! | string! | file! | binary!
                                ]
                                |
                                here:
                                [word! | get-word! | path! | paren!]
                                (
                                    throw-on-error [
                                        set/any [value here] do/next here
                                    ]
                                )
                                :here
                            ]
                            (
                                if switch type?/word value [
                                    string! [
                                        key: make prototype [
                                            Content-Disposition: rejoin [
                                                {form-data; name="} form key {"}
                                            ]
                                        ]
                                    ]

                                    binary! [
                                        case [
                                            ; Magic Numbers
                                            ;
                                            find/match value #{89504E470D0A1A0A} [
                                                type: "image/png"
                                                filename: "image.png"
                                            ]

                                            find/match value #{474946383761} [
                                                type: "image/gif"
                                                filename: "image.gif"
                                            ]

                                            find/match value #{474946383961} [
                                                type: "image/gif"
                                                filename: "image.gif"
                                            ]

                                            find/match value #{FFD8FF} [
                                                type: "image/jpeg"
                                                filename: "image.jpg"
                                            ]

                                            'else [
                                                type: "application/octet-stream"
                                                filename: "file.bin"
                                            ]
                                        ]

                                        key: make prototype [
                                            content-disposition: rejoin [
                                                {form-data; name="} form key {"; filename="} filename {"}
                                            ]
                                            content-type: type
                                            content-transfer-encoding: "binary"  ; "base64"
                                        ]

                                        ; value: break-lines enbase value
                                    ]

                                    ; file! [
                                    ;
                                    ; ]
                                ][
                                    keep "^M^/"
                                    keep boundary
                                    keep "^M^/"
                                    keep replace/all net-utils/export key "^/" "^M^/"
                                    keep "^M^/"
                                    keep as-string value
                                ]
                            )
                            | skip
                        ]
                    ]

                    keep "^M^/"
                    keep boundary
                    keep "--^M^/"
                ]
            ]
        ]

        sign: func [
            request [object!]
            /local header params timestamp out
        ][
            out: copy ""

            timestamp: now/precise

            header: make oauth-prototype [
                oauth_consumer_key: request/oauth/consumer-key
                oauth_token: request/oauth/oauth-token
                oauth_callback: request/oauth/oauth-callback
                oauth_nonce: enbase checksum/secure rejoin [
                    timestamp oauth_consumer_key
                ]

                oauth_timestamp: support/to-numeric-timestamp timestamp
            ]

            params: collect [
                keep body-of header

                if all [
                    request/content
                    not request/multipart
                ][
                    keep request/content
                ]
            ]

            sort/skip params 2

            header/oauth_signature: rejoin [
                uppercase form request/action "&" url-encode form request/url "&"
                url-encode replace/all to-webform params "+" "%20"
            ]

            header/oauth_signature: enbase checksum/secure/key header/oauth_signature rejoin [
                request/oauth/consumer-secret
                "&"
                any [
                    request/oauth/oauth-token-secret
                    ""
                ]
            ]

            foreach [name value] body-of header [
                if value [
                    repend out [
                        ", " form name {="} url-encode form value {"}
                    ]
                ]
            ]

            if all [
                request/action = "GET"
                request/content
            ][
                request/url: rejoin [
                    request/url
                    to-webform/prefix request/content
                ]

                request/content: _
            ]

            request/headers/Authorization: rejoin [
                "OAuth" next out
            ]
        ]

        prepare: func [
            port [port!]
            /local request
        ][
            port/locals/request: request: make request-prototype port/locals/request

            request/action: uppercase form request/action

            request/headers: make header-prototype any [
                request/headers
                []
            ]

            request/content: any [
                port/state/custom  ; WebForm simulation mode
                request/content
            ]

            case [
                request/oauth [
                    request/oauth: make oauth-credentials request/oauth
                    sign request
                ]

                request/bearer [
                    request/headers/Authorization: rejoin [
                        "Bearer " request/bearer
                    ]
                ]

                all [
                    not request/headers/Authorization
                    port/user port/pass
                ][
                    request/headers/Authorization: rejoin [
                        "Basic " enbase rejoin [
                            port/user #":" port/pass
                        ]
                    ]
                ]
            ]

            if port/state/index > 0 [
                request/version: 1.1
                request/headers/Range: rejoin [
                    "bytes=" port/state/index "-"
                ]
            ]

            case/all [
                block? request/content [
                    either request/multipart [
                        request/type: 'multipart/form-data
                        compose-multipart-request request
                    ][
                        request/content: to-webform request/content
                    ]
                ]

                any [
                    string? request/content
                    binary? request/content
                ][
                    request/length: length? request/content

                    if request/length > 1024 [
                        request/headers/Expect: ""
                        ; request/headers/Transfer-Encoding: "chunked"
                        ; request/headers/Connection: "keep-alive"
                    ]

                    request/headers/Content-Length: form request/length

                    request/headers/Content-Type: any [
                        request/headers/Content-Type form request/type
                    ]
                ]
            ]

            port
        ]
    ]

    execute: func [
        port [port!]
    ][
        curl/full/method/header/with/timeout/into  ; url action headers content timeout response
        port/locals/request/url
        port/locals/request/action
        port/locals/request/headers
        port/locals/request/content
        port/locals/request/timeout
        port/locals/response
    ]

    transcribe: use [
        response-code header-feed header-name header-part
        response-prototype header-prototype
    ][
        response-code: use [digit] [
            digit: charset "0123456789"
            [3 digit]
        ]

        header-feed: [
            newline | crlf
        ]

        header-part: use [chars] [
            chars: complement charset [
                #"^(00)" - #"^(1F)"
            ]

            [
                some chars
                any [
                    header-feed
                    some " "
                    some chars
                ]
            ]
        ]

        header-name: use [chars] [
            chars: charset [
                "_-0123456789"
                #"a" - #"z"
                #"A" - #"Z"
            ]

            [some chars]
        ]

        space: use [chars] [
            chars: charset " ^-"

            [some chars]
        ]

        response-prototype: context [
            status: _
            message: _
            http-headers: _
            headers: _
            content: _
            binary: _
            type: _
            length: _
        ]

        header-prototype: context [
            date: _
            server: _
            last-modified: _
            accept-ranges: _
            content-encoding: _
            content-type: _
            content-length: _
            location: _
            expires: _
            referer: _
            connection: _
            authorization: _
        ]

        transcribe: func [port [port!] /local response name value pos] [
            port/locals/response: response: make response-prototype [
                any [
                    parse/all port/locals/response [
                        "HTTP/" [
                            "1." ["0" | "1"]
                            space
                            copy status response-code
                            space
                            copy message header-part
                            |
                            "2"
                            space
                            copy status response-code
                            (message: "")
                            opt [
                                space opt [
                                    copy message header-part
                                ]
                            ]
                        ]
                        header-feed
                        (
                            net-utils/net-log reform [
                                "HTTP Response:" status message
                            ]
                        )
                        (
                            status: load status
                            headers: make block! []
                        )
                        some [
                            copy name header-name
                            ":" any " "
                            copy value header-part
                            header-feed
                            (
                                repend headers [
                                    to set-word! name
                                    value
                                ]
                            )
                        ]
                        header-feed
                        content: to end (
                            content: as-string binary: as-binary copy content
                        )
                    ]
                    (
                        net-utils/net-log pos
                        make error! "Could Not Parse HTTP Response"
                    )
                ]

                http-headers: new-line/skip headers true 2
                headers: make header-prototype http-headers

                type: all [
                    path? type: attempt [
                        load headers/Content-Type
                    ]
                    type
                ]

                length: any [
                    attempt [
                        headers/Content-Length: to integer! headers/Content-Length
                    ]
                    0
                ]
            ]
        ]
    ]

    context [
        port-flags: system/standard/port-flags/pass-thru

        init: func [
            port [port!]
            spec [url! block!]
            /local url
        ][
            port/locals: context [
                request: case/all [
                    url? spec [
                        spec: compose [
                            url: (
                                to url! replace form spec rest:// http://
                            )
                        ]
                    ]

                    block? spec [
                        ; we don't alter SPEC here, just resolve and validate the URL value
                        ;
                        case/all [
                            not url: find spec quote url: [
                                make error! "REST spec needs a URL"
                            ]

                            none? url: pick url 2 [
                                make error! "REST spec missing URL"
                            ]

                            get-word? :url [
                                url: get/any :url
                            ]

                            paren? :url [
                                url: do :url
                            ]

                            not url? :url [
                                make error! "REST spec needs a URL of type URL!"
                            ]

                            not parse/all url ["http" opt "s" "://" to end] [
                                make error! "REST Spec only works with HTTP(S) urls"
                            ]

                            :url [spec]
                        ]
                    ]
                ]

                response: make string! ""
            ]
        ]

        open: func [
            port [port!]
        ][
            port/state/flags: port/state/flags or port-flags
            execute prepare port
        ]

        copy: :transcribe

        close: does []
    ]
]
