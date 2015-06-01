# Assertion-based testing with Quickcheck




## Introduction

Quickcheck was originally a package for the language Haskell aimed at simplifying the writing of tests. The main idea is the automatic generation of tests based on assertions a function needs to satisfy and the signature of that function. The idea spread to other languages and is now implemented in R with this package (for the first time according to the best of our knowledge). Because of the differences in type systems between Haskell and other languages, the original idea morphed into something different for each language it was translated into. In R, the main ideas retained are that tests are based on assertions and that the developer should not have to specify the inputs and output values of a test. The main difference from Haskell is that, in R, the user needs to specify the type of each variable in an assertion with the optional possibility to fully specify its distribution. The main function in the package, `test`, will randomly generate input values, execute an assertion and collect results. There are several advantages to this approach:

  - each test can be run multiple times on different data points, improving coverage and the ability to detect bugs, at no additional cost for the developer;
  - tests can run on large size inputs, possible but impractical in non-randomized testing;
  - assertions are more self-documenting than specific examples of the I/O relation -- in fact, enough assertions can constitute a specification for the function being tested, but that's not necessary for testing to be useful;
  - it is less likely for the developer to use implicit assumptions in the selection of testing data -- randomized testing "keeps you honest".
  
## First example

Let's start with something very simple. Let's say we just wrote the function `t` for transpose. Using the widely used testing package `testthat`, one can just write a test as follows:


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

That works, but has some limitations. For instance, suppose we have to match some fictional military-grade testing which requires to run at least $10^4$ tests per  function: writing them this way would be pretty laborious. One solution is to replace examples of what the function is supposed to do with a general statement of one or  more properties that a function is supposed to have, also known as an assertion:



```r
for(x in list(matrix(c(1,2,3,4), ncol = 2), matrix(c(5:10), ncol = 3)))
  test_that(
    "transpose  test",
    expect_true(
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
rm(x)
```

That's progress, yet the testing points are chosen manually and arbitrarily. It's hard to have many or very large input values, and unstated assumptions may affect their choice. For instance, is `t` going to work for non-numeric matrices?`quickcheck` can solve or at least alleviate all these problems:


```r
library(quickcheck)
test(
  forall(
    x = rmatrix(),
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))),
  about = "t")
```

```
Testing t
Using seed 1259503250
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 

Creating /tmp/quickcheck/23790. Use qc.options(work.dir = <alternate-path>) to change location.
....
```

We recognize the assertion in the previous code snippet, modified to take into account matrices with 0 rows or columns. Here, though, it becomes the body of a function, which is called "assertion" in `quickcheck`, which has one or more arguments, all with default values, and returns a length-one logical vector. `TRUE` means success, `FALSE` or an error mean failure. Some of those arguments are initialized randomly, in this case using what in `quickcheck` is called a Random Data Generator, or RDG -- more on these later. In this case `rmatrix` is a function that returns a random matrix. The `forall` function creates assertions and does little more than `function`, but its name clarifies intent. The `test` function evaluates the assertion multiple times and produces some messages: 

- The function being tested
- the seed used, unique to each test
- a "pass" message
- the assertion tested -- useful when scanning a log of a long series of tests
- when in non-interactive mode, a useful R expression -- more on that later.

The success of this test means that we have tested that `t` satisfies this assertion on a sample of random matrices, including a variety of sizes, element types and, of course, element values. We don't have to write them one by one and later we will see how we can affect the distribution of such inputs, to make them, say, larger in size or value, or more likely to hit corner cases.  If we need to control the number of time the assertion is run, that's very simple:


```r
test(
  forall(
    x = rmatrix(),
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))),
  about = "t",
  sample.size = 100)
```

```
Testing t
Using seed 1509435391
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 
```

Done! If one had to write down those 100 matrices one by one, there would never be time to.  Let's review the advantages of this setup. We can increase the severity of the test by cranking up the number of runs of the assertion, just by changing a parameter. We can also change the distribution of matrices to test larger inputs, see Section [Modifying or defining random data generators](#Modifying_or_defining_random_data_generators) and `help(rmatrix)`. Moreover `quickcheck` tests communicate intent. While each test is run in practice on a small set of examples, the promise implied by the test is unmistakably that it ought to pass for any matrix. Finally, a user doesn't have to guess from a small set of inputs what the function does and what its allowable range is. Assertions are also executable documentation.

## Defining assertions

Unlike `testthat`, which requires the constructions of specially defined *expectations*, `quickcheck` accepts logical-valued functions, with a length-one return value and a default value for each argument. For example 


```
function(x = rdouble()) all(x + 0 == x)
```

```
function(x = rlist()) identical(x, rev(rev(x)))
```

