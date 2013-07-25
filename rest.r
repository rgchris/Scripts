[

REBOL [
	Title: "Service-oriented HTTP Protocol"
	Date: 24-Jul-2013
	Author: "Christopher Ross-Gill"
	; Type: 'module
	Version: 0.0.1
	File: %rest.r
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
