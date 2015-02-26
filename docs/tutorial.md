# Assertion-based testing with Quickcheck


```r
library(knitr)
opts_chunk$set(echo=TRUE, tidy=FALSE, comment="", cache=FALSE, error=FALSE)
```



## Introduction

Quickcheck was originally a package for the language Haskell aimed at simplifying the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package (for the first time according to my research). Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into. In R, the main ideas retained are that tests are based on assertions and that the developer should not have to specify the inputs and output values of a test. The difference from Haskell is that the user needs to specify the type of each variable in an assertion with the optional possibility to fully specify its distribution. The main function in the package, `test`, will randomly generate input values, execute the assertion and collect results. The advantages are multiple:

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
  18900   19100   19600   21000   20200   31900 
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
  17900   19200   20000   21800   20700   46900 
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
  18200   19200   19900   22000   22500   86800 
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
1930000 2140000 2180000 2480000 2380000 5140000 
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
```

```
Error: load("/tmp/95980/quickcheck176ec1e6e13fe")
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
[1] 6.501


$cases[[2]]
$cases[[2]]$x
[1]  20.79 152.31 -72.67 179.33


$cases[[3]]
$cases[[3]]$x
 [1] -149.472    5.802  142.713   -2.421 -168.728  175.137   74.703
 [8] -213.602  -30.324   50.191  -17.942 -179.265  110.803  -58.134
[15]   38.496  -58.666  -23.815   18.178 -109.916  167.573  -25.986
[22]   85.258   -4.724   -6.630


$cases[[4]]
$cases[[4]]$x
[1] 56.34


$cases[[5]]
$cases[[5]]$x
 [1]  -88.671   32.703  -35.948   28.460  102.032   35.691   71.906
 [8]  113.423   84.343  224.496   23.432   -5.049    5.378 -214.799
[15]   91.946


$cases[[6]]
$cases[[6]]$x
 [1]  109.000  -17.385 -121.661  -54.348  -64.869   34.382 -111.817
 [8] -185.236  195.518  -51.609   53.958   28.365  -95.117 -152.919
[15]  132.506  -13.893  140.272 -111.009   75.332  186.363  -29.579
[22]  -47.431   59.905   -3.385   21.666   48.881  -37.620   81.415
[29]  -16.331   41.649  -77.097   36.828   79.194  -50.813 -187.398
[36]  195.431  -63.890  -69.753  -17.075  -84.768


$cases[[7]]
$cases[[7]]$x
 [1]   55.99 -280.04  137.61   68.05   42.23   96.11  -28.56   61.52
 [9]   62.65   85.74


$cases[[8]]
$cases[[8]]$x
 [1]  -75.0611  -54.1539   63.2853   93.0066   12.2372 -136.3754   79.4539
 [8]  -59.7427  -18.7482   69.8092  -74.7152   49.0744   -9.8768  -97.3525
[15]    1.7548   -1.0646 -114.9410  168.7972  104.8447   37.7048  166.4863
[22]  -71.2445   48.0203   80.2498  -93.5185  -62.1018  -88.4403   29.3684
[29]  278.0700  117.2480  -74.2692 -158.1255  -92.7926   21.9017    2.0331
[36]   28.4028    4.9102  166.7208  122.0102  158.0508 -136.6660 -135.4718
[43]  -41.9699   -0.2347   65.8879  205.8819   68.1533  -88.6746   62.5711
[50]   37.9426  -20.9251  -66.0746  147.3807  -50.5599   39.6705  -33.6563
[57]  -19.9922   50.9942 -119.8879  -32.7671  101.8846  231.4199  168.7200
[64]  -17.5883   22.3975   66.5353 -150.8258 -164.6217 -149.1752  -20.8496
[71]  -43.0050  -63.9007   -5.2606   12.3264  223.9019   77.2305 -101.4042
[78]  -50.0144   21.5667


$cases[[9]]
$cases[[9]]$x
[1] -124.9 -120.2   80.2  199.3  127.1 -216.0  110.7


$cases[[10]]
$cases[[10]]$x
numeric(0)



$pass
 [1]  TRUE  TRUE FALSE  TRUE  TRUE FALSE  TRUE  TRUE  TRUE    NA

