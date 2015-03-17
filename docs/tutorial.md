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

Let's start with something very simple. Let's say we just wrote the function `t` for transpose. Using the widely used testing package `testthat`, one would like to write a test like:


```r
library(testthat)
```


```r
test_that("transpose self inverse test", expect_identical(t(t(x)), x))
```

That in general doesn't work because `x` is not defined. What I meant was something like a universally quantified statement *for all legal values of `x`*, but there isn't any easy way of implementing that. So a developer has to enter some values for `x`.



```r
for(x in list(matrix(c(1,2,3,4), ncol =2), matrix(c(5:10), ncol = 3)))
  test_that("transpose self inverse test", expect_identical(t(t(x)),x))
rm(x)
```

But there is no good reason to pick those specific examples, testing on more data  points or larger values would increase the clutter factor, a developer may inadvertently inject unwritten assumptions in the choice of data points etc. `quickcheck` can solve or at least alleviate all those problems:


```r
library(quickcheck)
test(forall(x = rmatrix(), identical(t(t(x)), x)))
```

```
Using seed 2055293039
Pass  
 function (x = rmatrix())  
 identical(t(t(x)), x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  31900   34000   39800   44800   44200   98300 
```

```
Creating /tmp/quickcheck/74203. Use qc.options(tmpdir = <alternate-path>) to change location.
```

We have supplied an assertion, that is a function with defaults for each argument, at least some set using random data generators, and returning a length-one logical vector, where `TRUE` means *passed* and `FALSE` or error means *failed*. Random data generators are related to random number generators in R, but they also vary the size of the return value randomly, and in same cases even its type. Quickcheck provides a selection of random data generators for most common R types and they are highly configurable.

What this test success means is that we have tested that `t` satisfies this assertion on a sample of random matrices, including a variety of sizes, element types and, of course, element values. We don't have to write them down one by one and later we will see how we can affect the distribution of such vectors, to make them, say, larger in size or value, or more likely to hit corner cases.  We can also repeat the test multiple times on different values with the least amount of effort -- in fact, we have already executed this test 10 times, which is the default. But if 100 times is required, no problem:


```r
test(forall(x = rmatrix(), identical(t(t(x)), x)), sample.size = 100)
```

```
Using seed 2055293039
Pass  
 function (x = rmatrix())  
 identical(t(t(x)), x) 
```

```
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  29700   31800   33600   35700   37100  104000 
```

Done! You see, if you had to write down those 100 matrices one by one, you would never have time to.  Quickcheck contains a whole repertoire of random data generators, including `rinteger`, `rdouble`, `rcharacter` etc. for most atomic types, and some also for non-atomic types such as `rlist` and `rdata.frame`. The library is easy to extend with your own generators and offers a number of constructors for data generators such as `constant` and `mixture`. There even is a generator `rany` that creates a mixture of all R types (in practice, the ones that `quickcheck` currently knows how to generate, but the intent is all of them). 

You may have noticed in the output some performance information. That's a first step toward adding performance testing capabilities in future releases.

## Defining assertions

Unlike `testthat` where you need to construct specially defined *expectations*, `quickcheck` accepts logical-valued functions, with a length-one return value and a default value for each argument. For example `function(x = rdouble()) all(x + 0 == x)` or `function(x = rlist()) identical(x, rev(rev(x)))` are valid assertions -- independent of their success or failure. For readability and safety, you can use `forall` as in `forall(x = rdouble(), all(x + 0 == x))` (`forall` checks that all arguments have a default). If an assertion returns `TRUE`, it is considered a success. If an assertion returns `FALSE` or generates an error, it is  considered a failure. For instance, `forall(x = rcharacter(), stop(x))` is a valid assertion but always fails. How do I express the fact that this is its correct behavior? `testthat` has a rich set of expectations to capture that and other requirements, such as printing something or generating a warning. Derived from those, `quickcheck` has an equivalent set of predefined assertion helpers, returned by the function `expect`:


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
1990000 2120000 2210000 2390000 2370000 4050000 
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
Error: repro("/tmp/quickcheck/74203/tr121db751834a1")
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
 [1]   30.23  -90.35  147.54   84.67   24.44  147.40   69.66   12.13
 [9]  130.66 -142.24  -22.43 -120.56   62.23 -129.12  -21.71  157.95
