\name{coverage}
\alias{coverage}
\title{Visualize test coverage}
\description{
 \code{coverage} produces an html report highlighting code that is not covered by tests in a package.}
\usage{coverage(x = "pkg/", ...)}
\arguments{
  \item{x}{Path to package to analyze}
  \item{...}{Arguments for specific methods, unused at this time}
}
\details{The report will open in a new browser window}
\value{\code{NULL}.}

\examples{
#coverage(".")
}
