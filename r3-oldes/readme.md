This folder contains various modules for [Rebol 3 by Oldes](https://github.com/oldes/Rebol3).

# Installation

There is more than one way to install these modules, here are two suggestions:

* Clone this repostory, then symlink this folder into the Rebol Home folder.

      git clone https://github.com/rgchris/Scripts.git ./rgchris-scripts
      ln -s rgchris-scripts/r3-oldes $REBOL_HOME/modules/rgchris

* Extract the [zip archive](https://github.com/rgchris/Scripts/archive/refs/heads/master.zip) and copy the `r3-oldes` folder as `$REBOL_HOME/modules/rgchris`

---

Once the folder is in place, the module system can be added to `%user.reb` either by adding `Needs: [%modules/rgchris/core.reb]` to the header, or `import %modules/rgchris/core.reb` within the body. This enables the `r3:...` scheme which binds all other modules within this folder.

*`%user.reb` is an optional script contained within the `REBOL_HOME` folder. For more detail on how `REBOL_HOME` is determined, see [this discussion](https://github.com/Oldes/Rebol3/discussions/131).*

# Usage

Once the core module has been invoked, all other modules can be added using the `r3:...` scheme. Note that no suffix is required:

    Rebol [
        Title: "My Script"
        Needs: [
            r3:rgchris:html
        ]
    ]

    load-html "<h1>Foo"

# Style Guide

Scripts in this folder adhere as close as possible to the 'Plan +4' model: Values are separated by one space or new lines, except containers where spaces can be omitted after an opening character and before a closing character (e.g. `one [(two)] three`), and between two blocks where the closing character and opening character of the two blocks appear on the same line by themselves. Full words are used, not abbreviations. 'Rebol' uses initial capitals, as do the set-words in headers. Much effort has been made to limit the number of evaluative operations per line, preferably to one (also for PARSE directives).

The module `r3:rgchris:clean-script` can aid in adopting this style (in most cases, it is a non-destructive code formatter), however please refer to ['More than Just Code—A Deep Lake'](https://www.rebol.com/article/0103.html) for limitations on any automatic code formatting.

# Scripts

The modules contained within this folder are intended to be self-contained with minimal dependencies. More detailed documentation to follow.

## `r3:rgchris:core`

Contains functions useful across this folder's modules.

* **NEATEN**

  A shorthand wrapper for NEW-LINE. Has various methods for common operations:

  ```rebol
  neaten [one two three]

  => [
      one
      two
      three
  ]
  ```

  ```rebol
  neaten/flat [
      one
      two
      three
  ]

  => [one two three]
  ```

  ```rebol
  neaten/pipes [
      one two | three four
  ]

  => [
      one two
      |
      three four
  ]
  ```

* **AMASS**

  Creates a MAP! containing words and their associated value:

  ```rebol
  amass [zero pi newline]

  => #[
      zero: 0
      pi: 3.14159265358979
      newline: #"^/"
  ]
  ```

* **COLLECT-EACH**

  A shorthand wrapper for COLLECT and FOREACH:

  ```rebol
  collect-each month system/locale/months [
      if #"J" == month/1 [
          keep month
      ]
  ]

  => ["January" "June" "July"]
  ```

* **COLLECT-WHILE**

  A shorthand wrapper for COLLECT and WHILE:

  ```rebol
  number: 0

  collect-while [
      number < 5
  ][
      keep number: number + 1
  ]

  => [1 2 3 4 5]
  ```

* **FLATTEN**

  De-nest values from a block containing blocks:

  ```rebol
  flatten [one [two [three]]]

  => [one two three]
  ```

* **FOLD**

  Apply a function to block of values:

  ```rebol
  fold [1 2 3 4] :add

  => 10
  ```

  ```rebol
  fold/initial [1 2 3 4] :add 100.0 

  => 110.0
  ```

* **PRIVATE**

  Binds a block to a private context:

  ```rebol
  reduce private [one: 1] [one]

  => [1]
  ```

* **R3 Module Resources Scheme**

  This is a scheme designed to offer access to modules and their associated files. In this iteratation, it is loosely mapped to filenames within the `$REBOL_HOME/modules/` folder (this may change):

  ```rebol
  import r3:rgchris:html
  read r3:rgchris:readme.txt
  ```

  Additionally, it offers an unambiguous access to system modules heretofore accessed by word:

  ```rebol
  Needs: [r3:xml]
  import r3:xml
  ```

## `r3:rgchris:altxml`

Legacy XML handler (from Rebol 2). Use of this module directly is not recommended.

## `r3:rgchris:ascii85`

```
import r3:rgchris:ascii85
```

Ascii85 Encoder/Decoder

## `r3:rgchris:bincode`

```
import r3:rgchris:bincode
```

Encode/Decode primitive values from a binary source

## `r3:rgchris:clean-script`

```
import r3:rgchris:clean-script
```

Rebol Script Formatter

## `r3:rgchris:clean`

```
import r3:rgchris:clean
```

Converts binary to string handling errant CP-1252 codepoints

## `r3:rgchris:collect-deep`

```
import r3:rgchris:collect-deep
```

Procedural deep-container constructor

## `r3:rgchris:combine`

```
import r3:rgchris:combine
```

Nuanced string concatenation

## `r3:rgchris:curl`

```
import r3:rgchris:curl
```

Wrapper for CURL command

## `r3:rgchris:dates`

```
import r3:rgchris:dates
```

Extended date handling

## `r3:rgchris:deflate`

```
import r3:rgchris:deflate
```

pull-streaming, iterative Deflate decoder

## `r3:rgchris:diff`

```
import r3:rgchris:diff
```

Detect difference between two series

## `r3:rgchris:do-with`

```
import r3:rgchris:do-with
```

Accumulative context creator

## `r3:rgchris:dom`

```
import r3:rgchris:dom
```

Document Object Model and support functions

## `r3:rgchris:eke`

```
import r3:rgchris:eke
```

Attempts to eke a value of given type from given input value

## `r3:rgchris:form error`

```
import r3:rgchris:form error
```

Pretty prints an error

## `r3:rgchris:html`

```
import r3:rgchris:html
```

HTML decoder/unpacker

## `r3:rgchris:int58`

```
import r3:rgchris:int58
```

Int58 decoder/encoder

## `r3:rgchris:iterate`

```
import r3:rgchris:iterate
```

Iterator API; core iterators

## `r3:rgchris:meta-db`

```
import r3:rgchris:meta-db
```

Simple associative database

## `r3:rgchris:octal`

```
import r3:rgchris:octal
```

Octal notation decoder/encoder

## `r3:rgchris:png`

```
import r3:rgchris:png
```

PNG Tools

## `r3:rgchris:rsp`

```
import r3:rgchris:rsp
```

Rebol hypertext pre-processor

## `r3:rgchris:sanitize`

```
import r3:rgchris:sanitize
```

HTML/XML sanitizer

## `r3:rgchris:scheme-capture`

```
import r3:rgchris:scheme-capture
```

Capture output

## `r3:rgchris:svg`

```
import r3:rgchris:svg
```

SVG Packer/Unpacker

## `r3:rgchris:utf-8`

```
import r3:rgchris:utf-8
```

UTF-8 decoder/encoder/tools

## `r3:rgchris:uuid`

```
import r3:rgchris:uuid
```

UUID Generator

## `r3:rgchris:zip`

```
import r3:rgchris:zip
```

Zip packer/unpacker
