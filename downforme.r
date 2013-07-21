REBOL [
	Title: "Is It Down?"
	Date: 31-May-2013
	Version: 1
	Author: "Christopher Ross-Gill"
]

either all [
	url? target: system/script/args
	target: select decode-url target quote host:
	answer: attempt [read join http://www.downforeveryoneorjustme.com/ target]
][
	print "Brought to you by http://www.downforeveryoneorjustme.com/"
	print either find to string! answer "It's Just You" ["It's Up"]["It's Down"]
][
	print "Address No Good, Sorry..."
]