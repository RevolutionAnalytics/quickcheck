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
  19100   19400   20400   22700   25200   33500 
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
  18000   19300   20400   21900   22000   55000 
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
  18300   20000   21100   22800   22900   71600 
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
2080000 2350000 3010000 2980000 3340000 4640000 
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
load("/Users/antonio/Projects/Revolution/quickcheck/docs/./quickchecka34646eb9a48")
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
 [1]  -98.975   28.273 -220.198  -49.237   -4.334  -28.163 -123.364
 [8]  -78.192   96.678  -99.423  104.382  -70.641 -153.486  -71.128
[15] -101.230   43.694  -96.047   77.706   68.739  142.194  -16.872
[22]   24.769  158.837   51.807  161.301  -50.542   56.489 -128.373
[29] -272.990  107.036 -219.462  -19.479


$cases[[2]]
$cases[[2]]$x
 [1] -174.838   94.992  -15.013    5.838 -124.245   32.476 -155.967
 [8]  144.174  -53.300  -79.188   61.380  -51.076 -110.643    5.273
[15]  -89.603  123.701 -211.628  -38.357   63.937  -19.068  -81.012
[22]   12.270    5.886   92.719 -110.506  -39.363   -6.268    6.469
[29]  -42.415  -23.826    7.260 -176.220  -49.952


$cases[[3]]
$cases[[3]]$x
 [1]  -17.783  -12.893  -76.531 -123.870   76.085  -56.670   -7.878
 [8]   30.638   -6.847   92.127  -64.241  -27.820  -75.772  -19.513
[15]   54.588   51.492  -31.787   23.318  -31.250


$cases[[4]]
$cases[[4]]$x
 [1]  -95.132 -229.090   19.809   69.598  159.529  -30.570   -1.485
 [8]   63.200   73.980   51.582  -40.716  -65.305  172.748    2.284
[15]  100.199   16.705   -4.799  -76.972   65.983  -42.567   42.980


$cases[[5]]
$cases[[5]]$x
[1] 119.74  19.58  55.11 148.65 166.24 -97.69


$cases[[6]]
$cases[[6]]$x
[1]  22.56  26.83 -97.71


$cases[[7]]
$cases[[7]]$x
numeric(0)


$cases[[8]]
$cases[[8]]$x
 [1]   54.82 -207.05  -50.88  168.61 -140.40   10.46  -80.71 -152.07
 [9] -122.32 -181.86   43.37   71.40  188.82   82.60


$cases[[9]]
$cases[[9]]$x
 [1]  -99.27  -47.55   33.64   43.27  -80.83 -131.12   59.11 -192.07
 [9]  -71.09 -124.08  -91.49   11.96  -12.18  -27.88   49.14  150.01
[17]   45.69  -40.79  120.51   59.39  -54.47 -215.99 -119.35   35.10
[25]  221.71   72.26   39.78  -26.70  -24.95


$cases[[10]]
$cases[[10]]$x
 [1] -131.565 -217.195  159.040    9.273   31.712   81.374  -26.818
 [8]  -51.663  -30.218  -61.646 -114.093  106.943  169.283   49.032
[15]   12.010 -167.584  -64.031   30.099  -10.723    2.993 -134.190
[22]  -68.134  104.171   36.005 -164.881   -8.686 -120.895  -57.921
[29]   52.073  -66.182   71.486  260.397   50.395 -130.245  -92.195
[36]  -13.636   90.362  -88.513   92.725    5.652  -67.213  -30.696
[43]  -20.203   59.226   56.710   41.287 -182.754   11.385  -83.507



$pass
 [1] FALSE FALSE FALSE  TRUE  TRUE FALSE    NA FALSE FALSE FALSE

$elapsed
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  26000   26800   27100   27900   27300   36700 
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
mean(x) > 0)(x = c(-98.975472647153, 28.2734948113111, -220.198135504239, 
-49.2366475437378, -4.33416209229328, -28.1626021552711, -123.363690410084, 
-78.1915278468566, 96.6784022810993, -99.4231593716358, 104.382113839079, 
-70.6407624976424, -153.485529470173, -71.1277390664433, -101.229891452784, 
43.693816436269, -96.0473379327379, 77.7060240406356, 68.7394422574265, 
142.194247061591, -16.8718277749083, 24.769161276441, 158.837095768532, 
51.8074423625048, 161.30101240996, -50.5417979160663, 56.4891215049301, 
-128.372941766827, -272.989898631072, 107.035838064454, -219.461820379847, 
-19.4787031281759))
debug: mean(x) > 0
exiting from: (function (x = rdouble()) 
mean(x) > 0)(x = c(-98.975472647153, 28.2734948113111, -220.198135504239, 
-49.2366475437378, -4.33416209229328, -28.1626021552711, -123.363690410084, 
-78.1915278468566, 96.6784022810993, -99.4231593716358, 104.382113839079, 
-70.6407624976424, -153.485529470173, -71.1277390664433, -101.229891452784, 
43.693816436269, -96.0473379327379, 77.7060240406356, 68.7394422574265, 
142.194247061591, -16.8718277749083, 24.769161276441, 158.837095768532, 
51.8074423625048, 161.30101240996, -50.5417979160663, 56.4891215049301, 
-128.372941766827, -272.989898631072, 107.035838064454, -219.461820379847, 
-19.4787031281759))
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
[1]  -11.78  -91.21 -143.76  -79.71  125.41   77.21  -21.95  -42.48  -41.90
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
 [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

The same is true for argument `size`. If numeric,  it is construed as a maximum size or a support range, depending on its length, otherwise it is called with a single argument equal to 1 .

First form:

```r
rdouble(size = 100)
```

```
 [1]   13.8053  -11.8792   19.7684 -106.8693  -80.3213 -111.3765  158.0092
 [8]  149.7819   26.2645 -123.2901   -0.3724  151.1672  -47.5698   79.7916
[15]  -97.4003   68.9373  -95.5839 -123.1707  -95.6892
```

Second form:

```r
rdouble(size = c(min = 3, max = 4))
```

```
[1] -91.068  74.128   6.851
```

RNG:


```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1] -166.50  -46.35 -111.59  -75.08
```

With the formula syntax:


```r
rdouble(size = ~10*runif(1))
```

```
 [1]  -44.817   47.174 -118.049  147.026 -131.142   -9.652  236.972
 [8]   89.063  -25.218  -86.576
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`, with the same possibile values. Nested data structures have an argument `height`. All of these are intended to be expectations as opposed to deterministic values but can be replaced by a generator, which gives you total control. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:


```r
rdouble(size = constant(3))
```

```
[1]  58.259  -1.253 -37.485
```

```r
rdouble(size = constant(3))
```

```
[1]  31.79 -48.88 265.87
```

Or, since ["succintness is power"](http://www.paulgraham.com/power.html):


```r
rdouble(size = ~3)
```

```
[1] 168.03  77.96  71.32
```

Without the `~` it would be a max size, with it it is deterministic. Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. Another simple generator is `rsample`, which creates a generator that picks randomly from a list, provided as argument -- not unlike `sample`, but consistent with the `quickcheck` definition of generator.


```r
rsample(1:5, 10)
```

```
integer(0)
```

```r
rsample(1:5, 10)
```

```
[1] 2 3 1 3 5 5
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
  52000   69300   73400  107000   81000  439000 
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
  51100   53800   55800   58300   58300   76600 
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
numeric(0)
```

```r
rdoublex()
```

```
[1] -Inf
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
  50000   51100   55200   61000   66500   86900 
```
