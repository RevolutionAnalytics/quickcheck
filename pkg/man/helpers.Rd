\name{as.assertion}
\alias{as.assertion}
\alias{fun}
\title{Helper functions for quikcheck}
\description{\code{as.assertion} allows to convert any  \code{testthtat} expectation into a assertion appropriate for use with the function \code{unit.test}. \code{fun} is equivalent to \code{Curry} but adds a little syntactic sugar. \code{fun(f(arg1 = val1, arg2 = val2, ...))} is the same as \code{Curry(fun, arg1 = val1, arg2 = val2, ...)}} 
\usage{
as.assertion(expectation)
fun(a.call)}
\arguments{
\item{expectation}{A \code{testthtat} expectation}
\item{a.call}{An R call}
}
\value{For \code{as.assertion}, a function returning a logical of length 1. For \code{fun} a function with a smaller number of arguments than its first argument}