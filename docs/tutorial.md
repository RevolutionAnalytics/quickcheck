# Assertion-based testing with Quickcheck





## Introduction

Quickcheck was originally a package for the language Haskell aiming to simplify the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package. Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into. In R, the main ideas retained are that tests are based on assertions and that the developer should not have to specify the inputs and output values of a test. The difference from Haskell is that the user needs to specify the type of each variable in an assertion with the optional possibility to fully specify its distribution. The main function in the package, `test`, will randomly generate input values, execute the assertion and collect results. The advantages are multiple:

  - each test can be run multiple times on different data points, improving coverage and the ability to detect bugs, at no additional cost for the developer;
  - tests can run on large size inputs, possible but impractical in non-randomized testing;
  - assertions are more self-documenting than specific examples of the I/O relation -- in fact, enough assertions can constitute a specification for the function being tested, but that's not necessary for testing to be useful;
  - it's less likely for the developer to use implicit assumptions in the selection of testing data -- randomized testing "keeps you honest".
  
## First example

Let's start with something very simple. Let's say we just wrote the function `identity`. Using the widely used testing package `testthat`, one would like to write a test like:


```r
library(testthat)
```


```r
test_that("identity test", expect_identical(identity(x), x))
```

That in general doesn't work because `x` is not defined. What was meant was something like a quantifier *for all legal values of `x`*, but there isn't any easy way of implementing that. So a developer has to enter some values for `x`.



```r
for(x in c(1L, 1, list(1), NULL, factor(1)))
  test_that("identity test", expect_identical(identity(x),x))
rm(x)
```

But there is no good reason to pick those specific examples, testing on more data  points or larger values would increase the clutter factor, a developer may inadvertently inject unwritten assumptions in the choice of data points etc. `quickcheck` can solve or at least alleviate all those problems:


```r
library(quickcheck)
test(assertion = function(x) identical(identity(x), x), generators = list(rinteger))
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```

We have supplied an assertion, that is a function returning a length-one logical vector, where `TRUE` means *passed* and `FALSE` means *failed*, and a list of generators, one for each argument of the assertion -- use named or positional arguments as preferred.
What this means is that we have tested `identity` for this assertion on random integer vectors. We don't have to write them down one by one and later we will see how we can affect the distribution of such vectors, to make them say large in size or value, or more likely to hit corner cases. We can also repeat the test multiple times on different values with the least amount of effort, in fact, we have already executed this test 10 times, which is the default. But if 100 times is required, no problem:


```r
test(assertion = function(x) identical(identity(x), x), generators = list(rinteger), sample.size = 100)
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```

Done! You see, if you had to write down those 100 integer vectors one by one, you'd never have time to. But, you may object, `identity` is not supposed to work only on integer vectors, why did we test only on those? That was just a starter indeed. Quickcheck contains a whole repertoire of random data generators, including `rinteger`, `rdouble`, `rcharacter` etc. for most atomic types, and some also for non-atomic types such as `rlist` and `rdata.frame`. The library is easy to extend with your own generators and offers a number of constructors for data generators such as `constant` and `mixture`. In particular, there is a generator `rany` that creates a mixture of all R types (in practice, the ones that `quickcheck` currently knows how to generate, but the intent is all of them). That is exactly what we need for our identity test.


```r
test(assertion = function(x) identical(identity(x), x), generators = list(rany), sample.size = 100)
```

```
[1] "Pass  function (x)  \n identical(identity(x), x) \n"
```

```
[1] TRUE
```

Now we have more confidence that `identity` works for all types of R objects.

## Defining assertions

Unlike `testhat` where you need to construct specially defined *expectations*, `quickcheck` accepts run of the mill logical-valued functions, with a length-one return value. For example `function(x) all(x + 0 == x)` or `function(x) identical(x, rev(rev(x)))` are valid assertions -- independent of their success or failure. If an assertion returns TRUE, it is considered a success. If an assertion returns FALSE or generates an error, it is  considered a failure. For instance, `stop` is a valid assertion but always fails. How do I express the fact that this is its correct behavior? `testthat` has a rich set of expectations to capture that and other requirements, such as printing something or generating a warning. Derived from those, `quickcheck` has a rich set of predefined assertions, returned by the function `assert`:


