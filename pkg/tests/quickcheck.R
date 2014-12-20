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
## define general tests that can apply to several if not most genrators
type.test = 
	function(is.class, generator) 
		unit.test(is.class, generators = list(generator))

variability.test = 
	function(generator)
		unit.test(
			function(x, y) !identical(x, y), 
			generators = replicate(2, generator))

distribution.test = 
	function(generator1, generator2)
		unit.test(
			function(s1, s2)
				suppressWarnings(
					ks.test(s1, s2, "two.sided")$p.value > 0.001),
			generators = list(generator1, generator2))

dim.test = 
	function(generator, lambda, f)
		unit.test(
			function()
				suppressWarnings(
					ks.test(
						replicate(1000, f(generator())), 
						rpois(1000, lambda), 
						"two.sided")$p.value > 0.001),
			generators = list())

length.test = 
	function(generator, lambda)
		dim.test(generator, lambda, length)

##rlogical 
type.test(is.logical, rlogical)
variability.test(rlogical)
length.test(rlogical, 10)
distribution.test(
	fun(rlogical(size = 1000)), 
	fun(rbinom(n = 1000, size = 1, prob = 0.5)))

##rinteger 
type.test(is.integer, rinteger)
variability.test(rinteger)
length.test(rinteger, 10)
distribution.test(
	fun(rinteger(size = 1000)), 
	fun(rpois(n = 1000, lambda = 100)))

##rdouble 
type.test(is.double, rdouble)
variability.test(rdouble)
length.test(rdouble, 10)
distribution.test(
	fun(rdouble(size = 1000)), 
	fun(rnorm(n = 1000)))

##rcharacter: 
type.test(is.character, rcharacter)
variability.test(rcharacter)
length.test(rcharacter, 10)
distribution.test(
	fun(nchar(rcharacter(size = 1000))),
	fun(rpois(n = 1000, lambda = 10)))


##rraw
type.test(is.raw, rraw)
variability.test(rraw)
length.test(rraw, 10)
distribution.test(
	fun(as.integer(rraw(size = 1000))), 
	fun(sample(0:255, 1000, replace = TRUE)))

#constant
unit.test(
	function(x) 
		unit.test(
			function(y) identical(x, y), 
			generators = list(constant(x))),
	generators = list(rany))

#select
unit.test(
	function(x)
		variability.test(select(x)),
	generators = list(fun(rlist(size = 100, height = 1))))

unit.test(
	function(l) 
		is.element(select(l)(), l),
	generators = list(rlist))

#rmixture
#very weak test
unit.test(
	function(n) 
		is.element(
			mixture(
				constant(n), 
				constant(2*n))(), 
			c(n,2*n)), 
	generators = list(fun(runif(n = 1))))

#rlist
height = #height function to build a test about height of a nested list
	function(l) 
		switch(
			class(l), 
			NULL = 0, 
			list = 1 + max({mm = sapply(l, height); if(is.list(mm)) 0 else mm}), 
			0)

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
variability.test(CurryL(class, rany())) # this passes by the skin of its teeth

