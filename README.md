# Receptor Marker [![Travis-CI Build Status](https://travis-ci.org/nsh87/receptormarker.svg?branch=dev)](https://travis-ci.org/nsh87/receptormarker)

## Installation

This package should be installed directly from GitHub using the `devtools`
package. The Bioconductor package `muscle` is a dependency that must be
installed first - follow [Bioconductor's
instructions](https://bioconductor.org/packages/release/bioc/html/muscle.html).
Then, to install `receptormarker`:

```R
install.packages("devtools")
devtools::install_github('nsh87/receptormarker')
```

## Further Note

This package is currently only tested on Unix (Linux/Mac OS X) environments.
Functionality in Windows might be limited due to the unavailability of Windows
binaries for included analytical tools.

We will not be making `receptormarker` available through CRAN or Bioconductor.
We include a number of dependencies and binary files used for analysis (such
as HMMER and standalone BLAST) so that the user does not need to have these
tools previously installed on his or her computer. This eases use of the package
but also prevents it from conforming to CRAN's guidelines.

## Development

Fork the repository, branch from `dev`, and submit your branch changes with a
pull request to `dev`.

To get started, make sure you have the latest version of R and RStudio
installed. It is strongly suggested - nay, required - that you have installed
the following packages in order to develop:

```R
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "htmlwidgets"))
devtools::install_github('jimhester/lintr')  # Do not install from CRAN
```

You also need to install `muscle` from Bioconductor (see link in Installation).

Clone this repo and load **receptormarker.Rproj** to open the project in
RStudio. Then load the code:

```R
devtools::load_all()
```

Be sure to follow this [code tyle](http://r-pkgs.had.co.nz/r.html#style
"Hadley Wickham's Modified Google R Style Guide")
 and [document your functions](http://r-pkgs.had.co.nz/man.html "Documenting
with Roxygen2").  If you create any functions that are internal and not of
interest to most users, be sure to document them with `@keywords internal` to
exclude them from the package index. You should explicitly
[define functions to
export](http://r-pkgs.had.co.nz/namespace.html#exports "Namespacing in R")
to NAMESPACE with Roxygen2's `@export` tag. Build .Rd files from Roxygen2
comments with:

```R
devtools::document()
```

It is strongly suggested that you [automate
testing](http://r-pkgs.had.co.nz/tests.html "Writing Tests for R") of all
functions written. Run all tests with:

```R
devtools::test()
```

Before submitting a pull request you should build the documentation, run tests, 
and check that the package builds. This can be done with a single command:

```R
devtools::check(cran=FALSE)
```

Note that we are not checking the package `--as-cran` since we have included
HMMER and BLAST+ binaries and CRAN does not allow executable binaries in
packages.

You can also load the package and then test functions after running:

```R
devtools::install()
library(receptormarker)
```

Installing the package is not required to run many functions locally, but for
any functions that use `htmlwidgets` this is a necessary step.
