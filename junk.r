REBOL [
	Title: "Junk"
	Date:  28-Feb-2013
	Author: "Christopher Ross-Gill"
]

load-junk: func [data [string!]][
	data: to binary! data
	collect [
		data: transcode/error data while [0 <> length? data][
			keep data/1 data: either not error? data/1 [
				next data
			][
				transcode/error data/2
			]
		]
	]
]