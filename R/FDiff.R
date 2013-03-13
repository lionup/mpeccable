# TODO: diag( x ) returns an error
# if x is of length 1, and it is not equal to an integer.
# If it is an integer, then a diagonal matrix with ones of size integer is returned.
# This is not what we want, so we have to specify ncol, nrow in all diag statements.

# rutn the following command to reload dev package
# roxygenise('~/git/fdiff');install('~/git/fdiff')

# creating a class for mutlivariate differentiation
# the structure is only a vector of values and a Jocabian

# Main class
# ==========
# Defining the main dif class that will sotre the 
# values and the hessian
require(Matrix)

#' @export
setClass("FDiff", 
    representation(
        F                = "numeric", 
        J                = "sparseMatrix",
        vars             = "list", 
        coloring         = "logical" ) )

# Constructor.
# initializes a variable it's NxN, F is x and J is diag(1)
#'@export
setMethod("initialize", "FDiff", function(.Object,F,J,vars,name) { 
    .Object@F <- F
    .Object@J <- J
    .Object@vars <- vars
    .Object@coloring=FALSE
    .Object
})

# Print FDiff object.
#'@export
setMethod("print", "FDiff", function(x) { 
    if (length(x@F)!=0){
        cat('FDiff object (', length(x@F) , 'x' , ncol(x@J), ') dense:', length(x@J@x)/prod(dim(x@J))  ,'% \n')
    } else {
        cat("empty FDiff object\n")
    }
})

##
#
# Unary operators.
#
##

# Unary operator(+)
#'@export
setMethod("+", c("FDiff","missing"), function(e1,e2) {
    e1@F = e1@F
    e1@J = e1@J
    return( e1 )
})

# Unary operator(-)
#'@export
setMethod("-", c("FDiff","missing"), function(e1,e2) {
    e1@F = -e1@F
    e1@J = -e1@J
    return( e1 )
})

##
#
# Binary operators("FDiff","numeric")
#
##

# By default, the operator is not defined.
setMethod("Ops", c("FDiff","numeric"), function(e1,e2) {
    stop('Operator on FDiff and numeric not yet implemented.')
})

#'@export
setMethod("+", c("FDiff","numeric"), function(e1,e2) {
    if ( length(e2) != 1 & length(e2) != length(e1@F) ) {
        stop(paste( deparse(substitute(e2)), ' should be a scalar or have the same length as ', deparse(substitute(e1)), '@F.', sep='' ))
    }
    e1@F = e1@F+e2
    return( e1 ) 
})

#'@export
setMethod("-", c("FDiff","numeric"), function(e1,e2) {
    if ( length(e2) != 1 & length(e2) != length(e1@F) ) {
        stop(paste( deparse(substitute(e2)), ' should be a scalar or have the same length as ', deparse(substitute(e1)), '@F.', sep='' ))
    }
    e1@F = e1@F-e2
    return( e1 )
})

#'@export
setMethod("/", c("FDiff","numeric"), function(e1,e2) {
    if ( length(e2) != 1 & length(e2) != length(e1@F) ) {
        stop(paste( deparse(substitute(e2)), ' should be a scalar or have the same length as ', deparse(substitute(e1)), '@F.', sep='' ))
    }
    e1@F = e1@F/e2
    e1@J = e1@J/e2
    return( e1 )
})

#'@export
setMethod("*", c("FDiff","numeric"), function(e1,e2) {
    if ( length(e2) != 1 & length(e2) != length(e1@F) ) {
        stop(paste( deparse(substitute(e2)), ' should be a scalar or have the same length as ', deparse(substitute(e1)), '@F.', sep='' ))
    }
    e1@F = e1@F*e2
    e1@J = e1@J*e2
    return( e1 )
})

#'@export
setMethod("^", c("FDiff","numeric"), function (e1, e2) {
    if ( length(e2) != 1 & length(e2) != length(e1@F) ) {
        stop(paste( deparse(substitute(e2)), ' should be a scalar or have the same length as ', deparse(substitute(e1)), '@F.', sep='' ))
    }
    e1@J = e2 * Matrix(diag( (e1@F)^(e2-1), nrow=length(e1@F), ncol=length(e1@F) ), sparse=TRUE) %*% e1@J 
    e1@F = (e1@F)^e2
    return( e1 )
})

