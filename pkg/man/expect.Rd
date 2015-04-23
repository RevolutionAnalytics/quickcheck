\name{expect}
\alias{expect}
\title{Create assertions from expectations}
\description{Create assertion equivalent to useful \code{testthat} expectations}
\usage{
	expect(what = c("error", "message", "output", "warning"),  ...)
}
\arguments{
	\item{what}{The name of the expectation}
	\item{...}{Arguments passed to the expectation}
}
\details{
This is typically used within the \code{assertion} argument to function \code{\link{test}} and is particularly useful to define assertions involving program behavior such as generating errors, messages, warnings or output. Other \code{testthat} expectations are not available and easily replaced with regular R code, for example \code{2 + 0 == 2} insted of \code{expect_equal(2 + 0, 2)}}

\examples{
expect("message", message("pippo"))
expect("error", stop())
test(forall(x = rcharacter(), expect("error", stop(x))))
}
