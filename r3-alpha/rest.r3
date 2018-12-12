[

Rebol [
	Title: "Service-oriented HTTP Protocol"
	Author: "Christopher Ross-Gill"
	Date: 24-Jul-2013
	Home: http://ross-gill.com/page/REST_Protocol
	File: %rest.r3
	Version: 0.0.1
	Type: module
	Name: rgchris.rest
	Usage: [
		read [
			scheme: 'rest
			url: http://www.ross-gill.com/
		]

		write [
			scheme: 'rest
			method: 'post
			type: 'webform
			url: http://somewhere-to-write/target
		][
			some data
		]
	]
	Notes: {
		Rebol 3 Alpha does not have a working CALL and thus this module as-is
		cannot sit upon the shell version of cURL.
	}
]

sys/make-scheme [
	Title: "Service-oriented HTTP Protocol"
	Name: 'rest

	Actor: [
		open: funct [port][
			probe port/spec
		]

		read: funct [port][
			open port
		]
	]
]

]
