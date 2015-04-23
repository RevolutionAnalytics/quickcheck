## @knitr library-testthat
library(testthat)
##@knitr end
if(FALSE)
## @knitr test_that
test_that(
  "transpose test",
  expect_identical(
    t(matrix(as.numeric(1:6), ncol = 3)),
    matrix(c(1,3,5,2,4,6), ncol = 2)))
## @knitr for-test_that
for(x in list(matrix(c(1,2,3,4), ncol = 2), matrix(c(5:10), ncol = 3)))
  test_that(
    "transpose  test",
    expect_true(
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))))
rm(x)
## @knitr test
library(quickcheck)
test(
  forall(
    x = rmatrix(),
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))),
  about = "t")
## @knitr sample.size
test(
  forall(
    x = rmatrix(),
    any(dim(x) == c(0,0)) ||
      all(sapply(1:nrow(x), function(i) all(x[i,] == t(x)[,i])))),
  about = "t",
  sample.size = 100)
## @knitr expect
test(
  forall(x = rcharacter(), expect("error", stop(x))),
  about = "stop")
## @knitr end
if(FALSE)
## @knitr output
test(forall(x = rdouble(), mean(x) > 0), stop = TRUE, about = "mean")
##  @knitr return-value
test.out = test(forall(x = rdouble(), mean(x) > 0), stop = FALSE, about = "mean")
## @knitr end
if(FALSE)
## @knitr repro
repro(test.out)
## @knitr rdouble
set.seed(0)
rdouble()
rdouble()
## @knitr rdouble-2
rdouble()
## @knitr rdouble-mean-sd
rdouble(elements = c(mean = 100, sd  = 20))
## @knitr rdouble-runif
rdouble(elements = runif)
## @knitr rinteger-min-max
rinteger(elements = c(min = 3, max = 7))
## @knitr rinteger-unnamed
rinteger(elements = c(3, 7))
## @knitr rinteger-matching
rinteger(elements = c(max = 7))
## @knitr rdouble-formula
rdouble(elements = ~runif(size, min = -1))
## @knitr rdouble-Curry
library(functional)
rdouble(elements = Curry(runif, min = -1))
## @knitr rinteger-formula
rinteger(elements = ~0, size = 100)
## @knitr rdouble-size-max
rdouble(size = c(max = 100))
## @knitr rdouble-size-min-max
rdouble(size = c(min = 0, max = 10))
## @knitr rdouble-size-function
rdouble(size = function(n) 10 * runif(n))
## @knitr rdouble-size-formula
rdouble(size = ~10*runif(1))
## @knitr rdouble-size-constant
rdouble(size = constant(3))
rdouble(size = constant(3))
## @knitr rdouble-size-formula-2
rdouble(size = ~3)
## @knitr rsample
rsample(elements = 1:5, c(max = 10))
rsample(elements = 1:5, c(max = 10))
## @knitr is.reciprocal.self.inverse
is.reciprocal.self.inverse = function(x) isTRUE(all.equal(x, 1/(1/x)))
## @knitr test-is.reciprocal.self.inverse
test(forall(x = rdouble(), is.reciprocal.self.inverse(x)))
## @knitr corner-cases
test(forall(x = rsample(c(0, -Inf, Inf)), is.reciprocal.self.inverse(x)))
## @knitr rdoublex
rdoublex =
  function(elements = c(mean = 0, sd = 1), size = c(min = 0, max = 100)) {
    data = rdouble(elements, size)
    sample(
      c(data, c(0, -Inf, Inf)),
      size = length(data),
      replace = FALSE)}
rdoublex(size = ~10)
rdoublex(size = ~10)
## @knitr test-rdoublex
test(forall(x = rdoublex(), is.reciprocal.self.inverse(x)))