$elapsed
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  25300   26400   31600   32700   38100   45400 
```

The output is a list with five elements:

  - the assertion that failed
  - a list of in-scope variables that could have affected the result -- this is work in progress and shouldn't be trusted at this time
  - a list of lists of arguments passed to the assertion in each run 
  - the outcome of each run
  - some performance stats (step towards a more complete performance harness support in future releases)
  
My recommendation is to write assertions that depend exclusively on their arguments and are deterministic functions, and leave all the randomness to `quickcheck` and its generators. This is because the first step in fixing a bug is almost always to reproduce it, and non-deterministic bugs are more difficult to reproduce. The `test` function seeds the random number generator so that every time it is called it will rerun the same tests, that is call the assertion with the same arguments, run after run. So I guess we should call it pseudo-random testing to be precise. Let's go in more detail on the `cases` element. It is a list with an element for each run, which has a value of `NULL`, if the run was successful, and a list of arguments passed to the assertion otherwise. In this case runs 2 through 7 failed. We can replicate it as follows.


```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > 0)(x = c(-149.472027829401, 5.80232484081566, 142.712804617082, 
-2.42114600788036, -168.727650036898, 175.13728003114, 74.7026696377599, 
-213.601851559202, -30.3242426360314, 50.1905193158911, -17.9422305811301, 
-179.265373319932, 110.803085742297, -58.1341803467617, 38.4957635427599, 
-58.6658830181767, -23.8154303092674, 18.1777757112529, -109.915809485638, 
167.572998250351, -25.9855740047145, 85.257718667166, -4.72390910353835, 
-6.63028079845378))
debug: mean(x) > 0
exiting from: (function (x = rdouble()) 
mean(x) > 0)(x = c(-149.472027829401, 5.80232484081566, 142.712804617082, 
-2.42114600788036, -168.727650036898, 175.13728003114, 74.7026696377599, 
-213.601851559202, -30.3242426360314, 50.1905193158911, -17.9422305811301, 
-179.265373319932, 110.803085742297, -58.1341803467617, 38.4957635427599, 
-58.6658830181767, -23.8154303092674, 18.1777757112529, -109.915809485638, 
167.572998250351, -25.9855740047145, 85.257718667166, -4.72390910353835, 
-6.63028079845378))
```

```
[1] FALSE
```

This opens the debugger at the beginning of a failed call to the assertion. Now it is up to the developer.

## What tests should I write

This is a difficult question, as you can imagine. One possible criterion is that of *test coverage*, the fraction of code that has been executed during the execution of tests. The other is the strictness of your assertions. The conjunction of all the assertions in your test set should imply the correctness of your program, in the ideal case and when universally quantified over their inputs. For instance `test(function(x = rinteger()) identical(x,x))` tests one important property of the `identical` function for all integer vectors. That doesn't mean it runs the test for all integer vectors, which is impossible, but it means two related concepts:

 - The developer meant that the function should work for all integer vectors
 - The test can in principle run on any subset of integer vectors and should pass in each case.
 
The attentive reader may have already noticed that this is not the most stringent test we could  have written, even if it achieves 100% coverage. `identical` is supposed to work with any R object, so `test(function(x = rany()) identical(x,x))` is also expected to pass, implies the previous test, if universally quantified over all inputs, that is it is strictly more stringent given infinite time to try all possible inputs and better captures the developer's intent. Finally, there is practical and some theoretical evidence that shorter programs can be tested more effectively, provided that the tests are also short. To summarize

 - Write the strictest set of tests possible. Only a correct program should be able to pass them, given infinite time to run the tests
 - Aim for 100% coverage
 - Keep code and tests simple. 
 
Quickcheck can help with the second point. Function `no.coverage` will generate a simple coverage report highlighting areas of your code, with line-level detail, that is not covered by any test. At this time it works only for packages, that is it runs all the tests implied by `R CMD check` and compiles its report based on that, but we hope to make it work at the file or function level in the future. Based on package `covr` by @jimhester.


## Modifying or defining random data generators

There are built in random data generators for most built-in data types. They follow a simple naming conventions, "r" followed by the class name. For instance `rinteger` generates a random integer vector. Another characteristic of random data generators as defined in this package is that they have defaults for every argument, that is they can be called without arguments. That's one difference with R random number generators, such as `rnorm` and `rpois`, the other being that those return a sample of a specific size, whereas for random data generators even that is random, unless specified otherwise. Like RNGs, quickcheck's generators promise statistical independence between calls. I said "promise" because it's hard to guarantee such a property, but that's the goal.


```r
set.seed(0)
rdouble()
```

```
 [1]  -32.6233  132.9799  127.2429   41.4641 -153.9950  -92.8567  -29.4720
 [8]   -0.5767  240.4653   76.3593  -79.9009 -114.7657  -28.9462  -29.9215