[17]   41.74  -47.86  -25.48   78.70  147.21  109.47   16.92  -94.71


$cases[[2]]
$cases[[2]]$x
[1] -12.74 180.93  94.25 103.14 -44.39 217.95


$cases[[3]]
$cases[[3]]$x
 [1]   95.422  160.247  -45.794   25.387   23.795  -64.653   17.253
 [8]  -12.464  203.773  -52.115   92.438  -53.802  -40.604    5.535
[15]  -96.459 -109.683   58.029   16.353 -126.000  -53.255  -14.273
[22]  -96.816  -69.660  125.992  -90.196   60.196   18.600    4.994
[29]    4.584   23.623  -17.451   27.210  -90.159  -29.591 -116.876
[36]   13.173  177.219   22.919   62.227 -184.341  -17.959  144.827
[43]   35.883   78.835   40.414  -47.551 -109.144   20.106 -176.666
[50]  125.194 -307.372 -179.329  116.614   72.302   70.832   83.026
[57]   49.849  -20.496  -70.845 -142.589 -126.418  -85.420 -136.640
[64]  -98.673   12.549   24.594


$cases[[4]]
$cases[[4]]$x
 [1]  -70.25 -225.29   60.52  -53.84  160.15   53.08   61.51   33.07
 [9] -143.24  -67.33   67.84  101.34 -274.27   10.05   80.51


$cases[[5]]
$cases[[5]]$x
numeric(0)


$cases[[6]]
$cases[[6]]$x
 [1]   83.8874   41.3460  -56.1588   74.6893    9.6191  -47.2369  -26.6739
 [8]   13.6375   -5.8388   50.4788  223.1645  -72.4229   19.9486 -242.4169
[15]   -0.1925   52.3147  -90.3645  -67.9644  -72.8291  114.1604 -217.3861
[22]   36.5910    8.5331 -120.1570    3.7068  -87.6672  -76.8738  -94.1695
[29]   68.7986  -49.3409  125.5676  -16.0159   89.2088  180.3242   31.3395
[36]   17.9524  -27.7861   -0.2758   71.7291 -105.0380    1.6056  255.0941
[43]  -13.3981   96.0800 -147.5796   -4.4352  164.2116  103.1424  112.8283
[50]  -14.6528  -27.5456  -23.9791  173.6533  150.6851  153.1711 -129.9755
[57]  164.5737   72.1590


$cases[[7]]
$cases[[7]]$x
[1] -108.1 -102.5


$cases[[8]]
$cases[[8]]$x
 [1]  -96.074   15.607  172.231   -3.361  -24.872  150.884  -39.833
 [8]   35.353   37.796   78.716  198.692  -39.817  -17.504  249.590
[15]   12.658   -9.146  223.155  -32.314  158.819  -48.906   71.488
[22]  142.401  -59.159   57.753  156.502 -103.347  -30.921


$cases[[9]]
$cases[[9]]$x
 [1] -182.4152  -43.0800   -0.7844   54.7517  -44.6931  -32.0640   22.5682
 [8]  219.9938   28.9261  134.4991   67.6724


$cases[[10]]
$cases[[10]]$x
 [1] -133.6441  -14.0297 -143.0724  118.8524 -114.6992  242.4669  -37.3830
 [8]    3.0691   79.2102  -85.3620  -53.0852   20.1529 -148.2454   86.0312
