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

library(quickcheck)
library(functional)
library(digest)

## generator test thyself
## define general tests that can apply to several if not most generators

type.test =
  function(is.class, generator)
    test(forall(x = generator(), {is.class(x)}), about = substitute(generator))

variability.test =
  function(generator, about = substitute(generator))
    test(
      forall(
        x = replicate(10, generator()),
        {length(unique(sapply(x, digest))) > 2}),
      about = about)

range.test =
  function(generator)
    test(
      forall(
        range = sort(generator(size = ~2)),
        data = generator(elements = range),
        {all(data >= min(range)) && all(data <= max(range))}),
      about = substitute(generator))

size.test =
  function(generator, size  = c(min = 0, max = default(vector.size %||% 4 * severity)))
    test(
      forall(
        size = sort(rinteger(elements = size, size = ~2)),
        data = generator(size = size),
        {length(data) >= min(size) && length(data) <= max(size)}),
      about = substitute(generator))

nrow.test =
  function(generator)
    test(
      forall(
        nrow = sort(rinteger(elements = c(min = 0), size = ~2)),
        data = generator(nrow = nrow),
        {(nrow(data) >= min(nrow) && nrow(data) <= max(nrow)) ||
            ncol(data) == 0}),
      about = substitute(generator))


ncol.test =
  function(generator)
    test(
      forall(
        ncol = sort(rinteger(elements = c(min = 0), size = ~2)),
        data = generator(ncol = ncol),
        {ncol(data) >= min(ncol) && ncol(data) <= max(ncol)}),
      about = substitute(generator))

#height function to build a test about height of a nested list
height =
  function(l)
    switch(
      class(l),
      NULL = 0,
      list = 1 + max({mm = sapply(l, height); if(is.list(mm)) 0 else mm}),
      0)

test.set(
  ##rlogical
  type.test(is.logical, rlogical),
  variability.test(rlogical),
  size.test(rlogical),
  test(
    forall(x = rlogical(c(p = 0)), {!any(x)}), about = "rlogical"),
  test(
    forall(x =  rlogical(c(p = 1)), {all(x)}), about = "rlogical"),


  ##rinteger
  type.test(is.integer, rinteger),
  variability.test(rinteger),
  range.test(rinteger),
  size.test(rinteger),

  ##rdouble
  type.test(is.double, rdouble),
  variability.test(rdouble),
  size.test(rdouble),
  test(
    forall(
      mean = rdouble(size = ~1),
      data = rdouble(elements = c(mean = mean, sd = 0)),
      {all(data == mean)}),
    about = "rdouble"),

  ## rnumeric
  type.test(is.numeric, rnumeric),
  variability.test(rnumeric),
  size.test(rnumeric),

  ##rcharacter:
  type.test(is.character, rcharacter),
  variability.test(rcharacter),
  size.test(rcharacter),
  test(
    forall(
      nchar.max = rsize(),
      unique.max = rsize(size = c(min = 1)),
      data = rcharacter(elements = list(nchar.max = nchar.max, unique.max = unique.max)),
      {all(sapply(data, nchar) <= nchar.max)}),
    about = "rcharacter"),

  ##rfactor
  type.test(is.factor, rfactor),
  variability.test(rfactor),
  size.test(rfactor),
  test(
    forall(
      nlevels = rsize(c(min = 1)),
      data = rfactor(elements =  c(nlevels = nlevels)),
      {length(unique(data)) <= nlevels}),
    about = "rfactor"),

  ##rDate

  ##rraw
  type.test(is.raw, rraw),
  variability.test(rraw),
  size.test(rraw),
  test(
    forall(
      n = rsize(),
      data = rraw(elements = c(min = n, max = n)),
      {all(data == as.raw(n))}),
    about = "rraw"),

  #constant
  test(
    forall(x = rany(), y = constant(x), {identical(x, y())}),
    about = "constant"),

  #rsample
  test(
    forall(
      x = rlist(),
      y = rsample(x),
      {y %in% x}),
    about = "rsample"),

  variability.test(Curry(rsample, elements = 1:1000, size =~2), about = "rsample"),

  #rlist
  type.test(is.list, rlist),
  test(
    forall(
      l = rlist(),
      {is.element(rsample(l), l)}),
    about = "rlist"),

  #mixture
  #very weak test
  test(
    forall(
      n = runif(n = 1),
      {is.element(
        mixture(
          list(
            constant(n),
            constant(2*n)))(),
        c(n,2*n))}),
    about = "mixture"),

  #rlist

  type.test(is.list, rlist),
  variability.test(rlist),
  size.test(rlist),

  # rdata.frame
  type.test(is.data.frame, rdata.frame),
  variability.test(rdata.frame),
  nrow.test(rdata.frame),
  ncol.test(rdata.frame),

  # rany
  variability.test(rany),

  #rmatrix

  type.test(is.matrix, rmatrix),
  variability.test(rmatrix),
  nrow.test(rmatrix),
  ncol.test(rmatrix),

  #ratomic
  type.test(is.atomic, ratomic),
  variability.test(ratomic),


  #rfunction
  type.test(is.function, quickcheck:::rfunction),
  variability.test(quickcheck:::rfunction),

  #named

  test(forall(x = named(ratomic)(), {!is.null(names(x))}), about = "named"),
  test(forall(x = rnamed(ratomic()), {!is.null(names(x))}), about = "named"),
  type.test(is.atomic, named(ratomic)),

  test(forall(x = named(rlist)(), {!is.null(names(x))}), about = "named"),
  test(forall(x = rnamed(rlist()), {!is.null(names(x))}), about = "named"),
  type.test(is.list, named(rlist)))
