# Assertion-based testing with Quickcheck





## Introduction

Quickcheck was originally a package for the language Haskell aimed at simplifying the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package (for the first time according to my research). Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into. In R, the main ideas retained are that tests are based on assertions and that the developer should not have to specify the inputs and output values of a test. The difference from Haskell is that the user needs to specify the type of each variable in an assertion with the optional possibility to fully specify its distribution. The main function in the package, `test`, will randomly generate input values, execute the assertion and collect results. The advantages are multiple:

  - each test can be run multiple times on different data points, improving coverage and the ability to detect bugs, at no additional cost for the developer;
  - tests can run on large size inputs, possible but impractical in non-randomized testing;
  - assertions are more self-documenting than specific examples of the I/O relation -- in fact, enough assertions can constitute a specification for the function being tested, but that's not necessary for testing to be useful;
  - it is less likely for the developer to use implicit assumptions in the selection of testing data -- randomized testing "keeps you honest".
  
## First example

Let's start with something very simple. Let's say we just wrote the function `t` for transpose. Using the widely used testing package `testthat`, one can just write a test like that:


```r
library(testthat)
```


```r
test_that(
  "transpose test",
  expect_identical(
    t(matrix(as.numeric(1:6), ncol = 3)),
    matrix(c(1,3,5,2,4,6), ncol = 2)))
```

That works, but has some limitations. For instance, imagine that we have to match military-grade testing which requires to run at least 10000 tests. It can be pretty laborious to write them this way. So the next step is to replace examples of what the function is supposed to do with a statement of the properties that a function is supposed to have, also known as an assertion:




That's progress, yet the testing points are chosen manually and arbitrarily. It's hard to have many or very large input values, and unstated assumptions my affect their choice. For instance, is `t` going to work for non-numeric matrices?`quickcheck` can solve or at least alleviate all these problems:


```r
library(quickcheck)
test(
  forall(
    x = rmatrix(),
### <b>
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
```

```
Using seed 477281578
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  19900   29400   62200   86400  117000  250000 
```

```
Creating /tmp/quickcheck/96574. Use qc.options(tmpdir = <alternate-path>) to change location.
```

```r
### </b>
```

We recognize the assertion in the previous code snippet, modified to take into account matrices with 0 rows or columns. Here though, it becomes the body of a function, which is what is called "assertion" in `quickcheck`, which has one or more arguments, all with default values, and returns a length-one logical vector. `TRUE` means success, `FALSE` or an error mean failure. Some of those arguments are initialized randomly, in this case using what in `quickcheck` is called a Random Data Generator, or RDG -- more on these later. In this case `rmatrix` is a function that returns a random matrix. The `test` function evaluates the assertion multiple times and outputs some messages: 

- the seed used is unique to each test, but ensures reproducibility
- a "pass" message
- the assertion tested -- imagine you are scanning a log of a long series of tests
- some performance information -- harbinger of future features
- information about a directory -- more on that later.

What this test success means is that we have tested that `t` satisfies this assertion on a sample of random matrices, including a variety of sizes, element types and, of course, element values. We don't have to write them down one by one and later we will see how we can affect the distribution of such inputs, to make them, say, larger in size or value, or more likely to hit corner cases.  If we need to control the number of time the assertion is run, that's very simple:


```r
test(
  forall(
    x = rmatrix(),
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))),
  sample.size = 100)
```

```
Using seed 477281578
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  18600   20500   63800  104000  120000 1830000 
```

Done! You see, if you had to write down those 100 matrices one by one, you would never have time to.  Let's review the advantages of this setup. We can increase the severity of the test by cranking up the number of runs of the assertion, just by changing a parameter. We can also change the distribution of matrices to test larger inputs, this will be explained later. Moreover `quickcheck` tests communicate intent. While each test is run in practice on a small set of examples, the implied promise from the authors of the package is unmistakably that it ought to pass for any matrix. You don't have to guess from a small set of inputs what the function does and what its allowable range is.


## Defining assertions

Unlike `testthat` where you need to construct specially defined *expectations*, `quickcheck` accepts logical-valued functions, with a length-one return value and a default value for each argument. For example `function(x = rdouble()) all(x + 0 == x)` or `function(x = rlist()) identical(x, rev(rev(x)))` are valid assertions -- independent of their success or failure. For readability and safety, you can use `forall` as in `forall(x = rdouble(), all(x + 0 == x))` (`forall` checks that all arguments have a default, as an added benefit). If an assertion returns `TRUE`, it is considered a success. If an assertion returns `FALSE` or generates an error, it is  considered a failure. For instance, `forall(x = rcharacter(), stop(x))` is a valid assertion but always fails. How can we express the fact that this is its correct behavior? `testthat` has a rich set of expectations to capture this and other requirements, such as printing something or generating a warning. `quickcheck` has a way to access those, implemented as the function `expect`:


