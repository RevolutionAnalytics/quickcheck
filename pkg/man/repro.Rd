\name{repro}
\alias{repro}
\title{Debug tests}
\description{
  Helps reproducing any failures incurred into while testing with the function \code{\link{test}}
}
\usage{
  repro(test.report, which = smallest.failed(test.report), assertion = test.report$assertion, debug = TRUE)
}
\arguments{
  \item{test.report}{The value returned by \code{\link{test}} when \code{stop} is \code{FALSE}}
  \item{which}{A number identifying the test case the developer would like to reproduce, defaults to the smallest failed, by \code{object.size}}
  \item{assertion}{The assertion to use when reproducing the error. Defaults to the one that actually failed, may be changed to test fixes to the assertion itself on the same data --- rerunning the test may change the input data based on seeding rules}
  \item{debug}{Whether to debug the assertion or just rerun it}
}
\details{
  Repro runs on the output of the function \code{\link{test}} and will run the assertion on a set of arguments on which the original assertion failed. The assertion can be run in the debugger.
}

\value{The value returned by the assertion.}

\examples{
  #repro(test(function(x = rdouble(10)) {all(x + 1 == x)}, stop = FALSE))
  #stop argument set to FALSE automatically when in an interactive session
  }
