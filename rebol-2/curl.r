Rebol [
    Title: "cURL"
    Author: "Christopher Ross-Gill"
    Date: 15-Jan-2017
    File: %curl.r
    Version: 0.1.4
    Needs: [2.7.7 shell]
    Purpose: "Rebol wrapper for cURL command."
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: 'module
    Name: 'rgchris.curl
    Exports: [curl]
    History: [
        15-Jan-2017 0.1.4 "Fix /BINARY mode"
        15-Jan-2017 0.1.3 "Added /LEGACY Refinement; Binary Uploads"
        21-Oct-2012 0.1.2 "First Published Version"
    ]
    Notes: [
        "cURL Home Page" http://curl.haxx.se/
    ]
]

curl: use [user-agent form-headers enquote curl-location] [
    if not exists? curl-location: %/usr/local/opt/curl/bin/curl [
        call/wait/output "which curl" curl-location: make string! 0
        curl-location: to file! trim/tail curl-location
    ]

    user-agent: reform ["Rebol" system/product system/version]

    enquote: func [
        data [block! any-string!]
        /local mark
    ][
        mark: switch/default system/version/4 [3 [{"}]] ["'"]
        rejoin compose [mark (data) mark]
    ]

    form-headers: func [headers [block! object!] /local out] [
        collect [
            foreach [header value] switch type?/word headers [
                block! [headers]
                object! [body-of headers]
            ][
                if value [
                    keep rejoin [" -H " enquote [form header ": " value]]
                ]
            ]
        ]
    ]

    curl: func [
        "Wrapper for the cURL shell function"
        [catch]
        url [url!] "URL to Retrieve"
        /method "Specify HTTP request method"
        verb [word! string! none!] "HTTP request method"
        /with "Include request body"
        data [string! binary! file! none!] "Request body"
        /header "Specify HTTP headers"
        headers [block! object! none!] "HTTP headers"
        /as "Specify user agent"
        agent [string!] "User agent"
        /user "Provide User Credentials"
        name [string! none!] "User Name"
        pass [string! none!] "User Password"
        /full "Include HTTP headers in response"
        /binary "Receive response as binary"
        /follow "Follow HTTP redirects"
        /fail "Return none! on 4xx/5xx HTTP responses"
        /secure "Disallow 'insecure' SSL transactions"
        /into "Specify result string"
        out [string! none!] "String to contain result"
        /error "Specify error string"
        err [string! none!] "String to contain error"
        /timeout "Specify a time limit"
        time [time! none!] "Time limit"
        /legacy "Use HTTP/1.0"
        /local command code
    ][
        out: any [out copy ""]
        err: any [err copy ""]

        command: rejoin collect [
            keep form curl-location
            
            keep " -s"

            case/all [
                legacy [keep "0"]
                full [keep "i"]
                fail [keep "f"]
                not secure [keep "k"]
                follow [keep "L"]
                verb [keep " -X " keep verb: uppercase form verb]
                time [keep " -m " keep to integer! time]
                data [
                    either file? data [
                        keep reduce [" --data-binary @" form data]
                        data: ""
                    ][
                        keep " --data-binary @-"
                    ]
                ]
                all [name pass] [keep " -u " keep enquote [name ":" pass]]
                headers [keep form-headers headers]
            ]

            keep reduce [
                " -A " enquote any [agent user-agent]
            ]

            keep reduce [" " enquote url]
        ]

        data: as-string any [data ""]

        code: call/wait/input/output/error command data out err

        net-utils/net-log [to word! any [verb "GET"] url]
        net-utils/net-log command
        net-utils/net-log reform ["cURL Response Code:" code]

        switch/default code [
            0 18 [either binary [as-binary out] [out]]
            1 [
                if empty? trim/head/tail err [
                    err: "Unsupported protocol. This build of curl has no support for this protocol."
                ]
                throw make error! :err
            ]
            2 [throw make error! "Failed to initialize."]
            3 [throw make error! "URL malformed. The syntax was not correct."]
            4 [throw make error! "Feature not included in this cURL build."]
            6 [throw make error! "Couldn't resolve host. The given remote host was not resolved."]
            7 [throw make error! "Failed to connect to host."]
            22 [none]
            28 [throw make error! "Request timed out."]
            50 [throw make error! "OS shell error."]
            52 [throw make error! "The server didn't reply anything."]
            56 [throw make error! "Failure with receiving network data."]
        ][
            code: reform ["cURL Error Code" code trim/head/tail err]
            throw make error! code
        ]
    ]
]
