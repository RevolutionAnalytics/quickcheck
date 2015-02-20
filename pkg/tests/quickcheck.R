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
library(digest)

## generator test thyself
## define general tests that can apply to several if not most generators

type.test =
	function(is.class, generator)
		test(function(x = generator()) is.class(x))

variability.test =
	function(generator)
		test(
			function(x = generator)
        length(unique(sapply(replicate(10, generator()), digest))) > 2)

#height function to build a test about height of a nested list
height =
	function(l)
		switch(
			class(l),
			NULL = 0,
			list = 1 + max({mm = sapply(l, height); if(is.list(mm)) 0 else mm}),
			0)


##rlogical
type.test(is.logical, rlogical)
variability.test(rlogical)



##rinteger
type.test(is.integer, rinteger)
variability.test(rinteger)

##rdouble
type.test(is.double, rdouble)
variability.test(rdouble)

##rcharacter:
type.test(is.character, rcharacter)
variability.test(rcharacter)



##rraw
type.test(is.raw, rraw)
variability.test(rraw)

#constant
test(
	function(x = rany(), y = constant(x)) identical(x, y()))

#rsample
variability.test(Curry(rsample, elements = 1:1000, size =~2))

#rlist
test(
	function(l = rlist())
		is.element(rsample(l), l))

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

# rdata.frame
type.test(is.data.frame, rdata.frame)
variability.test(rdata.frame)

# rany
variability.test(rany)

#rmatrix

type.test(is.matrix, rmatrix)
variability.test(rmatrix)

#ratomic
type.test(is.atomic, ratomic)
variability.test(ratomic)


#rfunction
type.test(is.function, quickcheck:::rfunction)
variability.test(quickcheck:::rfunction)
