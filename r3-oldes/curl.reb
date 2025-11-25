Rebol [
    Title: "CURL"
    Author: "Christopher Ross-Gill"
    Date: 1-Sep-2025
    Version: 0.1.6
    File: %curl.reb

    Purpose: "Rebol wrapper for CURL command"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.curl
    Exports: [
        curl
    ]

    History: [
        1-Sep-2025 0.1.6
        "Modifications for Rebol 3"

        15-Jan-2017 0.1.4
        "Fix /BINARY mode"

        15-Jan-2017 0.1.3
        "Added /LEGACY Refinement; Binary Uploads"

        21-Oct-2012 0.1.2
        "First Published Version"
    ]

    Comment: [
        https://curl.se/
        http://curl.haxx.se/
        "CURL Home Page"

        https://www.paehld.de/open_source/?CURL&search=curl
        "CURL for Windows"
    ]
]

curl: use [
    curl-location user-agent error-codes enquote form-headers
][
    if not exists? curl-location: %/usr/local/opt/curl/bin/curl [
        call/wait/shell/output "which curl" curl-location: ""
        curl-location: to file! trim/tail curl-location
    ]

    user-agent: reform [
        "Rebol" system/product system/version
    ]

    error-codes: #[
        1 "Unsupported protocol. This build of curl has no support for this protocol."
        2 "Failed to initialize."
        3 "URL malformed. The syntax was not correct."
        4 "Feature not included in this cURL build."
        6 "Couldn't resolve host. The given remote host was not resolved."
        7 "Failed to connect to host."
        28 "Request timed out."
        50 "OS shell error."
        52 "The server didn't reply anything."
        56 "Failure with receiving network data."
    ]

    enquote: func [
        data [block! any-string!]
        /local mark
    ][
        mark: switch/default system/version/4 [
            3 [
                #"^""
            ]
        ][
            #"'"
        ]

        rejoin compose [
            mark (data) mark
        ]
    ]

    form-headers: func [
        headers [block! object!]

        /local out
    ][
        collect [
            foreach [header value] switch type-of/word headers [
                block! [
                    headers
                ]

                object! [
                    body-of headers
                ]
            ][
                if value [
                    keep rejoin [
                        " -H " enquote [
                            form header ": " value
                        ]
                    ]
                ]
            ]
        ]
    ]

    curl: func [
        "Wrapper for the cURL shell function"

        url [url!]
        "URL to Retrieve"

        /method
        "Specify HTTP request method"

        verb [word! string! none!]
        "HTTP request method"

        /with
        "Include request body"

        data [string! binary! file! none!]
        "Request body"

        /header
        "Specify HTTP headers"

        headers [block! object! none!]
        "HTTP headers"

        /as
        "Specify user agent"

        agent [string!]
        "User agent"

        /user
        "Provide User Credentials"

        name [string! none!]
        "User Name"

        pass [string! none!]
        "User Password"

        /full
        "Include HTTP headers in response"

        /binary
        "Receive response as binary"

        /string
        "Receive response as string"

        /follow
        "Follow HTTP redirects"

        /fail
        "Return none! on 4xx/5xx HTTP responses"

        /secure
        "Disallow 'insecure' SSL transactions"

        /into
        "Specify result string"

        out [string! none!]
        "String to contain result"

        /error
        "Specify error string"

        err [string! none!]
        "String to contain error"

        /timeout
        "Specify a time limit"

        time [time! none!]
        "Time limit"

        /legacy
        "Use HTTP/1.0"

        /local command code
    ][
        out: any [
            out
            copy #{}
        ]

        err: any [
            err
            copy #{}
        ]

        command: rejoin collect [
            keep form curl-location

            keep " -s"

            case/all [
                legacy [
                    keep "0"
                ]

                full [
                    keep "i"
                ]

                fail [
                    keep "f"
                ]

                not secure [
                    keep "k"
                ]

                follow [
                    keep "L"
                ]

                verb [
                    keep " -X " keep verb: uppercase form verb
                ]

                time [
                    keep " -m " keep to integer! time
                ]

                data [
                    either file? data [
                        keep reduce [
                            " --data-binary @" form data
                        ]

                        data: ""
                    ][
                        keep " --data-binary @-"
                    ]
                ]

                all [
                    name
                    pass
                ][
                    keep " -u " keep enquote [
                        name #":" pass
                    ]
                ]

                headers [
                    keep form-headers headers
                ]
            ]

            keep reduce [
                " -A " enquote any [
                    agent user-agent
                ]
            ]

            keep reduce [
                #" " enquote url
            ]
        ]

        if not all [
            data
            not empty? data
        ][
            data: none
        ]

        code: call/wait/shell/input/output/error command data out err

        sys/log 'Rebol [
            to word! any [verb "GET"] url
        ]

        sys/log 'Rebol command

        sys/log 'Rebol reform [
            "cURL Response Code:" code
        ]

        case [
            find [0 18] code [
                either all [
                    string
                    not invalid-utf? out
                ][
                    to string! out
                ][
                    out
                ]
            ]

            code == 22 [
                none
            ]

            code == 1 [
                if empty? trim/head/tail err [
                    err: select error-codes 1
                ]

                do make error! :err
            ]

            find error-codes code [
                do make error! select error-codes code
            ]

            <else> [
                do make error! reform [
                    "cURL Error Code" code trim/head/tail err
                ]
            ]
        ]
    ]
]