[15]  -41.1511   25.2223  -89.1921   43.5683 -123.7538  -22.4268   37.7396
[22]   13.3336   80.4190   -5.7107   50.3608  108.5769  -69.0954 -128.4599
[29]    4.6726  -23.5707  -54.2888  -43.3310  -64.9472   72.6751  115.1912
[36]   99.2160  -42.9513  123.8304  -27.9346  175.7903   56.0746  -45.2784
[43]  -83.2043 -116.6571 -106.5591 -156.3782  115.6537   83.2047  -22.7329
[50]   26.6137  -37.6703  244.1365  -79.5339   -5.4877   25.0141   61.8243
[57]  -17.2624 -222.3900
```

```r
rdouble()
```

```
numeric(0)
```

As you can see, both elements and length change from one call to the next and in fact they are both random and independent (I set the seed to have something deterministic to comment upon. I am pseudo-honest in doing that). This is generally true for all generators, with the exception of the trivial generators created with `constant`. Most generators take two arguments, `generator` and `size` which are meant to specify the distribution of the elements and size of the returned data structures and whose exact interpretation depends on the specific generator. In general, if the argument `element` is a value it is construed as a parameter of the default RNG invoked to draw the elements, if it is a function, it is called with a single argument to generate the elements of the random data structure. For example


```r
rdouble()
```

```
 [1]   -1.105  -94.065  -11.583  -81.497   24.226 -142.510   36.594
 [8]   24.841    6.529    1.916   25.734  -64.901  -11.917   66.414
[15]  110.097
```

generates some random double vector. The next expression does the same but with an expectation equal to 100


```r
rdouble(elements = 100)
```

```
[1]  88.225   8.793 -43.759  20.291 225.408 177.214  78.048  57.519  58.102
```
and finally this extracts the elements from a uniform distribution with all parameters at default values.

```r
rdouble(elements = runif)
```

```
 [1] 0.3914 0.3805 0.8954 0.6443 0.7411 0.6053 0.9031 0.2937 0.1913 0.8865
[11] 0.5033 0.8771 0.1892 0.7581 0.7245 0.9437 0.5476 0.7117 0.3889 0.1009
[21] 0.9273 0.2832 0.5906 0.1104 0.8405 0.3180 0.7829 0.2675 0.2186 0.5168
[31] 0.2690 0.1812 0.5186 0.5628 0.1292 0.2564 0.7179 0.9614 0.1001 0.7632
[41] 0.9480 0.8186 0.3083
```

There is also a formula syntax, if you want for instance to modify the parameters of `runif`, as in 


```r
rdouble(elements = ~runif(size, min = -1))
```

```
 [1]  0.90747 -0.32004 -0.47505 -0.66909 -0.35566  0.02025  0.84794
 [8]  0.02192 -0.38859 -0.90708 -0.16429  0.70800 -0.30554 -0.73712
