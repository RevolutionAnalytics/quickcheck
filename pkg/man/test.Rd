\name{test}
\alias{test}
\alias{repro}
\title{
Run tests}
\description{
\code{test} evaluates an assertion with arguments provided by evaluating repeatedly a list of generators. Stops or returns test cases. \code{repro} help reproducing any error that might have occurred. 
}
\usage{
test(assertion, generators = list(), sample.size = 10, stop = TRUE)
}
\arguments{
  \item{assertion}{A function returning a length-1 logical vector. Alternatively, a formula with only the right side (left side is ignored) that evaluates to a length-1 logical vector in the environment of the caller expanded with the named list of objects obtained evaluating the generators.}
  \item{generators}{A list of random data generators, one per argument needed by the \code{assertion} argument when \code{assertion} is a formula, or one per free variable in \code{argument} when it is a formula --- in the latter case all element must be named.}
  \item{sample.size}{How many times to check the assertion, with newly sampled data as arguments}
  \item{stop}{Whether to stop in case of error or continue}
}
\details{
A test is considered passed if each run passes. A run passes if the assertion, evaluated with randomly generated arguments, returns \code{TRUE}. A run fails if the assertion returns \code{FALSE} or raises an error. The arguments for each run of the test are generated using the generators provided with the \code{generators} argument. \code{set.seed(0)} is performed at the beginning of each test for reproducibility.}

\value{When \code{stop} is FALSE, a list with three elements 
\enumerate{
\item{The assertion being evaluated}
\item{A list of in-scope variables for the assertion that may affect its result (still work-in-progress, consider incomplete)}
\item{A list of list of arguments passed to the assertion, one per run. An element is NULL if a run passed}
}
When \code{stop} is TRUE, the default, there is no returned value but the same list is stored in a file. The command to load that file into the current environment as the variable \code{test.cases} is printed as the error message. This allows to replicate the error.
}

\examples{
test(function(x) all(x + 0 == x), list(rdouble))
test(~all(x + 0 == x), list(x = ~rdouble(10)))
}
