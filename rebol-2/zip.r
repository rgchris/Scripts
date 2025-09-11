Rebol [
    Title: "Zip/Unzip for Rebol 2"
    Author: "Christopher Ross-Gill"
    Date: 1-May-2025
    Version: 0.3.0
    File: %zip.r

    Purpose: "Tools to create/extract-from ZIP archives"

    Home: https://github.com/rgchris/Scripts
    Rights: http://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.zip
    Exports: [
        zip
    ]

    Needs: [
        shim
        r2c:bincode
        r2c:deflate
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
            #"^@" - #"^_" #"/" #"\" #"^~"
        ]

        func [
            [throw]
            value [binary!]
        ][
            switch type?/word value [
                binary! [
                    value: as-string value
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
                throw make error! rejoin [
                    "Invalid Filename: " mold value
                ]
            ]
        ]
    ]

    as-integer: func [
        value
    ][
        to integer! as-binary reverse value
    ]

    checksum-of: func [
        value [string! binary!]
    ][
        reverse crc32/checksum-of either binary? value [
            value
        ][
            as-binary value
        ]
    ]

    date: context [
        encode: func [
            "Encoded a date as an Int32 value (MS-DOS format)"
            value [date!]
        ][
            (shift/left value/year - 1980 25)
            or (shift/left value/month 21)
            or (shift/left value/day 16)
            ; date

            or (shift/left value/time/hour 11)
            or (shift/left value/time/minute 5)
            or (shift to integer! value/time/second 1)
            ; time
        ]

        ; an earlier version of this function was more permissive, however
        ; in retrospect--an invalid date is likely indicator of malicious
        ; archives, thus is rejected
        ;
        decode: func [
            [catch]
            "Create a date from an Int32 value (MS-DOS format)"
            date [integer!]
            /local value day hour
        ][
            day: 31 and shift date 16
            hour: 31 and shift date 11

            throw-on-error [
                ; Leaning on Rebol to validate dates, reject if invalid
                ;
                value: make date! reduce [
                    1980 + shift date 25
                    15 and shift date 21
                    day

                    make time! reduce [
                        hour
                        63 and shift date 5
                        62 and shift/left date 1
                    ]
                ]

                ; Checking for overflow from invalid values
                ;
                throw-on-error [
                    assert [
                        day == value/day
                        hour == value/time/hour
                    ]
                ]

                value
            ]
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

    has-valid-space?: func [
        [catch]
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
                    throw make error! "Shouldn't get here..."
                ]
            ]
        ]

        entry/has-valid-range
    ]

    open: func [
        [catch]
        "Create an iterable representation of a ZIP archive"

        archive [binary!]
        "Binary representation of a ZIP archive"

        /strict
        "Conform within stricter sanity limits"

        /local mark comment-length
    ][
        case [
            not mark: find/last archive index-marker [
                throw make error! "Not a ZIP file"
            ]

            ; sanity check: room for core footer
            ;
            22 > length? mark [
                throw make error! "ZIP index truncated/corrupted"
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
                throw make error! "ZIP index corrupt/invalid"
            ]

            ; sanity check: sizes/offsets match up
            ;
            all [
                archive/is-strict
                not-equal? archive/offset + archive/size + 23 index? mark
                not tail? skip mark comment-length
            ][
                throw make error! "ZIP index (sizes/offsets) sanity check failure"
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
        [catch]
        "Retrieve the next available entry from a ZIP directory"

        archive [object!]
        "Iterable archive object (primarily created by ZIP/OPEN)"

        /local
        mark entry origin lengths attributes
    ][
        case [
            zero? archive/count [
                archive/entry: none
            ]

            not binary? mark: archive/entries [
                throw make error! "Invalid ZIP archive object"
            ]

            not all [
                entry: make entries/prototype []

                ; values consumed in order per ZIP specification
                ;
                consume mark entry-marker

                entry/version: consume mark 'unsigned-8
                origin: consume mark 'unsigned-8
                entry/needs: consume mark 'unsigned-16-le

                advance mark 2
                ; flags ignored

                entry/method: consume mark 'unsigned-16-le
                entry/date: date/decode consume mark 'signed-32-le

                entry/checksum: consume mark 4
                entry/compressed: consume mark 'unsigned-32-le
                entry/uncompressed: consume mark 'unsigned-32-le

                lengths: reduce [
                    'filename consume mark 'unsigned-16-le
                    'extra consume mark 'unsigned-16-le
                    'comment consume mark 'unsigned-16-le
                ]

                advance mark 2
                ; multi-file ZIP feature unsupported

                attributes: reduce [
                    'internal consume mark 'unsigned-16-le
                    'other consume mark 'unsigned-16-le
                    'filesystem consume mark 'unsigned-16-le
                ]

                entry/offset: consume mark 'unsigned-32-le

                entry/filename: as-filename consume mark lengths/filename
                entry/extra: consume mark lengths/extra
                entry/comment: consume mark lengths/comment

                entry/size: 30
                + entry/compressed
                + lengths/filename
                + lengths/extra
                + lengths/comment
                ;
                ; 30 is entry header length

                ; any [
                ;     archive/is-strict
                ;     has-valid-space? archive entry
                ; ]
                ; ;
                ; ; check for potential overlapping entries (slow)
            ][
                throw make error! "Invalid ZIP directory entry"
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
        [catch]
        "Retrieve the next available entry from a ZIP directory"

        archive [object!]
        "Iterable archive object (primarily created by ZIP/OPEN)"

        /local
        mark entry origin lengths attributes part
    ][
        case [
            zero? archive/count [
                archive/entry: none
            ]

            not binary? mark: archive/entries [
                throw make error! "Invalid ZIP archive object"
            ]

            not parse/all/case mark [
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
                (entry/date: date/decode to integer! as-binary reverse part)

                copy part 4 skip
                (entry/checksum: as-binary part)

                copy part 4 skip
                (entry/compressed: unsigned-32/decode as-binary reverse part)

                copy part 4 skip
                (entry/uncompressed: unsigned-32/decode as-binary reverse part)

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
                (entry/filename: as-filename as-binary part)

                copy part lengths/extra skip
                (entry/extra: as-binary any [part ""])

                lengths/comment skip

                (
                    entry/size: 30  ; entry header length
                    + entry/compressed
                    + lengths/filename
                    + lengths/extra
                    + lengths/comment
                )

                mark:
                (mark: as-binary mark)
                to end
            ][
                throw make error! "Invalid ZIP directory entry"
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

    to-block: func [
        [catch]
        "UnZIP an archive to filename/content pairs"

        archive [binary!]
        "Archive to extract"

        /strict
        "Uses sanity checks"

        /local index entry
    ][
        if index: throw-on-error [
            either strict [
                open/strict archive
            ][
                open archive
            ]
        ][
            new-line/all/skip collect [
                while [
                    entry: step index
                ][
                    keep entry/filename
                    keep entries/unpack entry
                ]
            ] true 2
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
                    throw make error! "Invalid ZIP archive object"
                ]

                not consume mark local-marker [
                    throw make error! "Invalid ZIP entry"
                ]

                find "/" last entry/filename [
                    either zero? entry/uncompressed [
                        none
                    ][
                        throw make error! "Empty ZIP folder entry expected"
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

                                not equal? filename-length: unsigned-16/le length? entry/filename [
                                    keep rejoin [
                                        "Entry filename-LENGTH field does not match directory record: "
                                        filename-length " s/b " length? entry/filename
                                    ]
                                ]

                                not equal? extra-length: unsigned-16/le length? entry/extra [
                                    keep rejoin [
                                        "Entry EXTRA-FIELD-LENGTH field does not match directory record: "
                                        extra-length " s/b " length? entry/extra
                                    ]
                                ]

                                not equal? consume filename-length as-binary entry/filename [
                                    keep "Entry filename field does not match directory record"
                                ]

                                not equal? consume extra-length entry/extra [
                                    keep "Entry EXTRA-FIELD field does not match directory record"
                                ]
                            ]
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
                                entry/content: as-string entry/content
                            ][
                                entry/content
                            ]
                        ]
                    ]
                ]
            ]
        ]

        clone: func [
            [catch]
            "Clone an existing Entry object"

            entry [object!]
            "Entry Object"

            /local mark warnings filename-length extra-length
        ][
            if not-equal? words-of entry words-of prototype [
                throw make error! "Not a ZIP entry"
            ]

            case [
                binary? entry/content [
                    ; use entry created by CREATE method
                    ;
                    throw-on-error [
                        assert [
                            entry/compressed == length? entry/content
                        ]
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
                            throw make error! "Invalid ZIP archive object"
                        ]

                        not consume mark local-marker [
                            throw make error! "Invalid ZIP entry"
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
                                throw make error! "Empty ZIP folder entry expected"
                            ]
                        ]

                        not empty? warnings: collect [
                            consume mark [
                                case/all [
                                    not advance 22 [
                                        keep "Existing ZIP entry not long enough (entry start)"
                                    ]

                                    not equal? filename-length: unsigned-16/le length? entry/filename [
                                        keep rejoin [
                                            "Entry filename-LENGTH field does not match directory record: "
                                            filename-length " s/b " length? entry/filename
                                        ]
                                    ]

                                    not equal? extra-length: unsigned-16/le length? entry/extra [
                                        keep rejoin [
                                            "Entry EXTRA-FIELD-LENGTH field does not match directory record: "
                                            extra-length " s/b " length? entry/extra
                                        ]
                                    ]

                                    not advance filename-length + extra-length [
                                        keep "Existing ZIP entry not long enough (entry extras)"
                                    ]
                                ]
                            ]
                        ][
                            throw make error! rejoin warnings
                        ]

                        zero? entry/uncompressed [
                            entry: make entry [
                                offset:
                                start: _
                                content: make binary! 0
                            ]
                        ]

                        entry/compressed > length? mark [
                            throw make error! "Existing ZIP entry not long enough (content)"
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

                    info: info? content

                    switch info/type [
                        file [
                            content: read/binary content

                            if text [
                                content: as-string content
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

            entry/uncompressed: length? content

            if not uncompressed [
                entry/method: 8
                entry/content: deflate content
                entry/compressed: length? entry/content

                if entry/uncompressed <= entry/compressed [
                    uncompressed: true
                ]
            ]

            if uncompressed [
                entry/method: 0
                entry/content: as-binary content
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

    text: complement charset as-string 64#{
        AAECAwQFBgcICwwNDg8QERITFBUWFxgZGhscHR4ffw==
    }

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
            65535 < length? content
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
                    ; padding
                    accumulate-to archive
                    accumulate entry
                ][
                    count: count + 1
                    entry/offset: length? archive

                    accumulate-to archive

                    accumulate local-marker
                    unsigned-16/le entry/needs
                    accumulate #{0000}  ; flags
                    unsigned-16/le entry/method
                    signed-32/le date/encode entry/date
                    accumulate entry/checksum
                    unsigned-32/le entry/compressed
                    unsigned-32/le entry/uncompressed
                    unsigned-16/le length? as-binary entry/filename
                    accumulate #{0000}  ; extrafield-length
                    accumulate as-binary entry/filename
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
                    unsigned-16/le length? as-binary entry/filename
                    accumulate #{0000}  ; extrafield length
                    accumulate #{0000}  ; comment length
                    accumulate #{0000}  ; disk number start
                    unsigned-16/le either entry/is-text [1] [0]
                    accumulate #{0000}  ; unused external attributes
                    unsigned-16/le permissions/encode entry
                    unsigned-32/le entry/offset
                    accumulate as-binary entry/filename
                ]
            ]

            accumulate-to archive
            offset: length? archive

            accumulate index

            accumulate index-marker
            accumulate #{0000}  ; disk number
            accumulate #{0000}  ; central directory on disk number
            unsigned-16/le count
            unsigned-16/le count
            unsigned-32/le length? index
            unsigned-32/le offset
            unsigned-16/le length? content
            accumulate as-binary content
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
            Add unindexed content between entries (unsupported by prominent unarchivers)
        }

        body [block!] 
        "Directives and associated code"

        /local
        archive comment
    ][
        comment: "Zipped using Rebol v2.7.8"

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
                    either uncompressed [
                        keep entries/create/uncompressed filename content
                    ][
                        keep entries/create filename content
                    ]
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
