Rebol [
    Title: "Make Feed"
    Author: "Christopher Ross-Gill"
    Date: 12-Jun-2013
    File: %make-feed.r3
    Version: 1.0.0
    Purpose: "Create an Atom Feed."
    Needs: [
        %form-date.r3
        %rsp.r3
    ]
    Usage: [
        make-feed reduce [
            make object! [
                Title: "Feed Name"
                ID: Home: http://www.example.com/
                Link: http://www.example.com/our.feed
                Subtitle: "Describes this Feed"
                Updated: none
            ]

            make object! [
                Title: "Journal Éntry title...."
                ID: Link: http://www.example.com/some/page/or/other
                Author: "Somebody"
                Published: Modified: 30-Dec-2004/12:00-9:00
                Description: {Entry HTML goes here...}
            ]
        ]
    ]
]

make-feed: use [feed.rsp entry.rsp][
    feed.rsp: trim/auto {
        <?xml version='1.0' encoding='UTF-8'?>
        <feed xmlns='http://www.w3.org/2005/Atom'
              xml:base='<%== header/home %>'
              xml:lang='en-us'>

        <title><%== header/title %></title>
        <id><%== header/id %></id>
        <link href='<%== header/home %>' />
        <link rel='self' href='<%== form header/link %>' />
        <updated><%= form-date/gmt any [header/updated now] "%c" %></updated>
        <subtitle><%== header/subtitle %></subtitle>

        <%= render-each entry feed entry.rsp %>
        </feed>
    }

    entry.rsp: trim/auto {
        <entry>
            <title><%== entry/title %></title>
            <link href='<%= entry/link %>' />
            <id><%== entry/id %></id>
            <author><name><%== entry/author %></name></author>
            <published><%= form-date/gmt entry/published "%c" %></published>
            <updated><%= form-date/gmt entry/modified "%c" %></updated>
            <content type='html'><%== entry/description %></content>
        </entry>
    }

    make-feed: func [feed [block!] /local header][
        header: take feed: copy feed
        render/with feed.rsp [header feed entry.rsp]
    ]
]
