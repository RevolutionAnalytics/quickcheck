\name{assert}
\alias{assert}
\title{Create assertions}
\description{Create assertion equivalent to \code{testthat} expectations}
\usage{
	assert(what, ...)
}
\arguments{
	\item{what}{The name of the expectation, without the "expect_" prefix}
	\item{...}{Arguments passed to the expectation}
}
\examples{
assert("equal",1 , 1)
assert("error", stop())
}