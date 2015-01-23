quickcheck
==========

This package provides support for randomized  software testing for R. Inspired by its influential Haskell namesake, it promotes a style of writing tests base were assertions about function are verified on random inputs. The package provides default generators for most common types but allows to modify their behavior or even to create new ones based on the needs of a each application. The main advantages over traditional testing are

 * Each test can be run many times, with better coverage and bug detection.
 * Tests can be run on large inputs that would be unwieldy to include in the test source or would require addtional development.
 * Assertions are more self-documenting that individual examples of the I/O relation, and in some instances can amount to a complete specification for a function.
 * The developer is less likely to incorporate unstated assumptions in the choice of test inputs.



Install with:

```
library(devtools)
install_github("RevolutionAnalytics/quickcheck@master", subdir = "pkg")`
```

See the [tutorial](docs/tutorial.md)