Rebol [
    Title: "Iterators for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 7-May-2025
    Version: 0.1.0
    File: %iterate.r

    Purpose: "Institute some iterator methods"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.iterator
    Exports: [
        iterators
    ]
]

iterators: context [
    _: none

    new: func [
        model [object!]
        value
    ][
        model/new value
    ]

    next: func [
        iterator [block! object!]
    ][
        iterator/next iterator
    ]

    close: func [
        iterator [block! object!]
    ][
        iterator/close iterator
    ]

    dom: context [
        ; uses output from PARSE-XML as a 'dom'
        prototype: [
            'next :next
            'close :close
            'node _
            'kids _
            'path _
            'event _
        ]

        new: func [
            node [block!]
            /local new
        ][
            new: reduce prototype

            new/node: node
            new/path: make block! 16
            new/kids: make block! 16

            new
        ]

        next: func [
            walker [block!]
        ][
            walker/event: case [
                none? walker/kids [
                    _
                ]

                ; initial state
                ;
                empty? walker/kids [
                    insert/only walker/path walker/node

                    insert/only walker/kids any [
                        walker/node/3 []
                    ]

                    'open
                ]

                tail? walker/kids/1 [
                    remove walker/kids

                    walker/node: take walker/path

                    ; all nodes processed
                    ;
                    if empty? walker/kids [
                        walker/kids: _
                    ]

                    'close
                ]

                (
                    walker/kids/1: skip walker/kids/1 1
                    string? walker/node: first back walker/kids/1
                ) [
                    'text
                ]

                block? walker/node/3 [
                    insert/only walker/path walker/node
                    insert/only walker/kids walker/node/3

                    'open
                ]

                <else> [
                    'empty
                ]
            ]
        ]

        close: func [
            walker [block!]
        ][
            walker/kids/1: tail walker/kids/1
        ]

        text-of: func [
            walker [block!]
        ][
            head collect/into [
                while [
                    next walker
                ][
                    if walker/event == 'text [
                        keep walker/node
                    ]
                ]
            ] make string! 128
        ]

        path-of: func [
            walker [block!]
        ][
            walker/path: tail walker/path

            collect [
                while [
                    not head? walker/path
                ][
                    walker/path: back walker/path
                    keep walker/path/1/1
                ]

                if not find/only/match walker/path walker/node [
                    keep walker/node/1
                ]
            ]
        ]
    ]

    string: context [
        ; return string chunks of a fixed size from a stream of strings
        ;
        prototype: [
            'next :next
            'chunk-size _
            'chunk _
            'buffer _
        ]

        new: func [
            value [block!]
            /local new
        ][
            assert [
                parse value [
                    integer! some string!
                ]
            ]
 
            new: reduce prototype

            new/buffer: reduce value
            new/chunk-size: take new/buffer

            new
        ]

        next: func [
            value [block!]
            /local continue? need chunk
        ][
            continue?: yes
            need: value/chunk-size
            value/chunk: _

            while [continue?] [
                case [
                    tail? value/buffer [
                        continue?: no
                    ]

                    empty? value/buffer/1 [
                        value/buffer: skip value/buffer 1
                    ]

                    <else> [
                        any [
                            value/chunk
                            value/chunk: make string! need
                        ]

                        either need <= length? value/buffer/1 [
                            insert/part tail value/chunk value/buffer/1 value/buffer/1: skip value/buffer/1 need

                            continue?: no
                        ][
                            insert tail value/chunk value/buffer/1

                            need: need - length? value/buffer/1
                            value/buffer: skip value/buffer 1
                        ]
                    ]
                ]
            ]

            value/chunk
        ]
    ]

    values: context [
        prototype: [
            'next :next
            'close :close
            'name _
            'value _
            'type _
            'parents _
            'path _
            'event 'init
        ]

        new: func [
            value [any-type!]
            /local new
        ][
            new: reduce prototype

            new/parents: reduce [
                _ reduce [
                    get/any 'value
                ]
            ]

            new
        ]

        next: func [
            walker [block!]
        ][
            walker/value: _
            walker/name: _

            walker/event: either empty? walker/parents [
                _
            ][
                if not any [
                    tail? walker/parents/2
                    walker/event == 'init
                    walker/event == 'open
                ][
                    walker/parents/2: skip walker/parents/2 1
                ]

                either tail? walker/parents/2 [
                    walker/value: take walker/parents
                    remove walker/parents

                    either empty? walker/parents [
                        walker/value: _
                    ][
                        walker/type: type?/word walker/value

                        'close
                    ]
                ][
                    walker/value: first walker/parents/2

                    if object? walker/parents/1 [
                        walker/name: walker/value
                        walker/value: select walker/parents/1 walker/name
                    ]

                    switch/default walker/type: type?/word walker/value [
                        block!
                        paren!
                        hash! [
                            insert walker/parents reduce [
                                walker/value walker/value
                                ; original value, working value
                            ]

                            'open
                        ]

                        object! [
                            insert walker/parents reduce [
                                walker/value words-of walker/value
                                ; original value, working value
                            ]

                            'open
                        ]
                    ][
                        walker/type
                    ]
                ]
            ]
        ]
    ]

    folders: context [
        prototype: [
            'next :next
            'close :close
            'file _
            'path _
            'full _
            'root _
            'folder _
            'parents _
            'disposition _
            'event 'initial
        ]

        new: func [
            folder [file!]
            /local walker splits
        ][
            walker: reduce prototype

            walker/full: clean-path folder

            splits: split-path walker/full

            walker/root: first splits
            walker/path:
            walker/file: second splits

            assert [
                dir? walker/full
                exists? walker/full
            ]

            walker/parents: reduce [
                reduce [walker/full]
            ]

            walker
        ]

        next: func [
            walker [block!]
            /local splits
        ][
            walker/disposition: _

            case [
                empty? walker/parents _

                tail? walker/parents/1 [
                    remove walker/parents

                    either empty? walker/parents [
                        walker/full:
                        walker/path:
                        walker/file:

                        walker/event: _
                    ][
                        walker/full: walker/parents/1/1
                        walker/path: find/match walker/full walker/root
                        walker/file: second split-path walker/full

                        remove walker/parents/1

                        walker/event: 'close
                    ]
                ]

                dir? walker/parents/1/1 [
                    walker/full: walker/parents/1/1
                    walker/path: find/match walker/full walker/root
                    walker/file: second split-path walker/full

                    either error? walker/disposition: try [
                        read walker/full
                    ][
                        remove walker/parents/1

                        walker/event: 'error
                    ][
                        insert/only walker/parents map-each file walker/disposition [
                            walker/full/:file
                        ]

                        walker/event: 'open
                    ]
                ]

                <else> [
                    walker/full: walker/parents/1/1
                    walker/path: find/match walker/full walker/root
                    walker/file: second split-path walker/full

                    remove walker/parents/1

                    walker/event: 'file
                ]
            ]
        ]

        close: func [
            walker [block! object! map!]
        ][
            walker/parents/1: clear walker/parents/1

            walker
        ]
    ]

    grids: context [
        prototype: make object! [
            next: _

            page: 612x792
            margins: 26x26
            gutter: 12x12

            columns: 6
            rows: 5

            index:
            offset:
            remaining:

            top-left:
            middle:
            bottom-right:

            width:
            height: _
        ]

        new: func [
            spec [block!]
            /local grid unsupported value
        ][
            unsupported: []

            grid: make prototype [
                parse reduce spec [
                    any [
                        /page
                        set page pair!
                        |
                        /margins
                        set margins pair!
                        |
                        /columns
                        set columns integer!
                        (columns: max columns 1)
                        |
                        /rows
                        set rows integer!
                        (rows: max rows 1)
                        |
                        /gutter
                        set gutter pair!
                        |
                        set value skip
                        (append unsupported value)
                    ]
                ]

                width: page/x - margins/x - margins/x + gutter/x / columns - gutter/x
                height: page/y - margins/y - margins/y + gutter/y / rows - gutter/y

                remaining: columns * rows
            ]

            if not empty? unsupported [
                insert unsupported "Unsupported Settings:"
                print unsupported
            ]

            grid/next: :next

            grid
        ]

        next: func [
            grid [object!]
        ][
            case [
                none? grid/offset [
                    grid/index: 1
                    grid/offset: 1x1
                    grid/remaining: grid/remaining - 1

                    grid/top-left: grid/margins
                    grid/middle: grid/top-left + as-pair grid/width / 2 grid/height / 2
                    grid/bottom-right: grid/top-left + as-pair grid/width grid/height

                    grid
                ]

                grid/offset/x = grid/columns [
                    either grid/offset/y = grid/rows [
                        ; end of page
                        ;
                        grid/offset:
                        grid/remaining:

                        grid/top-left:
                        grid/middle:
                        grid/bottom-right: _

                        _
                    ][
                        grid/index: grid/index + 1
                        grid/offset/x: 1
                        grid/offset/y: grid/offset/y + 1
                        grid/remaining: grid/remaining - 1

                        grid/top-left: as-pair grid/margins/x grid/top-left/y + grid/height + grid/gutter/y
                        grid/middle: grid/top-left + as-pair grid/width / 2 grid/height / 2
                        grid/bottom-right: grid/top-left + as-pair grid/width grid/height

                        grid
                    ]
                ]

                #else [
                    grid/index: grid/index + 1
                    grid/offset/x: grid/offset/x + 1
                    grid/remaining: grid/remaining - 1

                    grid/top-left/x: grid/top-left/x + grid/width + grid/gutter/x
                    grid/middle/x: grid/width / 2 + grid/top-left/x
                    grid/bottom-right/x: grid/bottom-right/x + grid/width + grid/gutter/x

                    grid
                ]
            ]
        ]
    ]
]

