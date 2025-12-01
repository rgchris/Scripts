Rebol [
    Title: "PDF Creator"
    Author: "Christopher Ross-Gill"
    Date: 18-Jan-2022
    Version: 0.1.0
    File: %pdf.reb

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Purpose: "Build a PDF object model for atomic construction of PDF documents"

    Type: module
    Name: rgchris.pdf
    Exports: [
        pdf
    ]

    Needs: [
        r3:rgchris:do-with
        r3:rgchris:combine
        r3:rgchris:ascii85
        r3:rgchris:zip
    ]

    History: [
        18-Jan-2022 0.1.0
        "Objects, registry, templates, stitcher"

        22-Dec-2021 0.0.1
        "Proof of concept: functions as an interface"
    ]

    Comment: [
        https://www.adobe.com/content/dam/acom/en/devnet/pdf/pdfs/pdf_reference_archives/PDFReference.pdf
        "Page references come from the PDF Reference v1.4"
        "Page # (pdf page offset #), figure/table #"

        https://opensource.adobe.com/dc-acrobat-sdk-docs/standards/pdfstandards/pdf/PDF32000_2008.pdf
        "ISO32000:1 2008 (PDF v1.7)"

        https://www.prepressure.com/pdf/basics/version
        "Version History"

        http://www.colellachiara.com/soft/PDFM2/pdf-maker.html
        "PDF Maker for Rebol 2"
    ]
]