```r
test(
  function(x) assert("error", stop(x)), 
  list(rcharacter))
```

```
[1] "Pass  function (x)  \n assert(\"error\", stop(x)) \n"
```

```
[1] TRUE
```

By executing this test successfully we have built confidence that the function `stop` will generate an error whenever called with any `character` argument. There are predefined `quickcheck` assertion defined for each `testthat` expectation, with a name equal to the `testthat` expectation, without the "expect_" prefix. We don't see why you'd ever want to use `assert("equal", ...)`, but we threw it in for completeness. Since writing assertions is a very common endeavor when developing with quickcheck, there is an alternate short syntax for doing so, using formulas. The above example becomes:


```r
test(
  ~assert("error", stop(x)), 
  list(rcharacter))
```

```
[1] "Pass  ~assert(\"error\", stop(x)) \n"
```

```
[1] TRUE
```

## What to do when tests fail

`quickcheck` doesn't fix bugs for you, but tries to get you started in a couple of ways. The first is its output:


```r
test(~mean(x) > 0, list(x = rdouble))
```

```
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
```

```
Error:
load("/Users/antonio/Projects/Revolution/quickcheck/docs/./quickcheck8386b707758")
```

Its output shows that about half of the default 10 runs have failed and then invites us to load some debugging data. Another way to get at that data is to run the test with the option `stop = FALSE` which doesn't produce an error. This is convenient for interactive sessions, but less so when running `R CMD check`.


```r
test(~mean(x) > 0, list(x = rdouble), stop = FALSE)
```

```
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
```

```
$assertion
~mean(x) > 0

$env
NULL

$cases
$cases[[1]]
NULL

$cases[[2]]
$cases[[2]]$x
[1] -0.4115  0.2522 -0.8919  0.4357 -1.2375 -0.2243  0.3774  0.1333  0.8042


$cases[[3]]
$cases[[3]]$x
[1]  0.50361  1.08577 -0.69095 -1.28460  0.04673 -0.23571 -0.54289 -0.43331
[9] -0.64947


$cases[[4]]
$cases[[4]]$x
 [1]  1.1519  0.9922 -0.4295  1.2383 -0.2793  1.7579  0.5607 -0.4528
 [9] -0.8320 -1.1666 -1.0656 -1.5638


$cases[[5]]
$cases[[5]]$x
 [1]  0.83205 -0.22733  0.26614 -0.37670  2.44136 -0.79534 -0.05488
 [8]  0.25014  0.61824 -0.17262 -2.22390 -1.26361  0.35873


$cases[[6]]
$cases[[6]]$x
[1] -0.94065 -0.11583 -0.81497  0.24226 -1.42510  0.36594  0.24841  0.06529
[9]  0.01916


$cases[[7]]
$cases[[7]]$x
 [1] -0.6490 -0.1192  0.6641  1.1010  0.1438 -0.1178 -0.9121 -1.4376
 [9] -0.7971  1.2541


$cases[[8]]
NULL

$cases[[9]]
NULL

$cases[[10]]
NULL
```

The output is a list with three elements:

  - the assertion that failed
  - a list of in-scope variables that could have affected the result -- this is work in progress and shouldn't be trusted at this time
  - a list of arguments passed to the assertion
  
My recommendation is to write assertions that depend exclusively on their arguments and are deterministic functions, and leave all the randomness to `quickcheck` and its generators. This is because the first step in fixing a bug is almost always to reproduce it, and non-deterministic bugs are more difficult to reproduce. The `test` function seeds the random number generator so that every time it is called it will rerun the same test, that is call the assertion with the same arguments, run after run. So I guess we should call it pseudo-random testing to be precise. Let's go in more detail on the `cases` element. It is a list with an element for each run, which has a value of `NULL`, if the run was successful, and a list of arguments passed to the assertion otherwise. In this case runs 2 through 7 failed. We can replicate it as follows.


```r
test.out = test(function(x) mean(x) > 0, list(rdouble), stop = FALSE)
```

