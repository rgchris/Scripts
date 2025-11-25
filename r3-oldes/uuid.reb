Rebol [
    Title: "UUID Generator"
    Author: "Christopher Ross-Gill"
    Date: 6-Jan-2022
    Version: 1.0.0
    File: %uuid.reb

    Purpose: "Generate unique IDs in standard form"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.uuid
    Exports: [
        uuid
    ]

    Needs: [
        r3:rgchris:core
    ]
]

uuid: make object! [
    use [
        seed
    ][
        seed: any [
            get-env "UNIQUE_ID"

            use [
                remote timestamp seconds
            ][
                timestamp: to decimal! difference now/precise 1-Jan-1970T0:00

                remote: any [
                    get-env "REMOTE_ADDR"

                    read rejoin [
                        dns:// system/options/hostname
                    ]
                ]

                rejoin [
                    to binary! to tuple! remote
                    skip tail to binary! system/options/process-id -4
                    skip tail to binary! to integer! timestamp -4
                    skip tail to binary! to integer! timestamp // 1 * 65535 -2
                ]
            ]
        ]

        random/seed seed
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

    to-text: func [
        uuid
    ][
        uuid/7: uuid/7 and 15 or 64
        uuid/9: uuid/9 and 63 or 128

        uuid: enbase to binary! uuid 16

        insert skip uuid 20 "-"
        insert skip uuid 16 "-"
        insert skip uuid 12 "-"
        insert skip uuid 8 "-"

        head uuid
    ]
]