```r
test(
  forall(x = rcharacter(), expect("error", stop(x))))
```

```
Using seed 770024200
Pass  
 function (x = rcharacter())  
 expect("error", stop(x)) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
2140000 2380000 2470000 2550000 2520000 3730000 
```

By executing this test successfully we have built confidence that the function `stop` will generate an error whenever called with any `character` argument. There are predefined `quickcheck` assertions defined for each `testthat` expectation, with a name equal to the `testthat` expectation, without the "expect_" prefix. We don't see why you would ever want to use `expect("equal", ...)`, but we threw it in for completeness. 

## What to do when tests fail

`quickcheck` doesn't fix bugs for you, but tries to get you started in a couple of ways. The first is its output:


```r
test(forall(x = rdouble(), mean(x) > 0), stop = TRUE)
```

```
Using seed 494012268
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
Error: to reproduce enter repro("/tmp/quickcheck/96574/tr1793e4db42bdc")
```

This output shows that about half of the default 10 runs have failed and then invites us to enter a command, `repro(<some-path>)`, that will execute the assertion in the debugger with the input data that made it fail. Another way to achieve the same is to run the test with the option `stop = FALSE` which doesn't produce an error and returns the same debugging data. This is convenient for interactive sessions, but less so when running `R CMD check`. In fact, the default for the `stop` argument is `FALSE` for interactive sessions and `TRUE` otherwise, which should work for most people.


```r
test.out = test(forall(x = rdouble(), mean(x) > 0), stop = FALSE)
```

