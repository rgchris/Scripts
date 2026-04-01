Rebol [
    Title: "Easings"
    Author: "Christopher Ross-Gill"
    Date: 26-Mar-2026
    Version: 1.0.0
    File: %easings.reb

    Home: https://github.com/rgchris/Scripts

    Purpose: "Collection of easing functions for transitions"

    Type: module
    Name: rgchris.easings
    Exports: [
        easings
    ]

    Comment: [
        "All functions accept a value between 0 and 1 and return a value between 0 and 1"

        https://github.com/sFrady20/easy-mesh-gradient/blob/main/lib/src/easings.ts
        {
        Adapted from 'Easings' for 'Easy Mesh Gradient' by @sFrady20
        Copyright (c) 2026, Steven Frady. MIT License
        }
    ]
]

easings: context [
    linear: func [
        x [number!]
    ][
        x
    ]

    quadratic-ease-in: func [
        "Ease in quadratic - slow start, accelerating."
        x [number!]
    ][
        x ** 2
    ]

    quadratic-ease-out: func [
        "Ease out quadratic - fast start, decelerating."
        x [number!]
    ][
        1 - power 1 - x 2
    ]

    quadratic-ease-in-out: func [
        "Ease in-out quadratic - slow start and end, fast middle."
        x
    ][
        either x < .5 [
            2 * x * x
        ][
            1 - divide power -2 * x + 2 2 2
        ]
    ]

    cubic-ease-in: func [
        "Ease in cubic - slow start, accelerating."
        x [number!]
    ][
        power x 3
    ]

    cubic-ease-out: func [
        "Ease out cubic - fast start, decelerating."
        x [number!]
    ][
        1 - power 1 - x 3
    ]

    cubic-ease-in-out: func [
        "Ease in-out cubic - slow start and end, fast middle."
        x [number!]
    ][
        either x < .5 [
            4 * power x 3
        ][
            1 - divide power -2 * x + 2 3 2
        ]
    ]

    sine-ease-in-out: func [
        "Ease in-out sine - smooth, natural motion."
        x
    ][
        divide 0 - subtract cosine/radians pi * x 1 2
    ]

    expo-ease-in-out: func [
        "Ease in-out exponential - very smooth, dramatic transitions."
        x [number!]
    ][
        case [
            x = 0.0 0.0
            x = 1.0 1.0

            x < 0.5 [
                divide power 2 20 * x - 10 2
            ]

            #else [
                divide 2 - power 2 -20 * x + 10 2
            ]
        ]
    ]

    show-shapes: func [
        ""
        x [number!]
    ][
        either .6 > x .4 0
    ]
]