are valid assertions -- independent of their success or failure. For readability and safety, `forall` can be used, as in `forall(x = rdouble(), all(x + 0 == x))`. As an added benefit, `forall` checks that all arguments have a default. If an assertion returns `TRUE`, it is considered a success. If an assertion returns `FALSE` or generates an error, it is  considered a failure. For instance, `forall(x = rcharacter(), stop(x))` is a valid assertion but always fails. How can we express the fact that this is `stop`'s correct behavior? `testthat` has a rich set of expectations to capture this and other requirements, such as printing something or generating a warning. `quickcheck` has a way to access those, implemented as the function `expect`:


```r
test(
  forall(x = rcharacter(), expect("error", stop(x))),
  about = "stop")
```

```
Testing stop
Using seed 1383265062
Pass  
 function (x = rcharacter())  
 expect("error", stop(x)) 
```

By executing this test successfully we have built confidence that the function `stop` will generate an error whenever called with any `character` argument. `expect` implements four `testthat` expectations, "error", "message", "output", "warning". Other expectations are easily implemented [with ordinary R code](http://asceticprogrammer.info/post/109520467889/i-find-it-unnecessary-to-invent-a-new-vocabulary) and are not supported.

## What to do when tests fail

`quickcheck` doesn't fix bugs automatically yet, but tries to assist that activity in a couple of ways. The first is its output:


```r
test(forall(x = rdouble(), mean(x) > -0.2), stop = TRUE, about = "mean")
```

```
Testing mean
Using seed 1457646180
FAIL: assertion:
function (x = rdouble()) 
mean(x) > -0.2
FAIL: assertion:
function (x = rdouble()) 
mean(x) > -0.2
....
```

```
Error in test(forall(x = rdouble(), mean(x) > -0.2), stop = TRUE, about = "mean"): to reproduce enter repro("/tmp/quickcheck/23790/tr5cee55466a07")
```

This output shows that some of the default 10 runs have failed and then invites us to enter a command, `repro(<some-path>)`, that will execute the assertion in the debugger with the input data that made it fail. Another way to achieve the same is to run the test with the option `stop = FALSE` which doesn't produce an error and returns the same debugging data. This is convenient for interactive sessions, but less so when running `R CMD check`. In fact, the default for the `stop` argument is `FALSE` for interactive sessions and `TRUE` otherwise, which should work for most people.


```r
test.out = test(forall(x = rdouble(), mean(x) > 0), stop = FALSE, about = "mean")
```

```
Testing mean
Using seed 420616293
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
FAIL: assertion:
function (x = rdouble()) 
mean(x) > 0
....
```

 In most cases all we need to do with the output of `test` is to pass it to another function, `repro`:


```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > 0)(x = c(10.5458043647435, -138.624953856954, 49.5664878632335, 
-66.9953355464049, -38.8970215857726, -136.86988586223, -86.5668871131464, 
-13.5894142393942, -189.819518324129, -62.6379943337981, -75.9198540914486, 
-128.548593676381, -68.2659777135941, 41.3580570802318, 27.2987557256821, 
-76.0310627702327, 26.6203565939801, -69.1400147516596, 63.345593663904, 
-114.574436578846, 37.1978171467256, -54.7356639428537, 50.3751301526856, 
-25.5469414286095, -25.2534376063315, 61.5801458064715, -47.2352268183056, 
....
```

```
[1] FALSE
```

This opens the debugger at the beginning of a failed call to the assertion. Now it is up to the developer to fix any bugs.

To achieve reproducibility, one has to write assertions that depend exclusively on their arguments and are deterministic functions thereof, and leave all the randomness to `quickcheck` and the assertion arguments default values. The `test` function seeds the random number generator in a way that ensures reproducibility from one call to the next. The seed is unique to each assertion, to guarantee independence of tests on different assertions and different implementations -- one can't code assuming certain data will occur again and again.

## What tests should we write?

There is no general answer to this question. One possible criterion is that of *test coverage*, the fraction of code that has been executed during the execution of tests, which is considered a practical proxy for "thoroughness". The other is the strictness assertions. The conjunction of all the assertions in a test set should imply the correctness of a program, in the ideal case and when universally quantified over their inputs. For instance `test(forall(x = rinteger(), identical(x,x))` tests one important property of the `identical` function for all integer vectors. That doesn't mean it runs the test for all integer vectors, which is impossible, but it means that there should be no failure no matter how many runs we allow the test to include. Also, while this may be the ideal case, we should not let "perfection be the enemy of the good". Any set of assertions is better than no assertion.
 
The attentive reader may have already noticed that this is not the strictest test we could  have written, independent of the fact that it achieves 100% coverage. `identical` is supposed to work with any R object, so `test(forall(x = rany(), identical(x,x))` is also expected to pass and, if universally quantified over all inputs, implies the previous test, which means that it is stricter and better captures the developer's intent. Hence, we should prefer the latter version of this test.

As a final guideline  for test-writing, there is practical and some theoretical evidence that shorter programs can be tested more effectively, provided that the tests are also short. To summarize:

 - Write the strictest set of tests possible. Only a correct program should be able to pass them, given infinite time to run the tests
 - Aim for 100% coverage
 - Keep code and tests short. 
 
Quickcheck can help with the second point. Argument `cover` to function `test`, when set to TRUE or the name of a function will cause `test` to start a Shiny app detailing coverage for a specific function. To get a package-level coverage report, enter `coverage(<path-to-package>)`.


## <a name=Modifying_or_defining_random_data_generators></a>Modifying or defining random data generators

There are built in random data generators for most built-in data types. They follow a simple naming conventions, "r" followed by the class name. For instance `rinteger` generates a random integer vector. Another characteristic of random data generators as defined in this package is that they have defaults for every argument, that is they can be called without arguments. That's one difference with R random number generators, such as `rnorm` and `rpois`, the other being that those return a sample of a specific size, whereas for random data generators even that is random, unless specified otherwise. Like RNGs, quickcheck's generators promise statistical independence between calls -- whatever that means in the pseudo-random setting.


```r
set.seed(0)
rdouble()
```

```
 [1]  -32.6233361  132.9799263  127.2429321   41.4641434 -153.9950042
 [6]  -92.8567035  -29.4720447   -0.5767173  240.4653389   76.3593461
[11]  -79.9009249 -114.7657009  -28.9461574  -29.9215118  -41.1510833
[16]   25.2223448  -89.1921127   43.5683299 -123.7538422  -22.4267885
[21]   37.7395646   13.3336361   80.4189510   -5.7106774   50.3607972
[26]  108.5769362  -69.0953840 -128.4599354    4.6726172  -23.5706556
[31]  -54.2888255  -43.3310317  -64.9471647   72.6750747  115.1911754
[36]   99.2160365  -42.9513109  123.8304101  -27.9346282  175.7903090
....
```

```r
rdouble()
```

```
numeric(0)
```

Both elements and length change from one call to the next and in fact they are both random and independent. This is generally true for all generators, with the exception of the trivial generators created with `constant`. Most generators take two arguments, `elements` and `size` which are meant to specify the distribution of the elements and size of the returned data structures and whose exact interpretation depends on the specific generator. In general, if the argument `elements` is a numeric it is construed as providing parameters of the default RNG invoked to draw the elements, if it is a function, it is called with a single argument to generate the elements of the random data structure. For example:


```r
rdouble()
```

```
 [1]   -1.104548  -94.064916  -11.582532  -81.496871   24.226348
 [6] -142.509839   36.594112   24.841265    6.528818    1.915639
[11]   25.733838  -64.901008  -11.916876   66.413570  110.096910
```

generates some random double vector. The next expression does the same but with expectation 100 and standard deviation 20


```r
rdouble(elements = c(mean = 100, sd  = 20))
```

```
[1]  97.64493  81.75863  71.24828  84.05821 125.08166 115.44284  95.60969
[8]  91.50379  91.62040
```
and finally this extracts the elements from a uniform distribution with all parameters at default values.

```r
rdouble(elements = runif)
```

```
 [1] 0.3913593 0.3804939 0.8954454 0.6443158 0.7410786 0.6053034 0.9030816
 [8] 0.2937302 0.1912601 0.8864509 0.5033395 0.8770575 0.1891936 0.7581031
[15] 0.7244989 0.9437248 0.5476466 0.7117439 0.3889051 0.1008731 0.9273021
[22] 0.2832325 0.5905732 0.1103606 0.8405070 0.3179637 0.7828513 0.2675082
[29] 0.2186453 0.5167968 0.2689506 0.1811683 0.5185761 0.5627829 0.1291569
[36] 0.2563676 0.7179353 0.9614099 0.1001408 0.7632227 0.9479664 0.8186347
[43] 0.3082923
```

For other generators the parameters may have different names and semantics, for instance


```r
rinteger(elements = c(min = 3, max = 7))
```

```
 [1] 7 4 4 3 4 5 7 5 4 3 5 7 4 3 4
```

For added convenience, the vector of parameters is subject to argument matching as if they were argument to a separate function, for instance:


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
```

leaves the `min` component at its default. The defaults are controlled by package options, see `help(qc.options)`.

There is also a formula syntax, for instance to modify the parameters of `runif`, as in 


```r
rdouble(elements = ~runif(size, min = -1))
```

```
 [1]  0.56436423 -0.46424374  0.52430306  0.97262318 -0.41278890
 [6] -0.20129779  0.62426305 -0.84569666 -0.27260638 -0.11481507
[11] -0.68657173  0.16441054  0.94032436  0.97899967 -0.64709593
[16]  0.08426085 -0.23139222  0.35232810 -0.46141244 -0.06149812
[21] -0.65639984 -0.26162108  0.45081055 -0.02770179 -0.87239507
[26]  0.56909246 -0.16335673  0.96203617 -0.43423209  0.69576430
[31] -0.83552154  0.77291750 -0.05613854 -0.78179807 -0.33344403
[36]  0.67483314 -0.44630032  0.17407028  0.67346454 -0.85769195
....
```

which is the same as


```r
library(functional)
rdouble(elements = Curry(runif, min = -1))
```

```
[1] -0.9777010  0.8806174  0.9874985
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
Warning in rdata(elements, size): recycling random numbers
```

```
  [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [36] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 [71] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

A similar range of options is available for argument `size`. It can be a range, partially or completely specified, a RNG function or a formula returning exactly a vector of length 1.

First form:

```r
rdouble(size = c(max = 100))
```

```
 [1]   -6.063478  -50.137832   92.606273    3.693769 -106.620017
 [6]  -23.845635  149.522344  117.215855 -145.770721    9.505623
[11]   84.766496 -162.436453  140.856336  -54.176036   27.866472
[16]  -19.397274  157.615818 -147.554764  -14.460821 -107.501019
[21]   40.654273  222.926220 -151.449701   -6.170742  -14.727079
[26]  154.159307  -98.185567   49.657817  169.694788  -26.073631
[31]  -70.592859  -16.117851   50.132183 -101.353967
```

Second form:

```r
rdouble(size = c(min = 0, max = 10))
```

```
[1]    0.5641985 -290.4899060 -110.7164819  154.7566933  -97.6830350
[6]  -10.1503448    4.2650250 -159.6718014   49.0967373
```

RNG:


```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1]   -6.965481  -24.766434   69.555081  114.622836 -240.309621   57.273956
[7]   37.472441
```

With the formula syntax:


```r
rdouble(size = ~10*runif(1))
```

```
[1]   35.28745   55.03934 -113.43310
```

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`, with the same possible values. Nested data structures have an argument `height`. For now `height` can only be one number construed as maximum height and applies only to `rlist`. To define a test with a random vector of a specific length as input, one can use the generator constructor `constant`:


```r
rdouble(size = constant(3))
```

```
[1] 146.23515  70.21167 250.71111
```

```r
rdouble(size = constant(3))
```

```
[1] -189.00271  -58.98128 -171.45023
```

Or, since ["succintness is power"](http://www.paulgraham.com/power.html):


```r
rdouble(size = ~3)
```

```
[1] -42.09979  31.01414 170.25706
```

Without the `~` it would be a min size, with it it is deterministic. Sounds contrived, but if one starts with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. 

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

We can not exclude adjustments to the default distributions in future versions. Please don't write tests that rely on implementation details of the generators.

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
Testing is.reciprocal.self.inverse
Using seed 1218381074
Pass  
 function (x = rdouble())  
 is.reciprocal.self.inverse(x) 
```

and one for the corner cases:

```r
test(forall(x = rsample(c(0, -Inf, Inf)), is.reciprocal.self.inverse(x)))
```

```
Testing is.reciprocal.self.inverse
Using seed 1421030040
Pass  
 function (x = rsample(c(0, -Inf, Inf)))  
 is.reciprocal.self.inverse(x) 
```

That's a start, but the two types of values never mix in the same vector. We can combine the two with a custom generator


```r
rdoublex =
  function(elements = c(mean = 0, sd = 1), size = c(min = 0, max = 100)) {
    data = rdouble(elements, size)
    sample(
      c(data, c(0, -Inf, Inf)),
      size = length(data),
      replace = FALSE)}
rdoublex(size = ~10)
```

```
 [1]         Inf -0.12589279 -0.41486412        -Inf -0.13377222
 [6]  0.06936754 -0.53545759 -1.06867910 -1.14770851  1.54599703
```

```r
rdoublex(size = ~10)
```

```
 [1]  0.3887475  0.9186447 -0.8863064 -2.0320849        Inf -1.3586576
 [7] -0.8698331       -Inf  0.0000000 -1.8034260
```
		
And use it in a more general test.


```r
test(forall(x = rdoublex(), is.reciprocal.self.inverse(x)))
```

```
Testing is.reciprocal.self.inverse
Using seed 890091164
Pass  
 function (x = rdoublex())  
 is.reciprocal.self.inverse(x) 
```

### Composition of generators

The alert reader may have already noticed how generators can be used to define other generators. For instance, a random list of double vectors can be generated with `rlist(rdouble)` and a list thereof with `rlist(function() rlist(rdouble))`. Since typing `function()` over and over again gets old quickly and adds clutter, we can use `~` as a shortcut `rlist(~rlist(rdouble))`. 
