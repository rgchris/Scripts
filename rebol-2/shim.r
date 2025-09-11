Rebol [
    Title: "Shim for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 2-Sep-2025
    Version: 0.2.0
    File: %shim.r

    Purpose: "Adds some expressivity, functionality to Rebol 2"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    History: [
        1-Sep-2025 0.2.0
        "Added scheme to broker access to shared resources"

        2-Nov-2022 0.1.0
        "DO retooling, modules; assorted core functions"
    ]

    Comment: [
        {
        For greatest effect, this script should be invoked from REBOL.R.
        This permits use of the NEEDS header in the USER.R user
        configuration/preferences file allowing for module import.

        Note that Rebol 2 looks for REBOL.R either in the HOME folder or
        the current/script working directory.
        }

        * "Refines Rebol's boot response"
        * "Expands SYSTEM/OPTIONS"
        * "Patches DO to support NEEDS and IMPORT of modules"
        * "Has some polyfill functions for 2.7.6 -> 2.7.8 support"
        * "Includes common BITSET! patterns"
        * "Includes addtional mezzanines"
    ]
]

if all [
    none? system/options/script
    ; invoked without any script

    none? system/options/do-arg
    ; invoked without do/args

    system/ports/output/scheme == 'file
    ; not invoked from the terminal
][
    print rejoin [
        "Rebol/" system/product " v" system/version
    ]
    ; default action--print version

    quit
]

