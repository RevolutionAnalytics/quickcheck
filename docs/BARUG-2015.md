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
### <b>
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
### </b>
rm(x)
```

# Randomized Testing

## {.build}


```r
library(quickcheck)
test(
  forall(
    x = rmatrix(),
### <b>
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
### </b>
```


```
Using seed 477281578
Pass  
 function (x = rmatrix())  
 any(dim(x) == c(0, 0)) || all(sapply(1:nrow(x), function(i) all(x[i,  
     ] == t(x)[, i]))) 

Creating /tmp/quickcheck/99444. Use qc.options(tmpdir = <alternate-path>) to change location.
```

# Advantages

## {.build}


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
  forall(x = rcharacter(), expect("error", stop(x))))
```

```
Using seed 770024200
Pass  
 function (x = rcharacter())  
 expect("error", stop(x)) 
```

# Failure

## {.build}


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
Error: to reproduce enter repro("/tmp/quickcheck/99444/tr18474854051b")
```

## {.build}


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

## {.build}


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


# Writing Tests

## {.build}


```r
test(forall(x = rinteger(), identical(x,x))) 
```

```
Using seed 1546314784
Pass  
 function (x = rinteger())  
 identical(x, x) 
```


```r
test(forall(x = rany(), identical(x,x)))
```

```
Using seed 589672567
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

## {.build}


```r
rdouble()
```

```
 [1]   -1.105  -94.065  -11.583  -81.497   24.226 -142.510   36.594
 [8]   24.841    6.529    1.916   25.734  -64.901  -11.917   66.414
[15]  110.097
```


```r
rdouble(elements = c(mean = 100, sd  = 20))
```

```
[1]  97.64  81.76  71.25  84.06 125.08 115.44  95.61  91.50  91.62
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
 [1] 0.93291 0.47068 0.60359 0.48499 0.10881 0.24773 0.49851 0.37287
 [9] 0.93469 0.52399 0.31714 0.27797 0.78754 0.70246 0.16503 0.06446
[17] 0.75471 0.62041 0.16958 0.06221 0.10903 0.38172 0.16931 0.29865
[25] 0.19221 0.25717 0.18123 0.47731 0.77074 0.02779 0.52731 0.88032
[33] 0.37306 0.04796 0.13863 0.32149 0.15483 0.13223 0.22131 0.22638
....
```


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

## {.build}


```r
library(functional)
rdouble(elements = Curry(runif, min = -1))
```

```
[1] -0.9777  0.8806  0.9875
```

## {.build}


```r
rdouble(size = c(max = 100))
```

```
[1]  81.656  -6.063 -50.138
```



```r
rdouble(size = c(min = 0, max = 10))
```

```
[1]    3.694 -106.620  -23.846  149.522  117.216 -145.771
```



```r
rdouble(size = function(n) 10 * runif(n))
```

```
[1] -125.3290   64.2241   -4.4709 -173.3218    0.2132
```



```r
rdouble(size = ~10*runif(1))
```

```
[1]  -19.4  157.6 -147.6
```

## {.build}


```r
rdouble(size = constant(3))
```

```
[1]  -14.46 -107.50   40.65
```

```r
rdouble(size = constant(3))
```

```
[1]  222.926 -151.450   -6.171
```



```r
rdouble(size = ~3)
```

```
[1] -14.73 154.16 -98.19
```

<!--
## {.build}


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
Using seed 1509604841
Pass  
 function (x = rdouble())  
 is.reciprocal.self.inverse(x) 
```

## {.build}


```r
test(forall(x = rsample(c(0, -Inf, Inf)), is.reciprocal.self.inverse(x)))
```

```
Using seed 590705710
Pass  
 function (x = rsample(c(0, -Inf, Inf)))  
 is.reciprocal.self.inverse(x) 
```

## {.build}


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

## {.build}


```r
test(forall(x = rdoublex(), is.reciprocal.self.inverse(x)))
```

```
Using seed 1300498190
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
