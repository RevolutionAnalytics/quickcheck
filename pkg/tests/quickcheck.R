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

## expect
## test (failure)
library(quickcheck)

pkg = "package:quickcheck"
stopifnot(expect("error", test(function(x = rcharacter()) stop(x), about = "test")))

#repro

stopifnot(expect("error", repro(test(function() TRUE, about = "test"))))

stopifnot(!expect("error", repro(test(function() FALSE, stop = FALSE, about = "test"), debug = FALSE)))

stopifnot(expect("warning", rinteger(elements= ~1, size = c(min = 2))))

test.set(
    ## qc.options

    test(
      forall(x = rsize(), {qc.options(character.max = x); qc.option("character.max") == x}),
      about = pkg),

    ## qc.option

    test(
      function(
        opts =
          rsample(
            names(formals(qc.options))[-1],
            size = c(min = 1, max = length(formals(qc.options)) - 1),
            replace = FALSE),
        values = rinteger(size = ~length(opts))) {
        args = as.list(values)
        names(args) = opts
        before = do.call(qc.options,  as.list(names(args)))
        after = do.call(qc.options, args)
        check = do.call(qc.options, as.list(names(args)))
        check2 = lapply(as.list(names(args)), qc.option)
        names(check2) = names(args)
        do.call(qc.options, before)
        identical(after[sort(names(after))], args[sort(names(args))]) &&
          identical(after[sort(names(after))], check[sort(names(check))]) &&
          identical(after[sort(names(after))], check2[sort(names(check2))]) },
      about = pkg))

