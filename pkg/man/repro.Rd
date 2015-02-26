\name{repro}
\alias{repro}
\title{Debug tests}
\description{
  Helps reproducing any failures incurred into while testing with the function \code{\link{test}}
}
\usage{
  repro(test.report, i = first.false(test.report$pass), debug = TRUE)
}
\arguments{
  \item{test.report}{The value returned by test when \code{stop} is \code{FALSE}}
  \item{i}{A number identifying the test case the developer would like to reproduce, defaults to the first failed}
  \item{debug}{Whether to debug the assertion or just rerun it}
}
\details{
  Repro runs on the output of the function \code{\link{test}} and will run the assertion on a set of arguments on which the assertion failed. The assertion can be run in the debugger.
}

\value{The value returned by the assertion.}

\examples{
  #repro(test(function(x = rdouble(10)) all(x + 1 == x), stop = FALSE))
  #stop argument set to FALSE automatically when in an interactive session
  }