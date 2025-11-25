Rebol [
    Title: "Core Functions for Rebol 3"
    Author: "Christopher Ross-Gill"
    Date: 20-Jun-2025
    Version: 1.0.0
    File: %core.reb

    Purpose: "Common Core functions for this folder's modules"

    Home: http://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.core
    Exports: [
        neaten
        type-of length-of
        collect-while collect-each
        elide flatten private amass fold
    ]

    Needs: 3.20.0
]

if not in lib 'did [
    extend lib 'did :true?
]

type-of: :lib/type?
length-of: :lib/length?

neaten: func [
    "Resets new-line markers in a BLOCK! value. Default: all new-line markers ON"

    block [block!]
    "Block to set"

    /pairs
    "Sets all new-line markers OFF, sets every second new-line marker ON"

    /triplets
    "Sets all new-line markers OFF, sets every third new-line marker ON"

    /flat
    "Sets all new-line markers OFF"

    /pipes
    "sets every new-line marker before/after a pipe ON"

    /words
    "sets every new-line marker before a word ON"

    /set-words
    "sets every new-line marker before a set-word ON"

    /first
    "sets first new-line marker ON"

    /by
    "sets new-line marker ON at a given interval"

    length
    "Interval with which to turn new-line markers ON"

    /force
    "Sets all new-line markers OFF before performing any operations above"
][
    case [
        words [
            if force [
                new-line/all block false
            ]

            parse block [
                any [
                    ['on | 'off | 'yes | 'no | 'true | 'false | 'none | none!]
                    |
                    [word! | set-word! | path! | set-path!]
                    block:
                    (new-line back block true)
                    |
                    skip
                ]
            ]

            new-line head block true
        ]

        set-words [
            if force [
                new-line/all block false
            ]

            parse block [
                any [
                    [set-word! | set-path!]
                    block:
                    (new-line back block true)
                    |
                    skip
                ]
            ]

            new-line head block true
        ]

        pipes [
            if force [
                new-line/all block false
            ]

            parse block [
                any [
                    '|
                    block:
                    skip
                    (
                        new-line back block true
                        new-line block true
                    )
                    |
                    skip
                ]
            ]

            new-line head block true
        ]

        first [
            new-line new-line/all block false true
        ]

        <else> [
            ; need this HEAD-REMOVE-BACK-TAIL-APPEND hack to fix the tail--NEW-LINE bug
            ;
            ; head remove back tail new-line/all/skip append block _ not flat case [
            new-line/all/skip block not flat case [
                pairs [2]
                triplets [3]
                by [length]
                <else> [1]
            ]
        ]
    ]
]

collect-while: func [
    {
    While condition block is TRUE, evaluate body block storing values via
    KEEP function, returning a block of collected values.
    }
    cond-block [block!]
    body-block [block!]
][
    collect reduce [
        :while :cond-block :body-block
    ]
]

collect-each: func [
    {
    Evaluates a block for each value(s), storing values via KEEP function,
    and returns block of collected values.
    }

    'word [get-word! word! block!]
    "Word or block of words to set each time (will be local)"

    data [series! map! any-object!]
    "The series to traverse"

    body [block!]
    "Block to evaluate each time"
][
    collect reduce [
        :foreach :word 'data body
    ]
]

elide: func [
    "First argument is evaluated, but discarded"
    discarded [any-type!]
    value [any-type! unset!]
][
    get/any 'value
]

flatten: func [
    "De-nest blocks"
    block [any-block!]
    /once
][
    once: either once [
        [(block: insert block take block)]
    ][
        [(insert block take block)]
    ]

    parse block [
        any [
            block:
            any-block!
            once
            :block
            |
            skip
        ]
    ]

    head block
]

private: func [
    context [block! object!]
    spec [block!]
][
    bind spec either block? context [
        make object! context
    ][
        context
    ]
]

amass: func [
    spec [block!]
    /local out
][
    out: copy #[]

    foreach word spec [
        if all [
            word? :word
            value? :word
        ][
            put out unbind :word get :word
        ]
    ]

    out
]

fold: func [
    "Accumulative function iterating across all values of a block"
    series [block!]
    do-fold [any-function!]
    /initial
    out
][
    if not initial [
        out: first series
        series: next series
    ]

    foreach value series [
        out: do-fold out value
    ]
]

; Rebol 3 Modules Directory Scheme
;
if not in system/schemes 'r3 [
    ; Establish Modules scheme
    ;
    append system/options/log [
        modules: 1
    ]

    context [
        ; module management to follow here
        ;
        digit: charset "0123456789"

        char: complement charset [
            0 - 64
            91 - 96
            123 - 127
        ]
        ; captures alpha + utf-8

        sys/make-scheme [
            name: 'r3
            title: "Rebol 3 Basic Module System"

            spec: make object! [
                title:
                scheme:
                ref:
                target:
                file:
                type:
                suffix:
                version:
                options:
                is-minimum: _
            ]

            init: func [
                port
                /local part
            ][
                case [
                    not url? port/spec/ref [
                        sys/log/info 'MODULES [
                            "R3 Modules: Block usage reserved.^[[m"
                        ]

                        do make error! "R3 Modules: Block usage reserved"
                    ]

                    not parse port/spec/ref [
                        "r3:"

                        copy part [
                            char
                            some [
                                some char | digit | #"-" | #","
                            ]

                            1 4 [
                                #":"
                                char
                                some [
                                    some char | digit | #"-" | #","
                                ]
                            ]
                        ]
                        (port/spec/target: part)

                        opt [
                            #"@"
                            copy part [
                                some digit
                                0 3 [
                                    #"."
                                    some digit
                                ]
                                opt ".x"
                            ]
                            (port/spec/version: part)

                            opt [
                                #"+"
                                (port/spec/is-minimum: yes)
                            ]
                        ]

                        opt [
                            copy part [
                                #"."
                                1 15 [
                                    digit | char
                                ]
                            ]
                            (port/spec/suffix: to file! part)
                        ]

                        opt [
                            ; reserved for future use
                            #"?" to end
                        ]
                        (port/spec/type: 'user)

                        |
                        "r3:"
                        ; internal version

                        copy part [
                            char
                            some [
                                some char | digit | #"-"
                            ]
                        ]
                        (port/spec/target: to word! part)

                        opt [
                            ; reserved for future use
                            #"?" to end
                        ]
                        (port/spec/type: 'system)
                    ][
                        sys/log/info 'MODULES [
                            "Invalid R3 Modules URL:^[[m" port/spec/ref
                        ]

                        do make error! rejoin [
                            "Invalid R3 Modules URL: " port/spec/ref
                        ]
                    ]
                ]

                ; minimal handling just for now
                ;
                switch port/spec/type [
                    user [
                        if not exists? port/data: to-real-file rejoin [
                            dirize system/options/data
                            %modules/
                            replace/all port/spec/target #":" #"/"
                            any [
                                port/spec/suffix
                                system/options/default-suffix
                            ]
                        ][
                            sys/log/info 'MODULES [
                                "Could not resolve R3 Modules URL:^[[m" port/spec/ref
                            ]

                            do make error! rejoin [
                                "Could not resolve R3 Modules URL: " port/spec/ref
                            ]
                        ]
                    ]

                    system [
                        either port/data: select system/modules to word! port/spec/target [
                            switch type-of port/data [
                                #(url!) [
                                    ; try to locate as an extension...

                                    if port/data: any [
                                        sys/locate-extension to word! port/spec/target

                                        all [
                                            url? port/data
                                            sys/download-extension to word! port/spec/target port/data
                                        ]
                                    ][
                                        sys/log/info 'MODULES [
                                            "Importing extension:^[[m" port/spec/ref
                                        ]
                                    ]
                                ]

                                #(module!) [
                                    port/data: to binary! rejoin [
                                        {Rebol } mold body-of spec-of port/data
                                    ]
                                    ; pretend to be an existing module,
                                    ; only a problem if OVERRIDE is used
                                ]

                                #(block!) [
                                    port/data: port/data/2
                                ]
                            ]
                        ][
                            port/data: rejoin [
                                dirize system/options/data
                                %modules/
                                port/spec/target
                                any [
                                    port/spec/suffix
                                    system/options/default-suffix
                                ]
                            ]
                        ]

                        if any [
                            none? port/data

                            all [
                                file? port/data
                                not exists? port/data
                            ]
                        ][
                            port/data: _

                            sys/log/info 'MODULES [
                                "Could not resolve R3 Modules URL:^[[m" port/spec/ref
                            ]

                            do make error! rejoin [
                                "Could not resolve R3 Modules URL: " port/spec/ref
                            ]
                        ]
                    ]
                ]
            ]

            actor: [
                read: func [
                    port
                ][
                    switch type-of port/data [
                        #(file!) [
                            read port/data
                        ]

                        #(binary!) [
                            port/data
                        ]
                    ]
                ]
            ]
        ]
    ]
]

; Couple of additions for SYSTEM/OPTIONS
;
if not in system/options 'process-id [
    use [out] [
        extend system/options 'process-id to integer! trim/tail also out: "" call/shell/output "echo $PPID" out

        ; assuming no process-id, no hostname
        ;
        extend system/options 'hostname any [
            attempt [
                read dns://
            ]

            trim/tail also out: "" call/output "hostname" out
        ]
    ]
]
