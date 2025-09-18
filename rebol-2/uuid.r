Rebol [
    Title: "UUID Generator for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 6-Jan-2022
    Version: 1.0.0
    File: %uuid.r

    Purpose: "Create UUID unique ID values"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.uuid
    Exports: [
        uuid
    ]

    Needs: [
        shim
    ]
]

uuid: context [
    random/seed any [
        get-env "UNIQUE_ID"

        use [
            remote timestamp
        ][
            timestamp: to decimal! difference now/precise 1-Jan-1970/0:00

            remote: any [
                get-env "REMOTE_ADDR"

                read rejoin [
                    dns:// system/options/hostname
                ]
            ]

            rejoin [
                to binary! to tuple! remote
                debase/base to-hex system/options/process-id 16
                skip tail to binary! to integer! timestamp -4
                skip tail to binary! to integer! timestamp // 1 * 65535 -2
            ]
        ]
    ]

    generate: func [
        "Generates a Version 4 UUID that is compliant with RFC 4122"
    ][
        collect [
            loop 16 [
                keep -1 + random/secure 256
            ]
        ]
    ]

    form: func [
        uuid
    ][
        uuid/7: uuid/7 and 15 or 64
        uuid/9: uuid/9 and 63 or 128

        uuid: enbase/base to binary! uuid 16

        insert skip uuid 20 #"-"
        insert skip uuid 16 #"-"
        insert skip uuid 12 #"-"
        insert skip uuid 8 #"-"

        uuid
    ]
]