##
#
# Binary operators("numeric","FDiff")
#
##

# By default, the operator is not defined.
setMethod("Ops", c("numeric","FDiff"), function(e1,e2) {
    stop('Operator on numeric and FDiff not yet implemented.')
})

#'@export
setMethod("+", c("numeric","FDiff"), function(e1,e2) {
    if ( length(e1) != 1 & length(e1) != length(e2@F) ) {
        stop(paste( deparse(substitute(e1)), ' should be a scalar or have the same length as ', deparse(substitute(e2)), '@F.', sep='' ))
    }
    e2@F = e2@F+e1
    return( e2 )
})

#'@export
setMethod("-", c("numeric","FDiff"), function(e1,e2) {
    if ( length(e1) != 1 & length(e1) != length(e2@F) ) {
        stop(paste( deparse(substitute(e1)), ' should be a scalar or have the same length as ', deparse(substitute(e2)), '@F.', sep='' ))
    }
    e2@F = e1 - e2@F
    e2@J = -e2@J
    return( e2 )
})

#'@export
setMethod("/", c("numeric","FDiff"), function(e1,e2) {
    if ( length(e1) != 1 & length(e1) != length(e2@F) ) {
        stop(paste( deparse(substitute(e1)), ' should be a scalar or have the same length as ', deparse(substitute(e2)), '@F.', sep='' ))
    }
    e2@F = e1/e2@F
    # Division of scalar by a sparse matrix (elementwise) by definition results in a 
    # dense matrix, because all zero elements are now Inf. In order to comply with the
    # definition of the Jacobian in FDiff, we explicitly convert the matrix to a sparse
    # matrix.
    e2@J = Matrix( -e1/((e2@J)^2), sparse=TRUE )
    return( e2 )
})

#'@export
setMethod("*", c("numeric","FDiff"), function(e1,e2) {
    if ( length(e1) != 1 & length(e1) != length(e2@F) ) {
        stop(paste( deparse(substitute(e1)), ' should be a scalar or have the same length as ', deparse(substitute(e2)), '@F.', sep='' ))
    }
    e2@F = e2@F*e1
    e2@J = e2@J*e1
    return( e2 )
})

##
#
# Binary operators("FDiff","FDiff")
#
##

# By default, the operator is not defined.
setMethod("Ops", c("FDiff","FDiff"), function(e1,e2) {
    stop('Operator on FDiff and FDiff not yet implemented.')
})

#'@export
setMethod("+", c("FDiff","FDiff"), function (e1, e2) {
    vars = mergevars(e1@vars,e2@vars)
    e1   = expandJacDomain(e1,vars)
    e2   = expandJacDomain(e2,vars)
    e1@F = e1@F + e2@F
    e1@J = e1@J + e2@J
    return( e1 )
})

#'@export
setMethod("-", c("FDiff","FDiff"), function (e1, e2) {
    vars = mergevars(e1@vars,e2@vars)
    e1   = expandJacDomain(e1,vars)
    e2   = expandJacDomain(e2,vars)
    e1@F = e1@F - e2@F
    e1@J = e1@J - e2@J
    return( e1 )
})

#'@export
setMethod("*", c("FDiff","FDiff"), function (e1, e2) {
    vars = mergevars(e1@vars,e2@vars)
    e1   = expandJacDomain(e1,vars)
    e2   = expandJacDomain(e2,vars)
    e1@J = Matrix(diag( e2@F, nrow=length(e2@F), ncol=length(e2@F) ), sparse=TRUE) %*% e1@J + 
           Matrix(diag( e1@F, nrow=length(e1@F), ncol=length(e1@F) ), sparse=TRUE) %*% e2@J
    e1@F = e1@F * e2@F
    return( e1 )
})

