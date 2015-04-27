# Copyright 2015 Revolution Analytics
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

for (f in c("ratomic", "rcharacter", "rDate", "rdouble", "rfactor", "rinteger", "rlogical", "rnumeric", "rraw")) {
  test(function(f = get(f)) assert.time.limit(f(size = ~10^6), 1, 1), about = f)}

test(forall(x = ratomic(size = ~10^6), assert.time.limit(rnamed(x), 1, 1)), about = "rnamed")

test(forall(x = ratomic(size = ~10^6), assert.time.limit(rsample(elements = x), 1, 1)), about = "rsample")

for(f in c("rmatrix", "rdata.frame"))
  test(function(f = get(f)) assert.time.limit(f(ncol = ~10, nrow = ~10^5), 1, 1), about = f)

test(function() assert.time.limit(rlist(),1,1), sample.size = 1000, about = "rlist")

test(function() assert.time.limit(rany(),1,1), sample.size = 1000, about = "rany")

test(function() assert.time.limit(rsize(),1,1), sample.size = 1000, about = "rsize")
