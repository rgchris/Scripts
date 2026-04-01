Rebol [
    Title: "Color Lab"
    Author: "Christopher Ross-Gill"
    Date: 25-Nov-2003
    Version: 0.2.0
    File: %color-lab.reb
    
    Purpose: "Manipulate colour values in the HSV and HSL color spaces"

    Home: http://www.ross-gill.com/
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.color-lab

    Exports: [
        color-lab
    ]
]

color-lab: context [
    rgb: context [
        to-hsv: func [
            "Converts an RGB colour into an HSV colour."

            color [tuple!]
            "The RGB colour to be converted."

            /local r g b a h s v mn mx delta
        ][
            r: color/1 / 255
            g: color/2 / 255
            b: color/3 / 255

            if not a: color/4 [
                a: 0
            ]

            mn: first find-min reduce [
                r g b
            ]

            v:
            mx: first find-max reduce [
                r g b
            ]

            delta: mx - mn

            either zero? delta [
                h: 0
                s: 0
            ][
                s: delta / mx

                h: 60 * case [
                    r = mx [
                        (g - b) / delta
                    ]

                    g = mx [
                        2 + ((b - r) / delta)
                    ]

                    b = mx [
                        4 + ((r - g) / delta)
                    ]
                ]

                if negative? h [
                    h: h + 360
                ]
            ]

            reduce [
                h s v a
            ]
        ]

        to-hsl: func [
            "Converts an RGB colour into an HSV colour."

            color [tuple!]
            "The RGB colour to be converted."

            /local r g b a h s v c f mn mx delta
        ][
            r: color/1 / 255
            g: color/2 / 255
            b: color/3 / 255

            if not a: color/4 [
                a: 0
            ]

            v: max max r g b
            c: v - min min r g b
            f: 1 - abs v + v - c - 1

            h: case [
                zero? c 0

                v = r [
                    g - b / c
                ]

                v = g [
                    b - r / c + 2
                ]

                v = b [
                    r - g / c + 4
                ]
            ]

            reduce [
                h // 6 * 60
                either zero? f [f] [c / f]
                v + v - c / 2
                a
            ]
        ]

        from-hsv: _
        from-hsl: _

        colorize: func [
            "Modifies the Hue value of an RGB color"

            color [tuple!]
            "Color to be modified"

            factor [tuple! integer!]
            "Hue from color (TUPLE!), increase/decrease hue (INTEGER!)"

            /local hsv hsv-new
        ][
            hsv: to-hsv color

            either tuple? factor [
                hsv-new: rgb/to-hsv factor

                if hsv-new/2 <> 0 [
                    hsv/1: hsv-new/1
                ]
            ][
                hsv/1: hsv/1 + factor
            ]

            hsv/1: remainder hsv/1 360

            if negative? hsv/1 [
                hsv/1: hsv/1 + 360
            ]

            from-hsv hsv
        ]

        negate: func [
            "Negates the brightness of an RGB color"

            color [tuple!]
            "The color to negate"

            /local hsv
        ][
            hsv: to-hsv color

            hsv/1: either hsv/1 < 180 [
                hsv/1 + 180
            ][
                hsv/1 - 180
            ]

            hsv/3: 1 - hsv/3

            from-hsv hsv
        ]
    ]

    hsv: context [
        to-rgba: func [
            "Converts an HSV colour into an RGBA colour."

            color [block!]
            "The HSV colour to be converted. H: 0-360 S: 0-1 V: 0-1"

            /local h s v a r g b i f
        ][
            h: color/1
            s: color/2
            v: color/3

            if not a: color/4 [
                a: 0
            ]

            either zero? s [
                r:
                g:
                b: v
            ][
                h: h // 360 / 60
                i: to integer! h
                f: h - i

                switch/default i [
                    0 [
                        r: v
                        g: v * (1 - (s * (1 - f)))
                        b: v * (1 - s)
                    ]

                    1 [
                        r: v * (1 - (s * f))
                        g: v
                        b: v * (1 - s)
                    ]

                    2 [
                        r: v * (1 - s)
                        g: v
                        b: v * (1 - (s * (1 - f)))
                    ]

                    3 [
                        r: v * (1 - s)
                        g: v * (1 - (s * f))
                        b: v
                    ]

                    4 [
                        r: v * (1 - (s * (1 - f)))
                        g: v * (1 - s)
                        b: v
                    ]
                ][
                    r: v
                    g: v * (1 - s)
                    b: v * (1 - (s * f))
                ]
            ]

            to tuple! reduce [
                round/to min 255 max 0 (r * 255) 1
                round/to min 255 max 0 (g * 255) 1
                round/to min 255 max 0 (b * 255) 1
                a
            ]
        ]

        to-rgb: func [
            "Converts an HSV colour into an RGBA colour."

            color [block!]
            "The HSV colour to be converted. H: 0-360 S: 0-1 V: 0-1"
        ][
            color: to-rgba color

            to tuple! reduce [
                color/1
                color/2
                color/3
            ]
        ]

        from-rgb: _
    ]

    hsl: context [
        to-rgba: func [
            "Converts an HSV colour into an RGBA colour."

            color [block!]
            "The HSV colour to be converted. H: 0-360 S: 0-1 V: 0-1"

            /local h s v a r g b z f k
        ][
            h: color/1
            s: color/2
            v: color/3

            if not a: color/4 [
                a: 0
            ]

            z: s * min v 1 - v

            f: func [
                n
            ][
                k: modulo n + divide h 30 12
                v - multiply z max -1 min 1 min k - 3 9 - k
            ]

            r: f 0
            g: f 8
            b: f 4

            to tuple! reduce [
                round/to min 255 max 0 (r * 255) 1
                round/to min 255 max 0 (g * 255) 1
                round/to min 255 max 0 (b * 255) 1
                a
            ]
        ]

        to-rgb: func [
            "Converts an HSV colour into an RGBA colour."

            color [block!]
            "The HSV colour to be converted. H: 0-360 S: 0-1 V: 0-1"
        ][
            color: to-rgba color

            to tuple! reduce [
                color/1
                color/2
                color/3
            ]
        ]

        from-rgb: _
    ]

    rgb/from-hsv: get in hsv 'to-rgba
    rgb/from-hsl: get in hsl 'to-rgba
    hsv/from-rgb: get in rgb 'to-hsv
    hsl/from-rgb: get in rgb 'to-hsl
]
