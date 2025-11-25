Rebol [
    Title: "Zip/Unzip for Rebol"
    Author: "Christopher Ross-Gill"
    Date: 1-May-2025
    Version: 0.3.0
    File: %zip.reb

    Purpose: "Tools to extract-from/create ZIP archives"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.zip
    Exports: [
        zip
    ]

    Needs: [
        r3:rgchris:bincode
        r3:rgchris:deflate
    ]

    History: [
        1-May-2025 0.3.0
        "ADD-ENTRY function; copy entries from old to new archives"

        8-Feb-2022 0.2.0
        "More atomic, versatile toolset"

        3-Jan-2022 0.1.0
        "Reworked UNZIP functions to be more atomic"
    ]

    Comment: [
        {
        A different approach to handling Zip files. This script allows
        fine-tuned access to Zip content. Motivations for this version
        include providing access to individual files without full
        extraction, and providing a more expressive approach to
        creating archives.
        }

        https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
        ".ZIP File Format Specification"

        https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html
        "Breakdown of the ZIP format"

        http://www.rebol.org/view-script.r?script=rebzip.r
        "RebZIP v1.0.1, wraps around the PNG deflate decoder(!)"

        https://www.bamsoftware.com/hacks/zipbomb/
        "Building a better Zip Bomb"

        https://unix.stackexchange.com/a/14727
        "Unix external file attributes"
    ]
]

