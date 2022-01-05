Rebol [
    Title: "Amazon S3 Protocol"
    Author: "Christopher Ross-Gill"
    Date: 30-Aug-2011
    File: %s3.r
    Version: 0.2.1
    Purpose: {Basic retrieve and upload protocol for Amazon S3.}
    Rights: http://opensource.org/licenses/Apache-2.0
    Example: [
        do/args http://reb4.me/r/s3 [args (see settings)]
        write s3://<bucket>/file/foo.txt "Foo"
        read s3://<bucket>/file/foo.txt
    ]
    History: [
        23-Nov-2008 ["Graham Chiu" "Maarten Koopmans" "Gregg Irwin"]
    ]
    Settings: [
        AWSAccessKeyId: <AWSAccessKeyId>
        AWSSecretAccessKey: <AWSSecretAccessKey>
        Secure: true  ; optional
    ]
]

do http://reb4.me/r/http-custom

make object! bind [
    port-flags: system/standard/port-flags/pass-thru

    init: use [chars url] [
        chars: charset [
            "-_!+%.,"
            #"0" - #"9"
            #"a" - #"z" #"A" - #"Z"
        ]

        url: [
            "s3://" [
                copy user some chars
                #":"
                copy pass some chars
                #"@"
                |
                (
                    user: none
                    pass: none
                )
            ]

            copy host some chars
            #"/"
            copy path any [
                some chars
                #"/"
            ]
            copy target any chars

            end

            (
                path: if path [
                    to file! path
                ]

                target: if target [
                    to file! target
                ]

                user: any [
                    user
                    settings/awsaccesskeyid
                ]

                pass: any [
                    pass
                    settings/awssecretaccesskey
                ]

                url: rejoin [
                    s3:// host "/"
                    any [path ""]
                    any [target ""]
                ]
            )
        ]

        func [port spec] [
            if not all [
                url? spec
                parse/all spec bind url port
            ][
                make error! "Invalid S3 Spec"
            ]

            spec: rejoin [
                either settings/secure [
                    https://
                ][
                    http://
                ]

                port/host ".s3.amazonaws.com/"

                any [
                    all [
                        port/target
                        port/path
                    ]
                    ""
                ]

                any [
                    port/target
                    ""
                ]
            ]

            port/sub-port: make port! spec
        ]
    ]

    open: use [options] [
        options: make object! [
            options:
            modes:
            type:
            md5:
            access:
            prefix: _
        ]

        func [port] [
            port/state/flags: port/state/flags or port-flags

            port/locals: make options [
                modes: make block! 3

                if port/state/flags and 1 > 0 [
                    append modes 'read
                ]

                if port/state/flags and 2 > 0 [
                    append modes 'write
                ]

                if port/state/flags and 32 > 0 [
                    append modes 'binary
                ]

                options: any [
                    port/state/custom
                    make block! 0
                ]

                if all [
                    port/path
                    not port/target
                ][
                    repend options [
                        'prefix port/path
                    ]
                ]

                parse options [
                    any [
                        'md5
                        set md5 string!
                        |
                        'type
                        set type path!
                        (type: form type)
                        |
                        'read
                        (access: "public-read")
                        |
                        'write
                        (access: "public-read-write")
                        |
                        'prefix
                        set prefix [
                            string! | file!
                        ]
                        (
                            if not port/target [
                                port/sub-port/path: join "?prefix=" prefix
                            ]
                        )
                        |
                        skip
                    ]
                ]
            ]
        ]
    ]

    copy: func [port] [
        send "GET" port _
    ]

    insert: func [port data] [
        if not port/target [
            make error! "Not a valid S3 key"
        ]

        case [
            none? data [
                send "DELETE" port _
            ]

            any [
                string? data
                binary? data
            ][
                send "PUT" port data
            ]

            data [
                send "PUT" port form data
            ]
        ]
    ]

    close: does []

    query: func [port] [
        port/locals: [
            modes [read]
        ]

        send "HEAD" port _

        port/size: attempt [
            to integer! port/sub-port/locals/headers/content-length
        ]

        port/date: port/sub-port/date

        port/status: either port/target [
            'file
        ][
            'directory
        ]
    ]

    if not in system/schemes 's3 [
        system/schemes: make system/schemes [
            s3: _
        ]
    ]

    system/schemes/s3: make system/standard/port compose [
        scheme: 's3
        port-id: 0
        handler: (self)
        passive: _
        cache-size: 5
        proxy: make object! [
            host:
            port-id:
            user:
            pass:
            type:
            bypass: _
        ]
    ]
]

