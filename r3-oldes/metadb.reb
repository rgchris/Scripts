Rebol [
    Title: "Mini-MetaDB"
    Author: "Christopher Ross-Gill"
    Date: 16-Mar-2010
    Version: 1.0.0
    File: %metadb.reb

    Purpose: "Simple associative database for managing metadata"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.metadb
    Exports: [
        meta
    ]

    Comment: [
        "Extracted from QuarterMaster project"
    ]
]

meta: meta://

metadb: context [
    root: case [
        get-env "R3_METADB" [
            dirize to-rebol-file get-env "R3_METADB"
        ]

        system/options/data [
            rejoin [
                dirize system/options/data
                %MetaDB/
            ]
        ]
    ]

    with: func [
        object [any-word! object! port!]
        block [any-block!]
        /only
    ][
        block: bind block object
        either only [block] :block
    ]

    url-encode: use [
        chars space
    ][
        chars: charset [
            "-."
            #"0" - #"9"
            #"A" - #"Z"
            #"-"
            #"a" - #"z"
            #"~"
        ]

        func [
            text [any-string!]
            /wiki
        ][
            space: either wiki ["_"] ["+"]

            either parse copy to binary! text [
                copy text any [
                    text:
                    end
                    |
                    some chars
                    |
                    change #" " space
                    |
                    if (wiki) change #"_" "=5F"
                    |
                    #"_"
                    |
                    (text: join "=" back back tail form to-hex text/1 16)
                    change skip text
                ]
            ][
                to string! text
            ][
                ""
            ]
        ]
    ]

    sys/make-scheme [
        name: 'meta
        title: "MetaDB"

        spec: make object! [
            title:
            scheme:
            ref:
            host:
            path:
            target: _
        ]

        init: func [
            port
            /local spec
        ][
            if not exists? root [
                return make error! reform [
                    "Metadata root directory does not exist."
                    "Please create the directory named" mold root
                ]
            ]

            if not all [
                url? port/spec/ref

                spec: copy find/tail port/spec/ref meta

                spec: split to string! spec #"/"

                parse spec with/only port/spec [
                    set host string!
                    (
                        target: rejoin [
                            root lowercase url-encode/wiki host %.reb
                        ]
                    )
                    set path opt string!
                    (
                        path: all [
                            path
                            to word! lowercase path
                        ]
                    )
                ]
            ][
                do make error! rejoin [
                    "Metadata URL <" port/spec/ref "> is invalid."
                ]
            ]
        ]

        actor: [
            open: func [
                port
            ][
                port/data: case [
                    not exists? port/spec/target [
                        make map! []
                    ]

                    error? port/data: try [
                        load port/spec/target
                    ][
                        do make error! rejoin [
                            "Could not open MetaDB file:"
                            mold port/spec/target
                        ]
                    ]

                    block? port/data [
                        make map! port/data
                    ]
                ]
            ]

            read: func [
                port
            ][
                open port

                either port/spec/path [
                    select port/data port/spec/path
                ][
                    port/data
                ]
            ]

            write: func [
                port value
            ][
                open port

                either none? port/spec/path [
                    do make error! rejoin [
                        "MetaDB requires a Key to write <"
                        port/spec/ref
                        ">"
                    ]
                ][
                    put port/data port/spec/path value
                    close port
                ]

                value
            ]

            delete: func [
                port
            ][
                either none? port/spec/path [
                    if exists? port/spec/target [
                        delete port/spec/target
                    ]
                ][
                    open port
                    remove/key port/data port/spec/path
                    close port
                ]

                ()
            ]

            close: func [
                port
            ][
                either empty? port/data [
                    if exists? port/spec/target [
                        delete port/spec/target
                    ]
                ][
                    save/header port/spec/target body-of port/data compose [
                        Title: (port/spec/host)
                        Type: metadb
                        Date: (now)
                    ]
                ]
            ]
        ]
    ]
]
