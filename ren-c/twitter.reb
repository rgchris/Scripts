Rebol [
    Title: "Twitter Client for Rebol"
    Author: ["Christopher Ross-Gill" "John Kenyon"]
    Date: 10-Jun-2013
    Home: http://ross-gill.com/page/Twitter_API_and_Rebol
    File: %twitter.reb
    Version: 0.3.8
    Purpose: {
        Rebol script to access and use the Twitter OAuth API.
        Warning: Currently configured to use HTTP only
        New user registration must be done using rebol 2 version
        This function will be updated when https is available (for Linux)
    }
    Rights: http://opensource.org/licenses/Apache-2.0
    Type: module
    Name: rgchris.twitter
    Exports: [twitter]
    Needs: [<webform> <json>]
    History: []
]

twitter: make object! bind [
    as: func [
        "Set current user"
        user [string!] "Twitter user name"
    ][
        either user: select users user [
            persona: make persona user
            persona/name
        ][
            either not error? user: try [register][
                repend users [
                    user/name
                    new-line/skip/all body-of user true 2
                ]
                persona/name
            ][do :user]
        ]
    ]

    save-users: func [
        "Saves authorized users"
        /to location [file! url!] "Alternate Storage Location"
    ][
        location: any [location settings/user-store]
        unless any [file? location url? location][
            make error! "No Storage Location Provided"
        ]
        save/header location new-line/skip/all users true 2 context [
            Title: "Twitter Authorized Users"
            Date: now/date
        ]
    ]

    authorized-users: func ["Lists authorized users"][extract users 2] 

    find: func [
        "Tweets by Search"
        query [string! issue! email!] "Search String"
        /size count [integer!] /page offset [integer!]
    ][ 
        case [
            issue? query [query: mold query]
            email? query [query: join-of "@" query/host]
        ]
        set words-of params reduce [query offset count]
        either attempt [
            result: to string! read join-of http://search.twitter.com/search.json? to-webform params
        ] load-result error/connection
    ]

    timeline: func [
        "Retrieve a User Timeline"
        /for user [string!] /size count [integer!] /page offset [integer!]
    ][
        unless persona/name error/credentials

        set words-of options reduce [
            any [:user persona/name _]
            any [if integer? :count [min 200 abs count] _]
            any [:offset _]
        ]

        either do [
            result: send/with 'get %1.1/statuses/user_timeline.json options
        ] load-result error/connection
    ]

    home: friends: func [
        "Retrieve status messages from friends"
        /size count [integer!] /page offset [integer!]
    ][
        unless persona/name error/credentials

        set words-of options reduce [
            _
            all [count min 200 abs count]
            offset
        ]

        either attempt [
            result: send/with 'get %1.1/statuses/home_timeline.json options
        ] load-result error/connection
    ]

    update: func [
        "Send Twitter status update"
        status [string!] "Status message"
        /reply "As reply to" id [issue!] "Reply reference" /override
    ][
        override: either override [200][140]
        unless persona/name error/credentials
        unless all [0 < length? status override > length? status] error/invalid
        set words-of message reduce [
            status
            any [:id _]
        ]
        either attempt [
            result: send/with 'post %1.1/statuses/update.json message
        ] load-result error/connection
    ]

] make object! [ ; internals
    config: case [
        block? system/script/args [
            make object! system/script/args
        ]

        file? system/script/args [
            make object! load system/script/args
        ]

        exists? %twitter.config.reb [
            make object! load %twitter.config.reb
        ]

        /else [
            do make error! "No Configuration Provided"
        ]
    ]

    root: config/twitter

    settings: make make object! [
        twitter: consumer-key: consumer-secret: users: _
    ][
        consumer-key: config/consumer-key
        consumer-secret: config/consumer-secret
    ]

    users: config/users

    options: make object! [screen_name: count: page: _]
    params: make object! [q: page: rpp: _]
    message: make object! [status: in_reply_to_status_id: _]

    result: _
    load-result: [load-json result]

    error: [
        credentials [do make error! "User must be authorized to use this application"]
        connection [do make error! "Unable to connect to Twitter"]
        invalid [do make error! "Status length should be between between 1 and 140"]
    ]

    persona: context [
        id: name: _
        token: secret: _
    ]

    oauth!: context [
        oauth_callback: _
        oauth_consumer_key: settings/consumer-key
        oauth_token: oauth_nonce: _
        oauth_signature_method: "HMAC-SHA1"
        oauth_timestamp: _
        oauth_version: 1.0
        oauth_verifier: oauth_signature: _
    ]

    send: use [make-nonce timestamp sign][
        make-nonce: does [
            enbase/base checksum/secure to binary! join-of form now/precise settings/consumer-key 64
        ]

        timestamp: func [/for date [date!]][
            date: any [:date now]
            date: form any [
                attempt [to integer! difference date 1-Jan-1970/0:0:0]
                date - 1-Jan-1970/0:0:0 * 86400.0
            ]
            clear find/last date "."
            date
        ]

        sign: func [
            method [word!]
            lookup [url!]
            oauth [object! block! blank!]
            params [object! block! blank!]
            /local out
        ][
            out: copy ""

            oauth: any [oauth make oauth! []]
            oauth/oauth_nonce: make-nonce
            oauth/oauth_timestamp: timestamp
            oauth/oauth_token: persona/token

            params: sort/skip unique/skip collect [
                for-each [key value] body-of make oauth any [:params []][
                    keep to word! key
                    keep switch/default type-of value [
                        issue! [to string! to word! value]
                    ][
                        value
                    ]
                ]
            ] 2 2

            oauth/oauth_signature: enbase/base checksum/secure/key to binary! rejoin [
                uppercase form method "&" replace/all url-encode form lookup "%5f" "_" "&"
                replace/all replace/all url-encode replace/all to-webform params "+" "%20" "%5f" "_" "%255F" "_"
            ] rejoin [
                settings/consumer-secret "&" any [persona/secret ""]
            ] 64

            foreach [header value] body-of oauth [
                if value [
                    repend out [", " form to string! to word! header {="} url-encode form value {"}]
                ]
            ]

            join-of "OAuth" next out
        ]

        send: func [
            method [word!] lookup [file!]
            /auth oauth [object!]
            /with params [object!]
        ][
            lookup: join-of dirize root lookup
            oauth: make oauth! any [:oauth []]
            if object? :params [params: body-of params ]

            switch method [
                put delete [
                    params: compose [method: (uppercase form method) (any [params []])]
                    method: 'post
                ]
            ]

            switch method [
                get [
                    method: compose/deep [
                        get [ Authorization: (sign 'get lookup oauth params) ]
                    ] 
                    if params [
                        params: context sort/skip params 2
                        append lookup to-webform/prefix params
                    ]
                ]
                post put delete [
                    method: compose/deep [
                        (method) [
                            Authorization: (sign method lookup oauth params)
                            Content-Type: "application/x-www-form-urlencoded"
                        ]
                        (either params [to-webform params][""]) 
                    ]
                ]
            ]
            lookup: to string! write lookup method
        ]
    ]

    register: use [request-broker access-broker verification-page][
        request-broker: %oauth/request_token
        verification-page: %oauth/authorize?oauth_token=
        access-broker: %oauth/access_token

        func [
            /requester request [function!]
            /local response verifier
        ][
            request: any [:request :ask]
            set words-of persona _

            response: load-webform send/auth 'post request-broker make oauth! [
                oauth_callback: "oob"
            ]

            persona/token: response/oauth_token
            persona/secret: response/oauth_token_secret

            browse join-of twitter-url/:verification-page response/oauth_token 
            unless verifier: request "Enter your PIN from Twitter: " [
                make error! "Not a valid PIN"
            ]

            response: load-webform send/auth 'post access-broker make oauth! [
                oauth_verifier: trim/all verifier
            ]

            persona/id: to-issue response/user_id
            persona/name: response/screen_name
            persona/token: response/oauth_token
            persona/secret: response/oauth_token_secret

            persona
        ]
    ]
]
