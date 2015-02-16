# Copyright 2011 Revolution Analytics
#    
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

library(quickcheck)
library(functional)

## generator test thyself
## define general tests that can apply to several if not most generators

type.test = 
	function(is.class, generator) 
		test(function(x = generator()) is.class(x))

variability.test = 
	function(generator)
		test(
			function(x = generator(), y = generator()) !identical(x, y))

distribution.test = 
	function(generator1, generator2)
		test(
			function(s1 = generator1(), s2 = generator2())
				suppressWarnings(
					ks.test(s1, s2, "two.sided")$p.value > 0.001),
			sample.size = 1)

dim.test = 
	function(generator, lambda, f)
		test(
			function()
				suppressWarnings(
					ks.test(
						replicate(1000, f(generator())), 
						rpois(1000, lambda), 
						"two.sided")$p.value > 0.001),
			sample.size = 1)

length.test = 
	function(generator, lambda)
		dim.test(generator, lambda, length)

#height function to build a test about height of a nested list
height = 
	function(l) 
		switch(
			class(l), 
			NULL = 0, 
			list = 1 + max({mm = sapply(l, height); if(is.list(mm)) 0 else mm}), 
			0)

height.test = 
	function(generator, lambda)
		dim.test(generator, lambda, height)

##rlogical 
type.test(is.logical, rlogical)
variability.test(rlogical)
length.test(rlogical, 10)
distribution.test(
	Curry(rlogical, size = 1000),
	Curry(rbinom, n = 1000, size = 1, prob = 0.5))

##rinteger 
type.test(is.integer, rinteger)
variability.test(rinteger)
length.test(rinteger, 10)
distribution.test(
	Curry(rinteger, size = 1000), 
	Curry(rpois, n = 1000, lambda = 100))

##rdouble 
type.test(is.double, rdouble)
variability.test(rdouble)
length.test(rdouble, 10)
distribution.test(
	Curry(rdouble, size = 1000), 
	Curry(rnorm, n = 1000))

##rcharacter: 
type.test(is.character, rcharacter)
variability.test(rcharacter)
length.test(rcharacter, 10)
distribution.test(
	Curry(nchar, rcharacter(size = 1000)),
	Curry(rpois, n = 1000, lambda = 10))


##rraw
type.test(is.raw, rraw)
variability.test(rraw)
length.test(rraw, 10)
distribution.test(
	Curry(as.integer, rraw(size = 1000)), 
	Curry(sample, 0:255, 1000, replace = TRUE))

#constant
test(
	function(x = rany(), y = constant(x)) identical(x, y()))

#select
test(
	function(x = rlist(size = 1000, height = 1))
		all(variability.test(select(x))$pass))

test(
	function(l = rlist()) 
		is.element(select(l)(), l))

#mixture
#very weak test
test(
	function(n = runif(n = 1)) 
		is.element(
			mixture(
				list(
					constant(n), 
					constant(2*n)))(), 
			c(n,2*n))) 

#rlist

type.test(is.list, rlist)
variability.test(rlist)
length.test(rlist, 5)

# rdata.frame 
type.test(is.data.frame, rdata.frame)
variability.test(rdata.frame)
dim.test(rdata.frame, lambda = 10, nrow)
dim.test(rdata.frame, lambda = 5, ncol)

# rany 
variability.test(rany)

#rmatrix

type.test(is.matrix, rmatrix)
variability.test(rmatrix)
dim.test(rmatrix, lambda = 10, nrow)
dim.test(rmatrix, lambda = 10, ncol)

#ratomic
type.test(is.atomic, ratomic)
variability.test(ratomic)
test(function() length(unique(replicate(10, class(ratomic())))) > 1)
length.test(ratomic, 10)


#rfunction
type.test(is.function, quickcheck:::rfunction)
variability.test(quickcheck:::rfunction)