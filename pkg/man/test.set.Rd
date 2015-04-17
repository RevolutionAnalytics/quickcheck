\name{test.set}
\alias{test.set}
\title{Produce a report from multiple test results}
\description{
 Turns multiple test results into a function-centric report of assertions that passed}
\usage{
  test.set(...)
}
\arguments{
  \item{...}{A single list of \code{test} return values or multiple arguments each evaluating to a test return value.}
  }
  \details{
  Gathers results from a number of tests, passed as two or more arguments or a single list thereof and produces a function-centric report. Which functions are tested by a test is determined based on the argument \code{about} of function \code{\link{test}}. The function is named generically \code{test.set} and may get additional or different features in the future that are also related to running multiple tests as a group, such as overall statistics.}

  \value{A list of lists of assertion, each element of the outer list named after a function that was tested in each of the assertions contained in that element. When tests are particurarly thorough it is possible to think of each element as a specification for one function.}

  \examples{
    test(function(x = rdouble(10)) {all(x + 0 == x)})
    #equivalent
    test(forall(x = rdouble(10), all(x + 0 == x)))
  }
