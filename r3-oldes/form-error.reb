Rebol [
    Title: "Form Error"
    Author: "Christopher Ross-Gill"
    Date: 6-Feb-2017
    Version: 1.0.0
    File: %form-error.reb

    Purpose: "Pretty prints an error"

    Home: https://github.com/rgchris/Scripts
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.form-error
    Exports: [
        form-error
    ]

    History: [
        6-Feb-2017 1.0.0
        "Original Version"
    ]
]

form-error: func [
    reason [error! object!]

    /local
    type message
][
    if error? :reason [
        reason: to object! :reason
    ]

    type: system/catalog/errors/(reason/type)/type

    message: compose [
        (system/catalog/errors/(reason/type)/(reason/id))
    ]

    message: reform bind message reason

    rejoin [
        "** " type ": " message
        "^/** Where: " copy/part mold reason/where 100
        "^/** Near: " copy/part mold reason/near 100
    ]
]

