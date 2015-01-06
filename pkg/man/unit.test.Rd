\name{unit.test}
\alias{unit.test}
\alias{catch.out}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Generate unit tests}
\description{
Evaluates a assertion with n arguments provided by evaluating the generators. Stops or returns test cases.
}
\usage{
unit.test(assertion, generators = list(), sample.size = 10, stop = TRUE)
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector}
  \item{generators}{A list of random data generators, one per argument needed by the \code{assertion} argument}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, evaluated with randomly generated arguments, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. The arguments for each run of the test are generated using the generators provided with the \code{generators} argument. \code{set.seed(0)} is performed at the beginning of each test for reproducibility.}
}
\value{When \code{stop} is FALSE, a list with three elements 
\enumerate{
\item{The assertion being evaluated}
\item{A list of in-scope variables for the assertion that may affect its result (still work-in-progress, consider incomplete)}
\item{A list of list of arguments passed to the assertion, one per run. An element is NULL if a run passed}
}
}

\examples{
unit.test(function(x) all(x + 0 == x), list(rdouble))
}
