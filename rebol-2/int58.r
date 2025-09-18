Rebol [
    Title: "Int58 Encode/Decode for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 5-Dec-2009
    Version: 1.0.0
    File: %int58.r

    Purpose: "Int58 Encoder/Decoder"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.int58
    Exports: [
        int58
    ]

    Needs: [
        shim
    ]

    History: [
        7-Jul-2022 0.1.0
        "Initial Encoder/Decoder"
    ]

    Comment: [
        https://www.flickr.com/groups/api/discuss/72157616713786392/
        "Flickr Short Urls"
    ]

    Usage: [
        probe "nh" = int58/encode 1234
        probe 1234 = int58/decode "nh"
        browse join http://flic.kr/p/ int58/encode #2740009121
    ]
]

int58: context private [
    alphabet: "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"

    factor: [
        1 58 3364 195112 11316496 656356768. 38068692544
        2207984167552 128063081718016 7427658739644928
    ]
][
    encode: func [
        value [number! issue!]
    ][
        value: load form value

        rejoin reverse collect [
            while [
                value > 0
            ][
                keep pick alphabet round value // 58 + 1
                value: to integer! value / 58
            ]
        ]
    ]

    decode: func [
        encoding [string! issue!]

        /local value
    ][
        encoding: tail encoding
        value: 0

        until [
            encoding: back encoding

            value: -1 + (index-of find/case alphabet encoding/1) * factor/(length-of encoding) + value

            head? encoding
        ]

        value
    ]
]
