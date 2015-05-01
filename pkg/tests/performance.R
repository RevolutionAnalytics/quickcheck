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
#

ncol = 10
nrow = 10^5
length = 10^6
max.time = 1

for (f in c("ratomic", "rcharacter", "rDate", "rdouble", "rfactor", "rinteger", "rlogical", "rnumeric", "rraw")) {
  test(function(f = get(f)) expect("time.limit", f(size = ~length), max.time, max.time, max.time), about = f)}

test(forall(x = ratomic(size = ~length), expect("time.limit", rnamed(x), max.time, max.time, max.time)), about = "rnamed")

test(forall(x = ratomic(size = ~length), expect("time.limit", rsample(elements = x), max.time, max.time, max.time)), about = "rsample")

for(f in c("rmatrix", "rdata.frame"))
  test(function(f = get(f)) expect("time.limit", f(ncol = ~ncol, nrow = ~nrow), max.time, max.time, max.time), about = f)

test(function() expect("time.limit", rlist(), max.time, max.time, max.time), sample.size = 1000, about = "rlist")

test(function() expect("time.limit", rany(), max.time, max.time, max.time), sample.size = 1000, about = "rany")

test(function() expect("time.limit", rsize(), max.time, max.time, max.time), sample.size = 1000, about = "rsize")