zip: make object! [
    entry-marker: #{504b0102}  ; "PK^A^B"
    local-marker: #{504b0304}  ; "PK^C^D"
    index-marker: #{504b0506}  ; "PK^E^F"

    prototype: make object! [
        type: 'zip-index
        count:
        size:
        offset:
        entry:
        comment:
        is-strict:
        pool:
        entries: _
    ]

    ; filename validation needs a bit of work -- the following should
    ; be adequate to catch malicious entries but users of this script
    ; should be wary of using filenames verbatim
    ;
    as-filename: use [
        valid-filename
    ][
        valid-filename: complement charset [
            0 - 31 #"/" #"\" 127
        ]

        func [
            value [binary!]
        ][
            switch type-of/word value [
                binary! [
                    value: to string! value
                ]

                string! []
            ][
                value: to string! value
            ]

            either all [
                parse value [
                    some [
                        some valid-filename opt #"/"
                    ]
                ]

                not find value ".."
            ][
                to file! value
            ][
                do make error! rejoin [
                    "Invalid Filename: " mold value
                ]
            ]
        ]
    ]

    as-integer: func [
        value [binary!]
    ][
        to integer! reverse value
    ]

    checksum-of: func [
        value [string! binary!]
    ][
        reverse crc32/checksum-of either binary? value [
            value
        ][
            to binary! value
        ]
    ]

    date: context [
        encode: func [
            "Encoded a date as an Int32 value (MS-DOS format)"
            value [date!]
        ][
            (shift value/year - 1980 25)
            or (shift value/month 21)
            or (shift value/day 16)
            ; date

            or (shift value/time/hour 11)
            or (shift value/time/minute 5)
            or (shift to integer! value/time/second -1)
            ; time
        ]

        ; an earlier version of this function was more permissive, however
        ; in retrospect--an invalid date is likely indicator of malicious
        ; archives, thus is rejected
        ;
        decode: func [
            "Create a date from an Int32 value (MS-DOS format)"
            date [integer!]
            /local value day hour
        ][
            day: 31 and shift date -16
            hour: 31 and shift date -11

            assert [
                ; Leaning on Rebol to validate dates, reject if invalid
                ;
                value: make date! reduce [
                    1980 + shift date -25
                    15 and shift date -21
                    day

                    make time! reduce [
                        hour
                        63 and shift date -5
                        62 and shift date 1
                    ]
                ]

                ; Checking for overflow from invalid values
                ;
                day == value/day
                hour == value/time/hour
            ]

            value
        ]
    ]

    permissions: context [
        encode: func [
            entry [object!]
            /local attributes
        ][
            attributes: 420
            ; default (octet) => 0644 => rw-r--r--

            either entry/is-folder [
                attributes: attributes or 16384 or 73
                ; +x (octet) => 0111 => 73
            ][
                attributes: attributes or 32768
            ]

            if entry/is-executable [
                attributes: attributes or 64
                ; u+x (octet) => 0100 => 64
            ]

            attributes
        ]
    ]

    ; Need to check that this works with PAIR/FLOAT
    ;
    has-valid-space?: func [
        "Check an entry's existence in a unique content range within an archive"
        archive [object!]
        entry [object!]

        /local location pool
    ][
        assert [
            parse archive/pool [
                some pair!
            ]
        ]

        pool: archive/pool
        location: as-pair entry/offset entry/offset + entry/size

        until [
            case [
                tail? pool [
                    ; exhausted the remaining free space
                    ;
                    entry/has-valid-range: no
                    true
                ]

                location/1 < pool/1/1 [
                    pool: next pool
                    false
                ]

                location/1 > pool/1/2 [
                    pool: next pool
                    false
                ]

                location/1 = pool/1/1 [
                    case [
                        location/2 < pool/1/2 [
                            change pool as-pair location/2 pool/1/2
                            entry/has-valid-range: yes
                        ]

                        location/2 = pool/1/2 [
                            remove pool
                            entry/has-valid-range: yes
                        ]

                        location/2 > pool/1/2 [
                            ; overlaps the beginning of a prior entry
                            ;
                            entry/has-valid-range: no
                            true
                        ]
                    ]
                ]

                location/1 > pool/1/1 [
                    case [
                        location/2 < pool/1/2 [
                            change/part pool reduce [
                                as-pair pool/1/1 location/1 - 1
                                as-pair location/2 pool/1/2
                            ] 1

                            entry/has-valid-range: yes
                        ]

                        location/2 = pool/1/2 [
                            change pool as-pair pool/1/1 location/1 - 1
                            entry/has-valid-range: yes
                        ]

                        <else> [
                            ; overlaps the beginning of a prior entry
                            ;
                            entry/has-valid-range: no
                            true
                        ]
                    ]
                ]

                <else> [
                    do make error! "Shouldn't get here..."
                ]
            ]
        ]

        entry/has-valid-range
    ]

    open: func [
        "Create an iterable representation of a ZIP archive"

        archive [binary!]
        "Binary representation of a ZIP archive"

        /strict
        "Conform within stricter sanity limits"

        /local mark comment-length
    ][
        case [
            not mark: find/last archive index-marker [
                do make error! "Not a ZIP file"
            ]

            ; sanity check: room for core footer
            ;
            22 > length-of mark [
                do make error! "ZIP index truncated/corrupted"
            ]

            not consume mark [
                archive: make prototype []

                archive/is-strict: did strict

                all [
                    consume index-marker
                    advance 6 
                    ; three entries related to a multi-file ZIP archive

                    archive/count: unsigned-16/le
                    archive/size: unsigned-32/le
                    archive/offset: unsigned-32/le
                    comment-length: unsigned-16/le
                ]
            ][
                do make error! "ZIP index corrupt/invalid"
            ]

            ; sanity check: sizes/offsets match up
            ;
            all [
                archive/is-strict
                not-equal? archive/offset + archive/size + 23 index? mark
                not tail? skip mark comment-length
            ][
                do make error! "ZIP index (sizes/offsets) sanity check failure"
            ]

            <else> [
                archive/comment: consume mark comment-length
                archive/entries: skip head mark archive/offset

                archive/pool: reduce [
                    as-pair 0 archive/offset
                ]

                archive
            ]
        ]
    ]

    step: func [
        "Retrieve the next available entry from a ZIP directory"

        archive [object!]
        "Iterable archive object (primarily created by ZIP/OPEN)"

        /local
        mark entry origin lengths attributes
        ln-fn ln-ex ln-cmt at-int at-oth at-fs val
    ][
        case [
            zero? archive/count [
                archive/entry: none
            ]

            not binary? mark: archive/entries [
                do make error! "Invalid ZIP archive object"
            ]

            not all [
                entry: make entries/prototype []

                ; values consumed in order per ZIP specification
                ;
                consume mark [
                    consume entry-marker

                    entry/version: unsigned-8
                    origin: unsigned-8
                    entry/needs: unsigned-16/le
                
                    advance 2
                    ; flags ignored
                
                    entry/method: unsigned-16/le
                    entry/date: date/decode signed-32/le

                    entry/checksum: consume 4
                    entry/compressed: unsigned-32/le
                    entry/uncompressed: unsigned-32/le

                    lengths: reduce [
                        'filename unsigned-16/le
                        'extra unsigned-16/le
                        'comment unsigned-16/le
                    ]

                    advance 2
                    ; multi-file ZIP feature unsupported

                    attributes: reduce [
                        'internal unsigned-16/le
                        'other unsigned-16/le
                        'filesystem unsigned-16/le
                    ]

                    entry/offset: unsigned-32/le

                    entry/filename: as-filename consume lengths/filename
                    entry/extra: consume lengths/extra
                    entry/comment: consume lengths/comment
                ]

                entry/size: 30  ; entry header length
                + entry/compressed
                + lengths/filename
                + lengths/extra
                + lengths/comment

                ; ; check for potential overlapping entries (slow)
                ; ;
                ; has-valid-space? archive entry
            ][
                do make error! "Invalid ZIP directory entry"
            ]

            <else> [
                archive/entries: mark
                archive/count: archive/count - 1
                entry/start: skip head archive/entries entry/offset

                entry/is-text: 1 and attributes/internal == 1

                if origin == 3 [
                    ; Unix file attributes
                    ;
                    entry/is-folder: 16384 and attributes/filesystem == 16384
                    entry/is-executable: 64 and attributes/filesystem == 64
                ]

                archive/entry: entry
            ]
        ]
    ]

    quick-step: func [
        "Retrieve the next available entry from a ZIP directory"

        archive [object!]
        "Iterable archive object (primarily created by ZIP/OPEN)"

        /local
        mark entry origin lengths attributes part
    ][
        case [
            zero? archive/count [
                none
            ]

            not binary? mark: archive/entries [
                do make error! "Invalid ZIP archive object"
            ]

            not parse/case mark [
                (
                    entry: make entries/prototype []

                    lengths: reduce [
                        'filename _
                        'extra _
                        'comment _
                    ]

                    attributes: reduce [
                        'internal _
                        'other _
                        'filesystem _
                    ]
                )

                entry-marker

                6 skip
                ; version: unsigned-8
                ; origin: unsigned-8
                ; needs: unsigned-16
                ; flags unsigned-16

                copy part 2 skip
                (entry/method: as-integer part)

                copy part 4 skip
                (entry/date: date/decode to integer! reverse part)

                copy part 4 skip
                (entry/checksum: part)

                copy part 4 skip
                (entry/compressed: unsigned-32/decode reverse part)

                copy part 4 skip
                (entry/uncompressed: unsigned-32/decode reverse part)

                copy part 2 skip
                (lengths/filename: as-integer part)

                copy part 2 skip
                (lengths/extra: as-integer part)

                copy part 2 skip
                (lengths/comment: as-integer part)

                2 skip
                ; disk-no unsigned-16

                copy part 2 skip
                (attributes/internal: as-integer part)

                copy part 2 skip
                (attributes/other: as-integer part)

                copy part 2 skip
                (attributes/filesystem: as-integer part)

                copy part 4 skip
                (entry/offset: as-integer part)

                copy part lengths/filename skip
                (entry/filename: as-filename part)

                copy part lengths/extra skip
                (entry/extra: any [part #{}])

                lengths/comment skip

                (
                    entry/size: 30  ; entry header length
                    + entry/compressed
                    + lengths/filename
                    + lengths/extra
                    + lengths/comment
                )

                mark:
                to end
            ][
                do make error! "Invalid ZIP directory entry"
            ]

            <else> [
                archive/entries: mark
                archive/count: archive/count - 1
                entry/start: skip head archive/entries entry/offset

                entry/is-text: 1 and attributes/internal == 1

                if origin == 3 [
                    ; Unix file attributes
                    ;
                    entry/is-folder: 16384 and attributes/filesystem == 16384
                    entry/is-executable: 64 and attributes/filesystem == 64
                ]

                entry
            ]
        ]
    ]

    to-block: func [
        "UnZIP an archive to filename/content pairs"

        archive [binary!]
        "Archive to extract"

        /strict
        "Uses sanity checks"

        /local index entry
    ][
        if index: try [
            open/:strict archive
        ][
            new-line/all/skip collect-while [
                entry: step index
            ][
                keep entry/filename
                keep entries/unpack entry
            ] true 2
        ]
    ]

    as-map: func [
        "UnZIP an archive to filename/content pairs"

        archive [binary!]
        "Archive to extract"

        /strict
        "Uses sanity checks"

        /local index entry map
    ][
        if index: try [
            open/:strict archive
        ][
            also map: copy #[]

            while [
                entry: step index
            ][
                put map entry/filename entry
            ]
        ]
    ]

    entries: make object! [
        prototype: make object! [
            type: 'zip-entry
            filename:
            date:

            version:
            needs:
            method:

            content:
            offset:
            compressed:
            uncompressed:
            has-valid-range:
            checksum:

            is-text:
            is-folder:
            is-executable:

            comment:
            extra:

            size:
            start:

            is-strict: _
        ]

        unpack: func [
            "Unpack content from a ZIP archive entry"

            entry [object!]
            "Entry to extract content from"

            /local mark value warnings filename-length extra-length
        ][
            case [
                not binary? mark: entry/start [
                    do make error! "Invalid ZIP archive object"
                ]

                not consume mark local-marker [
                    do make error! "Invalid ZIP entry"
                ]

                find "/" last entry/filename [
                    either zero? entry/uncompressed [
                        none
                    ][
                        do make error! "Empty ZIP folder entry expected"
                    ]
                ]

                <else> [
                    warnings: collect [
                        consume mark [
                            case/all [
                                entry/needs <> unsigned-16/le [
                                    keep "Entry NEEDS field does not match directory record"
                                ]

                                not unsigned-16/le [
                                    keep "Entry FLAGS field does not match directory record"
                                ]

                                entry/method <> unsigned-16/le [
                                    keep "Entry METHOD field does not match directory record"
                                ]

                                entry/date <> date/decode signed-32/le [
                                    keep "Entry DATE field does not match directory record"
                                ]

                                entry/checksum <> consume 4 [
                                    keep "Entry CHECKSUM field does not match directory record"
                                ]

                                entry/compressed <> unsigned-32/le [
                                    keep "Entry COMPRESSED field does not match directory record"
                                ]

                                entry/uncompressed <> unsigned-32/le [
                                    keep "Entry UNCOMPRESSED field does not match directory record"
                                ]

                                not equal? filename-length: unsigned-16/le length-of entry/filename [
                                    keep rejoin [
                                        "Entry filename-LENGTH field does not match directory record: "
                                        filename-length " s/b " length-of entry/filename
                                    ]
                                ]

                                not equal? extra-length: unsigned-16/le length-of entry/extra [
                                    keep rejoin [
                                        "Entry EXTRA-FIELD-LENGTH field does not match directory record: "
                                        extra-length " s/b " length-of entry/extra
                                    ]
                                ]

                                not equal? consume filename-length to binary! entry/filename [
                                    keep "Entry filename field does not match directory record"
                                ]

                                not equal? consume extra-length entry/extra [
                                    keep "Entry EXTRA-FIELD field does not match directory record"
                                ]
                            ]
                        ]
                    ]
                    [
                        if archive/is-strict [
                            do make error! ""
                        ]
                    ]

                    case [
                        all [
                            entry/is-strict
                            not empty? warnings
                        ][
                            do make error! "Discrepency between Zip ARCHIVE/ENTRY fields"
                        ]

                        entry/content: switch entry/method [
                            0 [
                                copy/part mark entry/uncompressed
                            ]

                            8 [
                                either zero? entry/uncompressed [
                                    make binary! 0
                                ][
                                    inflate mark
                                ]
                            ]
                        ][
                            either entry/is-text [
                                entry/content: to string! entry/content
                            ][
                                entry/content
                            ]
                        ]
                    ]
                ]
            ]
        ]

        clone: func [
            "Clone an existing Entry object"

            entry [object!]
            "Entry Object"

            /local mark warnings filename-length extra-length
        ][
            if not-equal? words-of entry words-of prototype [
                do make error! "Not a ZIP entry"
            ]

            case [
                binary? entry/content [
                    ; use entry created by CREATE method
                    ;
                    assert [
                        entry/compressed == length-of entry/content
                    ]

                    make entry [
                        offset: _
                        start: _
                        checksum: copy checksum
                        content: copy entry/content
                    ]
                ]

                binary? entry/start [
                    ; need to reuse code from ENTRIES/UNPACK
                    ; also, probably overkill for folders
                    ;
                    case [
                        not binary? mark: entry/start [
                            do make error! "Invalid ZIP archive object"
                        ]

                        not consume mark local-marker [
                            do make error! "Invalid ZIP entry"
                        ]

                        find "/" last entry/filename [
                            either zero? entry/uncompressed [
                                entry/start: _

                                entry: make entry [
                                    offset:
                                    start: _
                                    content: make binary! 0
                                ]
                            ][
                                do make error! "Empty ZIP folder entry expected"
                            ]
                        ]

                        not empty? warnings: collect [
                            consume mark [
                                case/all [
                                    not advance 22 [
                                        keep "Existing ZIP entry not long enough (entry start)"
                                    ]

                                    not equal? filename-length: unsigned-16/le length-of entry/filename [
                                        keep rejoin [
                                            "Entry filename-LENGTH field does not match directory record: "
                                            filename-length " s/b " length-of entry/filename
                                        ]
                                    ]

                                    not equal? extra-length: unsigned-16/le length-of entry/extra [
                                        keep rejoin [
                                            "Entry EXTRA-FIELD-LENGTH field does not match directory record: "
                                            extra-length " s/b " length-of entry/extra
                                        ]
                                    ]

                                    not advance filename-length + extra-length [
                                        keep "Existing ZIP entry not long enough (entry extras)"
                                    ]
                                ]
                            ]
                        ][
                            do make error! rejoin warnings
                        ]

                        zero? entry/uncompressed [
                            entry: make entry [
                                offset:
                                start: _
                                content: make binary! 0
                            ]
                        ]

                        entry/compressed > length-of mark [
                            do make error! "Existing ZIP entry not long enough (content)"
                        ]

                        <else> [
                            entry: make entry [
                                offset:
                                start: _
                                checksum: copy checksum
                                content: copy/part mark compressed
                                ; not copying filename or extras fields for now
                            ]
                        ]
                    ]

                    entry
                ]
            ]
        ]

        create: func [
            "Creates an Entry object from a filename/content pair"

            file [file!]
            "Filename within archive"

            content [file! string! binary! none!]
            "Content to add to archive"

            /text
            "Load external content as STRING!"

            /uncompressed
            "Do not compress content"

            /local entry info lengths attributes
        ][
            entry: make prototype [
                filename: file
                date: now

                version: 20
                needs: 20

                is-executable: no
                is-folder: no
                is-text: no
            ]

            case [
                file? content [
                    assert compose [
                        exists? (content)
                        ; wrapping with compose yields specific
                        ; feedback on errors
                    ]

                    info: make map! reduce [
                        'size attempt [query content 'size]
                        'date query content 'modified
                        'type query content 'type
                        ; 'name query content 'name
                        ; 'modified attempt [query content 'modified]
                        ; 'created attempt [query content 'created]
                        ; 'accessed attempt [query content 'accessed]
                    ] 

                    switch info/type [
                        file [
                            content: read/binary content

                            if text [
                                content: to string! content
                                entry/is-text: yes
                            ]
                        ]

                        directory [
                            uncompressed: true
                            content: #{}
                        ]
                    ]

                    entry/date: info/date
                ]

                #"/" == last file [
                    entry/is-folder: yes
                    uncompressed: true
                    content: #{}
                ]

                string? content [
                    entry/is-text: yes
                ]

                none? content [
                    content: #{}
                ]
            ]

            if entry/date/zone [
                entry/date/time: entry/date/time - entry/date/zone
                entry/date/zone: _
            ]

            entry/uncompressed: length-of content

            if not uncompressed [
                entry/method: 8
                entry/content: deflate content
                entry/compressed: length-of entry/content

                if entry/uncompressed <= entry/compressed [
                    uncompressed: true
                ]
            ]

            if uncompressed [
                entry/method: 0
                entry/content: content
                entry/compressed: entry/uncompressed
            ]

            entry/checksum: checksum-of content

            entry
        ]
    ]

    extract: func [
        "Extract content from a ZIP archive entry"

        entry [object!]
        "Entry to extract content from"

        ; Legacy wrapper, to be removed
    ][
        entries/unpack entry
    ]

    text: complement charset [
        0 - 8
        11 - 31
        127
    ]

    pack: func [
        "Build a ZIP archive from a collection of ZIP entries"

        entries [block!]
        "Block of ZIP entry objects"

        /message
        content [string!]
        "Append a message to the resultant ZIP archive"

        /local
        container archive index offset count
    ][
        assert [
            not empty? entries
        ]

        if any [
            not content
            not parse content [any text end]
            65535 < length-of content
        ][
            content: ""
        ]

        archive: make binary! 2048
        index: make binary! 512
        count: 0

        ; accumulate values according to ZIP specification; the
        ; following represents complete expression of a ZIP archive
        ;
        accumulate archive [
            foreach entry entries [
                either binary? entry [
                    accumulate-to archive
                    accumulate entry
                ][
                    count: count + 1
                    entry/offset: length-of archive

                    accumulate-to archive

                    accumulate local-marker
                    unsigned-16/le entry/needs
                    accumulate #{0000}  ; flags
                    unsigned-16/le entry/method
                    signed-32/le date/encode entry/date
                    accumulate entry/checksum
                    unsigned-32/le entry/compressed
                    unsigned-32/le entry/uncompressed
                    unsigned-16/le length-of to binary! entry/filename
                    accumulate #{0000}  ; extrafield-length
                    accumulate to binary! entry/filename
                    accumulate entry/content

                    accumulate-to index

                    accumulate entry-marker
                    unsigned-8 entry/version
                    unsigned-8 3  ; unix--affects filesystem attributes
                    unsigned-16/le entry/needs
                    accumulate #{0000}  ; no flags
                    unsigned-16/le entry/method
                    signed-32/le date/encode entry/date
                    accumulate entry/checksum
                    unsigned-32/le entry/compressed
                    unsigned-32/le entry/uncompressed
                    unsigned-16/le length-of to binary! entry/filename
                    accumulate #{0000}  ; extrafield length
                    accumulate #{0000}  ; comment length
                    accumulate #{0000}  ; disk number start
                    unsigned-16/le either entry/is-text [1] [0]
                    accumulate #{0000}  ; unused external attributes
                    unsigned-16/le permissions/encode entry
                    unsigned-32/le entry/offset
                    accumulate to binary! entry/filename
                ]
            ]

            accumulate-to archive
            offset: length-of archive

            accumulate index

            accumulate index-marker
            accumulate #{0000}  ; disk number
            accumulate #{0000}  ; central directory on disk number
            unsigned-16/le count
            unsigned-16/le count
            unsigned-32/le length-of index
            unsigned-32/le offset
            unsigned-16/le length-of content
            accumulate content
        ]
    ]

    create: func [
        {
            Build a ZIP archive from an evaluated block and contextual functions:

            TOUCH-FOLDER
            Include an empty directory reference

            ADD-FILE
            Add a file/content

            ADD-ENTRY
            Include a previously prepared entry from this or another archive

            ADD-COMMENT
            Prepend a comment to the archive

            ADD-PADDING
            Add unindexed content between entries
        }

        body [block!] 
        "Directives and associated code"

        /local
        archive comment
    ][
        comment: rejoin [
            "Zipped using Rebol v" system/version " (Oldes)"
        ]

        archive: collect [
            do-with body [
                touch-folder: func [
                    filename [file!]
                ][
                    keep entries/create filename none
                ]

                add-file: func [
                    filename [file!]
                    content [binary! string! file!]
                    /uncompressed
                ][
                    keep entries/create/:uncompressed filename content
                ]

                add-entry: func [
                    entry [object!]
                ][
                    keep entries/clone entry
                ]

                add-comment: func [
                    text [string!]
                ][
                    comment: text
                ]

                add-padding: func [
                    part [binary! string!]
                ][
                    keep to binary! part
                ]
            ]
        ]

        zip/pack/message archive comment
    ]
]