if native? :do [
    _: none

    ; aliases replacing '?' functions that do not return a LOGIC! value
    ;
    did: :found?
    context-of: :bound?
    info-of: :info?
    length-of: :length?
    modification-of: :modified?
    offset-of: :offset?
    size-of: :size?
    suffix-of: :suffix?
    type-of: :type?

    ; Polyfill functions 2.7.6 -> 2.7.8
    ;
    if unset? get/any 'assert [
        assert: func [
            [catch throw]
            {Assert that condition is true, else throw an assertion error.}

            conditions [block!]

            /type
            "Safely check datatypes of variables (words)"

            /local w
        ][
            throw-on-error [
                either type [
                    parse conditions [
                        any [
                            [
                                set w word!
                                |
                                set w skip
                                (cause-error 'script 'invalid-arg type-of get/any 'w)
                            ]
                            [
                                set type [block! | word!]
                                (
                                    unless find to-typeset t type-of get/any w [
                                        make error! join "datatype assertion failed for: " w
                                    ]
                                )
                                |
                                set t skip
                                (cause-error 'script 'invalid-arg type-of get/any 't)
                            ]
                        ]
                    ]
                ][
                    any [
                        all conditions
                        make error! join "assertion failed for: " mold conditions
                    ]
                ]
            ]
        ]

        words-of: any [
            attempt [:words-of]

            func [
                {Returns a copy of the words of a function or object.} 
                value
            ][
                case [
                    object? :value [
                        bind remove first :value :value
                    ]
                
                    any-function? :value [
                        first :value
                    ]

                    #else [
                        cause-error 'script 'cannot-use reduce [
                            'reflect type-of :value
                        ]
                    ]
                ]
            ]
        ]
    ]

    system/standard: make system/standard [
        ; used to create state for a script
        ;
        script-state: make object! [
            title:
            header:
            parent:
            path:
            args:
            words: _
        ]

        ; commonly used as a placeholder in custom schemes
        ;
        port-proxy: make object! [
            host:
            port-id:
            user:
            pass:
            type:
            bypass: _
        ]
    ]

    ; Retooling SYSTEM/OPTIONS
    ;
    system/options: make make object! [
        boot: _
        home: _

        if documents: any [
            get-env "HOME"
            get-env "USERPROFILE"
        ][
            documents: dirize clean-path to-rebol-file documents
        ]

        modules: system/script/path
        ; Modules live wherever this file lives

        script:
        path:

        args:
        do-arg: _

        call/shell/wait/output "echo $PPID" process-id: ""

        process-id: attempt [
            to integer! trim/tail process-id
        ]

        hostname: any [
            attempt [
                read dns://
            ]

            trim/tail also hostname: "" call/wait/output "hostname" hostname
        ]

        quiet:
        trace:
        help:
        boot-flags:
        boot-version:
        binary-base: _
        default-suffix: %.r
        cgi:
        browser-type:
        install:
        server:
        link-url: _
    ] system/options

    ; Home folder (not HOME, but where Rebol finds its data)
    ;
    case [
        get-env "REBOL_HOME" [
            case [
                exists? system/options/home: dirize to-rebol-file get-env "REBOL_HOME" [
                    system/options/home
                ]

                ; assuming that a data folder MUST exist
                ;
                not error? try [
                    make-dir/deep system/options/home
                ][
                    system/options/home
                ]

                #else [
                    make error! "Could not establish a data folder"
                    none
                ]
            ]
        ]

        either system/version/4 == 3 [
            all [
                get-env "APPDATA"
                system/options/home: join dirize to-rebol-file get-env "APPDATA" %Rebol/
            ]
        ][
            all [
                get-env "HOME"
                system/options/home: join dirize to-rebol-file get-env "HOME" %.rebol/
            ]
        ][
            case [
                exists? system/options/home [
                    system/options/home
                ]

                ; ; assuming that a data folder MUST exist
                ; ;
                ; not error? try [
                ;     make-dir system/options/home
                ; ][
                ;     system/options/home
                ; ]

                #else [
                    make error! "Could not establish a data folder"
                    none
                ]
            ]
        ]

        #else [
            make error! "Could not establish a HOME folder"
        ]
    ]

    ; Absolute Boot Path
    ; not fully secure, but an attempt to locate the absolute boot path
    ;
    if #"/" <> first system/options/boot [
        use [
            os-path path-char path boot-path
        ][
            if os-path: get-env "PATH" [
                path-char: complement charset ":"

                boot-path: _

                parse/all os-path [
                    some [
                        copy path some path-char
                        [#":" | end]
                        (
                            if exists? path: join dirize to-rebol-file path system/options/boot [
                                boot-path: any [
                                    boot-path
                                    path
                                ]
                            ]
                        )
                    ]
                ]

                if boot-path [
                    system/options/boot: boot-path
                ]
            ]
        ]
    ]

    ; DO patch to support module includes in the NEEDS header
    ;
    do: use [
        do-native here do-script
    ][
        do-native: :do

        ; here: system/script/path
        ; ; the location of this script determines how to find adjacent modules
        ; ; deprecated

        which: func [
            [throw]
            need [file! url!]
            /local resolved target
        ][
            resolved: []

            case [
                url? need [
                    need
                ]

                find resolved target: clean-path need [
                    target
                ]

                exists? target [
                    last append resolved target
                ]

                ; find resolved target: clean-path here/:need [
                ;     target
                ; ]
                ;
                ; exists? target [
                ;     last append resolved target
                ; ]
                ;
                ; relative path modules deprecated in favour of r2c:... scheme

                ; find resolved target: system/options/home/(%r3c)/:need [
                ;     target
                ; ]
                ;
                ; exists? target [
                ;     last append resolved target
                ; ]
                ;
                ; system folder modules deprecated in favour of r2c:... scheme
            ]
        ]

        import: func [
            [catch]
            needs [file! url! block!]
            /local imported need version target
        ][
            imported: []
            ; this block will transcend function calls

            parse compose [(needs)] [
                any [
                    set need word!
                    (
                        throw-on-error [
                            assert [
                                need: component? need
                            ]
                        ]
                    )

                    opt [
                        set version tuple!
                        (
                            if not all [
                                tuple? get/any in need/2 'version
                                need/2/version >= version
                            ][
                                throw make error! reduce [
                                    'script 'needs
                                    uppercase form need/1
                                    form version
                                ]
                            ]
                        )
                    ]
                    |
                    set need [file! | url!]
                    (
                        case [
                            none? target: which need [
                                throw make error! reduce [
                                    'script 'needs
                                    uppercase form need
                                ]
                            ]

                            find imported target []

                            <else> [
                                append imported target
                                ; do-script target version none
                                ; version depricated, 

                                do-script target _ _
                            ]
                        ]
                    )
                    |
                    skip
                ]
            ]
        ]

        do-script: func [
            "DO a stored script"
            target [file! url!]
            version [tuple! none!]
            args [any-type!]

            /local script location header result
        ][
            throw-on-error [
                if file? target [
                    if not exists? target: clean-path target [
                        make error! reduce [
                            'access 'cannot-open form target
                        ]
                    ]
                ]

                script: load/all/header target
                ; LOAD/HEADER observes the traditional Rebol NEEDS
                ; rule, no workaround save replacing LOAD

                header: take script

                assert [
                    find [none! word!] type-of/word get/any in header 'type
                ]

                if version [
                    if not all [
                        tuple? get/any in header 'version
                        header/version >= version
                    ][
                        make error! reduce [
                            'script 'needs
                            mold second target
                            form version
                        ]
                    ]
                ]
            ]

            parent: system/script

            system/script: make system/standard/script-state []

            set/any in system/script 'title get/any in header 'title
            set/any in system/script 'args get/any 'args

            system/script/header: header
            system/script/parent: parent

            system/script/path: either all [
                url? target
                find/match form target "r2c:"
            ][
                system/script/parent/path
            ][
                first split-path target
            ]

            if not none? header/needs reduce [
                'import header/needs
            ]

            set/any 'result try [
                do-native script
            ]

            system/script: system/script/parent

            get/any 'result
        ]

        change at second :apply 28 :do-native
        change at second :collect 4 :do-native
        ; functions that use DO in a way that can't be replicated in a usermode function

        if component? 'view [
            change second :do-face :do-native
            change second :do-face-alt :do-native
            change at fourth second pick pick pick second get in svv 'grow-facets 23 7 26 4 :do-native
            change at pick pick second pick pick pick second get in svv 'grow-facets 23 7 26 10 7 4 :do-native
        ]

        do: func [
            [catch]

            "Evaluates a block, file, URL, function, word, or any other value."

            value
            "Normally a file name, URL, or block"

            /args
            "If value is a script, this will set its system/script/args"

            arg
            "Args passed to a script. Normally a string."

            /next
            "Do next expression only. Return block with result and new position."
        ][
            switch/default type-of/word get/any 'value [
                error! [
                    :value
                ]

                action! function! native! op! [
                    throw make error! [
                        script invalid-arg "DO FUNCTION! disabled, use APPLY"
                    ]
                ]

                file! url! [
                    if next [
                        throw make error! [
                            script invalid-arg "Cannot DO/NEXT on a FILE! or URL!"
                        ]
                    ]

                    do-script value none get/any 'arg
                ]
            ][
                apply :do-native [
                    :value :args :arg :next
                ]
            ]
        ]
    ]

    ; Common bitset patterns
    ;
    digit: charset [
        #"0" - #"9"
    ]

    hex-digit: charset [
        #"0" - #"9"
        #"A" - #"F"
        #"a" - #"f"
    ]

    alpha: charset [
        #"A" - #"Z"
        #"a" - #"z"
    ]

    upper-alpha: charset [
        #"A" - #"Z"
    ]

    lower-alpha: charset [
        #"a" - #"z"
    ]

    ; Additional Mezzanines
    ;
    neaten: func [
        "Updates NEW-LINE markers on a given block"

        block [block!]
        "Block value to neaten"

        /pairs
        "Neatens every second value"

        /triplets
        "Neatens every third value"

        /flat
        "Removes all NEW-LINE markers"

        /pipes
        "Neatens around every pipe '| word"

        /words
        "Neatens before every WORD!"

        /set-words
        "Neatens before SET-WORD!/SET-PATH! values"

        /first
        "Neatens only at the head of a block"

        /by
        "Neatens every LENGTH value"

        length

        /force
        "Removes any prior NEW-LINE markers"
    ][
        case [
            words [
                if force [
                    new-line/all block false
                ]

                parse/all block [
                    any [
                        ['on | 'off | 'yes | 'no | 'true | 'false | 'none | '_]
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

                parse/all block [
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

                parse/all block [
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

            #else [
                ; need this HEAD-REMOVE-BACK-TAIL-APPEND hack to fix the tail--NEW-LINE bug
                ;
                head remove back tail new-line/all/skip append block _ not flat case [
                    pairs [2]
                    triplets [3]
                    by [length]
                    <else> [1]
                ]
            ]
        ]
    ]

    protect 'neaten
    ; temporary, to see where else this is defined

    add-protocol: func [
        'name
        id
        handler
        /with
        block
    ][
        if not in system/schemes name [
            system/schemes: make system/schemes compose [
                (to set-word! name) (_)
            ]
        ]

        set in system/schemes name make system/standard/port compose [
            scheme: name
            port-id: (id)
            handler: (handler)
            passive: _
            cache-size: 5
            proxy: make system/standard/port-proxy []

            (block)
        ]
    ]

    ; wrapper for USE using top-level set-word collection to discern locals
    ;
    wrap: func [
        body [block!]
    ][
        use collect [
            parse body [
                any [
                    to set-word!
                    body:
                    skip
                    (keep to word! body/1)
                ]
            ]
        ] head body
    ]

    ; wrapper for BIND allowing the context to appear first
    ;
    with: func [
        object [any-word! object! port!]
        block [any-block!]
        /only
    ][
        block: bind block object
        either only [block][do block]
    ]

    ; Rebol 3/Red-style PUT function
    ;
    put: func [
        "Sets a value following a key (replaces value if key exists)"

        series [block! hash! port! object!]
        key [any-string! word! integer! decimal! date! time! tuple!]
        value
        /case

        /local mark
    ][
        system/words/case [
            any-block? series [
                mark: any [
                    either case [
                        find/tail/skip/case series key 2
                    ][
                        find/tail/skip series key 2
                    ]

                    insert tail series key
                ]

                change/part/only mark value 1
            ]

            object? series [
                assert [
                    word? key
                    in series key
                ]

                set in series key value
            ]

            port? series [
                assert [
                    in port/actors 'put
                ]

                port/actors/put port key value
            ]
        ]

        value
    ]

    ; not a perfect shim for Ren-C's ELIDE--returns UNSET! in the case of (ELIDE VALUE)
    ;
    elide: func [
        "First argument is evaluative, but discarded"
        discarded [any-type!]
        value [any-type! unset!]
    ][
        get/any 'value
    ]

    ; version of PARSE that returns current position 
    ;
    parse-to: func [
        "Progress-returning version of Parse (/ALL implied)"
        input [series!]
        rules [block!]
        /case
        /local mark
    ][
        if apply :parse [
            :input [rules mark: to end] #[true] :case
        ][
            :mark
        ]
    ]

    ; enhanced version of CHARSET, allows for numeric characters
    ;
    charset: func [
        "Makes a bitset of chars for the parse function."

        chars [binary! string! block!]
    ][
        make bitset! switch type-of/word chars [
            string! [
                chars
            ]

            binary! [
                as-string chars
            ]

            block! [
                ; map-each bug on empty blocks
                ;
                either empty? chars [
                    chars
                ][
                    map-each value chars [
                        either integer? value [to char! value] [value]
                    ]
                ]
            ]
        ]
    ]

    ; combination of COLLECT and WHILE
    ;
    collect-while: func [
        {
        While a condition block is TRUE, evaluates another block storing values via
        KEEP function, and returns block of collected values.
        }
        condition [block!]
        body [block!]
    ][
        collect reduce [
            :while :condition :body
        ]
    ]

    ; combination of COLLECT and FOREACH
    ;
    collect-each: func [
        {
        Evaluates a block for each value(s), storing values via KEEP function,
        and returns block of collected values.
        }

        'word [get-word! word! block!]
        "Word or block of words to set each time (will be local)"

        data [series!]
        "The series to traverse"

        body [block!]
        "Block to evaluate each time"
    ][
        collect reduce [
            :foreach :word 'data body
        ]
    ]

    fold: func [
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

    private: func [
        "Binds a given block to a private context"

        context [block! object!]
        body [block!]
    ][
        bind body either block? context [
            make object! context
        ][
            context
        ]
    ]

    flatten: func [
        "Flatten a nested block structure"

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

    throw-from: func [
        "Evaluates a block, which if it results in an error, throws that error"

        [throw]
        name [word!]
        body [block!]
    ][
        throw-on-error [
            catch/name body name
        ]
    ]

    ; Experimental method for handling a multi-return item
    ;
    progression-of: func [
        'target [set-word!]
        result [block! error!]
    ][
        either error? :result [
            error? set/any to word! target :result
            _
        ][
            set/any to word! target first result
            second result
        ]
    ]

    ; R2C Scheme used to access system folder resources
    ;
    if not in system/schemes 'r2c [
        context [
            ; module management to follow here
            ;
            char: complement charset [
                0 - 43
                45 - 64
                91 - 96
                123 - 127
            ]
            ; captures alpha + utf-8

            prototype: make object! [
                title:
                scheme:
                ref:
                target:
                file:
                suffix:
                version:
                options:
                is-minimum: _
            ]

            add-protocol r2c 0 context [
                port-flags: system/standard/port-flags/pass-thru

                init: func [
                    [catch]

                    port url
                ][
                    port/state/custom: #initialized

                    case [
                        not url? url [
                            throw make error!
                            "R2C Modules: BLOCK! usage reserved."
                        ]

                        not parse/all/case url with/only port/locals: make prototype [
                            ref: url
                        ][
                            "r2c:"

                            copy target [
                                char
                                some [
                                    some char | digit | #"-"
                                ]

                                any [
                                    #":"
                                    char
                                    some [
                                        some char | digit | #"-"
                                    ]
                                ]
                            ]

                            opt [
                                #"@"
                                copy version [
                                    some digit
                                    0 3 [
                                        #"."
                                        some digit
                                    ]
                                    opt ".x"
                                ]
                                opt [
                                    #"+"
                                    (is-minimum: yes)
                                ]
                            ]

                            opt [
                                copy suffix [
                                    #"."
                                    1 15 [
                                        digit | char
                                    ]
                                ]
                                (suffix: to file! suffix)
                            ]

                            opt [
                                ; reserved for future use
                                #"?" to end
                            ]
                        ][
                            throw make error!
                            join "Invalid R2C URL: " port/locals/ref
                        ]
                    ]

                    either exists? port/target: rejoin [
                        system/options/modules
                        replace/all port/locals/target #":" #"/"
                        any [
                            port/locals/suffix
                            system/options/default-suffix
                        ]
                    ][
                        port/sub-port: make port! port/target

                        port/state/custom: #closed
                        ; initialization complete
                    ][
                        throw make error!
                        join "Could not resolve R2C Modules URL: " port/locals/ref
                    ]
                ]

                open: func [
                    port
                ][
                    with port [
                        assert [
                            #closed == state/custom
                        ]

                        if not zero? -524386 and state/flags [
                            make error! join "Limited access only to system files: " locals/ref
                        ]

                        system/words/open/mode sub-port collect-each [name flag] [
                            read 1
                            binary 32
                            lines 64
                            direct 524288
                        ][
                            if state/flags and flag == flag [
                                keep name
                            ]
                        ]

                        state/tail: sub-port/state/tail
                        state/index: sub-port/state/index
                        state/custom: #opened

                        state/flags: state/flags or port-flags
                        ; Rebol 2 requirement
                    ]
                ]

                copy: func [
                    port
                ][
                    either #opened == port/state/custom [
                        port/user-data: system/words/copy skip port/sub-port port/state/index
                    ][
                        make error! "Can't COPY on a closed port"
                    ]
                ]

                close: func [
                    port
                ][
                    either #opened == port/state/custom [
                        system/words/close port/sub-port
                        port/state/custom: #closed
                    ][
                        make error! Cannot CLOSE an opened port
                    ]

                    port
                ]

                query: func [
                    port
                ][
                    system/words/query port/sub-port
                    port/size: port/sub-port/size
                    port/date: port/sub-port/date
                    port/status: port/sub-port/status
                ]
            ]
        ]
    ]

    append system/components reduce [
        'shim system/script/header none
    ]
]