[15]  -45.3053  140.1637   23.9451  186.2628   89.9620   77.7193   54.0741
[22]  -44.3657  145.7331  184.3038  121.2508   42.1546 -243.3366  140.8445
[29] -100.4693   -6.3112   -4.0823 -178.1115 -133.9058  -13.9660  -46.5035
[36]  164.0090  152.8117   -0.5749   91.7690   43.7919    8.2102   93.0675
[43] -215.6150   81.7335   58.2618  -42.6668  106.7141  -39.1231   78.3340
[50] -253.7700   21.9546   82.2783   92.2768   28.5932  -24.7575 -262.5270
[57]  -27.8361  -97.7953  -66.2059   28.6508  -70.3984  -19.3608  142.4069
[64] -247.1285   89.7244  128.4257  208.6695   33.8146  -50.1988   79.2563
[71]   -1.7874   57.4255   96.3371  -10.8953   12.6059   33.8523   -9.1788
[78]  232.8219   64.2209   16.2955   51.5385  101.8698  -16.2072   59.9606
[85]   -8.2975  -12.4083   90.6222



$pass
 [1]  TRUE  TRUE FALSE FALSE    NA  TRUE FALSE  TRUE  TRUE  TRUE

$coverage
NULL

$elapsed
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  25500   26300   26800   27100   27300   31400 
```

The output is a list with elements:

  - the assertion that failed
  - a list of in-scope variables that could have affected the result -- this is work in progress and shouldn't be trusted at this time
  - a list of lists of arguments passed to the assertion in each run 
  - the outcome of each run
  - optional coverage information
  - some performance stats
  
A recommended practice is to write assertions that depend exclusively on their arguments and are deterministic functions, and leave all the randomness to `quickcheck` and the assertion arguments default values. This is because the first step in fixing a bug is almost always to reproduce it, and non-deterministic bugs are more difficult to reproduce. The `test` function seeds the random number generator so that every time it is called it will rerun the same tests, that is call the assertion with the same arguments, run after run. Different assertions should have different seeds, but small edits to an assertion should not change the seed in most cases, which is helpful for developing the assertion itself. In most cases all we need to do with the output of `test` is to pass it to another function, `repro`:



```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > 0)(x = c(95.4220841095448, 160.246710415966, -45.794324713949, 
25.3869065691574, 23.7946291303444, -64.6528676719553, 17.2532503680657, 
-12.4640292985689, 203.772824804286, -52.1154926680255, 92.4381620907306, 
-53.8018711197192, -40.6044884240434, 5.53494104755664, -96.4591445419219, 
-109.683471253244, 58.0287678728267, 16.3525969901045, -126.000189107398, 
-53.255300164802, -14.2731714455475, -96.816445430208, -69.659853319032, 
125.992306242745, -90.1956918321312, 60.1962863666949, 18.6002068439976, 
4.99428030800119, 4.58402264147253, 23.623411052165, -17.4508456991157, 
27.209622142362, -90.1588911365441, -29.5911341572048, -116.876063189637, 
13.1728185982359, 177.218919685008, 22.918513324043, 62.2273004400145, 
-184.340606782764, -17.9591518749144, 144.826739712447, 35.8834848574434, 
78.835223509374, 40.414151866309, -47.5514286265603, -109.144147376676, 
20.1060240788122, -176.666011435914, 125.194260988087, -307.37210087961, 
-179.328859839397, 116.614258802597, 72.3015207164044, 70.8316830826215, 
83.0263255157706, 49.8493399679659, -20.4958968102388, -70.8449904349165, 
-142.588780669802, -126.418333050793, -85.41982546496, -136.639818355124, 
-98.673091366056, 12.5492398761927, 24.5937200252946))
debug: mean(x) > 0
exiting from: (function (x = rdouble()) 
mean(x) > 0)(x = c(95.4220841095448, 160.246710415966, -45.794324713949, 
25.3869065691574, 23.7946291303444, -64.6528676719553, 17.2532503680657, 
-12.4640292985689, 203.772824804286, -52.1154926680255, 92.4381620907306, 
-53.8018711197192, -40.6044884240434, 5.53494104755664, -96.4591445419219, 
-109.683471253244, 58.0287678728267, 16.3525969901045, -126.000189107398, 
-53.255300164802, -14.2731714455475, -96.816445430208, -69.659853319032, 
125.992306242745, -90.1956918321312, 60.1962863666949, 18.6002068439976, 
4.99428030800119, 4.58402264147253, 23.623411052165, -17.4508456991157, 
27.209622142362, -90.1588911365441, -29.5911341572048, -116.876063189637, 
13.1728185982359, 177.218919685008, 22.918513324043, 62.2273004400145, 
-184.340606782764, -17.9591518749144, 144.826739712447, 35.8834848574434, 
78.835223509374, 40.414151866309, -47.5514286265603, -109.144147376676, 
20.1060240788122, -176.666011435914, 125.194260988087, -307.37210087961, 
-179.328859839397, 116.614258802597, 72.3015207164044, 70.8316830826215, 
83.0263255157706, 49.8493399679659, -20.4958968102388, -70.8449904349165, 
-142.588780669802, -126.418333050793, -85.41982546496, -136.639818355124, 
-98.673091366056, 12.5492398761927, 24.5937200252946))
```

```
[1] FALSE
```
As before, this opens the debugger at the beginning of a failed call to the assertion. Now it is up to the developer to fix any bugs.

## What tests should I write?

There is no general answer to this question, as you can imagine. One possible criterion is that of *test coverage*, the fraction of code that has been executed during the execution of tests. The other is the strictness of your assertions. The conjunction of all the assertions in your test set should imply the correctness of your program, in the ideal case and when universally quantified over their inputs. For instance `test(forall(x = rinteger(), identical(x,x))` tests one important property of the `identical` function for all integer vectors. That doesn't mean it runs the test for all integer vectors, which is impossible, but it means two related concepts:

 - The developer meant that the function should work for all integer vectors, so it works as a specification.
 - The test can in principle run on any integer vector and should pass in each case, you are not restricted to the original `sample.size`; you can run as many times as needed.
 
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
```

For other generators the paramters may have different names and semantics, for instance


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
[36]  0.67483 -0.44630  0.17407  0.67346 -0.85769  0.40556  0.39765
[43] -0.07208 -0.12614  0.12435  0.85697 -0.53907 -0.55637 -0.15957
[50] -0.33296  0.72962 -0.64561 -0.01336 -0.14057  0.12853  0.31232
[57]  0.95711 -0.53568 -0.51838  0.59367  0.66334 -0.77298  0.92662
[64] -0.70535 -0.71275  0.85046  0.01407 -0.69030 -0.30340  0.31964
[71] -0.37646 -0.29685 -0.70431  0.31776 -0.62986  0.90876  0.79570
[78]  0.88739  0.44738
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
 - a formula containing the variable `size` and evalating to a length `size` vector. 
 
 In general the RNG or forumula should return exactly `size` elements. If not, recycling will be applied after issueing a warning. Recycling random numbers in general changes their stochastic properties and it is not recommended. But there are some use cases, like creating a random-length vector of 0s.
 

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

Two dimensional data structures have the argument `size` replaced by `nrow` and `ncol`, with the same possibile values. Nested data structures have an argument `height`. For now `height` can only be one number construed as maximum height and applies only to `rlist`. If you need to define a test with a random vector of a specific length as input, use the generator constructor `constant`:


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

Without the `~` it would be a min size, with it it is deterministic. Sounds contrived, but if you start with the assumption that in `quickcheck` random is the default, it make sense that slightly more complex expressions be necessary to express determinism. Another simple generator is `rsample`, which creates a generator that picks randomly from a list, provided as argument -- not unlike `sample`, but consistent with the `quickcheck` definition of generator.


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
integer(0)
```

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
  53800   56300   70100  119000   90500  479000 
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
  51400   55500   59900   58900   61700   67800 
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
  54000   61000   68900   73400   82500  116000 
```

### Composition of generators

The alert reader may have already noticed how generators can be used to define other generators. For instance, a random list of double vectors can be generated with `rlist(rdouble)` and a list thereof with `rlist(function() rlist(rdouble))`. Since typing `function()` over and over again gets old quickly and adds clutter, we can use `~` as a shortcut `rlist(~rlist(rdouble))`. 