make object! [
    _: none

    settings: make context [
        awsaccesskeyid:
        awssecretaccesskey: ""
        secure: true
    ] any [
        system/script/args
        system/script/header/settings
    ]

    get-http-response: func [port] [
        reform next parse do bind [response-line] last second get in port/handler 'open none
    ]

    send: use [timestamp detect-mime sign compose-request] [
        timestamp: func [/for date [date!]] [
            date: any [
                date
                now
            ]
            date/time: date/time - date/zone

            rejoin [
                copy/part pick system/locale/days date/weekday 3
                ", "
                next form 100 + date/day
                " "
                copy/part pick system/locale/months date/month 3
                " "
                date/year
                " "
                next form 100 + date/time/hour
                ":"
                next form 100 + date/time/minute
                ":"
                next form 100 + to integer! date/time/second
                " GMT"
            ]
        ]

        detect-mime: use [types] [
            types: [
                application/octet-stream
                text/html %.html %.htm
                image/jpeg %.jpg %.jpeg
                image/png %.png
                image/tiff %.tif %.tiff
                application/pdf %.pdf
                text/plain %.txt %.r
                application/xml %.xml
                video/mpeg %.mpg %.mpeg
                video/x-m4v %.m4v
            ]

            func [
                file [file! url! none!]
            ][
                if file [
                    file: any [
                        find types suffix? file
                        next types
                    ]

                    form first find/reverse file path!
                ]
            ]
        ]

        sign: func [
            verb [string!]
            port [port!]
            request [object!]
        ][
            rejoin [
                "AWS " port/user ":"
                enbase/base checksum/secure/key rejoin [
                    form verb
                    newline
                    newline  ; any [port/locals/md5 ""] newline
                    any [
                        request/type ""
                    ]
                    newline
                    timestamp
                    newline
                    either request/auth [
                        rejoin [
                            "x-amz-acl:" request/auth "^/"
                        ]
                    ][
                        ""
                    ]
                    "/" port/host
                    "/" any [
                        all [
                            port/target
                            port/path
                        ] ""
                    ]
                    any [
                        port/target ""
                    ]
                ] port/pass 64
            ]
        ]

        compose-request: func [
            verb [string!]
            port [port!]
            data [series! none!]
        ][
            data: make object! [
                body: any [
                    data ""
                ]

                size: all [
                    data
                    length? data
                ]

                type: all [
                    data any [
                        port/locals/type
                        detect-mime port/target
                    ]
                ]

                auth: all [
                    data
                    port/locals/access
                ]
            ]

            reduce [
                to-word verb data/body

                foreach [header value] [
                    "Date" [timestamp]
                    "Content-Type" [data/type]
                    "Content-Length" [data/size]
                    "Authorization" [sign verb port data]
                    "x-amz-acl" [data/auth]
                    "Pragma" ["no-cache"]
                    "Cache-Control" ["no-cache"]
                ][
                    if value: all :value [
                        repend [] [
                            to-set-word header
                            form value
                        ]
                    ]
                ]
            ]
        ]

        send: func [
            [catch]
            method [string!]
            port [port!]
            data [any-type!]
        ][
            either error? data: try [
                open/mode/custom port/sub-port port/locals/modes compose-request method port data
            ][
                net-error rejoin [
                    "Target url " port/url " could not be retrieved "
                    "(" get-http-response port/sub-port ")."
                ]
            ][
                data: copy port/sub-port

                either port/target [
                    data
                ][
                    unless method = "HEAD" [
                        data: load/markup data
                        parse data [
                            copy data any [
                                data:
                                <key>
                                (
                                    remove data
                                    change data to-file data/1
                                )
                                |
                                skip
                                (
                                    remove data
                                )
                                :data
                            ]
                        ]
                        data
                    ]
                ]
            ]
        ]
    ]
]
