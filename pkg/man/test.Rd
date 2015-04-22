\name{test}
\alias{test}
\alias{forall}
\title{Define and run software tests }
\description{
\code{test} evaluates an assertion multiple times by re-evaluating its arguments, some of which are expected to be random data generators. Stops or returns a test report.
}
\usage{
 test(assertion, sample.size = default(sample.size \%||\%
                 severity), stop = !interactive(), about =
                 tested.functions(assertion), cover = FALSE)
 forall(..., .env = parent.frame())
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector and having defaults for all arguments.}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
  \item{about}{Names of functions, as a character vector, that the current call was designed to test. Alternatively, the name of a package as "package:<package-name>", in which case the test is associated with all the functions in the package that are present in the body of the assertion. The default is the names of functions that are present in the body of the assertion and defined in its environment or the enclosing one. This is just a heuristic and should not be expected to guess the correct functions all the time.}
  \item{cover}{Name of function whose coverage to report, as a character string. If \code{TRUE}, the first element of the \code{about} argument. Limited to a single function for now.}
  \item{...}{The arguments of a function, followed by its body}
  \item{.env}{Environment in which to create the function}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, once called, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. The random number generator is seeded at the beginning of each test for reproducibility. The seed depends on the functions being tested, the test itself and their implementation, to guarantee independence. \code{forall} is just a different way to create a function, with a check that all arguments have default values as a bonus; it is used to create assertions. Coverage information consists of an overall coverage percentage and shiny application displaying line-by-line coverage information. The \code{about} argument is important to clarify intent, affects the seeding of the random number generator and affects how the function \code{\link{test.set}} displays the results of multiple tests.}

\value{A list with information to reproduce an error or to summarize with \code{\link{test.set}}.
When \code{stop} is TRUE, this list is stored in a file. A message will suggest to use it as argument to the function \code{\link{repro}}. When \code{stop} is FALSE, the list is returned directly and can be passed to \code{\link{repro}}. Multiple such lists can be passed to \code{\link{test.set}}  to obtain a summary.}

\examples{
test(function(x = rdouble(10)) {all(x + 0 == x)})
#equivalent
test(forall(x = rdouble(10), all(x + 0 == x)))
}
