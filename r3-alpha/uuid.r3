Rebol [
    Title: "UUID Generator"
    Date: 6-Jan-2022
    File: %uuid.r3
    Version: 1.0.0

    Type: module
    Name: rgchris.uuid
    Exports: [
        uuid
    ]
]

uuid: make object! [
    generate: func [
        "Generates a Version 4 UUID that is compliant with RFC 4122"
    ][
        random/seed now/precise

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

        uuid: insert skip uuid 8 "-"
        uuid: insert skip uuid 4 "-"
        uuid: insert skip uuid 4 "-"
        uuid: insert skip uuid 4 "-"
        head uuid
    ]
]
