Rebol [
    Title: "Document Object Model"
    Author: "Christopher Ross-Gill"
    Date: 20-Aug-2025
    Version: 0.1.0
    File: %dom.reb

    Purpose: "DOM and support functions"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.dom
    Exports: [
        dom
    ]

    Needs: [
        r3:rgchris:collect-deep
    ]
]

dom: context [
    new: does [
        copy #[
            type document
            name _
            public _
            system _
            form _
            head _
            body _
            parent _
            first _
            last _
            warnings _
        ]
    ]

    make-node: does [
        copy #[
            type _
            name _
            value _
            parent _
            back _
            next _
            first _
            last _
        ]
    ]

    for-display: func [
        node [map!]
    ][
        intersect node either 'document = node/type [
            #[type _ name _ public _ system _]
        ][
            #[type _ name _ value _]
        ]
    ]

    insert-before: func [
        item [map!]
        /local node
    ][
        node: make-node

        node/parent: item/parent
        node/back: item/back
        node/next: item

        either none? item/back [
            item/parent/first: node
        ][
            item/back/next: node
        ]

        item/back: node
    ]

    insert-after: func [
        item [map!]
        /local node
    ][
        node: make-node

        node/parent: item/parent
        node/back: item
        node/next: item/next

        either none? item/next [
            item/parent/last: node
        ][
            item/next/back: node
        ]

        item/next: node
    ]

    insert: func [
        list [map!]
    ][
        either list/first [
            insert-before list/first
        ][
            also
            list/first:
            list/last: make-node
            list/first/parent: list
        ]
    ]

    append: func [
        list [map!]
    ][
        either list/last [
            insert-after list/last
        ][
            insert list
        ]
    ]

    append-existing: func [
        list [map!]
        node [map!]
    ][
        node/parent: list
        node/next: _

        either none? list/last [
            node/back: _
            list/first: list/last: node
        ][
            node/back: list/last
            node/back/next: node
            list/last: node
        ]
    ]

    remove: func [
        item [map!]
        /back
        /next
    ][
        if not item/parent [
            do make error! "Node does not exist in tree"
        ]

        either item/back [
            item/back/next: item/next
        ][
            item/parent/first: item/next
        ]

        either item/next [
            item/next/back: item/back
        ][
            item/parent/last: item/back
        ]

        item/parent:
        item/back:
        item/next: _
        ; node becomes freestanding

        case [
            back [
                item/back
            ]

            next [
                item/next
            ]

            <else> [
                item
            ]
        ]
    ]

    clear: func [
        list [map!]
    ][
        while [
            list/first
        ][
            remove list/first
        ]
    ]

    clear-from: func [
        item [map!]
    ][
        also item/back
        until [
            not item: remove item
        ]
    ]

    walker-prototype: [
        node:
        event:
        root: _
        state: 'initial

        next: func [] [
            event: switch/default state [
                opened [
                    either node/first [
                        node: node/first

                        ; probe for-display node

                        either node/first [
                            'open
                        ][
                            state: 'closed

                            either 'element = node/type [
                                'empty
                            ][
                                node/type
                            ]
                        ]
                    ][
                        state: 'closed
                        'close
                    ]
                ]

                closed [
                    case [
                        same? node root [
                            state: 'done
                            _
                        ]

                        node/next [
                            node: node/next

                            either node/first [
                                state: 'opened
                                'open
                            ][
                                either 'element = node/type [
                                    'empty
                                ][
                                    node/type
                                ]
                            ]
                        ]

                        node/parent [
                            node: node/parent
                            'close
                        ]

                        <else> [
                            print "Walker encountered parent-less node—probably shouldn't happen"
                            state: 'done
                            _
                        ]
                    ]
                ]

                initial [
                    state: 'opened
                    'open
                ]

                done [
                    do make error! "Walker already completed"
                ]
            ][
                do make error! "Walker should not get here"
            ]
        ]
    ]

    walk: func [
        node [block! map!]
        /local walker
    ][
        walker: make object! walker-prototype

        walker/node:
        walker/root: node

        walker
    ]

    to-block: function [
        node [map! block!]
        /local walker
    ][
        walker: walk node

        neaten/pairs collect-deep [
            while [
                walker/next
            ][
                switch/default walker/event [
                    open [
                        switch walker/node/type [
                            ; type parent first last name public system form head body

                            document []

                            element [
                                keep to tag! form walker/node/name

                                push

                                if walker/node/value [
                                    keep %.attrs
                                    keep walker/node/value
                                ]
                            ]
                        ]
                    ]

                    close [
                        if 'element = walker/node/type [
                            neaten/pairs pop
                        ]
                    ]

                    empty [
                        keep to tag! walker/node/name

                        either walker/node/value [
                            push
                            keep %.attrs
                            keep walker/node/value
                            neaten/pairs pop
                        ][
                            keep _
                        ]
                    ]

                    text [
                        keep %.txt
                        keep walker/node/value
                    ]

                    comment [
                        keep to tag! rejoin ["!--" walker/node/value "--"]
                        keep _
                    ]
                ][
                    probe to tag! form walker/event
                ]
            ]
        ]
    ]
]
