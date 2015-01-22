\name{expect}
\alias{expect}
\title{Create assertions from expectations}
\description{Create assertion equivalent to \code{testthat} expectations}
\usage{
	expect(what, ...)
}
\arguments{
	\item{what}{The name of the expectation, without the "expect_" prefix}
	\item{...}{Arguments passed to the expectation}
}
\examples{
expect("equal",1 , 1)
expect("error", stop())
}