\name{no.coverage}
\alias{no.coverage}
\title{Visualize test coverage}
\description{
 \code{no.coverage} produces an html report highlighting code that is not covered by tests in a package.}
\usage{no.coverage(x = "pkg/")}
\arguments{
  \item{x}{Path to package to analyze}
}
\details{The report will open in a new browser window}
\value{\code{NULL}.}

\examples{
#no.coverage(".")
}