```
[1] "FAIL: assertion: function (x)  mean(x) > 0"
[1] "FAIL: assertion: function (x)  mean(x) > 0"
[1] "FAIL: assertion: function (x)  mean(x) > 0"
[1] "FAIL: assertion: function (x)  mean(x) > 0"
[1] "FAIL: assertion: function (x)  mean(x) > 0"
[1] "FAIL: assertion: function (x)  mean(x) > 0"
```

```r
do.call(test.out$assertion, test.out$cases[[3]])
```

```
[1] FALSE
```

At this point we can use `debug` or any other debugging technique and modify our code until the assertion returns true. If the assertion is a formula, evaluating it is a little more complicated, therfore you can use the function `repro` for both formulas and functions:


```r
repro(test.out$assertion, test.out$cases[[3]])
```

```
[1] FALSE
```

```r
test.out = test(~mean(x) > 0, list(x = rdouble), stop = FALSE)
```

```
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
[1] "FAIL: assertion: ~mean(x) > 0"
```

```r
repro(test.out$assertion, test.out$cases[[3]])
```

```
[1] FALSE
```


## Modifying or defining random data generators

There are built in random data generators for most built-in data types. They follow a simple naming conventions, "r" followed by the class name. For instance `rinteger` generates a random integer vector. Another characteristic of random data generators as defined in this package is that they have defaults for every argument, that is they can be called without arguments. Finally, the return value of different calls are statistically independent. For example


```r
rdouble()
```

```
 [1] -0.50806 -0.20738 -0.39281 -0.31999 -0.27911  0.49419 -0.17733
 [8] -0.50596  1.34304 -0.21458 -0.17956 -0.10019  0.71267 -0.07356
```

```r
rdouble()
```

```
[1] -0.68166 -0.32427  0.06016 -0.58889  0.53150 -1.51839  0.30656 -1.53645
[9] -0.30098
```

As you can see, both elements and length change from one call to the next and in fact they are both random and independent. This is generally true for all generators, with the exception of the trivial generators created with `constant`. Most generators take two arguments, `element` and `size` which are meant to specify the distribution of the elements and size of the returned data structures and whose exact interpretation depends on the specific generator. In general, if the argument `element` is a value it is construed as a desired expectation of the elements of the return value, if it is a function, it is called with a single argument to generate the elements of the random data structure. For example


```r
rdouble()
```

```
[1] -0.6521 -0.0569 -1.9144  1.1766 -1.6650 -0.4635 -1.1159 -0.7508
```
generates some random double vector. The next expression does the same but with an expectation equal to 100

```r
rdouble(element = 100)
```

```
 [1] 100.02  98.71  98.36 100.45  99.98  99.68  99.07  98.51  98.92 101.00
[11]  99.38  98.62 101.87 100.43  99.76 101.06
```
and finally this extracts the elements from a uniform distribution with all parameters at default values.

```r
rdouble(runif)
```

```
 [1] 0.26788 0.76215 0.98631 0.29361 0.39935 0.81213 0.07715 0.36370
 [9] 0.44259 0.15671 0.58221 0.97016
```

The same is true for argument `size`. If not a function, it's construed as a length expectation, otherwise it is called with a single argument equal to 1 to generate a random length.

First form:

```r
rdouble(size = 1)
```

```
[1] -0.9290 -0.2942 -0.6150 -0.9471
```

```r
rdouble(size = 1)
```

```
[1] -0.03473
```

Second form:
```
rdouble(size = function(x) 10 * runif(x))
rdouble(size = function(x) 10 * runif(x))
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`. Nested data structures have an argument `height`. All of these are intended to be expectations as opposed to deterministic values but can be replaced by a generator, which gives you total control. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:

```r
rdouble(size = constant(3))
```

```
[1] 0.7876 2.0752 1.0274
```

```r
rdouble(size = constant(3))
```

```
[1]  1.2079 -1.2313  0.9839
```

The function returned by `constant(x)` is itself a generator, that we can use when we want to specify a deterministic value for a test:


```r
test(function(x, y) all(abs(x)/y == Inf), generators = list(rdouble, constant(0))) 
```

```
[1] "Pass  function (x, y)  \n all(abs(x)/y == Inf) \n"
```

```
[1] TRUE
```

Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. Another simple constructor is `select` which creates a generator that picks randomly from a list, provided as argument -- not unlike `sample`, but consistent with the `quickcheck` definition of generator.