[15] -0.25103
```

Remember to use the variable `size` as the sample size argument to the RNG or anywhere appropriate in the formula.
Unfortunately, different generators take parameters with different intepretations. The default is usually a named vector where the names should provide a clue as to the semantics, and it's also documented in the help. For instance, for `rinteger`, `elements` can be one of the following:

 - an integer vector of size 1, representing the max of the support of a distribution symmetric around 0; 
 - an integer vector of size 2, representing the extremes of the support;
 - an RNG;
 - a formula containing the variable `size` and returning a length `size` vector. 
 
 In general the RNG or forumula should return exactly `size` elements. If not, recycling will be applied after issueing a warning. Recycling random numbers in general change their stochastic properties and it is not recommended. But there are some use cases, like creating a random-length vector of 0s.
 

```r
rinteger(~0, 100)
```

```
Warning: recycling random numbers
```

```
  [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [36] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [71] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

The same is true for argument `size`. If numeric,  it is construed as a maximum size or a support range, depending on its length, otherwise it is called with a single argument equal to 1 .

First form:

```r
rdouble(size = 100)
```

```
  [1]   13.8053  -11.8792   19.7684 -106.8693  -80.3213 -111.3765  158.0092
  [8]  149.7819   26.2645 -123.2901   -0.3724  151.1672  -47.5698   79.7916
 [15]  -97.4003   68.9373  -95.5839 -123.1707  -95.6892  -86.9783  -91.0681
 [22]   74.1276    6.8512  -32.3751 -108.6503 -101.5929  -76.7790 -111.9720
 [29]  -44.8174   47.1736 -118.0491  147.0257 -131.1421   -9.6525  236.9720
 [36]   89.0626  -25.2183  -86.5764   58.2586   -1.2529  -37.4855   31.7886
 [43]  -48.8806  265.8658  168.0278   77.9584   71.3241  -54.2882   88.5778
 [50]  -34.8595 -100.8055  188.3183  -92.8971  -29.4196  -61.4950  -94.7076
 [57]   59.8975 -152.3615  -20.6189  -57.4295 -139.0166   -7.0417  -43.0880
 [64]  -59.2225   98.1116   53.2409   -9.0456   15.6490  -73.7312  -20.1341
 [71]  110.2177   -1.6748   16.1789  202.4761  -70.3694   96.0792  179.0485
 [78] -106.4165    1.7637  -38.9909  -49.0833 -104.5718  -89.6211  126.9387
 [85]   59.3841   77.5634  155.7370  -36.5402   81.6556   -6.0635  -50.1378
 [92]   92.6063    3.6938 -106.6200  -23.8456  149.5223  117.2159 -145.7707
 [99]    9.5056   84.7665
```

Second form:

```r
rdouble(size = c(min = 3, max = 4))
```

```
[1] 140.86 -54.18  27.87
```

RNG:


```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1]  -34.10 -115.66  180.31  -33.11
```

With the formula syntax:


```r
rdouble(size = ~10*runif(1))
```

```
[1] 40.65
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`, with the same possibile values. Nested data structures have an argument `height`. All of these are intended to be expectations as opposed to deterministic values but can be replaced by a generator, which gives you total control. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:


```r
rdouble(size = constant(3))
```

```
[1]  222.926 -151.450   -6.171
```

```r
rdouble(size = constant(3))
```

```
[1] -14.73 154.16 -98.19
```

Or, since ["succintness is power"](http://www.paulgraham.com/power.html):


```r
rdouble(size = ~3)
```

```
[1]  49.66 169.69 -26.07
```

Without the `~` it would be a max size, with it it is deterministic. Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. Another simple generator is `rsample`, which creates a generator that picks randomly from a list, provided as argument -- not unlike `sample`, but consistent with the `quickcheck` definition of generator.


```r
rsample(elements = 1:5, c(max = 10))
```

```
integer(0)
```

```r
rsample(elements = 1:5, c(max = 10))
```

```
[1] 4
```

The default distributions are still work in progress, but follow a general principle that testing larger vectors or vectors with larger elements should not be at the expense of skipping the small ones. Programs need to walk before they can run. We intend to adjust the default distributions based on user feedback.

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
  55000   73500   77000  111000   85100  406000 
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
  47300   48700   50100   55800   56300   86300 
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
 [1]  279.657  291.963  202.648   52.734   76.336    3.277  109.215
 [8]  181.009  143.225  -86.984  -61.526  174.678  242.583  119.444
[15]   24.033   64.065   67.008  253.185  134.176  101.699   76.711
[22]  133.447   68.497    7.465  175.478  153.857  206.425  193.252
[29]   56.890  263.055   98.299  119.352   56.892  132.321  170.423
[36]  257.138  105.329  -19.598  211.302  164.084  126.694  -38.436
[43]  165.653  111.645 -112.783  150.413  200.248  185.765  126.683
[50]   73.710  -29.130  311.507   19.766  106.864  -12.649  145.763
[57]   32.298  184.751   81.291  172.574   65.625      Inf    0.000
[64]  -89.647   31.485  144.076  229.041  217.171   72.907   80.114
[71]  125.128   59.955 -125.129  200.671  195.660  165.462     -Inf
[78]  133.273  193.314  275.649  -76.322   71.642  126.627   91.914
[85]  121.586  118.830   72.753   15.944 -121.239  154.091  160.252
```

```r
rdoublex()
```

```
 [1]  252.424  246.280   75.704   88.751  227.244      Inf   29.693
 [8]    0.000  102.764   25.555   27.209  101.024  -39.749   81.983
[15]   63.004  152.292  161.167  -27.487   35.389   15.769  303.020
[22]  106.453   17.602  118.964  276.810 -121.675  -41.006  254.404
[29]  108.026   98.510  128.823    2.229   63.007  150.943   11.900
[36]  -89.212     -Inf  -22.450   87.645   -7.139  -23.736  230.368
[43]  -51.131  370.301  339.720    9.569   67.234  278.934   98.661
[50]   87.700
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
  65900   73300   79800   81700   88800  108000 
```