#'@export
setMethod("/", c("FDiff","FDiff"), function (e1, e2) {
    vars = mergevars(e1@vars,e2@vars)
    e1   = expandJacDomain(e1,vars)
    e2   = expandJacDomain(e2,vars)
    e1@J = Matrix(diag( (e2@F)^2, nrow=length(e2@F), ncol=length(e2@F) ), sparse=TRUE) %*% ( 
                - Matrix(diag( e2@F, nrow=length(e2@F), ncol=length(e2@F) ), sparse=TRUE) %*% e1@J + 
                  Matrix(diag( e1@F, nrow=length(e1@F), ncol=length(e1@F) ), sparse=TRUE) %*% e2@J )
    e1@F = e1@F / e2@F
    return( e1 )
})

##
#
# Operators on matrix and FDiff.
#
##

#'@export
setMethod("%*%", c("matrix","FDiff"), function(x,y) {
    y@F = as.numeric(x %*% y@F)
    y@J = Matrix(x, sparse=TRUE) %*% y@J
    return( y )
})

##
#
# Functions working separate elements of FDiff.
#
##

#'@export
# TODO: throw some error maybe if we have non-positive numbers?
setMethod("log", "FDiff", function(x) {
    # Order of defining J and F matters, as J is defined in terms of the original F (i.e. before taking the log).
    x@J = Matrix(diag( 1/(x@F), nrow=length(x@F), ncol=length(x@F) ), sparse=TRUE) %*% x@J
    x@F = log(x@F)
    return( x ) 
})

##
#
# Functions working on all elements of FDiff at the same time.
#
##

#'@export
# TODO: is there a better way to find out the number of variables in a FDiff, rather
# than using length( x@F )?
setMethod("sum", "FDiff", function(x) {
    x@J = Matrix( 1, nrow=1, ncol=length(x@F), sparse=TRUE ) %*% x@J
    x@F = sum( x@F )
    return( x )
})

# initializes a variable it's NxN, F is x and J is diag(1)
#' @export
setGeneric("pMax", function(e1,e2) {
  standardGeneric("pMax")
})

# initializes a variable it's NxN, F is x and J is diag(1)
#' @export
setGeneric("appendJac", function(x,J,vs) {
    standardGeneric("appendJac")
})


#' like pmax, take the max between two values. It works on vector and
#' computes the Jacobian correctly
#' @docType methods
#' @rdname fdiff-methods
setMethod("pMax", c("FDiff","numeric"), function(e1,e2) { 
  I = e1@F < e2
  if(!any(I)) return(e1);

  e1@J[I,] = 0
  if (length(e2)>1) {
    e1@F[I]  = e2[I]
  } else {
    e1@F[I]  = e2
  }
  e1
})

#' append to Jac
#' @docType methods
#' @rdname fdiff-methods
#' @export
setMethod("appendJac", c("FDiff","sparseMatrix","list"), function(x,J,vs) { 
  x@J = cBind(x@J,J)
  x@vars = c(x@vars,vs)
  x
})

#' like rBind, combines the levels and jacobian, however
#' it makes the variables of the Jacobian consistent 
#' @docType methods
#' @rdname fdiff-methods
#' @export
setMethod("rbind2", c("FDiff","FDiff"), function(x,y) { 
  vars = mergevars(x@vars,y@vars)
  x   = expandJacDomain(x,vars)
  y   = expandJacDomain(y,vars)
  x@F = c(x@F,y@F)
  x@J = rBind(x@J,y@J)
  x@vars = vars
  x
})

#' allows accessing the levels directly, this is convenient
#' within the code
#' @method [ FDiff
#' @name extract 
setMethod(
  f= "[",
  signature="FDiff",
  definition=function(x,i){
    return(x@F[i])
  }
)

#' creates a variable to be tracked by the computation of the Jacobian
#' @param x a vector of current values
#' @param name a anme that uniquly identify this variable in the overall
#' @export
FDiff <- function(x, name) {
  N = length(x)
  vars = list()
  vars[name] = N
  new("FDiff",
    F    = x,
    J    = Matrix(diag(rep(1,N), nrow=N, ncol=N), sparse=TRUE),
    vars = vars)
}