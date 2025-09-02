Ren-C Scripts (archive)
=======================

These scripts were targeted to embryonic iterations of the [Ren-C](https://github.com/metaeducation/ren-c) fork of Rebol 3 (ca. 2014-2019). That project has since veered significantly away from Rebol syntax and semantics leaving this folder offering but a mere glimpse into its formative age. Of note, subtle changes from Rebol that I found to be beneficial:

* The addition of the literal `_` for NONE! values. This has proven effective on syntactic, semantic, and cognitive levels providing a subtle and intuitve solution to a longstanding omission in Rebol grammar. Surveying code and data—technically the same thing in Rebol—is greatly enhanced by this change and should be a part of the Rebol lexical canon
* PARSE did not require a full match to return a positive result, rather it returned the position of progress. This obviated the need to perform a complete match of a series, and brought PARSE in line with other Rebol core functions.
* Renaming of core compoenents and functions in pursuit of greater consistency/rationality. Datatype renaming, such as STRING! → TEXT!, PAREN! → GROUP!, NONE! → BLANK!, reflects a shift towards more semantically appropriate nomenclature. So too renaming functions such as FOR-EACH to bring it line those of a similar purpose: REMOVE-EACH and MAP-EACH

---

At the time of writing, Ren-C is an ongoing concern and is delving into the depths of how the Rebol concept can adapt to more fundamental, atomic computing domains. No version of Ren-C that I know of will run these scripts—it's possible to find some commit or other from that time period that might fit the bill; though even then, the platform was something of a moving target to develop for.