```
Using seed 494012268
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

 In most cases all we need to do with the output of `test` is to pass it to another function, `repro`:


```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > 0)(x = c(95.4220841095448, 160.246710415966, -45.794324713949, 
25.3869065691574, 23.7946291303444, -64.6528676719553, 17.2532503680657, 
-12.4640292985689, 203.772824804286, -52.1154926680255, 92.4381620907306, 
-53.8018711197192, -40.6044884240434, 5.53494104755664, -96.4591445419219, 
....
```

```
[1] FALSE
```

This opens the debugger at the beginning of a failed call to the assertion. Now it is up to the developer to fix any bugs.

To achieve reproducibility, it is necessary to write assertions that depend exclusively on their arguments and are deterministic functions, and leave all the randomness to `quickcheck` and the assertion arguments default values. The `test` function seeds the random number generator in a way that ensures reproducibilit from one call of the test to the next. The seed is unique to each assertion, but doesn't change for small edits of the assertion, to facilitate assertion development.

## What tests should I write?

There is no general answer to this question, as you can imagine. One possible criterion is that of *test coverage*, the fraction of code that has been executed during the execution of tests. The other is the strictness of your assertions. The conjunction of all the assertions in your test set should imply the correctness of your program, in the ideal case and when universally quantified over their inputs. For instance `test(forall(x = rinteger(), identical(x,x))` tests one important property of the `identical` function for all integer vectors. That doesn't mean it runs the test for all integer vectors, which is impossible, but it means that there should be no failure no matter how many runs we allow the test to include.
 
The attentive reader may have already noticed that this is not the most stringent test we could  have written, even if it achieves 100% coverage. `identical` is supposed to work with any R object, so `test(forall(x = rany(), identical(x,x))` is also expected to pass, implies the previous test, if universally quantified over all inputs, that is it is strictly more stringent given infinite time to try all possible inputs and better captures the developer's intent.

As a final guideline  for test-writing, there is practical and some theoretical evidence that shorter programs can be tested more effectively, provided that the tests are also short. To summarize:

 - Write the strictest set of tests possible. Only a correct program should be able to pass them, given infinite time to run the tests
 - Aim for 100% coverage
 - Keep code and tests short. 
 
Quickcheck can help with the second point. Function `no.coverage` will generate a simple coverage report highlighting areas of your code, with line-level detail, that is not covered by any test. At this time it works only for packages, that is it runs all the tests implied by `R CMD check` and compiles its report based on that, but we hope to make it work at the file or function level in the future (this feature is based on package `covr` by @jimhester).
Quickcheck own tests achieve 90% coverage, with the function `no.coverage` itself representing most of the left out lines.

## Modifying or defining random data generators

There are built in random data generators for most built-in data types. They follow a simple naming conventions, "r" followed by the class name. For instance `rinteger` generates a random integer vector. Another characteristic of random data generators as defined in this package is that they have defaults for every argument, that is they can be called without arguments. That's one difference with R random number generators, such as `rnorm` and `rpois`, the other being that those return a sample of a specific size, whereas for random data generators even that is random, unless specified otherwise. Like RNGs, quickcheck's generators promise statistical independence between calls -- whatever that means in the pseudo-random setting.


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
....
```

```r
rdouble()
```

```
numeric(0)
```

As you can see, both elements and length change from one call to the next and in fact they are both random and independent. This is generally true for all generators, with the exception of the trivial generators created with `constant`. Most generators take two arguments, `elements` and `size` which are meant to specify the distribution of the elements and size of the returned data structures and whose exact interpretation depends on the specific generator. In general, if the argument `elements` is a numeric it is construed as providing parameters of the default RNG invoked to draw the elements, if it is a function, it is called with a single argument to generate the elements of the random data structure. For example


```r
rdouble()
```

```
 [1]   -1.105  -94.065  -11.583  -81.497   24.226 -142.510   36.594
 [8]   24.841    6.529    1.916   25.734  -64.901  -11.917   66.414
[15]  110.097
```

generates some random double vector. The next expression does the same but with expectation 100 and standard deviation 20


```r
rdouble(elements = c(mean = 100, sd  = 20))
```

```
[1]  97.64  81.76  71.25  84.06 125.08 115.44  95.61  91.50  91.62
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
....
```

For other generators the parameters may have different names and semantics, for instance


```r
rinteger(elements = c(min = 3, max = 7))
```

```
 [1] 7 4 4 3 4 5 7 5 4 3 5 7 4 3 4
```

For added convenience, the vector of parameters is subject to argument matching as if they were argument to a separate function, for instance


```r
rinteger(elements = c(3, 7))
```

```
 [1] 6 6 5 5 5 4 5 7 3 5 4 5 3 5
```

is equivalent to the previous one, and 


```r
rinteger(elements = c(max = 7))
```

```
 [1]   0 -50 -35 -48 -89 -74 -47 -60   0 -44 -66 -70 -15 -25 -83 -94 -19
[18] -33 -82 -94 -89 -59 -82 -68 -80 -73 -81 -49 -17 -97 -44  -5 -60 -95
[35] -86 -66 -84 -86 -77 -76 -86   6 -65 -46 -27 -90 -88 -95   0 -28 -90
[52] -47 -51 -60   7 -81 -13 -93 -57 -85 -80 -10 -23 -72 -47 -92 -62   4
[69] -33 -29 -67 -57   7  -8
....
```

leaves the `min` component at its default. The defaults are controlled by package options, see `help(qc.options)`.

There is also a formula syntax, if for instance you need to modify the parameters of `runif`, as in 


```r
rdouble(elements = ~runif(size, min = -1))
```

```
 [1]  0.56436 -0.46424  0.52430  0.97262 -0.41279 -0.20130  0.62426
 [8] -0.84570 -0.27261 -0.11482 -0.68657  0.16441  0.94032  0.97900
[15] -0.64710  0.08426 -0.23139  0.35233 -0.46141 -0.06150 -0.65640
[22] -0.26162  0.45081 -0.02770 -0.87240  0.56909 -0.16336  0.96204
[29] -0.43423  0.69576 -0.83552  0.77292 -0.05614 -0.78180 -0.33344
....
```

which is the same as


```r
library(functional)
rdouble(elements = Curry(runif, min = -1))
```

```
[1] -0.9777  0.8806  0.9875
```

Remember to use the variable `size` anywhere appropriate in the formula, so that it evaluates to exactly `size` elements.

To summarize, `elements` can be:

 - a named or unnamed vector of distribution parameters
 - an RNG that takes the sample size as its first argument;
 - a formula containing the variable `size` and evaluating to a length `size` vector. 
 
 In general the RNG or formula should return exactly `size` elements. If not, recycling will be applied after issuing a warning. Recycling random numbers in general changes their stochastic properties and it is not recommended. But there are some use cases, like creating a random-length vector of 0s.
 

```r
rinteger(elements = ~0, size = 100)
```

```
Warning: recycling random numbers
```

```
  [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [36] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [71] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

The same is `TRUE` for argument `size`. It can be a range, partially or completely specified, a RNG function or a formula returning exactly a vector of length 1.

First form:

```r
rdouble(size = c(max = 100))
```

```
 [1]   -6.063  -50.138   92.606    3.694 -106.620  -23.846  149.522
 [8]  117.216 -145.771    9.506   84.766 -162.436  140.856  -54.176
[15]   27.866  -19.397  157.616 -147.555  -14.461 -107.501   40.654
[22]  222.926 -151.450   -6.171  -14.727  154.159  -98.186   49.658
[29]  169.695  -26.074  -70.593  -16.118   50.132 -101.354
....
```

Second form:

```r
rdouble(size = c(min = 0, max = 10))
```

```
[1]    0.5642 -290.4899 -110.7165  154.7567  -97.6830  -10.1503    4.2650
[8] -159.6718   49.0967
```

RNG:


```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1]   -6.965  -24.766   69.555  114.623 -240.310   57.274   37.472
```

With the formula syntax:


```r
rdouble(size = ~10*runif(1))
```

```
[1]   35.29   55.04 -113.43
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`, with the same possible values. Nested data structures have an argument `height`. For now `height` can only be one number construed as maximum height and applies only to `rlist`. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:


```r
rdouble(size = constant(3))
```

```
[1] 146.24  70.21 250.71
```

```r
rdouble(size = constant(3))
```

```
[1] -189.00  -58.98 -171.45
```

Or, since ["succintness is power"](http://www.paulgraham.com/power.html):


```r
rdouble(size = ~3)
```

```
[1] -42.10  31.01 170.26
```

Without the `~` it would be a min size, with it it is deterministic. Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. 

|function| description|
|---|---|
`rany` | any R object|
`ratomic` | any atomic vector|
`rcharacter` | character
`rdata.frame` |data.frame|
`rDate` |Date|
`rdouble` |double|
`rfactor` |factor|
`rinteger` | integer|
`rlist` | list|
`rlogical` | logical
`rmatrix` | matrix
`rnamed` | random names for a vector
`rnumeric` | any numeric|
`rraw` |raw
`rsample` | sample from vector
`constant` | trivial constant RDG
`mixture` | mixture RDG
`named` | named version of any RDG

We can not exclude adjustments to the default distributions in future versions. Please don't make your tests reliant on implementation details of the generators.

## Advanced topics


### Custom generators

There is no reason to limit oneself to built-in generators and one can do much more than just change the parameters. For instance, we may want to 
make sure that extremes of the allowed range are hit more often than the built-in generators ensure. For instance, `rdouble` uses by default a standard normal, and values like 0 and Inf have very small or 0 probability of occurring. Let's say we want to test the following assertion about the ratio:


```r
is.reciprocal.self.inverse = function(x) isTRUE(all.equal(x, 1/(1/x)))
```

We can have two separate tests, one for values returned by `rdouble`:


```r
test(forall(x = rdouble(), is.reciprocal.self.inverse(x)))
```

```
Using seed 1509604841
Pass  
 function (x = rdouble())  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  56400   63300   78000  115000   92600  461000 
```

and one for the corner cases:

```r
test(forall(x = rsample(c(0, -Inf, Inf)), is.reciprocal.self.inverse(x)))
```

```
Using seed 590705710
Pass  
 function (x = rsample(c(0, -Inf, Inf)))  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  54100   54700   55400   62300   62500  100000 
```

That's a start, but the two types of values never mix in the same vector. We can combine the two with a custom generator


```r
rdoublex =
	function(elements = c(mean = 100), size = c(max = 10)) {
		data = rdouble(elements, size)
		sample(
			c(data, c(0, -Inf, Inf)),
			size = length(data),
			replace = FALSE)}
rdoublex()
```

```
[1] 147.902    -Inf 149.221     Inf  19.504  -8.808
```

```r
rdoublex()
```

```
[1] 162.9   Inf 103.0 143.6 130.1 104.6  -Inf 268.0
```
		
And use it in a more general test.


```r
test(forall(x = rdoublex(), is.reciprocal.self.inverse(x)))
```

```
Using seed 1300498190
Pass  
 function (x = rdoublex())  
 is.reciprocal.self.inverse(x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  50700   53500   62100   69100   71300  124000 
```

### Composition of generators

The alert reader may have already noticed how generators can be used to define other generators. For instance, a random list of double vectors can be generated with `rlist(rdouble)` and a list thereof with `rlist(function() rlist(rdouble))`. Since typing `function()` over and over again gets old quickly and adds clutter, we can use `~` as a shortcut `rlist(~rlist(rdouble))`. 
