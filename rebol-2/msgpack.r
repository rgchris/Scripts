Rebol [
    Title: "MessagePack Encoder/Decoder for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 18-Apr-2022
    Home: https://gist.github.com/rgchris
    File: %msgpack.r
    Version: 0.0.3
    Rights: http://opensource.org/licenses/Apache-2.0
    Purpose: {
        (De)Serialize MessagePack content
    }

    Type: 'module
    Name: 'rgchris.msgpack
    Exports: [
        msgpack
    ]

    History: [
        18-Apr-2022 0.0.3 "Cleaner stream branching code"
        15-Feb-2022 0.0.2 "Correct code for block! export"
        30-Jan-2022 0.0.1 "Proof of concept: streaming parser"
    ]

    Notes: [
        https://msgpack.org/
        https://github.com/msgpack/msgpack/blob/master/spec.md

        https://stackoverflow.com/q/6355497/292969
        "Relative Merits of MessagePack"
    ]
]

do %bincode.r

msgpack: make object! [
    get-container: func [
        'stream [word!]
        type [datatype!]
        size [word!]
        handler [function!]
    ][
        either error? value: try [
            size: consume :stream size
        ][
            handler error! :value
        ][
            handler type size
        ]
    ]

    get-part: func [
        'stream [word!]
        type [datatype!]
        size [word! integer!]
        handler [function!]
    ][
        either error? value: try [
            if word? size [
                size: consume :stream size
            ]

            if type == datatype! [
                type: consume :stream 'signed-8
            ]

            consume :stream size
        ][
            handler error! :value
        ][
            handler type to type value
        ]
    ]

    get-number: func [
        'stream [word!]
        type [datatype!]
        size [word!]
        handler [function!]
    ][
        either error? value: try [
            consume :stream size
        ][
            handler error! :value
        ][
            handler type value
        ]
    ]

    stream: func [
        series [binary!]
        handler [function!]

        /local continue? value
    ][
        continue?: true

        while [
            continue?
        ][
            either tail? series [
                handler none! </end>
                continue?: false
            ][
                value: consume series 'unsigned-8

                continue?: case [
                    ; 0 0x00-7F => Unsigned-8
                    ;
                    value < 128 [
                        handler integer! value
                    ]

                    ; 111 0xE0-FF => Signed-8
                    ;
                    value and 224 == 224 [
                        handler integer! complement to integer! complement value
                    ]

                    ; 101 0xA0-BF => Short String
                    ;
                    value and 224 == 160 [
                        get-part series string! value and 31 :handler
                    ]

                    ; 1000 0x80-8F => Short Map
                    ;
                    value and 240 == 128 [
                        handler map! value and 15
                    ]

                    ; 1001 0x90-9F => Short Block
                    ;
                    value and 240 == 144 [
                        handler block! value and 15
                    ]

                    ; 110 0xC0-DF => Everything Else
                    ;
                    <else> [
                        switch value [
                            ; 1100 - 0xC0-CF
                            ;
                            192 [handler none! none]
                            193 [handler unset! none]
                            194 [handler logic! true]
                            195 [handler logic! false]
                            196 [get-part series binary! 'unsigned-8 :handler]
                            197 [get-part series binary! 'unsigned-16 :handler]
                            198 [get-part series binary! 'unsigned-32 :handler]
                            199 [get-part series datatype! 'unsigned-8 :handler]  ; -1 => date
                            200 [get-part series datatype! 'unsigned-16 :handler]
                            201 [get-part series datatype! 'unsigned-32 :handler]
                            202 [get-number series decimal! 'float-32 :handler]
                            203 [get-number series decimal! 'float-64 :handler]
                            204 [get-number series integer! 'unsigned-8 :handler]
                            205 [get-number series integer! 'unsigned-16 :handler]
                            206 [get-number series integer! 'unsigned-32 :handler]
                            207 [get-number series integer! 'unsigned-64 :handler]

                            ; 1101 - 0xD0-DF
                            ;
                            208 [get-number series integer! 'signed-8 :handler]
                            209 [get-number series integer! 'signed-16 :handler]
                            210 [get-number series integer! 'signed-32 :handler]
                            211 [get-number series integer! 'signed-64 :handler]
                            212 [get-part series datatype! 1 :handler]
                            213 [get-part series datatype! 2 :handler]  ; -1 => date
                            214 [get-part series datatype! 4 :handler]  ; -1 => date
                            215 [get-part series datatype! 8 :handler]
                            216 [get-part series datatype! 16 :handler]
                            217 [get-part series string! 'unsigned-8 :handler]
                            218 [get-part series string! 'unsigned-16 :handler]
                            219 [get-part series string! 'unsigned-32 :handler]
                            220 [get-container series block! 'unsigned-16 :handler]
                            221 [get-container series block! 'unsigned-32 :handler]
                            222 [get-container series map! 'unsigned-16 :handler]
                            223 [get-container series map! 'unsigned-32 :handler]
                        ]
                    ]
                ]
            ]
        ]

        series
    ]

    unpack: func [
        [catch]
        series [binary!]
        /local outcome stack counts
    ][
        stack: reduce []

        series: msgpack/stream series func [
            type [datatype!]
            value
        ][
            switch/default to word! type [
                block! [
                    value: array value

                    either empty? stack [
                        insert/only stack value
                    ][
                        stack/1: change/only stack/1 value
                        insert/only stack value
                    ]
                ]

                hash! [
                    value: make hash! array value * 2

                    either empty? stack [
                        insert/only stack value
                    ][
                        stack/1: change/only stack/1 value
                        insert/only stack value
                    ]
                ]

                none! [
                    either value == </end> [
                        throw make error! "Premature end of stream"
                    ][
                        stack/1: next stack/1
                    ]
                ]
            ][
                if not empty? stack [
                    stack/1: change stack/1 value
                ]
            ]

            while [
                all [
                    not empty? stack
                    tail? stack/1
                ]
            ][
                value: head take stack

                if block? value [
                    new-line/all value true
                ]
            ]

            if empty? stack [
                outcome: value
            ]

            ; continue streaming if not empty
            ;
            not empty? stack
        ]

        new-line/all reduce [
            outcome series
        ] true
    ]

    pack: func [
        value [block!]
        /local queue encoding
    ][
        queue: reduce [value]

        encoding: make binary! 1024

        accumulate encoding [
            while [
                not tail? queue
            ][
                switch type?/word value: take queue [
                    block! [
                        case [
                            16 > length? value [
                                unsigned-8 144 or length? value  ; 0x90-95
                            ]

                            65536 > length? value [
                                unsigned-8 220  ; 0xDC
                                unsigned-16 length? value
                            ]

                            <else> [
                                unsigned-8 221  ; 0xDD
                                unsigned-32 length? value
                            ]
                        ]

                        insert queue value
                    ]

                    integer! [
                        case [
                            value < -32768 [
                                unsigned-8 210  ; 0xD2
                                signed-32 value
                            ]

                            value < -128 [
                                unsigned-8 209  ; 0xD1
                                signed-16 value
                            ]

                            value < -31 [
                                unsigned-8 208  ; 0xD0
                                signed-8 value
                            ]

                            value < 128 [
                                signed-8 value
                            ]

                            value < 256 [
                                unsigned-8 204  ; 0xCC
                                unsigned-8 value
                            ]

                            value < 65536 [
                                unsigned-8 205  ; 0xCD
                                unsigned-16 value
                            ]

                            <else> [
                                unsigned-8 206  ; 0xCE
                                unsigned-32 value
                            ]
                        ]
                    ]

                    decimal! [
                        unsigned-8 203
                        float-64 value
                    ]

                    binary! [
                        case [
                            256 > length? value [
                                unsigned-8 196  ; 0xC4
                                unsigned-8 length? value
                            ]

                            65536 > length? value [
                                unsigned-8 197  ; 0xC5
                                unsigned-16 length? value
                            ]

                            <else> [
                                unsigned-8 198  ; 0xC6
                                unsigned-32 length? value
                            ]
                        ]

                        accumulate value
                    ]

                    string! url! email! [
                        case [
                            32 > length? value [
                                unsigned-8 160 or length? value
                            ]

                            256 > length? value [
                                unsigned-8 217  ; 0xD9
                                unsigned-8 length? value
                            ]

                            65536 > length? value [
                                unsigned-8 218  ; 0xDA
                                unsigned-16 length? value
                            ]

                            <else> [
                                unsigned-8 219  ; 0xDB
                                unsigned-32 length? value
                            ]
                        ]

                        accumulate value
                    ]

                    logic! [
                        unsigned-8 either value [195] [194]  ; 0xC3/0xC2
                    ]

                    none! [
                        unsigned-8 192  ; 0xC0
                    ]
                ]
            ]
        ]
    ]
]
