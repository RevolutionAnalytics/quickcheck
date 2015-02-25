\name{test}
\alias{test}
\title{Define and run software tests }
\description{
\code{test} evaluates an assertion multiple times by re-evaluating its arguments, some of which are expected to be random data generators. Stops or returns a test report.
}
\usage{
test(assertion, sample.size = default(sample.size \%||\% severity), stop = !interactive())
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector and having defaults for all arguments.}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, once called, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. \code{set.seed(0)} is performed at the beginning of each test for reproducibility.
}

\value{A list with five elements:
\enumerate{
\item{The assertion being evaluated}
\item{A list of in-scope variables for the assertion that may affect its result (still work-in-progress, consider incomplete)}
\item{A list of list of arguments passed to the assertion, one per run. An element is NULL if a run passed}
\item{A logical vector of test results}
\item{A summary of elapsed times for each test run, in the units returned by \code{microbenchmark::get_nanotime}}
}
When \code{stop} is TRUE, this list is stored in a file. The command to load that file into the current environment as the variable \code{test.report} is printed as an error message. This allows to replicate the error, see \code{\link{repro}}. Other than this use, a developer may want to directly inspect the arguments to try and identify a pattern for the failures. Running time information is also printed in stderr on success.}

\examples{
test(function(x = rdouble(10)) all(x + 0 == x))
}
