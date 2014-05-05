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
##rlogical 
unit.test(function(p.true) {
  sample = rlogical(p.true,lambda=1000)
  binom.test(
    sum(sample),
    length(sample), 
    p.true,"two.sided")$p.value > 0.001},
          generators = list(Curry(runif, n = 1, min = .1, max = .9)))
##rinteger 
unit.test(is.integer,
          generators = list(rinteger))
##rdouble 
unit.test(is.double,
          generators = list(rdouble))
##rcomplex NAY
##rcharacter: 
unit.test(is.character,
          generators = list(rcharacter))

##rraw
unit.test(is.raw,
          generators = list(rraw))

#rconstant
unit.test(function(x) rconstant(x) == x, generators = list(Curry(runif, n = 100)))
#rselect
unit.test(function(l) is.element(make.rselect(l)(), l), generators = list(rnumeric.list))
#rmixture
unit.test(function(n) is.element(make.rmixture(Curry(rconstant, n), Curry(rconstant, 2*n))(), list(n,2*n)), 
          generators = list(Curry(runif, n = 1)))
# rlist
# rdata.frame 
# rnumeric.list
# rfixed.list
# rprototype
# rprototype.list
# rconstant
# rselect
# rmixture 
# rany 