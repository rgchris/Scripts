Rebol [
    Title: "Zip/Unzip for Rebol 2"
    Date: 8-Feb-2022
    Author: "Christopher Ross-Gill"
    Home: https://github.com/rgchris/Scripts/
    File: %zip.r
    Version: 0.2.0
    Rights: http://opensource.org/licenses/Apache-2.0
    Purpose: {
        Tools to create/extract-from ZIP archives
    }

    Type: 'module
    Name: 'rgchris.zip
    Exports: [
        zip
    ]

    History: [
        8-Feb-2022 0.2.0 "More atomic, versatile toolset"
        3-Jan-2022 0.1.0 "Reworked UNZIP functions to be more atomic"
    ]

    Notes: [
        https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
        ".ZIP File Format Specification"

        https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html
        "Breakdown of the ZIP format"

        http://www.rebol.org/view-script.r?script=rebzip.r
        "RebZIP v1.0.1"

        https://www.bamsoftware.com/hacks/zipbomb/
        "Building a better Zip Bomb"

        https://unix.stackexchange.com/a/14727
        "Unix external file attributes"
    ]

    Future: {
        For obvious reason, investment in a Rebol 2 script has limiting
        factors and room for evolution, there is a kernel here compatible
        with streaming and other efficient mechanisms. The breakdown in
        concerns in this module should be instructive to other Rebol-
        derived languages looking to implement more nuanced ZIP handling
    }
]

do %deflate.r
do %bincode.r

