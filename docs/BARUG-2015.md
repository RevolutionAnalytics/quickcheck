# Randomized testing with Quickcheck
Revolution Analytics  





# Testing
 
## {.build}


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


```r
for(x in list(matrix(c(1,2,3,4), ncol = 2), matrix(c(5:10), ncol = 3)))
  test_that(
    "transpose  test",
    expect_true(
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
rm(x)
```

# Randomized Testing

## {.build}


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
Using seed 734758519
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 

Creating /tmp/quickcheck/37643.
 Use qc.options(work.dir = <alternate-path>) to change location.
```

# Advantages

## {.build}


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
Using seed 1193381102
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 
```

# Assertions

##  {.build}


```r
function(x = rdouble(), y = rdouble()) all(x + y == y + x))
```


```r
function(x = rlist()) identical(x, rev(rev(x)))
```


```r
forall(x = rdouble(), y = rdouble(), all(x + y == y + x))
```


```r
forall(x = rcharacter(), stop(x))
```



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

# Failure

## {.build}


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
```

```
Error in test(forall(x = rdouble(), mean(x) > -0.2), stop = TRUE, about = "mean"): 
to reproduce enter repro("/tmp/quickcheck/37643/tr930b404c9047")
```

## {.build}


```r
test.out = test(forall(x = rdouble(), mean(x) > -0.2), stop = FALSE, about = "mean")
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
```

## {.build}


```r
repro(test.out)
```

```
debugging in: (function (x = rdouble()) 
mean(x) > -0.2)(x = c(-6.65729066543014, -14.3899169752211, 31.9287715279062, 
-89.7578411993386, -168.372562610363, -121.325771981739))
debug: mean(x) > -0.2
exiting from: (function (x = rdouble()) 
....
```

```
[1] FALSE
```


# Writing Tests

## {.build}


```r
test(forall(x = rinteger(), identical(x,x)), about = "identical") 
```

```
Testing identical
Using seed 257169588
Pass  
 function (x = rinteger())  
 identical(x, x) 
```


```r
test(forall(x = rany(), identical(x,x)), about = "identical")
```

```
Testing identical
Using seed 430915620
Pass  
 function (x = rany())  
 identical(x, x) 
```


# Random Data Generators

## {.build}


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
....
```

```r
rdouble()
```

```
numeric(0)
```

## {.build}


```r
rdouble()
```

```
 [1]   -1.104548  -94.064916  -11.582532  -81.496871   24.226348
 [6] -142.509839   36.594112   24.841265    6.528818    1.915639
[11]   25.733838  -64.901008  -11.916876   66.413570  110.096910
```


```r
rdouble(elements = c(mean = 100, sd  = 20))
```

```
[1]  97.64493  81.75863  71.24828  84.05821 125.08166 115.44284  95.60969
[8]  91.50379  91.62040
```

## {.build}


```r
rinteger(elements = c(min = 3, max = 7))
```

```
 [1] 4 4 7 6 6 6 7 4 3 7 5 7 3 6 6 7 5 6 4 3 7 4 5 3 7 4 6 4 4 5 4 3 5 5 3
[36] 4 6 7 3 6 7 7 4
```


```r
rinteger(elements = c(3, 7))
```

```
 [1] 7 4 4 3 4 5 7 5 4 3 5 7 4 3 4
```



```r
rinteger(elements = c(max = 7))
```

```
 [1] -26 -26 -41 -54 -52 -67 -38  -2 -85 -56 -78 -54 -86 -51
```

## {.build}



```r
rdouble(elements = runif)
```

```
 [1] 0.93290983 0.47067850 0.60358807 0.48498968 0.10880632 0.24772683
 [7] 0.49851453 0.37286671 0.93469137 0.52398608 0.31714467 0.27796603
[13] 0.78754051 0.70246251 0.16502764 0.06445754 0.75470562 0.62041003
[19] 0.16957677 0.06221405 0.10902927 0.38171635 0.16931091 0.29865254
[25] 0.19220954 0.25717002 0.18123182 0.47731371 0.77073704 0.02778712
....
```


```r
rdouble(elements = ~runif(size, min = -1))
```

```
 [1]  0.56436423 -0.46424374  0.52430306  0.97262318 -0.41278890
 [6] -0.20129779  0.62426305 -0.84569666 -0.27260638 -0.11481507
[11] -0.68657173  0.16441054  0.94032436  0.97899967 -0.64709593
[16]  0.08426085 -0.23139222  0.35232810 -0.46141244 -0.06149812
[21] -0.65639984 -0.26162108  0.45081055 -0.02770179 -0.87239507
....
```

## {.build}


```r
library(functional)
rdouble(elements = Curry(runif, min = -1))
```

```
[1] -0.9777010  0.8806174  0.9874985
```

## {.build}


```r
rdouble(size = c(max = 100))
```

```
[1]  81.655645  -6.063478 -50.137832
```



```r
rdouble(size = c(min = 0, max = 10))
```

```
[1]    3.693769 -106.620017  -23.845635  149.522344  117.215855 -145.770721
```



```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1] -125.328976   64.224131   -4.470914 -173.321841    0.213186
```



```r
rdouble(size = ~10*runif(1))
```

```
[1]  -19.39727  157.61582 -147.55476
```

## {.build}


```r
rdouble(size = constant(3))
```

```
[1]  -14.46082 -107.50102   40.65427
```

```r
rdouble(size = constant(3))
```

```
[1]  222.926220 -151.449701   -6.170742
```



```r
rdouble(size = ~3)
```

```
[1] -14.72708 154.15931 -98.18557
```

<!--
## {.build}


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
-->


## {.build}

|function| description|
|---|---|
`rany` | any R object|
`ratomic` | any atomic vector|
`rcharacter` | character
`rdata.frame` |data.frame|
`rDate` |Date|
`rdouble` |double|
`rfactor` |factor|

## {.build}

|function| description|
|---|---|
`rinteger` | integer|
`rlist` | list|
`rlogical` | logical
`rmatrix` | matrix
`rnamed` | random names for a vector
`rnumeric` | any numeric|
`rraw` |raw
`rsample` | sample from vector

## {.build}

|function| description|
|---|---|
`constant` | trivial constant RDG
`mixture` | mixture RDG
`named` | named version of any RDG


<!--

# Custom Generators

## {.build} 


```r
is.reciprocal.self.inverse = function(x) isTRUE(all.equal(x, 1/(1/x)))
```



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

## {.build}


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

## {.build}


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

## {.build}


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

## {.build}

```r
rlist(rdouble)
```

```r
rlist(function() rlist(rdouble))
```


```r
rlist(~rlist(rdouble))
```

-->

## Repo

- http://github.com/RevolutionAnalytics/quickcheck
