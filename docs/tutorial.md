# Assertion-based testing with Quickcheck





## Introduction

Quickcheck was originally a package for the language Haskell aiming to simplify the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package. Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into. In R, the main ideas retained are that tests are based on assertions and that the developer should not have to specify the inputs and output values of a test. The difference from Haskell is that the user needs to specify the type of each variable in an assertion with the optional possibility to fully specify its distribution. The main function in the package, `test`, will randomly generate input values, execute the assertion and collect results. The advantages are multiple:

  - each test can be run multiple times on different data points, improving coverage and the ability to detect bugs, at no additional cost for the developer;
  - tests can run on large size inputs, possible but impractical in non-randomized testing;
  - assertions are more self-documenting than specific examples of the I/O relation -- in fact, enough assertions can constitute a specification for the function being tested, but that's not necessary for testing to be useful;
  - it is less likely for the developer to use implicit assumptions in the selection of testing data -- randomized testing "keeps you honest".
  
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
test(function(x = rinteger()) identical(identity(x), x))
```

```
Pass  
 function (x = rinteger())  
 identical(identity(x), x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  18900   19300   19600   21000   20100   29300 
```

We have supplied an assertion, that is a function with defaults for each argument, at least some set using random data generators, and returning a length-one logical vector, where `TRUE` means *passed* and `FALSE` means *failed*.
What this means is that we have tested `identity` for this assertion on random integer vectors. We don't have to write them down one by one and later we will see how we can affect the distribution of such vectors, to make them say large in size or value, or more likely to hit corner cases. We can also repeat the test multiple times on different values with the least amount of effort, in fact, we have already executed this test 10 times, which is the default. But if 100 times is required, no problem:


```r
test(function(x = rinteger()) identical(identity(x), x), sample.size = 100)
```

```
Pass  
 function (x = rinteger())  
 identical(identity(x), x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  17900   19700   20100   20700   20600   56800 
```

Done! You see, if you had to write down those 100 integer vectors one by one, you'd never have time to. But, you may object, `identity` is not supposed to work only on integer vectors, why did we test only on those? That was just a starter indeed. Quickcheck contains a whole repertoire of random data generators, including `rinteger`, `rdouble`, `rcharacter` etc. for most atomic types, and some also for non-atomic types such as `rlist` and `rdata.frame`. The library is easy to extend with your own generators and offers a number of constructors for data generators such as `constant` and `mixture`. In particular, there is a generator `rany` that creates a mixture of all R types (in practice, the ones that `quickcheck` currently knows how to generate, but the intent is all of them). That is exactly what we need for our identity test.


```r
test(function(x = rany()) identical(identity(x), x), sample.size = 100)
```

```
Pass  
 function (x = rany())  
 identical(identity(x), x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  17000   19400   20100   21300   21800   46100 
```

Now we have more confidence that `identity` works for all types of R objects. 


## Defining assertions

Unlike `testhat` where you need to construct specially defined *expectations*, `quickcheck` accepts run of the mill logical-valued functions, with a length-one return value. For example `function(x) all(x + 0 == x)` or `function(x) identical(x, rev(rev(x)))` are valid assertions -- independent of their success or failure. If an assertion returns TRUE, it is considered a success. If an assertion returns FALSE or generates an error, it is  considered a failure. For instance, `function(x = rcharacter()) stop()` is a valid assertion but always fails. How do I express the fact that this is its correct behavior? `testthat` has a rich set of expectations to capture that and other requirements, such as printing something or generating a warning. Derived from those, `quickcheck` has a rich set of predefined assertions, returned by the function `expect`:


```r
test(
  function(x = rcharacter()) expect("error", stop(x)))
```

```
Pass  
 function (x = rcharacter())  
 expect("error", stop(x)) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
2000000 2160000 2390000 2530000 2450000 4410000 
```

By executing this test successfully we have built confidence that the function `stop` will generate an error whenever called with any `character` argument. There are predefined `quickcheck` assertions defined for each `testthat` expectation, with a name equal to the `testthat` expectation, without the "expect_" prefix. We don't see why you'd ever want to use `expect("equal", ...)`, but we threw it in for completeness. 

## What to do when tests fail

`quickcheck` doesn't fix bugs for you, but tries to get you started in a couple of ways. The first is its output:


```r
test(function(x = rdouble()) mean(x) > 0, stop = TRUE)
```

```
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
```

```
Error:
load("/Users/antonio/Projects/Revolution/quickcheck/docs/./quickcheck3efe56cd8d12")
```

Its output shows that about half of the default 10 runs have failed and then invites us to load some debugging data. Another way to get at that data is to run the test with the option `stop = FALSE` which doesn't produce an error. This is convenient for interactive sessions, but less so when running `R CMD check`. In fact, the default for the `stop` argument is `FALSE` for interactive sessions and `TRUE` otherwise, which should work for most people.


```r
test.out = test(function(x = rdouble()) mean(x) > 0, stop = FALSE)
```

```
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
```

```r
test.out
```

```
$assertion
function (x = rdouble()) 
mean(x) > 0

$env
NULL

$cases
$cases[[1]]
$cases[[1]]$x
 [1]  -32.6233  132.9799  127.2429   41.4641 -153.9950  -92.8567  -29.4720
 [8]   -0.5767  240.4653   76.3593  -79.9009 -114.7657  -28.9462  -29.9215
[15]  -41.1511   25.2223  -89.1921   43.5683 -123.7538  -22.4268   37.7396
[22]   13.3336   80.4190   -5.7107   50.3608  108.5769


$cases[[2]]
$cases[[2]]$x
[1] -128.5


$cases[[3]]
$cases[[3]]$x
[1] -23.57 -54.29 -43.33 -64.95


$cases[[4]]
$cases[[4]]$x
 [1]  115.19   99.22  -42.95  123.83  -27.93  175.79   56.07  -45.28
 [9]  -83.20 -116.66 -106.56 -156.38  115.65   83.20


$cases[[5]]
$cases[[5]]$x
[1]  26.61 -37.67


$cases[[6]]
$cases[[6]]$x
 [1]  -79.534   -5.488   25.014   61.824  -17.262 -222.390 -126.361
 [8]   35.873   -1.105  -94.065  -11.583  -81.497   24.226 -142.510
[15]   36.594   24.841    6.529    1.916   25.734  -64.901  -11.917
[22]   66.414  110.097   14.377  -11.775  -91.207 -143.759  -79.709
[29]  125.408   77.214  -21.952  -42.481  -41.898   99.699  -27.578
[36]  125.602   64.667  129.931  -87.326


$cases[[7]]
$cases[[7]]$x
[1] -88.09  59.63  11.97 -28.22


$cases[[8]]
$cases[[8]]$x
 [1]   22.902   99.654   78.186  -77.678  -61.599    4.658 -113.039
 [8]   57.672 -128.075  162.545  -50.070  167.830  -41.252  -97.229
[15]    2.538    2.748 -168.018  105.375 -111.960   33.562   49.480
[22]   13.805  -11.879   19.768 -106.869  -80.321 -111.377  158.009
[29]  149.782


$cases[[9]]
$cases[[9]]$x
[1] -123.2901   -0.3724  151.1672  -47.5698   79.7916  -97.4003   68.9373


$cases[[10]]
$cases[[10]]$x
numeric(0)



$pass
 [1]  TRUE FALSE FALSE  TRUE FALSE FALSE FALSE FALSE  TRUE    NA

$elapsed
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  25600   26200   27000   29100   29500   40200 
```

The output is a list with five elements:

  - the assertion that failed
  - a list of in-scope variables that could have affected the result -- this is work in progress and shouldn't be trusted at this time
  - a list of arguments passed to the assertion
  
My recommendation is to write assertions that depend exclusively on their arguments and are deterministic functions, and leave all the randomness to `quickcheck` and its generators. This is because the first step in fixing a bug is almost always to reproduce it, and non-deterministic bugs are more difficult to reproduce. The `test` function seeds the random number generator so that every time it is called it will rerun the same tests, that is call the assertion with the same arguments, run after run. So I guess we should call it pseudo-random testing to be precise. Let's go in more detail on the `cases` element. It is a list with an element for each run, which has a value of `NULL`, if the run was successful, and a list of arguments passed to the assertion otherwise. In this case runs 2 through 7 failed. We can replicate it as follows.


```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > 0)(x = -128.459935387219)
debug: mean(x) > 0
exiting from: (function (x = rdouble()) 
mean(x) > 0)(x = -128.459935387219)
```

```
[1] FALSE
```

This opens the debugger at the beginning of a failed call to the assertion. Now it is up to the developer.

## Modifying or defining random data generators

There are built in random data generators for most built-in data types. They follow a simple naming conventions, "r" followed by the class name. For instance `rinteger` generates a random integer vector. Another characteristic of random data generators as defined in this package is that they have defaults for every argument, that is they can be called without arguments. Finally, the return value of different calls are statistically independent. For example""


```r
rdouble()
```

```
numeric(0)
```

```r
rdouble()
```

```
numeric(0)
```

As you can see, both elements and length change from one call to the next and in fact they are both random and independent. This is generally true for all generators, with the exception of the trivial generators created with `constant`. Most generators take two arguments, `element` and `size` which are meant to specify the distribution of the elements and size of the returned data structures and whose exact interpretation depends on the specific generator. In general, if the argument `element` is a value it is construed as a desired expectation of the elements of the return value, if it is a function, it is called with a single argument to generate the elements of the random data structure. For example


```r
rdouble()
```

```
numeric(0)
```

generates some random double vector. The next expression does the same but with an expectation equal to 100


```r
rdouble(generator = 100)
```

```
numeric(0)
```
and finally this extracts the elements from a uniform distribution with all parameters at default values.

```r
rdouble(runif)
```

```
 [1] 0.52731 0.88032 0.37306 0.04796 0.13863 0.32149 0.15483 0.13223
 [9] 0.22131 0.22638 0.13142 0.98156 0.32701 0.50694
```

The same is true for argument `size`. If not a function, it is construed as a length expectation, otherwise it is called with a single argument equal to 1 to generate a random length.

First form:

```r
rdouble(size = 1)
```

```
numeric(0)
```

```r
rdouble(size = 1)
```

```
numeric(0)
```

Second form:

```r
rdouble(size = function() 10 * runif(1))
```

```
 [1]  -92.94 -148.75 -107.52  100.00  -62.13 -138.44  186.93   42.51
 [9]  -23.86  105.85
```

```r
rdouble(size = function() 10 * runif(1))
```

```
[1]   77.96   71.32  -54.29   88.58  -34.86 -100.81  188.32  -92.90
```

A shorthand for the above expression is:


```r
rdouble(size = ~10*runif(1))
```

```
[1]  45.700  -7.715 -33.400  -3.473
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`. Nested data structures have an argument `height`. All of these are intended to be expectations as opposed to deterministic values but can be replaced by a generator, which gives you total control. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:


```r
rdouble(size = constant(3))
```

```
[1]  78.76 207.52 102.74
```

```r
rdouble(size = constant(3))
```

```
[1]  120.79 -123.13   98.39
```

Or, since "conciseness is power":


```r
rdouble(size = ~3)
```

```
[1]   21.99 -146.73   52.10
```

Without the `~` it would be an expected size, with it it is deterministic.

Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. Another simple constructor is `rsample` which creates a generator that picks randomly from a list, provided as argument -- not unlike `sample`, but consistent with the `quickcheck` definition of generator.


```r
rsample(1:5, 10)
```

```
[1] 5
```

```r
rsample(1:5, 10)
```

```
integer(0)
```

The default distributions are still work in progress, but follows a general principle that testing larger vectors or vectors with larger elements should not be at the TODO.

## Advanced topics

### Composition of generators

The alert reader may have already noticed how generators can be used to define other generators. For instance, a random list of double vectors can be generated with `rlist(rdouble)` and a list thereof with `rlist(function() rlist(rdouble))`. Since typing `function()` over and over again gets old quickly and adds clutter, we can use `~` as a shortcut `rlist(~rlist(rdouble))`. 

### Custom generators

There is no reason to limit oneself to built-in generators and one can do much more than just change the parameters. For instance, we may want to 
make sure that extremes of the allowed range are hit more often than the built-in generators ensure. For instance, `rdouble` uses by default a standard normal, and values like 0 and Inf have very small or 0 probability of occurring. Let's say we want to test the following assertion about the ratio:


```r
is.reciprocal.self.inverse = function(x) isTRUE(all.equal(x, 1/(1/x)))
```

We can have two separate tests, one for values returned by `rdouble`:


```r
test(function(x = rdouble()) is.reciprocal.self.inverse(x))
```

```
Pass  
 function (x = rdouble())  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  50200   52500   64800  113000   77300  502000 
```

and one for the corner cases:

```r
test(function(x = rsample(c(0, -Inf, Inf))) is.reciprocal.self.inverse(x))
```

```
Pass  
 function (x = rsample(c(0, -Inf, Inf)))  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  50700   53900   66200   69500   67500  126000 
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
[1] 25.22
```

```r
rdoublex()
```

```
[1]    0.00 -198.94   78.21    -Inf   91.90   82.12
```
		
And use it in a more general test.


```r
test(function(x = rdoublex()) is.reciprocal.self.inverse(x))
```

```
Pass  
 function (x = rdoublex())  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  52300   53400   58500  256000   73400 2000000 
```
