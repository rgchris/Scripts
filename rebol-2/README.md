# Scripts for Rebol 2 (R2C)

This folder contains a collection of scripts for Rebol 2 extending the functionality of that platform. These additions include functions, algorithms, schemes, constructs, and expanded support for various file formats, all somewhat centered around digital publishing.

Rebol 2 is not under active development and newer operating systems/architectures no longer natively support Rebol 2 releases (said releases are over a decade old at the time of writing). As such, the contents of this folder are mostly of historical interest even if much of the code is still transferable and applicable to more recent iterations. On systems that run Rebol 2, this code should still function just fine.

## Shim

Many of the contained scripts require the presence of the SHIM script that includes patches, scheme, and expanded options to support a rudimentary module system. The SHIM can be evoked from a REBOL.R script present in either the home directory or the current working directory by adding the line:

    do %/path/to/shim.r

If a REBOL.R file doesn't already exist, it is just a regular Rebol script that can be created with a standard header:

    Rebol []

    do %/path/to/shim.r

(for more information on the REBOL.R file, see the [Startup Files](https://www.rebol.com/docs/core23/rebolcore-2.html#section-2.10) section of the Rebol Users Guide)


It is recommended that the SHIM file not be removed from this folder as it uses its location to establish a path to all other scripts herein.

Though some effort has been made to ensure backward compatibility with existing Rebol code, it's possible that some parts may break. In particular, the DO function has been patched in a way that precludes using DO with a FUNCTION! argument. In such cases, it is advisable to use APPLY instead.