zip: make object! [
    _: none

    entry-marker: #{504B0102}  ; "PK^A^B"
    local-marker: #{504B0304}  ; "PK^C^D"
    index-marker: #{504B0506}  ; "PK^E^F"

    prototype-index: make object! [
        type: 'index
        count:
        size:
        offset:
        comment:
        pool:
        entries: _
    ]

    prototype-entry: make object! [
        type: 'entry
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
        start: _
    ]

    ; filename validation needs a bit of work -- the following should
    ; be adequate to catch malicious entries but users of this script
    ; should be wary of commiting verbatim to disk
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

    ; an earlier version of this function was more permissive, however
    ; in retrospect--an invalid date is likely indicator of malicious
    ; archives, thus is rejected
    ;
    as-date: func [
        [catch]
        "Create a date from two Uin16 values (MS-DOS format)"
        time [integer!]
        date [integer!]
        /local value
    ][
        ; Leaning on Rebol to validate dates, reject
        ; if invalid
        ;
        value: throw-on-error [
            make date! reduce [
                1980 + shift date 9
                15 and shift date 5
                31 and date
            ]
        ]

        value/time: throw-on-error [
            make time! reduce [
                shift time 11
                63 and shift time 5
                31 and time * 2
            ]
        ]

        ; Checking for overflow from invalid values
        ;
        throw-on-error [
            assert [
                all [
                    value/date/day == (31 and date)
                    value/time/hour == shift time 11
                ]
            ]
        ]

        value
    ]

    has-valid-space?: func [
        [catch]
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

    load: func [
        [catch]
        "Create an iterable representation of ZIP archive directory"

        archive [binary!]
        "Binary representation of a ZIP archive"

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
                archive: make prototype-index []

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
            not all [
                equal? archive/offset + archive/size + 23 index? mark
                tail? skip mark comment-length
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
        "Iterable archive object (primarily created by ZIP/LOAD)"

        /local
        mark entry origin lengths attributes
    ][
        case [
            zero? archive/count [
                none
            ]

            not binary? mark: archive/entries [
                throw make error! "Invalid ZIP archive object"
            ]

            not consume mark [
                entry: make prototype-entry []

                all [
                    ; values consumed in order per ZIP specification
                    ;
                    consume entry-marker

                    entry/version: unsigned-8
                    origin: unsigned-8
                    entry/needs: unsigned-16/le

                    advance 2  ; flags ignored

                    entry/method: unsigned-16/le
                    entry/date: as-date unsigned-16/le unsigned-16/le

                    entry/checksum: reverse consume 4
                    entry/compressed: unsigned-32/le
                    entry/uncompressed: unsigned-32/le

                    lengths: reduce [
                        'filename unsigned-16/le
                        'extra unsigned-16/le
                        'comment unsigned-16/le
                    ]

                    advance 2  ; multi-file ZIP feature unsupported

                    attributes: reduce [
                        'internal unsigned-16/le
                        'other unsigned-16/le
                        'filesystem unsigned-16/le
                    ]

                    entry/offset: unsigned-32/le

                    entry/filename: as-filename consume lengths/filename
                    entry/extra: consume lengths/extra
                    entry/comment: consume lengths/comment

                    ; check for potential overlapping entries
                    ;
                    entry/size: 30  ; entry header length 
                    + entry/compressed
                    + lengths/filename
                    + lengths/extra
                    + lengths/comment

                    has-valid-space? archive entry
                ]
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

                entry
            ]
        ]
    ]

    unpack: func [
        entry [object!]
        "Unpack a ZIP archive entry"

        /local mark value warnings
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
                if not empty? warnings: collect [
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

                            entry/date <> as-date unsigned-16/le unsigned-16/le [
                                keep "Entry DATE field does not match directory record"
                            ]

                            entry/checksum <> reverse consume 4 [
                                keep "Entry CHECKSUM field does not match directory record"
                            ]

                            entry/compressed <> unsigned-32/le [
                                keep "Entry COMPRESSED field does not match directory record"
                            ]

                            entry/uncompressed <> unsigned-32/le [
                                keep "Entry UNCOMPRESSED field does not match directory record"
                            ]

                            unsigned-16/le <> length? entry/filename [
                                keep "Entry filename-LENGTH field does not match directory record"
                            ]

                            unsigned-16/le <> length? entry/extra [
                                keep "Entry EXTRA-FIELD-LENGTH field does not match directory record"
                            ]

                            not consume as-binary entry/filename [
                                keep "Entry filename field does not match directory record"
                            ]

                            not consume entry/extra [
                                keep "Entry EXTRA-FIELD field does not match directory record"
                            ]
                        ]
                    ]
                ][
                    ; probe warnings
                ]

                if value: switch entry/method [
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
                    if entry/is-text [
                        value: as-string value
                    ]

                    value
                ]
            ]
        ]
    ]

    to-block: func [
        [catch]
        "UnZIP an archive to filename/content pairs"

        archive [binary!]
        "Archive to unpack"

        /local index entry
    ][
        if index: throw-on-error [
            load archive
        ][
            new-line/all/skip collect [
                while [
                    entry: step index
                ][
                    keep entry/filename
                    keep unpack entry
                ]
            ] true 2
        ]
    ]

    prepare: func [
        file [file!]
        content [file! string! binary! none!]

        /text
        "Load external content as STRING!"

        /uncompressed
        "Do not compress content"

        /local entry info lengths attributes
    ][
        entry: make prototype-entry [
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

            #"/" = last file [
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

        entry/checksum: reverse crc32-checksum-of entry/content

        entry
    ]

    encode-date: func [
        value [date!]
    ][
        (shift/left value/year - 1980 9)
        or (shift/left value/month 5)
        or value/day
    ]

    encode-time: func [
        value [time!]
    ][
        (shift/left value/hour 11)
        or (shift/left value/minute 5)
        or round value/second / 2
    ]

    encode-fs-attributes: func [
        entry [object!]
        /local attributes
    ][
        attributes: 420
        ; default => 0644 => rw-r--r--

        either entry/is-folder [
            attributes: attributes or 16384 or 73
            ; +x => 0111 => 73
        ][
            attributes: attributes or 32768
        ]

        if entry/is-executable [
            attributes: attributes or 64
            ; u+x => 0100 => 64
        ]

        attributes
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
        "Prepend a message to the resultant ZIP archive"

        /local
        container archive index offset
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

        ; accumulate values according to ZIP specification; the
        ; following represents complete expression of a ZIP archive
        ;
        accumulate archive [
            foreach entry entries [
                entry/offset: length? archive

                accumulate-to archive

                accumulate local-marker
                unsigned-16/le entry/needs
                accumulate #{0000}  ; flags
                unsigned-16/le entry/method
                unsigned-16/le encode-time entry/date/time
                unsigned-16/le encode-date entry/date
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
                unsigned-16/le encode-time entry/date/time
                unsigned-16/le encode-date entry/date
                accumulate entry/checksum
                unsigned-32/le entry/compressed
                unsigned-32/le entry/uncompressed
                unsigned-16/le length? as-binary entry/filename
                accumulate #{0000}  ; extrafield length
                accumulate #{0000}  ; comment length
                accumulate #{0000}  ; disk number start
                unsigned-16/le either entry/is-text [1] [0]
                accumulate #{0000}  ; unused external attributes
                unsigned-16/le encode-fs-attributes entry
                unsigned-32/le entry/offset
                accumulate as-binary entry/filename
            ]

            accumulate-to archive
            offset: length? archive

            accumulate index

            accumulate index-marker
            accumulate #{0000}  ; disk number
            accumulate #{0000}  ; central directory on disk number
            unsigned-16/le length? entries
            unsigned-16/le length? entries
            unsigned-32/le length? index
            unsigned-32/le offset
            unsigned-16/le length? content
            accumulate as-binary content
        ]
    ]

    build: func [
        {
            Build a ZIP archive from an evaluated block and contextual functions:

            ADD-FILE - add a file/content
            TOUCH-FOLDER - include an empty directory reference
            ADD-COMMENT - prepend a comment to the archive
        }

        body [block!] 
        "Directives and associated code"

        /local
        entries comment
    ][
        comment: "Zipped using Rebol v2.7.6"

        entries: collect [
            do-with body [
                add-file: func [
                    filename [file!]
                    content [binary! string! file!]
                ][
                    keep prepare filename content
                ]

                touch-folder: func [
                    filename [file!]
                ][
                    keep prepare filename none
                ]

                add-comment: func [
                    text [string!]
                ][
                    comment: text
                ]
            ]
        ]

        zip/pack/message entries comment
    ]
]