```r
select(1:5)()
```

```
[1] 5
```

```r
select(1:5)()
```

```
[1] 3
```

When passing generators to `test`, one needs to pass a function, not a data set, so to provide custom arguments to generators one needs a little bit of functional programming, namely function `Curry` from package `functional`. If `rdouble(element = 100)` generates data from the desired distribution, then a test would use it as follow


```r
library(functional)
test(function(x) sum(x) > 100, list(Curry(rdouble, element = 100)))
```

```
[1] "Pass  function (x)  \n sum(x) > 100 \n"
```

```
[1] TRUE
```

Note the the last two tests only pass with high probability. Sometimes accepting a high probability of passing is  a shortcut to writing an effective, simple test when a deterministic one is not available. Since currying is common when using `quickchek`, we thought of providing an alternate syntax using formulas. The last example would become


```r
library(functional)
test(function(x) sum(x) > 100, list(~rdouble(element = 100)))
```

```
[1] "Pass  function (x)  \n sum(x) > 100 \n"
```

```
[1] TRUE
```

Whether it's better, it's probably a matter of taste, but we find it looks more like the actual call that's going to generate the data and it works better with completion at the R prompt and in Rstudio.




Whether it's better
## Advanced topics

### Composition of generators and tests as assertions

The alert reader may have already noticed how generators can be used to define other generators. For instance, a random list of double vectors can be generated with `rlist(rdouble)` and a list thereof with `rlist(function() rlist(rdouble))`. Composition can also be applied to tests, which can be used as assertions inside other tests. One application of this is developing a test that involves two random vectors of the same random length. There isn't a built in way in quickcheck to express this dependency between arguments, but the solution is not far using the composability of tests. We first pick a random length in the "outer" test, then use it to generate equal length vectors in the "inner" test.


```r
test(
	function(l) 
		test(
			function(x,y) 
				isTRUE(all.equal(x, x + y - y)), 
			list(
				~rdouble(size = constant(l)), 
				~rdouble(size = constant(l)))), 
	list(~rinteger(size = constant(1))))
```

```
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (x, y)  \n isTRUE(all.equal(x, x + y - y)) \n"
[1] "Pass  function (l)  \n test(function(x, y) isTRUE(all.equal(x, x + y - y)), list(~rdouble(size = constant(l)),  \n     ~rdouble(size = constant(l)))) \n"
```

```
[1] TRUE
```

### Custom generators

There is not reason to limit oneself to built in generators and one can do much more than just change the parameters. For instance, we may want to 
make sure that extremes of the allowed range are hit more often than the built-in generators ensure. For instance, `rdouble` uses by default a standard normal, and values like 0 and Inf have very small or 0 probability of occurring. Let's say we want to test the following assertion about the ratio:


```r
is.self.reverse = function(x) isTRUE(all.equal(x, 1/(1/x)))
```

We can have two separate tests, one for values returned by `rdouble`:


```r
test(is.self.reverse, list(rdouble))
```

```
[1] "Pass  function (x)  \n isTRUE(all.equal(x, 1/(1/x))) \n"
```

```
[1] TRUE
```

and one for the corner cases:

```r
test(is.self.reverse, list(select(c(0, -Inf, Inf))))
```

```
[1] "Pass  function (x)  \n isTRUE(all.equal(x, 1/(1/x))) \n"
```

```
[1] TRUE
```

That's a start, but the two type of values never mix in the same vector. We can combine the two with a custom generator


```r
rdoublex = 
	function(element = 100, size = 10) {
		data = rdouble(element, size)
		sample(
			c(data, c(0, -Inf, Inf)), 
			size = length(data), 
			replace = FALSE)}
rdoublex()
```

```
 [1] 100.92  99.96 101.12 100.82 100.74  99.38   -Inf  97.79 100.39  99.98
[11] 101.51 100.58 100.59 100.94
```

```r
rdoublex()
```

```
[1]  98.62   0.00  99.61 100.39    Inf  99.59  99.90  99.95
```
		
And use it in a more general test.


```r
test(is.self.reverse, list(rdoublex))
```

```
[1] "Pass  function (x)  \n isTRUE(all.equal(x, 1/(1/x))) \n"
```

```
[1] TRUE
```
