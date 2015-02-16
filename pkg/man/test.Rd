\name{test}
\alias{test}
\alias{repro}
\title{
Run and debug tests}
\description{
\code{test} evaluates an assertion multiple times by re-evaluating its arguments, some of which are expected to be random data generators. Stops or returns a test report. \code{repro} helps reproducing any error that might have occurred. 
}
\usage{
test(assertion, sample.size = 10, stop = !interactive())
repro(test.report, i = first.false(test.report$pass), debug = TRUE)
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector and defaults for all arguments.}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
  \item{test.report}{The valued returned by test when \code{stop} is \code{FALSE}}
  \item{i}{A number identifying test case the developer would like to reproduce, defaults to the first failed}
  \item{debug}{Whether to debug the assertion or just rerun it}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, once called, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. \code{set.seed(0)} is performed at the beginning of each test for reproducibility.}

\value{For \code{test}, when \code{stop} is FALSE, a list with five elements:
\enumerate{
\item{The assertion being evaluated}
\item{A list of in-scope variables for the assertion that may affect its result (still work-in-progress, consider incomplete)}
\item{A list of list of arguments passed to the assertion, one per run. An element is NULL if a run passed}
\item{A logical vector of test results}
\item{A summary of elapsed times for each test run, in the units returned by \code{microbenchmark::get_nanotime}}
}
When \code{stop} is TRUE, there is no return value but the same list is stored in a file. The command to load that file into the current environment as the variable \code{test.report} is printed as the error message. This allows to replicate the error. Run time information is also printed in stderr on success. For \code{repro}, the value returned by the assertion.}

\examples{
test(function(x = rdouble(10)) all(x + 0 == x))
#repro(test(function(x = rdouble(10)) all(x + 1 == x), stop = FALSE))
#stop argument set to FALSE automatically when in an interactive session
#repro(test(function(x = rdouble(10)) all(x + 1 == x)))
}
