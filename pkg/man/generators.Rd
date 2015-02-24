\name{generators}
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
\alias{rsample}
\title{
Generators and generator constructors for random data of many types
}
\description{
These functions are divided into two groups, random data generators, and constructors for such functions. Random data generators, prefixed with "r",  are functions with no mandatory arguments that generate random data of the type indicated in their names. Their use is typically as default values for the arguments of the \code{assertion} function, which itself is the main argument to \code{test}. That is, these data generators are called for each test run and fed into the assertion. All arguments are given a default but can also be modified, thus defining customized data generators. In cases when no reasonable defaults could be defined, instead of a random data generator, a constructor is available that returns a random data generator.
}
\usage{
rany(generators = all.generators)
ratomic(generators = atomic.generators, size =
                 default.vector.size())
rcharacter(elements = c(nchar = default(nchar.size \%||\%
                 severity), string = default(character.max \%||\%
                 severity)), size = default.vector.size())
rdata.frame(generator = ratomic, nrow = default(data.frame.nrow
                 \%||\% 4 * severity), ncol = default(data.frame.ncol
                 \%||\% severity))
rdouble(elements = c(mean = 0, sd = default(double.size \%||\%
                 10 * severity)), size = default.vector.size())
rfactor(elements = c(nlevels = default(nlevels \%||\%
                 severity)), size = default.vector.size())
rinteger(elements = c(max = default(integer.size \%||\% 10 *
                 severity)), size = default.vector.size())
rlist(generator = Curry(rany, generators = list(rlogical,
                 rinteger, rdouble, rcharacter, rraw, rDate, rfactor,
                 Curry(rlist, size = size, height = rsize(height -
                 1)))), size = default(list.size \%||\%
                 round(severity/2)), height = default(list.height \%||\%
                 round(severity/3)))
rlogical(elements = c(p = 0.5), size = default.vector.size())
rmatrix(generator = ratomic, nrow = default(matrix.nrow \%||\% 4
                 * severity), ncol = default(matrix.ncol \%||\%
                 severity))
rnumeric(generators = list(integer = c(max =
                 default(integer.size \%||\% 10 * severity)), double =
                 c(mean = 0, sd = default(double.size \%||\% 10 *
                 severity))), size = default.vector.size())
rraw(elements = c(max = default(raw.max \%||\% severity)), size =
                 default.vector.size())
rsample(elements, size = round(length(elements)/2), replace =
                 TRUE)
mixture(generators)
constant(const = NULL)}
\arguments{
 \item{elements}{Specify the distribution of elements of the returned data structure, either as a vector of distribution parameters or as a random number generator function or a formula that will be used as a random number generator. Different generators accept different parameters. Using names in the vectors is optional when no ambiguity arises.
 \describe{
  \item{rcharacter}{\code{nchar}, the maximum length of each string and \code{string}, the maximum number of distinct strings generated. }
  \item{rdouble}{\code{mean} and \code{sd} are the mean and standard deviation}
 \item{rfactor}{\code{nlevels} is the maximum number of levels}
 \item{rinteger}{\code{min} and \code{max} values; when \code{min} is omitted, \code{-max} is assumed, that is a symmetric distribution centered at 0}
 \item{rlogical}{\code{p} is the probability of \code{TRUE}}
 \item{rraw}{\code{max} is the maximum value for an element, as an integer. Alternately, one can specify a raw vector whose elements will be sampled}
 \item{rsample}{A vector or list of elements to sample from.}
 }
 A random number generator can be also passed, such as \code{rnorm} or \code{runif}.  Also, this argument accepts formulas that contain the \code{size} variable and whose right side evaluates to exactly \code{size} elements, as is \code{~10*runif(size)}. If the formula or function evaluates to the wrong class, a conversion will be attempted; if it evaluate to the wrong size, a warning will be issued and recycling will be attempted.}
 \item{size}{The maximum size of the returned data structure. Alternatively, a random number generator taking a single argument and returning exactly one integer or a formula whose right side evaluates to the same (see also the \code{elements} argument)}
 \item{nrow}{The maximum number of rows for the returned data frame. Alternatively, a function or a formula (see \code{size})}
 \item{ncol}{The maximum number of columns for the returned data frame. Alternatively, a function specifying its distribution (see \code{size})}
 \item{height}{A parameter monotonically increasing with the average height (amount of nesting) of the returned list, for a fixed \code{size} argument. We plan to make the interpretation of this parameter more direct in a future release.}
 \item{replace}{Whether to sample with replacement}
 \item{generator}{A random data generator}
 \item{generators}{List of random data generators}
 \item{const}{Any R object}
}
\details{
The defaults for the \code{elements} and \code{size} refer to variables that are defined only as package options, such as \code{nchar.size} and \code{severity}. See \code{\link{qc.options}}.
}
\value{
\code{rcharacter}, \code{rfactor}, \code{rdata.frame}, \code{rdouble}, \code{rinteger}, \code{rnumeric}, \code{rraw}, \code{rlogical} and \code{rlist} follow a naming convention with an "r" prefix followed by a class name and generate random data of the type specified by the name. \code{rany} generates an R object of any type. In practice, it's a mixture of the available generators, but may be enriched with more generators in the future. \code{constant} is a constructor for a degenerate random data generator that always returns the same object. It's useful for testing, say, corner cases that a developer needs to make sure they are going to be hit, not just with a certain probability. It's a bridge to deterministic testing. \code{rsample} returns a generator that picks among a list of possible values. \code{mixture} creates a random generator that follows a mixture distribution of the generators provided as arguments (equally weighted).
}

\examples{
#generate random integer vectors of size 4 or less
rinteger(size = 4)
#generate random integer vectors of maximum size 4 and elements between -5 and 5.
rinteger(element = 5, size = 4)
#pick from a given vector (not unlike sample)
rsample(1:5, c(max = 3))
#generate random numeric vector
mixture(list(rinteger, rdouble))()
#always return 1
constant(1)()
# generate random integer vector of size exactly 4
rinteger(size = constant(4))
#same with formulas
rinteger(size = ~4)}

