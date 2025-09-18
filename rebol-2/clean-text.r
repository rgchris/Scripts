Rebol [
    Title: "Clean Text"
    Author: "Christopher Ross-Gill"
    Date: 22-Dec-2015
    Version: 0.2.0
    File: %clean.r

    Purpose: "Trims and Converts Errant CP-1252 to UTF-8"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: r2c.clean-text
    Exports: [
        clean-text
    ]

    Needs: [
        shim
        r2c:bincode
    ]

    History: [
        22-Dec-2015 0.2.0
        "Added /Lines"

        14-Aug-2013 0.1.1
        "Original Version"
    ]
]

clean-text: use [
    codepages codepage cleaner lines?
][
    codepages: [
        cp-1252 [
            128 #{E282AC} 130 #{E2809A} 131 #{C692} 132 #{E2809E}
            133 #{E280A6} 134 #{E280A0} 135 #{E280A1} 136 #{CB86}
            137 #{E280B0} 138 #{C5A0} 139 #{E280B9} 140 #{C592}
            142 #{C5BD} 145 #{E28098} 146 #{E28099} 147 #{E2809C}
            148 #{E2809D} 149 #{E280A2} 150 #{E28093} 151 #{E28094}
            152 #{CB9C} 153 #{E284A2} 154 #{C5A1} 155 #{E280BA}
            156 #{C593} 158 #{C5BE} 159 #{C5B8} 160 #{C2A0}
            161 #{C2A1} 162 #{C2A2} 163 #{C2A3} 164 #{C2A4}
            165 #{C2A5} 166 #{C2A6} 167 #{C2A7} 168 #{C2A8}
            169 #{C2A9} 170 #{C2AA} 171 #{C2AB} 172 #{C2AC}
            173 #{C2AD} 174 #{C2AE} 175 #{C2AF} 176 #{C2B0}
            177 #{C2B1} 178 #{C2B2} 179 #{C2B3} 180 #{C2B4}
            181 #{C2B5} 182 #{C2B6} 183 #{C2B7} 184 #{C2B8}
            185 #{C2B9} 186 #{C2BA} 187 #{C2BB} 188 #{C2BC}
            189 #{C2BD} 190 #{C2BE} 191 #{C2BF} 192 #{C380}
            193 #{C381} 194 #{C382} 195 #{C383} 196 #{C384}
            197 #{C385} 198 #{C386} 199 #{C387} 200 #{C388}
            201 #{C389} 202 #{C38A} 203 #{C38B} 204 #{C38C}
            205 #{C38D} 206 #{C38E} 207 #{C38F} 208 #{C390}
            209 #{C391} 210 #{C392} 211 #{C393} 212 #{C394}
            213 #{C395} 214 #{C396} 215 #{C397} 216 #{C398}
            217 #{C399} 218 #{C39A} 219 #{C39B} 220 #{C39C}
            221 #{C39D} 222 #{C39E} 223 #{C39F} 224 #{C3A0}
            225 #{C3A1} 226 #{C3A2} 227 #{C3A3} 228 #{C3A4}
            229 #{C3A5} 230 #{C3A6} 231 #{C3A7} 232 #{C3A8}
            233 #{C3A9} 234 #{C3AA} 235 #{C3AB} 236 #{C3AC}
            237 #{C3AD} 238 #{C3AE} 239 #{C3AF} 240 #{C3B0}
            241 #{C3B1} 242 #{C3B2} 243 #{C3B3} 244 #{C3B4}
            245 #{C3B5} 246 #{C3B6} 247 #{C3B7} 248 #{C3B8}
            249 #{C3B9} 250 #{C3BA} 251 #{C3BB} 252 #{C3BC}
            253 #{C3BD} 254 #{C3BE} 255 #{C3BF}
        ]

        macroman [
            128 #{C384} 129 #{C385} 130 #{C387} 131 #{C389}
            132 #{C391} 133 #{C396} 134 #{C39C} 135 #{C3A1}
            136 #{C3A0} 137 #{C3A2} 138 #{C3A4} 139 #{C3A3}
            140 #{C3A5} 141 #{C3A7} 142 #{C3A9} 143 #{C3A8}
            144 #{C3AA} 145 #{C3AB} 146 #{C3AD} 147 #{C3AC}
            148 #{C3AE} 149 #{C3AF} 150 #{C3B1} 151 #{C3B3}
            152 #{C3B2} 153 #{C3B4} 154 #{C3B6} 155 #{C3B5}
            156 #{C3BA} 157 #{C3B9} 158 #{C3BB} 159 #{C3BC}
            160 #{E280A0} 161 #{C2B0} 162 #{C2A2} 163 #{C2A3}
            164 #{C2A7} 165 #{E280A2} 166 #{C2B6} 167 #{C39F}
            168 #{C2AE} 169 #{C2A9} 170 #{E284A2} 171 #{C2B4}
            172 #{C2A8} 173 #{E289A0} 174 #{C386} 175 #{C398}
            176 #{E2889E} 177 #{C2B1} 178 #{E289A4} 179 #{E289A5}
            180 #{C2A5} 181 #{C2B5} 182 #{E28882} 183 #{E28891}
            184 #{E2888F} 185 #{CF80} 186 #{E288AB} 187 #{C2AA}
            188 #{C2BA} 189 #{CEA9} 190 #{C3A6} 191 #{C3B8}
            192 #{C2BF} 193 #{C2A1} 194 #{C2AC} 195 #{E2889A}
            196 #{C692} 197 #{E28988} 198 #{E28886} 199 #{C2AB}
            200 #{C2BB} 201 #{E280A6} 202 #{C2A0} 203 #{C380}
            204 #{C383} 205 #{C395} 206 #{C592} 207 #{C593}
            208 #{E28093} 209 #{E28094} 210 #{E2809C} 211 #{E2809D}
            212 #{E28098} 213 #{E28099} 214 #{C3B7} 215 #{E2978A}
            216 #{C3BF} 217 #{C5B8} 218 #{E28184} 219 #{E282AC}
            220 #{E280B9} 221 #{E280BA} 222 #{EFAC81} 223 #{EFAC82}
            224 #{E280A1} 225 #{C2B7} 226 #{E2809A} 227 #{E2809E}
            228 #{E280B0} 229 #{C382} 230 #{C38A} 231 #{C381}
            232 #{C38B} 233 #{C388} 234 #{C38D} 235 #{C38E}
            236 #{C38F} 237 #{C38C} 238 #{C393} 239 #{C394}
            240 #{EFA3BF} 241 #{C392} 242 #{C39A} 243 #{C39B}
            244 #{C399} 245 #{C4B1} 246 #{CB86} 247 #{CB9C}
            248 #{C2AF} 249 #{CB98} 250 #{CB99} 251 #{CB9A}
            252 #{C2B8} 253 #{CB9D} 254 #{CB9B} 255 #{CB87}
        ]
    ]

    cleaner: use [
        here ascii utf2 utf-3 utf-4 utf-b
    ][
        ; Simplistic UTF-8 spec
        ;
        ascii: charset [#"^(00)" - #"^(0C)" #"^(0E)" - #"^(7F)"]
        utf-2: charset [#"^(C2)" - #"^(DF)"]
        utf-3: charset [#"^(E0)" - #"^(EF)"]
        utf-4: charset [#"^(F0)" - #"^(F4)"]
        utf-b: charset [#"^(80)" - #"^(BF)"]

        [
            ; OK
            ;
            ascii
            |
            utf-2 utf-b
            |
            utf-3 2 utf-b
            |
            utf-4 3 utf-b
            |
            ; Not OK
            ;
            here:
            [
                #"^M"
                (
                    here: either lines? [
                        remove here
                    ][
                        next here
                    ]
                )
                |
                skip
                (
                    here: change/part here any [
                        select/case codepage to integer! here/1
                        #{EFBFBD}
                        "<?>"
                    ] 1
                )
            ]
            :here
        ]
    ]

    clean-text: func [
        "Convert Windows 1252 characters in a string to UTF-8"

        string [any-string!]
        "String to convert"

        /as
        page [word!]

        /lines
        "Also Clean Line Endings"
    ][
        lines?: :lines

        codepage: select codepages either as [
            page
        ][
            'cp-1252
        ]

        parse/all string [
            any cleaner
        ]

        string
    ]
]
