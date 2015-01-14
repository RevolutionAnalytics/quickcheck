\name{rany}
\alias{rany}
\alias{rcharacter}
\alias{rfactor}
\alias{constant}
\alias{rdata.frame}
\alias{rmatrix}
\alias{ratomic}
\alias{rdouble}
\alias{rinteger}
\alias{rnumeric}
\alias{rlist}
\alias{rlogical}
\alias{mixture}
\alias{rraw}
\alias{rDate}
\alias{select}
\title{
Generators and generator constructors for random data of many types
}
\description{
These functions are divided into two groups, random data generators, and constructors for such functions. Random data generators, prefixed with "r",  are functions with no mandatory arguments that generate random data of the desired type, to be used for the \code{generators} argument to the \code{\link{test}} function. All arguments are given a default and can be modified with \code{\link{Curry}}, thus defining customized data generators. In cases when no reasonable defaults could be defined, instead of a random data generator, a constructor is available that returns a valid random data generator.
}
\usage{
rany(generators = all.generators)
rcharacter(element = 10, size = 10)
rfactor(element = 10, size = 10)
constant(const = NULL)  
rdata.frame(element = ratomic, nrow = 10, ncol = 5)
rmatrix(element, nrow, ncol)
ratomic(element = atomic.generators, size = 10)
rdouble(element = 0, size = 10)
rinteger(element = 100, size = 10)  
rnumeric(element = 100, size = 10)
rlist(element =	Curry(rany, generators =	list(rlogical, rinteger, rdouble, rcharacter, rraw, rDate, rfactor, fun(rlist(size = size, height = rsize(height - 1))))), size = 5, height = 4)
rlogical(element = 0.5, size = 10)  
mixture(generators)  
rraw(element = as.raw(0:255), size = 10)  
select(from, replace = TRUE)}
\arguments{
 \item{element}{The expectation for the element of the random data structure (for numeric types). For logical, the probability of \code{TRUE}. For character, the expected length of each element of the returned character vector. For factor, TODO. For raw, a raw vector from which to pick. Alternatively (and for list, exclusively), a function specifying the distribution of the elements in the form of a single argument random object generator. Its single argument -- at least, single mandatory argument -- is the size of the sample (e.g. \code{rnorm})}
 \item{size}{The average size of the returned data structure. Alternatively, a function specifying its distribution in the form of a argument-less random non-negative integer number generator with a sample size of one.}
 \item{nrow}{The average number of rows for the returned data frame. Alternatively, a function specifying its distribution (see \code{size})}
 \item{ncol}{The average number of columns for the returned data frame. Alternatively, a function specifying its distribution (see \code{size})}
 \item{height}{A parameter monotonically increasing with the average height (amount of nesting) of the returned list, for a fixed \code{size} argument. The goal is to make this parameter the expected height of the returned list, but this needs more work on the algorithm or its analysis.}
 \item{from}{Vector of items to randomly sample from.}
 \item{replace}{Whether to sample with replacement}
 \item{generators}{List of random data generators to use in generating each column of a data frame or to combine in a mixture}
 \item{const}{Any R object} \item{...}{Random generators to combine in a mixture distribution with equal weights}
}
\details{
\code{rcharacter}, \code{rfactor}, \code{rdata.frame}, \code{rdouble}, \code{rinteger}, \code{rnumeric}, \code{rraw}, \code{rlogical} and \code{rlist} follow an obvious naming convention with an "r" prefix followed by a class name and generate random data of the type specified by the name. \code{rany} generates an R object of any type. In practice, it's a mixture of the available generators, but may be enriched with more generators in the future. \code{constant} is a constructor for a degenerate random data generator that always returns the same object. It's useful for testing, say, corner cases that a developer needs to make sure they are going to be hit, not just with a certain probability. It's a bridge to deterministic testing. \code{select} returns a generator that picks among a list of possible values. \code{mixture} creates a random generator that follows a mixture distribution of the generators provided as arguments (equally weighted). 
}

\examples{
#generate random integer vectors of expected size 4
rinteger(size = 4)
#generate random integer vectors of expected size 4 and expected value 5
rinteger(element = 5, size = 4)
#pick from a given vector (not unlike sample)
select(1:5)(3)
#generate random numeric vector
mixture(list(rinteger, rdouble))()
#always return 1
constant(1)()
# generate random integer vector of size exactly 4, note the composition of generators
rinteger(size = constant(4))}

