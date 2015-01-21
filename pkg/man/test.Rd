\name{test}
\alias{test}
\alias{repro}
\title{
Run tests}
\description{
\code{test} evaluates an assertion with arguments provided by evaluating repeatedly a list of generators. Stops or returns test cases. \code{repro} help reproducing any error that might have occurred. 
}
\usage{
test(assertion, sample.size = 10, stop = TRUE)
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector and defaults for all arguments.}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, once called, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. \code{set.seed(0)} is performed at the beginning of each test for reproducibility.}

\value{When \code{stop} is FALSE, a list with three elements 
\enumerate{
\item{The assertion being evaluated}
\item{A list of in-scope variables for the assertion that may affect its result (still work-in-progress, consider incomplete)}
\item{A list of list of arguments passed to the assertion, one per run. An element is NULL if a run passed}
}
When \code{stop} is TRUE, the default, there is no returned value but the same list is stored in a file. The command to load that file into the current environment as the variable \code{test.cases} is printed as the error message. This allows to replicate the error.
}

\examples{
test(function(x = rdouble(10)) all(x + 0 == x))
}
