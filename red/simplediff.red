Red [
	Title: "SimpleDiff"
	Author: "Christopher Ross-Gill"
	Date: 25-Aug-2016
	Home: https://github.com/paulgb/simplediff
	File: %simplediff.red
	Version: 1.1.0
	Purpose: "Identify the differences between two series"
	Rights: http://opensource.org/licenses/Apache-2.0
	Type: module
	Name: rgchris.simplediff
	Exports: [diff]
	Comment: {
		Based on Simple Diff for Python, CoffeeScript v0.1
		(C) Paul Butler 2008 <http://www.paulbutler.org/>
	}
	History: [
		25-Aug-2016 1.1.0 "Tweaked to be compatible with Ren/C and Red"
		22-May-2014 1.0.0 "Original Version"
	]
	Usage: [
		probe diff probe [a b c d]   probe [b c d e]
		probe diff probe [a b c d]   probe [e f g h d]
		probe diff probe [a b c d]   probe [e f g h]
		probe diff probe [A B c D]   probe [a b c d]
		probe diff probe ["A" "B" "c" "D"]   probe ["a" "b" "c" "d"]
		probe diff probe [a b b b c] probe [a b b b b c]
		probe diff
			probe parse "you might say that, I couldn't possibly comment" none
			probe parse "You may wish to say that, couldn't possibly comment either way." none
	]
]

diff: func [
	{
		Find the differences between two blocks. Returns a block of pairs, where the first value
		is in [+ - =] and represents an insertion, deletion, or no change for that list.
		The second value of the pair is the element.
	}
	before [block! string!] after [block! string!]
	/local items-before starts-before starts-after run this-run test tests limit
][
	unless all [equal? type? before type? after][
		make error! "Before and After values must be of the same type."
	]

	run: 0

	; Build a map with elements from 'before as keys, and
	; each position starting with each element as values.
	items-before: make map! 0

	forall before [
		append/only any [
			select items-before first before
			put items-before first before make block! 0
		] before
	]

	; Find the largest subseries common to before and after
	forall after [
		if tests: select items-before first after [
			limit: length? after

			foreach test tests [
				repeat offset min limit length? test [
					this-run: :offset
					unless test/:offset == after/:offset [
						this-run: offset - 1
						break
					]
				]

				if this-run > run [
					run: :this-run
					starts-before: :test
					starts-after: :after
				]
			]
		]
	]

	new-line/all/skip collect [
		either zero? run [
			; If no common subseries is found, assume that an
			; insert and delete has taken place

			unless tail? before [keep reduce ['- before]]
			unless tail? after [keep reduce ['+ after]]
		][
			; Otherwise he common subseries is considered to have no change, and we
			; recurse on the text before and after the substring

			keep diff copy/part before starts-before copy/part after starts-after
			keep reduce ['= copy/part starts-after run]
			keep diff copy skip starts-before run copy skip starts-after run
		]
	] true 2
]
