# Assertion-based testing with Quickcheck





## Introduction

Quickcheck was originally a package for the language Haskell aiming to simplify the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package. Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into, and R is no different. The main ideas retained are that tests are based on assertions and that the developer should not have to specify the specific inputs and output values of a test. The difference from Haskell is that the user needs to specify the type of each argument to a function with the optional possibility to fully specify its distribution. The main function in the package, `unit.test`, will randomly generate input values, execute the function to be tested and verify an assertion about the input output relation. The advantages are multiple:

  - each test can be run multiple times on different data points, improving coverage and ability to detect bugs;
  - test can run on large size inputs, possible but impractical in non-randomized testing;
  - assertions are more self-documenting that specific examples of the I/O relation. In fact, enough assertions can constitute a specfication for the function being tested (that's why Quickcheck is sometimes said to implement specifcation-based testing, which I hink is setting a discouraginly high bar for no reason).
  
## First example

Let's start with something very simple. Let's say we just wrote the function identity. Using the widley used testing package `testhat`, one would like to write a test like:


```r
library(testthat)
test_that("identity test", expect_identical(identity(x), x))
```

That in general doesn't work because `x` is not defined. What was intended was something like a quantifier *for all legal values of `x`*, but there isn't any easy way of doing that. So a developer has to enter some values for `x`.


```r
for(x in c(1L, 1, list(1), NULL, factor(1)))
  test_that("identity test", expect_identical(identity(x),x))
```

But there is no specific reason to pick those specific examples, testing on more data  points would increase the clutter factor, a developer may inadvertently select values known to work already, using larger values would also increase clutter etc. `quickcheck` can solve or at lease alleviate all those problems


```r
library(quickcheck)
unit.test(assertion = function(x) identical(identity(x), x), generators = list(rinteger))
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```

What this means is that we have tested `identity` for this assertion on random integer vectors. We don't have to write them down one by one and later we will see how we can affect the distribution of such vectors, to make them potentially huge in size and contained values. We can also repeat the test multiple times on different values with the least amount of effort, in fact, we have already repeated the test 10 times, which is the default. But if 100 times is required, no problem:


```r
unit.test(assertion = function(x) identical(identity(x), x), generators = list(rinteger), sample.size = 100)
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```

Done! You see, if you had to write down those 100 integer vectors one by one, you'd never have time to. But, you may object, `identity` is not supposed to work only on integer vectors, why did you test only on those? That was just a starter indeed. Quickcheck contains a whole repertoire of random data generators, including `rinteger`, `rdouble`, `rcharacter` etc for most atomic types, and some also for non-atomic types such as `rlist` and `rdata.frame`. Notable omissions are `rmatrix` (in the works) and `rfunction` (not any time soon). The library is easy to extend with your own gernerators (for instance, `rnorm` works out of the box) and offers a number of constructors for data generators such as `constant` and `mixture`. In partocular, there is a generator `rany` that creates a mixture of all R types (in practice, the ones that `quickcheck` currently knows how to generate, but it's defined in the most general way). That is what we need for our identity test.


```r
unit.test(assertion = function(x) identical(identity(x), x), generators = list(rany), sample.size = 100)
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```


## Ways to define assertions

## Ways to define random data generators

## Advanced topics


```r
unit.test(function(l) unit.test(function(x,y) {x + y; TRUE}, list(fun(rdouble(size = constant(l))), fun(rdouble(size = constant(l))))), list(rinteger))
```

```
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (x, y)  \n { \n     x + y \n     TRUE \n } \n"
[1] "Pass  function (l)  \n unit.test(function(x, y) { \n     x + y \n     TRUE \n }, list(fun(rdouble(size = constant(l))), fun(rdouble(size = constant(l))))) \n"
```

```
[1] TRUE
```
