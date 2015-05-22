

quickcheck
==========


This package provides support for randomized  software testing for R. Inspired by its influential [Haskell namesake](http://www.eecs.northwestern.edu/~robby/courses/395-495-2009-fall/quick.pdf), it promotes a style of writing tests where assertions about functions are verified on random inputs. The package provides default generators for most common types but allows users to modify their behavior or even to create new ones based on the needs of a each application. The main advantages over traditional testing are

 * Each test can be run many times, with better coverage and bug detection.
 * Tests can be run on large inputs that would be unwieldy to include in the test source or would require addtional development.
 * Assertions are more self-documenting than individual examples of the I/O relation, and in some instances can amount to a complete specification for a function.
 * The developer is less likely to incorporate unstated assumptions in the choice of test inputs.

Additional features include the `repro` function that supports reproducing and debugging a failed test. For additional information, see the [tutorial](docs/tutorial.md). For support, we are [monitoring](http://stackoverflow.com/questions/tagged/r+quickcheck) tags [R] [quickcheck] on [Stackoverflow](http://stackoverflow.com). Please remember to add *both* tags to your question. For new releases, subscribe to `quickcheck`'s Release notes [feed](https://github.com/RevolutionAnalytics/quickcheck/releases.atom) or by [email](https://feedburner.google.com/fb/a/mailverify?uri=ReleaseNotesFromQuickcheck&amp;loc=en_US)

To install, first install and load `devtools`

```
install.packages(devtools)
library(devtools)
```



Then, to install from source:

```
install_github("RevolutionAnalytics/quickcheck@3.5.0", subdir = "pkg")
```

Linux package:

```
install_url(
  "https://github.com/RevolutionAnalytics/quickcheck/releases/download/3.5.0/quickcheck_3.5.0.tar.gz")
```

Windows package:

```
install_url(
  "https://github.com/RevolutionAnalytics/quickcheck/releases/download/3.5.0/quickcheck_3.5.0.zip")
```

The current version is 3.5.0 .

While this package was first developed to support the activities of the RHadoop project, it's not part of it nor related to Hadoop or big data. While it has been in use for a few years to test packages used in production, version 3.0.0 marks the first version of the project that's offered for general use and as such it went through a major API re-design. Hence, versions 3.x.y should be considered beta  releases and no backward compatibility guarantees are offered, as it is customary in [semantic versioning](http://semver.org) for 0.x.y releases. We will switch to the normal major/minor/hotfix releases from version 4.