pdf: make object! [
    metrics-file: r3:rgchris:pdf-font-metrics.zip

    ; 255 -> %-based colors
    ;
    color-constant: 20 / 51

    header: #{255044462d312e330a25decafbad0a}
    ; header: #{255044462d312e330a890d0a251a0a}

    some: func [
        "Returns a series unless empty (returns NONE)"
        series [series!]
    ][
        all [
            not empty? series
            series
        ]
    ]

    has-substance: func [
        value [any-type!]
    ][
        not any [
            unset? :value
            none? value

            if object? value [
                parse values-of value [
                    any none!
                ]
            ]

            if block? value [
                parse value [
                    some none!
                    ; empty blocks are allowed
                ]
            ]
        ]
    ]

    formatter: make object! [
        pad-integer: func [
            value [integer!]
            length [integer!]
        ][
            head insert insert/dup make string! length #"0" length - length-of value: form value value
        ]

        convert: func [
            value [integer! decimal!]
            unit [word!]
        ][
            switch word [
                pt point [
                    value
                ]

                mm [
                    value * 2.83464566929134
                    ; 72 / 25.4
                ]

                cm [
                    value * 28.3464566929134
                    ; 72 / 2.54
                ]

                pc pica [
                    value * 12
                ]

                px [
                    value * 0.75
                    ; 72 / 96
                ]
            ]
        ]

        mm2pt: func [mm] compose/deep [
            mm * (72 / 25.4)
        ]

        octal: make object! [
            encode: func [
                value [integer!]
            ][
                rejoin [
                    #"0" + remainder shift value 6 8
                    #"0" + remainder shift value 3 8
                    #"0" + remainder value 8
                ]
            ]

            decode: func [
                value [string! binary!]
            ][
                value/3 - 48
                or (shift/left value/2 - 48 3)
                or shift/left value/1 - 48 6
            ]
        ]

        ; PDF does not support Exponent notation
        ; use external %bincode.reb FLOAT-64/FORM instead?
        ;
        form-decimal: use [
            digit digit-19 padding
        ][
            digit: charset "0123456789"
            digit-19: charset "123456789"
            padding: "00000000000000000000000000000000"

            func [
                "Render a decimal! value sans scientific notation"
                value [integer! decimal!]
                /local sign whole part exp
            ][
                if not parse form value [
                    [
                        copy sign #"-"
                        |
                        (sign: copy "")
                    ]

                    copy whole [
                        digit-19 any digit
                        |
                        #"0"
                    ]

                    [
                        #"." copy part [
                            any #"0"
                            digit-19
                            any digit
                        ]
                        |
                        opt ".0"
                        (part: "")
                    ]

                    opt [
                        #"E" copy exp [
                            opt [
                                #"-" | #"+"
                            ]

                            some digit
                        ]
                    ]
                ][
                    make error! rejoin [
                        "Could not parse DECIMAL!:" mold form value
                    ]
                ]

                rejoin case [
                    not exp [
                        [
                            sign
                            whole
                            pick ["" #"."] empty? part
                            part
                        ]
                    ]

                    negative? exp: to integer! exp [
                        [
                            sign
                            "0."
                            copy/part padding -1 - exp
                            whole
                            part
                        ]
                    ]

                    <else> [
                        [
                            sign
                            whole
                            part
                            copy/part padding exp - length-of part
                        ]
                    ]
                ]
            ]
        ]

        ; valid characters in strings
        ;
        string-escapes: complement charset "()\"

        ; this converts Rebol values to PDF values; it's not perfect but works.
        ;
        form-value: func [
            "Rebol to PDF"
            value
            /with result [string!]
            /only

            /local mark extent
        ][
            result: any [
                :result
                make string! 256
            ]

            switch/default type-of :value [
                #(block!) [
                    either empty? value [
                        append result "[]"
                    ][
                        if any [with only] [
                            append result #"["
                        ]

                        mark: for-each kid value [
                            insert tail form-value/with :kid tail result pick "^/ " word? kid
                        ]

                        head either any [with only] [
                            change back mark #"]"
                        ][
                            remove back mark
                        ]
                    ]
                ]

                #(object!) [
                    append result "<<^/"

                    for-each kid words-of value [
                        if has-substance get/any kid [
                            append result mold to refinement! kid
                            append result #" "
                            form-value/with get/any kid tail result
                            append result #"^/"
                        ]
                    ]

                    append result ">>"
                ]

                #(map!) [
                    append result "<<^/"

                    for-each kid keys-of value [
                        if has-substance select value kid [
                            append result mold to refinement! kid
                            append result #" "
                            form-value/with select value kid tail result
                            append result #"^/"
                        ]
                    ]

                    append result ">>"
                ]

                #(path!) [
                    for-each kid next to block! value [
                        insert tail form-value/with kid tail result #" "
                    ]

                    append mark form value/1
                ]

                #(char!) [
                    repend result [
                        #"("
                        pick [#"\" ""] found? find string-escapes value
                        value
                        #")"
                    ]
                ]

                #(string!) [
                    result: insert tail result #"("

                    parse value [
                        some [
                            mark:
                            some string-escapes
                            extent:
                            (result: insert/part result mark extent)
                            |
                            skip
                            (result: insert insert result #"\" mark/1)
                        ]
                    ]

                    append result #")"
                ]

                #(decimal!) [
                    append result form-decimal value
                ]

                #(date!) [
                    if not value/time [
                        value/time: 12:00
                    ]

                    if value/zone [
                        value/time: value/time - value/zone
                    ]

                    repend result [
                        "(D:"
                        value/year
                        pad-integer value/month 2
                        pad-integer value/day 2
                        pad-integer value/time/hour 2
                        pad-integer value/time/minute 2
                        pad-integer to integer! value/time/second 2
                        "Z)"
                    ]
                ]

                ; more permissive /NAME type than REFINEMENT!
                ;
                #(issue!) [
                    append result back change mold value #"/"
                ]

                #(time!) [
                    repend result [
                        value/1 " " value/2 " R"
                    ]
                ]
            ][
                ; other values simply molded currently.
                ;
                append result mold :value
            ]
        ]
    ]

    reference-of: func [
        value [object! none!]
    ][
        case [
            none? value [
                _
            ]

            not in value 'id [
                make error! "Not a PDF object"
            ]

            not time? value/id [
                make error! "Object not registered"
            ]

            <else> [
                value/id
            ]
        ]
    ]

    form-of: func [
        value [object! none!]
    ][
        case [
            none? value [
                _
            ]

            not in value 'template [
                make error! "Not a PDF object"
            ]

            not block? value/template [
                make error! "Object missing template (should not happen)"
            ]

            <else> [
                make object! reduce-only value/template
            ]
        ]
    ]

    prototype: make object! [
        prototype: make object! [
            type:
            id:
            template: _
        ]

        make-prototype: func [
            'name [set-word!]
            spec [block!]
        ][
            spec: make prototype spec
            spec/type: to word! name
            set to word! name spec
        ]

        ; Page 68 (88), Table 3.12
        ;
        make-prototype trailer: [
            size:
            previous:
            root:
            encrypt:
            info: _

            template: [
                Size: size
                Prev: previous
                Root: reference-of root
                Info: reference-of info
            ]
        ]

        ; Page 83 (103), Table 3.16
        ;
        make-prototype catalog: [
            pages:
            labels:
            names:
            ; destinations:  ; /Dests  ; named destinations
            mode:  ; [/UseNone /UseOutlines /UseThumbs /FullScreen]
            outlines:  ; to research
            acroform: _  ; to research

            template: [
                Type: /Catalog
                Version: #1.4
                Pages: reference-of pages
                PageLabels: labels
                Outlines: reference-of outlines
            ]
        ]

        ; Page 86 (106), Table 3.17
        ;
        make-prototype pages: [
            kids:
            parent: _  ; for fragmented page trees

            template: [
                Type: /Pages
                Count: length-of kids
                Kids: collect-each page kids [
                    keep reference-of page
                ]
            ]
        ]

        ; Page 88 (108), Table 3.18
        ;
        make-prototype page: [
            contents:
            parent: _

            ; MediaBox parameters
            ;
            origin: 0x0
            size:
            width:
            height: _

            ; Page 678 (698), Figure 9.3
            ;
            crop-box:
            bleed-box:
            trim-box:
            art-box:

            rotation:
            thumbnail:
            beads:
            transition:

            resources:
            annotations: _

            graphics-state:
            stream: _

            template: [
                Type: /Page
                Contents: reference-of contents
                Parent: parent

                MediaBox: reduce [
                    origin/x origin/y
                    size/x size/y
                ]

                Resources: form-of resources

                Annots: if some annotations [
                    collect-each annotation annotations [
                        keep form-of annotation
                    ]
                ]
            ]
        ]

        make-prototype content: [
            ; length:
            filter:
            stream: _

            template: [
                Length: 0
                Filter: _
            ]
        ]

        ; Page 97 (117), Table 3.21
        ;
        make-prototype resource: [
            extended-graphics-state:
            color-space:
            pattern:
            shading:
            x-object:
            font:
            procedure-set:
            properties: _

            template: [
                XObject: if some x-object [
                    collect-each [name object] x-object [
                        keep name
                        keep reference-of object
                    ]
                ]

                Font: if some font [
                    make object! collect-each [name object] font [
                        keep to set-word! name
                        keep reference-of object
                    ]
                ]

                ProcSet: some procedure-set
            ]
        ]

        ; Page 221 (241), Table 4.22
        ;
        make-prototype pattern: [
            name:
            width:
            height: _
            type: _
            ; 1 - tiling
            ; 2 - shading

            paint-type:
            ; (for type: 1)
            ; 1 - colored
            ; 2 - uncolored (stencil)
            
            tiling-type:
            ; 1 - constant
            ; 2 - no-distortion
            ; 3 - constant-faster

            bbox:
            x-step:
            y-step:
            resources:
            matrix: _

            template: [
                Type: /Pattern
                PatternType: type
                Shading: _
            ]
        ]

        ; Page 267 (287), Table 4.35
        ;
        make-prototype image: [
            name:
            width:
            height: _
            color-space: /DeviceRGB  ; /DeviceGray
            bits-per-component: 8
            image-mask:
            mask:
            s-mask:
            decode:
            interpolate:
            stream: _

            template: [
                Type: /XObject
                Subtype: /Image
                Width: width
                Height: height
                ColorSpace: color-space
                BitsPerComponent: bits-per-component

                Length: _
                Filter: _
            ]
        ]

        ; Page 284 (304), Table 4.41
        ;
        ; note that this is a reusable graphical element, not to
        ; be confused with input forms/fields (AcroForm)
        ;
        make-prototype form: [
            name:
            bounding-box:
            matrix:
            resources:
            stream: _

            template: [
                Type: /XObject
                Subtype: /Form
                BBox: bounding-box
                Matrix: matrix
                Resources: resources

                Length: _
                Filter: _
            ]
        ]

        ; Page 317 (337), Table 5.8
        ;
        make-prototype font: [
            ; for convenience
            ;
            name:
            family:
            style:
            weight: _

            is-standard: false

            sub-type: /Type1
            base-font:
            first-character:
            last-character:
            widths:
            descriptor:
            encoding:  ; /WinAnsiEncoding
            to-unicode:
            stream:

            kerning:
            charset: _

            template: [
                Type: /Font
                Subtype: sub-type
                BaseFont: base-font

                FirstChar:
                LastChar:
                Widths:
                FontDescriptor: _

                if not is-standard [
                    FirstChar: first-character
                    LastChar: last-character
                    Widths: widths
                    FontDescriptor: reference-of descriptor
                ]

                Encoding: encoding

                Length:
                Filter: _
            ]
        ]

        ; Page 356 (376), Table 5.18
        ;
        make-prototype font-descriptor: [
            name:
            flags:
            bounding-box:

            angle:
            ascent:
            descent:
            leading:

            capital-height:
            x-height:
            stem-v:
            stem-h:

            average-width:
            maximum-width:

            font-afb:
            font-ttf: _

            template: [
                Type: /FontDescriptor
                FontName: name
                Flags: flags
                FontBBox: bounding-box
                ItalicAngle: angle
                Ascent: ascent
                Descent: descent
                Leading: leading
                CapHeight: capital-height
                XHeight: x-height
                StemV: stem-v
                StemH: stem-h
                AvgWidth: average-width
                MaxWidth: maximum-width
                FontFile: font-afb
                FontFile2: font-ttf
            ]
        ]

        ; Page 475 (495), Table 8.2
        ;
        make-prototype destination: [
            page:
            top:
            left: _
            zoom: 0  ; null

            ; Renders as:
            ; [page /XYZ top left zoom]
            ; e.g. [3 0 R /XYZ 0 792 0]
            ;
            template: [
                reference-of page /XYZ top left zoom
            ]
        ]

        ; Page 478 (498), Table 8.3
        ;
        make-prototype outlines: [
            first:
            last:
            count: _

            template: [
                Type: /Outlines
                First: first
                Last: last
                Count: count
            ]
        ]

        ; Page 478 (498), Table 8.4
        ;
        make-prototype outline: [
            title:
            ; 'title is linkable, e.g. my.pdf#Title or my.pdf#nameddest=Title

            parent:
            previous:
            next:
            first:
            last:
            count: _
        ]

        ; Page 483 (503), Table 8.6
        ;
        ; used for managing page numbering, possibly ignored
        ; by many readers
        ;
        make-prototype label: [
            style:
            prefix:
            start: _

            template: [
                Type: /PageLabel
            ]
        ]

        ; Page 486 (506), Table 8.9
        ;
        make-prototype transition: [
            type: 'transition  ; /Trans
            id: _

            duration:
            style:
            dimension:
            motion:
            direction: _

            template: [
                Type: /Trans
            ]
        ]

        ; Page 490 (510), Table 8.10
        ;
        make-prototype annotation: [
            sub-type:
            name:  ; /NM
            page:  ; /P
            contents:
            rectangle:  ; required
            opacity:
            title: _
            border: [0 0 0]
        ]

        ; Page 500 (520), Table 8.15
        ;
        text-annotation: make annotation [
            type: 'text-annotation
            is-open:
            icon: _
            ;
            ; ICON is one of:
            ; [/Comment /Key /Note /Help /NewParagraph /Paragraph /Insert]

            template: [
                Type: /Annot
                Subtype: /Text

                Rect: rectangle
                Border: border
                CA: opacity

                T: title
                Contents: contents
                Open: is-open
                Name: icon
            ]
        ]

        ; Page 501 (521), Table 8.16
        ;
        link-annotation: make annotation [
            type: 'link-annotation
            highlight: /P  ; Push instead of default Invert
            action:
            destination: _
            ;
            ; A link annotation can refer to a URL (or any) Action or
            ; a Destination, cannot refer to both
            ;
            ; Opting to refer to destinations by GoTo Action
            ; though not compatible with PDF v1.0

            template: [
                Type: /Annot
                Subtype: /Link

                Rect: rectangle
                Border: border
                CA: opacity

                T: title
                H: highlight
                A: action
                Dest: reduce destination/template
            ]
        ]

        ; action sub-types of interest:
        ; [/GoTo /Thread /URI /SubmitForm /ResetForm]
        ;
        ; Page 523 (543), Table 8.40
        ;
        make-prototype goto-action: [
            destination: _

            template: [
                Type: /Action
                S: /GoTo
                D: reduce destination/template
            ]
        ]

        ; Page 523 (543), Table 8.40
        ;
        make-prototype uri-action: [
            href: _

            template: [
                Type: /Action
                S: /URI
                URI: href
            ]
        ]

        ; Page 576 (596), Table 9.2
        ;
        make-prototype info: [
            title:
            author: _
            creator:
            producer: "Rebol v2.7.8"
            ; need to keep this value until conversion checks pass
            subject:
            keywords:
            created:
            modified: _

            template: [
                Title: title
                Author: author
                Subject: subject
                Keywords: keywords
                Creator: creator
                Producer: producer
                CreationDate: created
                ModDate: modified
            ]
        ]

        ; Tracking graphics state particularly regarding typography
        ; is essential for making calculations based on available space
        ;
        graphics-state: make object! [
            font: _
            size: _
            character-spacing: 0
            word-spacing: 0
            horizontal-scale: 1
            leading: 0
            text-rise: 0
        ]
    ]

    emit: func [
        canvas [block!]
        command [word!]
        /with
        value [any-type!]
    ][
        canvas: tail canvas

        if not none? value [
            for-each value reduce compose [
                (value)
            ][
                switch/default type-of value [
                    #(tuple!) [
                        switch length-of value [
                            3 [
                                ; RGB 0.0.0 - 255.255.255
                                ;
                                value: value * color-constant

                                repend canvas [
                                    0.01 * value/1
                                    0.01 * value/2
                                    0.01 * value/3
                                ]
                            ]

                            4 [
                                ; CMYK 0.0.0.0 - 100.100.100.100
                                ;
                                repend canvas [
                                    0.01 * min 100 value/1
                                    0.01 * min 100 value/2
                                    0.01 * min 100 value/3
                                    0.01 * min 100 value/4
                                ]
                            ]
                        ]
                    ]
                ][
                    repend/only canvas value
                ]
            ]
        ]

        append canvas command

        canvas
    ]

    add-info: func [
        document [object!]
        spec [block!]
    ][
        document/index/info: make prototype/info [
            id: register document self
        ]

        do-with spec [
            title: func [
                title [string!]
            ][
                document/index/info/title: title
            ]

            author: func [
                author [string!]
            ][
                document/index/info/author: author
            ]

            created: func [
                date [date!]
            ][
                if none? document/index/info/modified [
                    document/index/info/modified: date
                ]

                document/index/info/created: date
            ]

            modified: func [
                date [date!]
            ][
                if none? document/index/info/created [
                    document/index/info/created: date
                ]

                document/index/info/modified: date
            ]
        ]
    ]

    add-graphic: func [
        container [object!]
        'stroke [word! none!]
        'fill [word! none!]
        'clip [word! none!]
        body [block!]

        /local content mark
    ][
        assert [
            all [
                find [line shape none _] stroke
                find [even-odd non-zero none _] fill
                find [even-odd non-zero none _] clip
            ]
        ]

        content: container/stream
        mark: tail content

        do-with body [
            ; Page 163 (183), Table 4.9
            ;
            move-to: func [
                end-point [pair! block!]
            ][
                emit/with content 'm [
                    end-point/1 end-point/2
                ]
            ]

            line-to: func [
                end-point [pair! block!]
            ][
                emit/with content 'l [
                    end-point/1 end-point/2
                ]
            ]

            curve-to: func [
                control-1 [pair! block!]
                control-2 [pair! block!]
                end-point [pair! block!]
            ][
                control-1: reduce control-1
                control-2: reduce control-2
                end-point: reduce end-point

                emit/with content 'c [
                    control-1/1 control-1/2
                    control-2/1 control-2/2
                    end-point/1 end-point/2
                ]
            ]

            smooth-starting-curve-to: func [
                control-2 [pair! block!]
                end-point [pair! block!]
            ][
                emit/with content 'v [
                    control-2/1 control-2/2
                    end-point/1 end-point/2
                ]
            ]

            smooth-ending-curve-to: func [
                control-1 [pair! block!]
                end-point [pair! block!]
            ][
                emit/with content 'y [
                    control-1/1 control-1/2
                    end-point/1 end-point/2
                ]
            ]

            close-path: func [] [
                emit content 'h
            ]

            box: func [
                point [pair! block!]
                end-point [pair! block!]
            ][
                point: reduce point
                end-point: reduce end-point

                emit/with content 're [
                    point/1 point/2
                    end-point/1 end-point/2
                ]
            ]
        ]

        switch clip [
            even-odd [
                emit content 'W*
            ]

            non-zero [
                emit content 'W
            ]
        ]

        emit content switch fill switch stroke [
            line [
                [
                    even-odd ['B*]
                    non-zero ['B]
                    none _ ['S]
                ]
            ]

            shape [
                [
                    even-odd ['b*]
                    non-zero ['b]
                    none _ ['s]
                ]
            ]

            none _ [
                [
                    even-odd ['f*]
                    non-zero ['f]
                    none _ ['n]
                ]
            ]
        ]

        mark
    ]

    fonts: context [
        glyph-width-at: func [
            text [string!]
            font [object!]
        ][
        
        ]

        kerning-value-at: func [
            text [string!]
            font [object!]

            /local value
        ][
            case [
                head? text [
                    0
                ]

                tail? text [
                    0
                ]

                value: select/case pick font/kerning-table last-char char [
                    value
                ]

                <else> [
                    0
                ]
            ]
        ]

        calc-width-of: func [
            text [string! block!]
            graphics-state [object!]

            /local width char char-width last-char part 
        ][
            width: 0

            either block? text [
                assert [
                    parse text [
                        string! any [
                            integer! string!
                        ]
                    ]
                ]
            ][
                text: back change [] text
            ]

            forall text [
                part: text/1

                either number? part [
                    width: width - part
                ][
                    while [
                        not tail? part
                    ][
                        char: to integer! part/1
                        part: next part

                        if char-width: graphics-state/font/widths/(char + 1) [
                            width: width + char-width
                        ]
                    ]
                ]
            ]

            width / 1000 * graphics-state/size * graphics-state/horizontal-scale
        ]

        ; lazy-loading of font metrics
        ;
        metrics-for: use [
            entries init
        ][
            entries: _

            init: func [
                /local index entry
            ][
                index: zip/open read/binary metrics-file

                entries: #[]

                while [
                    entry: zip/step index
                ][
                    switch/default entry/filename [
                        %mimetype
                        %index.reb []
                    ][
                        put entries entry/filename entry
                    ]
                ]

                make block! 28
            ]

            func [
                name [refinement!]
                /local target metrics
            ][
                target: head insert copy %.reb form name

                if none? entries [
                    init
                ]

                case [
                    none? metrics: select entries target [
                        make error! rejoin [
                            "Not an embedded font: " form name
                        ]
                    ]

                    object? metrics [
                        metrics: load zip/extract metrics
                        entries/(target): metrics
                    ]

                    <else> [
                        metrics
                    ]
                ]
            ]
        ]
    ]

    add-text: func [
        document [object!]
        container [object!]
        offset [pair! block!]
        body [block!]

        /local content mark origin line-origin graphics-state
    ][
        content: container/stream
        mark: tail content
        graphics-state: container/graphics-state/1

        origin:
        line-origin:
        offset: reduce offset

        if not find container/resources/procedure-set /Text [
            append container/resources/procedure-set /Text
            ; add /Text as a property of the container if not
            ; set already
        ]

        emit content 'BT

        emit/with content 'Td [
            offset/1 offset/2
        ]

        do-with body [
            state: graphics-state

            line-origin: func [] [
                line-origin
            ]

            cursor: func [] [
                offset
            ]

            set-font: func [
                name [string!]
                size [number!]

                /local font
            ][
                name: to refinement! trim/all copy name

                assert [
                    font: select document/fonts name
                ]

                if not find container/resources/font name [
                    repend container/resources/font [
                        name font
                    ]
                ]

                graphics-state/font: font
                graphics-state/size: size

                emit/with content 'Tf [
                    name size
                ]
            ]

            set-character-spacing: func [
                space [number!]
            ][
                container/graphics-state/1/character-spacing: space

                emit/with content 'Tc space
            ]

            set-word-spacing: func [
                space [number!]
            ][
                container/graphics-state/1/word-spacing: space

                emit/with content 'Tw space
            ]

            set-horizontal-scale: func [
                scale [number!]
            ][
                container/graphics-state/1/horizontal-scale: scale

                emit/with content 'Tz 100 * scale
            ]

            set-leading: func [
                lead [number!]
            ][
                container/graphics-state/1/leading: lead

                emit/with content 'TL lead
            ]

            set-rendering-mode: func [
                fill [logic!]
                stroke [logic!]
                clip [logic!]

                /local mode
            ][
                mode: either fill [
                    either stroke [2] [0]
                ][
                    either stroke [1] [3]
                ]

                if clip [
                    mode: mode + 4
                ]

                emit/with content 'Tr mode
            ]

            set-text-rise: func [
                rise [number!]
            ][
                container/graphics-state/1/text-rise: lead

                emit/with content 'Ts rise
            ]

            new-line: func [] [
                line-origin:
                offset: as-pair line-origin/1 line-origin/2 - graphics-state/leading
                ;
                ; use block for more precision

                emit content 'T*
            ]

            show-text: func [
                text [string! block!]
            ][
                offset/x: offset/x + fonts/calc-width-of text graphics-state

                switch type-of/word text [
                    string! [
                        emit/with content 'Tj text
                    ]

                    block! [
                        assert [
                            parse text [
                                string! any [
                                    number! string!
                                ]
                            ]
                        ]

                        emit/with content 'TJ [
                            text
                        ]
                    ]
                ]
            ]
        ]

        emit content 'ET

        mark
    ]

    ; Content cannot exist outwith the context of a container as
    ; it is dependent on references to fonts, images and
    ; other resources
    ;
    add-content: func [
        document [object!]
        container [object!]
        body [block!]

        /local
        content mark state
    ][
        content: container/stream
        mark: tail content

        do-with body [
            ; Page 156 (176), Table 4.7
            ;
            page: container

            rotation: _

            push: func [
                body [block!]
            ][
                insert container/graphics-state make container/graphics-state/1 []
                emit content 'q

                add-content document container body

                remove container/graphics-state
                emit content 'Q
            ]

            set-matrix: func [
                matrix [block!]
            ][
                assert [
                    parse reduce matrix [6 number!]
                ]

                emit/with content 'cm matrix
            ]

            draw: func [
                'stroke [word! none!] "LINE, SHAPE or NONE"
                'fill [word! none!] "EVEN-ODD, NON-ZERO or NONE"
                body [block!]
            ][
                add-graphic container :stroke :fill :none body
            ]

            clip: func [
                'clip [word! none!] "EVEN-ODD, NON-ZERO or NONE"
                body [block!]
            ][
                add-graphic container _ _ :clip body
            ]

            typeset: func [
                offset [pair! block!]
                body [block!]
            ][
                add-text document container offset body
            ]

            ; set-translation
            ; set-rotation
            ; set-scale

            set-line-width: func [
                width [number!]
            ][
                emit/with content 'w width
            ]

            set-line-cap: func [
                type [integer! word!]
            ][
                type: switch/default type [
                    butt 0 [0]
                    round 1 [1]
                    square 2 [2]
                ][
                    make error! "Unsupported Line Cap"
                ]

                emit/with content 'J type
            ]

            set-line-join: func [
                type [integer! word!]
            ][
                type: switch/default type [
                    miter 0 [0]
                    round 1 [1]
                    bevel 2 [2]
                ][
                    make error! "Unsupported Line Join"
                ]

                emit/with content 'j type
            ]

            set-miter-limit: func [
                limit [number!]
            ][
                emit/with content 'M limit
            ]

            set-dash-array: func [
                phase [number!]
                array [block!]
            ][
                assert [
                    parse array: reduce array [
                        any number!
                    ]
                ]

                emit/with content 'd [
                    array phase
                ]
            ]

            set-pen: func [
                color [integer! tuple!]
            ][
                case [
                    integer? color [
                        emit/with content 'G [
                            (max 0 min 100 color) / 100
                        ]
                    ]

                    3 = length-of color [
                        emit/with content 'RG color
                    ]

                    4 = length-of color [
                        emit/with content 'K color
                    ]
                ]
            ]

            set-fill: func [
                color [integer! tuple!]
            ][
                case [
                    integer? color [
                        emit/with content 'g [
                            (max 0 min 100 color) / 100
                        ]
                    ]

                    3 = length-of color [
                        emit/with content 'rg color
                    ]

                    4 = length-of color [
                        emit/with content 'k color
                    ]
                ]
            ]
        ]

        ; Returning the point at which additions began so as to permit
        ; isolation for other uses
        ;
        mark
    ]

    ; A page cannot exist outwith the context of a document
    ; It is dependent on the document for fonts, images and
    ; other resources
    ;
    add-page: func [
        document [object!]
        size [pair! word!]
        body [block!]
        /local page
    ][
        switch size [
            us-letter [
                size: 612x792
            ]

            a4 [
                size: 595x842
            ]
        ]

        assert [
            pair? size
        ]

        page: make prototype/page compose [
            id: register document self

            parent: reference-of document/pages

            size: (size)
            width: size/x
            height: size/y

            contents: make prototype/content [
                id: register document self
                length: 0
            ]

            graphics-state: reduce [
                make prototype/graphics-state []
            ]

            contents/stream: stream: make block! 0

            resources: make prototype/resource [
                font: make block! 0
                x-object: make block! 0
                procedure-set: copy [
                    /PDF /Text
                ]
            ]

            annotations: make block! 0
        ]

        add-content document page body

        append document/pages/kids page

        page
    ]

    add-font: func [
        [catch]
        document [object!]
        name [string!]
        spec [block!]

        /local font metrics
    ][
        if find document/fonts name [
            throw make error! "Font name already assigned"
        ]

        font: make prototype/font [
            id: register document self
            sub-type: /Type1
            source: _
        ]

        font/name: to refinement! trim/all copy name

        do-with spec [
            family: func [
                family [string!]
            ][
                font/family: trim/all copy family

                if switch font/family [
                    "Times" "TimesNewRoman" [
                        font/family: "Times"
                    ]

                    "Helvetica" "Arial" [
                        font/family: "Helvetica"
                    ]

                    "Courier" "CourierNew" [
                        font/family: "Courier"
                    ]

                    "Symbol" "ZapfDingbats" [
                        font/family: font/family
                    ]
                ][
                    font/is-standard: true
                ]

                font/family
            ]

            style: func [
                style [word!]
            ][
                style: switch style [
                    italic [
                        either find ["Helvetica" "Courier"] font/family [
                            "Oblique"
                        ][
                            "Italic"
                        ]
                    ]

                    oblique [
                        font/family = "Times" [
                            "Italic"
                        ][
                            "Oblique"
                        ]
                    ]
                ]

                font/style: style
            ]

            weight: func [
                weight [word!]
            ][
                font/weight: if weight = 'bold [
                    "Bold"
                ]
            ]

            source: func [
                file [file!]
            ][
                font/sub-type: /TrueType

                make error! "Embedded fonts not yet supported"
            ]
        ]

        assert [
            string? font/family
        ]

        font/base-font: to refinement! combine [
            font/family
            case [
                any [
                    font/weight
                    font/style
                ][
                    #"-"
                ]

                font/family == "Times" [
                    "-Roman"
                ]
            ]
            font/weight
            font/style
        ]

        if font/is-standard [
            metrics: fonts/metrics-for font/base-font

            font/widths: metrics/1
            font/kerning: metrics/2
            font/charset: make bitset! metrics/3
        ]

        repend document/fonts [
            font/name font
        ]

        font
    ]

    add-image: func [
        document [object!]
        name [refinement! issue!]
        spec [block!]

        /local image
    ][
        image: make prototype/image [
            id: register document self
        ]

        do-with spec [
            image: image
        ]

        assert [
            all [
                integer? image/width
                integer? image/height
            ]
        ]

        repend document/images [
            name image
        ]

        image
    ]

    add-pattern: func [
        document [object!]
        name [word!]
        size [pair!]
        spec [block!]

        /local pattern
    ][
        pattern: make prototype/pattern [
            id: register document self
        ]

        do-with spec [
            pattern: pattern
        ]

        repend document/patterns [
            name pattern
        ]

        pattern
    ]

    register: func [
        document [object!]
        value

        /local id
    ][
        id: document/last-id + 1:00

        repend document/registry [
            id value
        ]

        document/last-id: id
    ]

    create: func [
        body [block!]
        /local document
    ][
        document: make object! [
            index: make prototype/trailer []

            pages: _

            fonts: make block! 0
            images: make block! 0
            forms: make block! 0
            patterns: make block! 0
            actions: make block! 0

            last-id: 0:00

            registry: make map! 0
        ]

        document/index/root: make prototype/catalog [
            id: register document self

            document/pages: pages: make prototype/pages [
                id: register document self
                kids: make block! 0
            ]
        ]

        do-with body [
            info: func [
                spec [block!]
            ][
                add-info document spec
            ]

            add-page: func [
                size [pair! word!]
                content [block!]
            ][
                add-page document size content
            ]

            add-font: func [
                name [string!]
                spec [block!]
            ][
                add-font document name spec
            ]

            add-image: func [
                name [issue! refinement!]
                spec [block!]
            ][
                add-image document name spec
            ]

            add-pattern: func [
                name [word!]
                size [pair!]
                spec [block!]
            ][
                add-pattern document name size spec
            ]
        ]

        document
    ]

    render: func [
        document [object!]
        /compressed

        /local content xref xref-offset stream
    ][
        xref: make block! document/last-id/1

        content: tail copy header

        for-each [reference object] document/registry [
            append xref -1 + index? content

            content: insert content reduce [
                ; newline
                form reference/1 " " form reference/2 " obj^/"
            ]

            either object? object [
                assert [
                    word? in object 'template
                ]

                either not any [
                    object/type = 'page
                    not in object 'stream
                    none? object/stream
                ][
                    stream: switch/default type-of object/stream [
                        #(binary!) [
                            object/stream
                        ]
                    ][
                        formatter/form-value object/stream
                    ]

                    if compressed [
                        stream: compress stream 'zlib
                        stream: ascii85/encode copy stream
                    ]

                    object: form-of object
                    object/length: length-of stream

                    if compressed [
                        object/filter: [/A85 /FlateDecode]
                    ]

                    content: insert tail content reduce [
                        formatter/form-value object
                        "^/stream^/" stream "^/endstream"
                    ]
                ][
                    content: insert content formatter/form-value form-of object
                ]
            ][
                content: insert content formatter/form-value/only object
            ]

            content: insert content "^/endobj^/"
        ]

        xref-offset: index? content

        document/index/size: document/last-id/1 + 1

        content: insert content reduce [
            "^/xref^/0 " form document/index/size
            "^/0000000000 65535 f ^/"
        ]

        for-each offset xref [
            content: insert content reduce [
                formatter/pad-integer offset 10
                " 00000 n ^/"
            ]
        ]

        content: insert content reduce [
            "trailer^/"
            formatter/form-value form-of document/index
            "^/startxref^/"
            form xref-offset
            "^/%%EOF^/"
        ]

        head content
    ]
]
