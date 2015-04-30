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


time.limit =
  function(expr, cpu = Inf, elapsed = Inf) {
    setTimeLimit(cpu, elapsed, TRUE)
    retval = eval.parent(expr)
    setTimeLimit(Inf, Inf, TRUE)
    TRUE}

benchmark =
  function(){
    v = rdouble(size = ~10^6)
    i = 1:10^6
    ret = list()
    ret[[1]] = system.time({v = v[i]})[1:3]
    i = sample(i)
    ret[[2]] = system.time({v = v[i]})[1:3]
    tf = tempfile()
    ret[[3]] = system.time(saveRDS(v, tf))[1:3]
    ret[[4]] = system.time({v = readRDS(tf)})[1:3]
    do.call(rbind, ret)}

