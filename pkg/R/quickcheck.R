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

##main function
unit.test = 
	function(
		predicate, 
		generators = list(), 
		sample.size = 10, 
		precondition = function(...) TRUE, 
		stop = TRUE) {
		set.seed(0)
		test.cases = 
			list(
				predicate = predicate, 
				env = 
					do.call(
						c, 
						lapply(
							all.vars(body(predicate)), 
							function(name) 
								tryCatch({
									val = list(eval(as.name(name)))
									names(val) = name
									val}, 
									error = function(e) NULL))),
				cases = 
					lapply(
						1:sample.size, 
						function(i) {
							args = lapply(generators, function(a) a())
							if(do.call(precondition, args) && 
								 	!do.call(
								 		function(...){
								 			tryCatch(
								 				predicate(...), 
								 				error = 
								 					function(e){
								 						traceback() 
								 						print(e) 
								 						FALSE})}, 
								 		args)){
								print(
									paste(
										"FAIL: predicate:",
										paste(deparse(predicate), collapse = " ")))
								args}}))
		if(is.null(unlist(test.cases$cases)))
			print(paste ("Pass ", paste(deparse(predicate), "\n", collapse = " ")))
		else {
			if (stop) {
				tf = tempfile(tmpdir=".", pattern = "quickcheck")
				save(test.cases, file = tf)
				stop(file.path(getwd(),tf))}
			else test.cases}}

## for short
catch.out = function(...) capture.output(invisible(...))
## test data  generators generators, 

## basic types
rlogical = function(p.true = .5, lambda = 8) rbinom(1 + rpois(1, lambda),1,p.true) == 1

rinteger = 
	function(elem.lambda = 100, len.lambda = 8) 
		as.integer(rpois(1 + rpois(1, len.lambda), elem.lambda)) #why poisson? Why not? Why 100?

rdouble = function(min = -1, max = 1, lambda = 8) runif(1 + rpois(1, lambda), min, max)

##rcomplex NAY

rcharacter = 
	function(str.lambda = 8, len.lambda = 8)  
		sapply(runif(1 + rpois(1, len.lambda)), function(x) substr(digest(x), 1, rpois(1, str.lambda)))

rraw = 
	function(lambda = 8) 
		sample(as.raw(0:255), rpois(1, lambda),  replace = TRUE)


rlist = 
	function(
		rdg = make.rany(max.level = max.level - 1, len.lambda = lambda), 
		lambda = 10, 
		max.level = 4) {
		if(max.level > 0) 
			replicate(rpois(1, lambda), rdg(), simplify = FALSE) 
		else list()}

rdata.frame = 
	function(
		row.lambda = 20, 
		col.lambda = 5) {
		ncol = 1 + rpois(1, col.lambda)
		nrow = 1 + rpois(1, row.lambda)
		gens = 
			list(
				rlogical, 
				rinteger, 
				rdouble, 
				rcharacter)
		columns = 
			lapply(
				sample(gens,ncol, replace=TRUE), 
				function(g) replicate(nrow, g()[1], simplify = TRUE))
		names(columns) = paste("col", 1:ncol)
		do.call(data.frame, columns)}

## special distributions
rnumeric.list = function(lambda = 100) lapply(1:rpois(1,lambda), function(i) runif(1))
make.rfixed.list = function(...) function() lapply(list(...), function(rdg) rdg())
make.rprototype = function(prototype, generator = make.rany()) function() rapply(prototype, function(x) generator(), how = "list")

make.rprototype.list = 
	function(prototype, lambda = 10, generator) {
		rdg = make.rprototype(prototype, generator)
		function() replicate(rpois(1, lambda), rdg(), simplify = FALSE)}

rconstant = function(const = NULL) const
make.rselect = function(l) function() sample(l,1)[[1]]

##combiners
make.rmixture = function(...) function() sample(list(...), 1)[[1]]()

## combine everything
make.rany = 
	function(
		p.true = .5, 
		int.lambda = 100, 
		min = -1, 
		max = 1, 
		len.lambda = 10,  
		list.rdg = 
			make.rany(len.lambda = len.lambda, max.level= max.level - 1), max.level = 4) 
		make.rmixture(
			Curry(rlogical, p.true, len.lambda), 
			Curry(rinteger, int.lambda, len.lambda), 
			Curry(rdouble, min, max, len.lambda), 
			Curry(rcharacter, len.lambda), 
			Curry(rraw, len.lambda),
			Curry(rlist, list.rdg, len.lambda, max.level))
