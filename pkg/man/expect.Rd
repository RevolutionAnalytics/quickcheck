\name{expect}
\alias{expect}
\title{Create assertions from expectations}
\description{Create assertions equivalent to useful \code{testthat} expectations and then some}
\usage{
	expect(what = c("error", "message", "output", "warning", "success", "time.limit"),  expr, ...)
}
\arguments{
	\item{what}{The name of the expectation}
	\item{expr}{Expression that is expected to follow a certain behaviour}
	\item{...}{Additional arguments to define the expectation:
	\describe{
	\item{regexp}{A regular expression to be matched by the error, message, warning or output produced by the \dots expressions when evaluated}
	\item{system, user, elapsed}{Three types of time limit to be met by the evaluation of \code{expr}}}}
}
\details{
This is typically used within the \code{assertion} argument to function \code{\link{test}} and can be used to characterize the following program behaviours:
\describe{
\item{error}{The \dots expressions produces an error when evaluated}
\item{message}{The \dots expressions produce a message when evaluated}
\item{output}{The \dots expressions produce an output when evaluated}
\item{warning}{The \dots expressions produce a warning when evaluated}
\item{success}{The \dots expressions evaluate without errors}
\item{time.limit}{The \dots expressions evaluate within certain time limits (see arguments)}

}. Other \code{testthat} expectations are not available and easily replaced with regular R code, for example \code{2 + 0 == 2} insted of \code{expect_equal(2 + 0, 2)}}
\value{
True if expectation is satisfied, false otherwise.
}
\examples{
expect("message", message("message"))
expect("error", stop())
test(forall(x = rcharacter(), expect("error", stop(x))))
}
