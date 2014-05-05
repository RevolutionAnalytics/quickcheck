\name{make.rany}
\alias{make.rany}
\alias{rcharacter}
\alias{rconstant}
\alias{rdata.frame}
\alias{rdistribution}
\alias{rdouble}
\alias{rfixed.list}
\alias{rinteger}
\alias{rlist}
\alias{rlogical}
\alias{make.rmixture}
\alias{rnumeric.list}
\alias{make.rprototype}
\alias{make.rprototype.list}
\alias{make.rfixed.list}
\alias{rraw}
\alias{make.rselect}
\alias{rvector}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Meta-generators for random data of all types
}
\description{
These function are random data generators, argument-less functions that generate all sort of random data, to be used for the \code{generators} argument to the \code{\link{unit.test}} function. All arguments are given a default and can be modified with Curry, generating customized data generators. Exception to this pattern are the make.* functions which return a random data generator.
}
\usage{
make.rany(p.true = 0.5, int.lambda = 100, min = -1, max = 1,
                 len.lambda = 10, list.rdg = make.rany(len.lambda =
                 len.lambda, max.level = max.level - 1), max.level = 4)
rcharacter(str.lambda = 8, len.lambda = 8)  
rconstant(const)  
rdata.frame(row.lambda = 20, col.lambda = 5)  
rdouble(min = -1, max = 1, lambda = 8)  
make.rfixed.list(...)  
rinteger(elem.lambda = 100, len.lambda = 8)  
rlist(rdg = make.rany(max.level = max.level - 1, len.lambda
                 = lambda), lambda = 10, max.level = 4)
rlogical(p.true = 0.5, lambda = 8)  
make.rmixture(...)  
rnumeric.list(lambda = 100)  
make.rprototype(prototype, generator = make.rany())
make.rprototype.list(prototype, lambda, generator)  
make.rfixed.list(...)
rraw(lambda = 8)  
make.rselect(l)  }
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{col.lambda}{}
  \item{const}{}
  \item{elem.lambda}{}
  \item{generator}{}
  \item{lambda}{}
  \item{len.lambda}{}
  \item{int.lambda}{}
  \item{list.rdg}{}
  \item{l}{}
  \item{max.level}{}
  \item{max}{}
  \item{min}{}
  \item{p.true}{}
  \item{prototype}{}
  \item{row.lambda}{}
  \item{str.lambda}{}
  \item{rdg}{}
  \item{...}{}
}
\details{

}
\value{
}
\references{
}
\author{

}
\note{

}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{

}
\examples{
}

\keyword{  }
\keyword{  }
