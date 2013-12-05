dummy:
---- 

LUA MODULE

  matrix v$(_VERSION) - matrix functions implemented with Lua tables
	
SYNOPSIS

  matrix: require 'matrix'
  m1 = matrix( ((8,4,1),(6,8,3)) )
  m2 = matrix( ((-8,1,3),(5,2,1)) )
  assert(m1 + m2 == matrix(((0,5,4),(11,10,4))))
  
DESCRIPTION

  With simple matrices this script is quite useful, though for more
  exact calculations, one would probably use a program like Matlab insted.
  Matrices of size 100x100 can still be handled very well.
  The error for the determinant and the inverted matrix is around 10^-9
  with a 100x100 matrix and an element range from -100 to 100.
 	
   Characteristics:
	
	- functions called via matrix.<function> should be able to handle
	  any table matrix of structure t[i][j] = value
	- can handle a type of complex matrix
	- can handle symbolic matrices. (Symbolic matrices cannot be
	  used with complex matrices.)
	- arithmetic functions { not change the matrix itself
	  but build and return a new matrix
	- functions are intended to be light on checks
	  since one gets a Lua error on incorrect use anyways
	- uses mainly Gauss-Jordan elimination
	- for Lua tables optimised determinant calculation (fast)
	  but not invoking any checks for special types of matrices
	- vectors can be set up via vec1 = matrix(( 1,2,3 ))^'T' or matrix(1,2,3)
	- vectors can be multiplied to a scalar via num = vec1^'T' * vec2
	  where num will be a matrix with the result in mtx[1][1],
	  or use num = vec1:scalar( vec2 ), where num is a number

API
	
	matrix function list:

	matrix.add
	matrix.columns
	matrix.concath
	matrix.concatv
	matrix.copy
	matrix.cross
	matrix.det
	matrix.div
	matrix.divnum
	matrix.dogauss
	matrix.elementstostring
	matrix.getelement
	matrix.gsub
	matrix.invert
	matrix.ipairs
	matrix.latex
	matrix.len
	matrix.mul
	matrix.mulnum
	matrix:new
	matrix.normf
	matrix.normmax
	matrix.pow
	matrix.print
	matrix.random
	matrix.replace
	matrix.root
	matrix.rotl
	matrix.rotr
	matrix.round
	matrix.rows
	matrix.scalar
	matrix.setelement
	matrix.size
	matrix.solve
	matrix.sqrt
	matrix.sub
	matrix.subm
	matrix.tostring
	matrix.transpose
	matrix.type
	
	See code and test_matrix.lua.

DEPENDENCIES

  None (other than Lua 5.1 or 5.2).  May be used with complex.lua.

HOME PAGE

  http://luamatrix.luaforge.net
  http://lua-users.org/wiki/LuaMatrix

DOWNLOAD/INSTALL

  ./util.mk
  cd tmp/*
  luarocks make
  
LICENSE
  
  Licensed under the same terms as Lua itself.
	
  Developers:
    Michael Lutz (chillcode) - original author
    David Manura http://lua-users.org/wiki/DavidManura
==== 

 _ ////////////
 _ // matrix //
 _ ////////////

matrix: (_TYPE:'module', _NAME:'matrix', _VERSION:'0.2.11.20120416')

 _  access to the metatable we set at the } of the file
matrix_meta: ()

 _ /////////////////////////////
 _ // Get 'new' matrix object //
 _ /////////////////////////////

 _ // matrix:new ( rows [, columns [, value]] )
 _  if rows is a table then sets rows as matrix
 _  if rows is a table of structure (1,2,3) then it sets it as a vector matrix
 _  if rows and columns are given and are numbers, returns a matrix with size rowsxcolumns
 _  if num is given then returns a matrix with given size and all values set to num
 _  if rows is given as number and columns is "I", will return an identity matrix of size rowsxrows
func matrix.new( rows, columns, value ){
	 _  check for given matrix
	if type( rows ) == "table" {
		 _  check for vector
		if type(rows[1]) ~= "table" {  _  expect a vector
			return setmetatable( ((rows[1],),(rows[2],),(rows[3],)),matrix_meta )
	 }
		return setmetatable( rows,matrix_meta )
 }
	 _  get matrix table
	mtx: ()
	value: value or 0
	 _  build identity matrix of given rows
	if columns == "I" {
		for i = 1,rows {
			mtx[i] = ()
			for j = 1,rows {
				if i == j {
					mtx[i][j] = 1
                }
				else {
					mtx[i][j] = 0
                }
			 }
		 }
	 }
	 _  build new matrix
	else {
		for i = 1,rows {
			mtx[i] = ()
			for j = 1,columns {
				mtx[i][j] = value
		 }
	 }
 }
	 _  return matrix with shared metatable
	return setmetatable( mtx,matrix_meta )
}

 _ // matrix ( rows [, comlumns [, value]] )
 _  set __call behaviour of matrix
 _  for matrix( ... ) as matrix.new( ... )
setmetatable( matrix, ( __call: func( ... ){ return .matrix.new( ... ) } ) )


 _  functions are designed to be light on checks
 _  so we get Lua errors instead on wrong input
 _  matrix.<functions> should handle any table of structure t[i][j] = value
 _  we always return a matrix with scripts metatable
 _  cause its faster than setmetatable( mtx, getmetatable( input matrix ) )

 _ ///////////////////////////////
 _ // matrix 'matrix' functions //
 _ ///////////////////////////////

 _ // for real, complex and symbolic matrices // _ 

 _  note: real and complex matrices may be added, subtracted, etc.
 _ 		real and symbolic matrices may also be added, subtracted, etc.
 _ 		but one should avoid using symbolic matrices with complex ones
 _ 		since it is not clear which metatable then is used

 _ // matrix.add ( m1, m2 )
 _  Add two matrices; m2 may be of bigger size than m1
func matrix.add( m1, m2 ){
	mtx: ()
	for i = 1,#m1 {
		m3i: ()
		mtx[i] = m3i
		for j = 1,#m1[1] {
			m3i[j] = m1[i][j] + m2[i][j]
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.sub ( m1 ,m2 )
 _  Subtract two matrices; m2 may be of bigger size than m1
func matrix.sub( m1, m2 ){
	mtx: ()
	for i = 1,#m1 {
		m3i: ()
		mtx[i] = m3i
		for j = 1,#m1[1] {
			m3i[j] = m1[i][j] - m2[i][j]
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.mul ( m1, m2 )
 _  Multiply two matrices; m1 columns must be equal to m2 rows
 _  e.g. #m1[1] == #m2
func matrix.mul( m1, m2 ){
	 _  multiply rows with columns
	mtx: ()
	for i = 1,#m1 {
		mtx[i] = ()
		for j = 1,#m2[1] {
			num: m1[i][1] * m2[1][j]
			for n = 2,#m1[1] {
				num = num + m1[i][n] * m2[n][j]
		 }
			mtx[i][j] = num
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ //  matrix.div ( m1, m2 )
 _  Divide two matrices; m1 columns must be equal to m2 rows
 _  m2 must be square, to be inverted,
 _  if that fails returns the rank of m2 as second argument
 _  e.g. #m1[1] == #m2; #m2 == #m2[1]
func matrix.div( m1, m2 ){
	rank:0
    m2,rank = matrix.invert( m2 )
	if not m2 { return m2, rank }  _  singular
	return matrix.mul( m1, m2 )
}

 _ // matrix.mulnum ( m1, num )
 _  Multiply matrix with a number
 _  num may be of type 'number' or 'complex number'
 _  strings get converted to complex number, if that fails then to symbol
func matrix.mulnum( m1, num ){
	mtx: ()
	 _  multiply elements with number
	for i = 1,#m1 {
		mtx[i] = ()
		for j = 1,#m1[1] {
			mtx[i][j] = m1[i][j] * num
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.divnum ( m1, num )
 _  Divide matrix by a number
 _  num may be of type 'number' or 'complex number'
 _  strings get converted to complex number, if that fails then to symbol
func matrix.divnum( m1, num ){
	mtx: ()
	 _  divide elements by number
	for i = 1,#m1 {
		mtxi: ()
		mtx[i] = mtxi
		for j = 1,#m1[1] {
			mtxi[j] = m1[i][j] / num
	 }
 }
	return setmetatable( mtx, matrix_meta )
}


 _ // for real and complex matrices only // _ 

 _ // matrix.pow ( m1, num )
 _  Power of matrix; mtx^(num)
 _  num is an integer and may be negative
 _  m1 has to be square
 _  if num is negative and inverting m1 fails
 _  returns the rank of matrix m1 as second argument
func matrix.pow( m1, num ){
	assert(num == math.floor(num), "exponent not an integer")
	if num == 0 {
		return matrix.new( #m1,"I" )
 }
	if num < 0 {
		rank: 0 
        m1,rank = matrix.invert( m1 )
      if not m1 { return m1, rank }  _  singular
		num = -num
 }
	mtx: matrix.copy( m1 )
	for i = 2,num {
		mtx = matrix.mul( mtx,m1 )
 }
	return mtx
}

number_norm2: func(x){
  return x * x
}

 _ // matrix.det ( m1 )
 _  Calculate the determinant of a matrix
 _  m1 needs to be square
 _  Can calc the det for symbolic matrices up to 3x3 too
 _  The function to calculate matrices bigger 3x3
 _  is quite fast and for matrices of medium size ~(100x100)
 _  and average values quite accurate
 _  here we try to get the nearest element to |1|, (smallest pivot element)
 _  os that usually we have |mtx[i][j]/subdet| > 1 or mtx[i][j];
 _  with complex matrices we use the complex.abs function to check if it is bigger or smaller
func matrix.det( m1 ){

	 _  check if matrix is quadratic
	assert(#m1 == #m1[1], "matrix not square")
	
	size: #m1
	
	if size == 1 {
		return m1[1][1]
 }
	
	if size == 2 {
		return m1[1][1]*m1[2][2] - m1[2][1]*m1[1][2]
 }
	
	if size == 3 {
		return ( m1[1][1]*m1[2][2]*m1[3][3] + m1[1][2]*m1[2][3]*m1[3][1] + m1[1][3]*m1[2][1]*m1[3][2]
			- m1[1][3]*m1[2][2]*m1[3][1] - m1[1][1]*m1[2][3]*m1[3][2] - m1[1][2]*m1[2][1]*m1[3][3] )
 }
	
	 _ // no symbolic matrix supported below here
	e: m1[1][1]
	zero: type(e) == "table" and e.zero or 0
	norm2: type(e) == "table" and e.norm2 or number_norm2

	 _ // matrix is bigger than 3x3
	 _  get determinant
	 _  using Gauss elimination and Laplace
	 _  start eliminating from below better for removals
	 _  get copy of matrix, set initial determinant
	mtx: matrix.copy( m1 )
	det: 1
	 _  get det up to the last element
	for j = 1,#mtx[1] {
		 _  get smallest element so that |factor| > 1
		 _  and set it as last element
		rows: #mtx
		subdet: 0
        xrow: 0
		for i = 1,rows {
			 _  get element
			e: mtx[i][j]
			 _  if no subdet has been found
			if not subdet {
				 _  check if element it is not zero
				if e ~= zero {
					 _  use element as new subdet
					subdet,xrow = e,i
                }
			 }
			 _  check for elements nearest to 1 or -1
			elseif e ~= zero and math.abs(norm2(e)-1) < math.abs(norm2(subdet)-1) {
				subdet,xrow = e,i
            }
	    }
		 _  only cary on if subdet is found
		if subdet {
			 _  check if xrow is the last row,
			 _  else switch lines and multiply det by -1
			if xrow ~= rows {
				mtx[rows],mtx[xrow] = mtx[xrow],mtx[rows]
				det = -det
		    }
			 _  traverse all fields setting element to zero
			 _  we don't set to zero cause we don't use that column anymore then anyways
			for i = 1,rows-1 {
				 _  factor is the dividor of the first element
				 _  if element is not already zero
				if mtx[i][j] ~= zero {
					factor: mtx[i][j]/subdet
					 _  update all remaining fields of the matrix, with value from xrow
					for n = j+1,#mtx[1] {
						mtx[i][n] = mtx[i][n] - factor * mtx[rows][n]
                     }
                 }
             }
			 _  update determinant and remove row
			if math.fmod( rows,2 ) == 0 {
				det = -det
		 }
			det = det * subdet
			.table.remove( mtx )
		} else {
			 _  break here table det is 0
			return det * 0
	 }
 }
	 _  det ready to return
	return det
}

 _ // matrix.dogauss ( mtx )
 _  Gauss elimination, Gauss-Jordan Method
 _  this function changes the matrix itself
 _  returns on success: true,
 _  returns on failure: false,'rank of matrix'

 _  locals
 _  checking here for the element nearest but not equal to zero (smallest pivot element).
 _  This way the `factor` in `dogauss` will be >= 1, which
 _  can give better results.
pivotOk: func( mtx,i,j,norm2 ){
	 _  find min value
	iMin: nil
	normMin: math.huge
	for _i = i,#mtx {
		e: mtx[_i][j]
		norm: math.abs(norm2(e))
		if norm > 0 and norm < normMin {
			iMin = _i
			normMin = norm
		 }
	 }
	if iMin {
		 _  switch lines if not in position.
		if iMin ~= i {
			mtx[i],mtx[iMin] = mtx[iMin],mtx[i]
	 }
		return true
	 }
	return false
}

copy: func(x){
	return type(x) == "table" and x.copy(x) or x
}

 _  note: in  _ // ... // _  we have a way that does no divison,
 _  however with big number and matrices we get problems since we { no reducing
func matrix.dogauss( mtx ){
	e: mtx[1][1]
	zero: type(e) == "table" and e.zero or 0
	one: type(e) == "table" and e.one  or 1
	norm2: type(e) == "table" and e.norm2 or number_norm2

	rows: #mtx
    columns: #mtx[1]
	 _  stairs left -> right
	for j = 1,rows {
		 _  check if element can be setted to one
		if pivotOk( mtx,j,j,norm2 ) {
			 _  start parsing rows
			for i = j+1,rows {
				 _  check if element is not already zero
				if mtx[i][j] ~= zero {
					 _  we may add x*otherline row, to set element to zero
					 _  tozero - x*mtx[j][j] = 0; x = tozero/mtx[j][j]
					factor: mtx[i][j]/mtx[j][j]
					 _ // this should not be used although it does no division,
					 _  yet with big matrices (since we { no reducing and other things)
					 _  we get too big numbers
					 _ local factor1,factor2 = mtx[i][j],mtx[j][j] // _ 
					mtx[i][j] = copy(zero)
					for _j = j+1,columns {
						 _ // mtx[i][_j] = mtx[i][_j] * factor2 - factor1 * mtx[j][_j] // _ 
						mtx[i][_j] = mtx[i][_j] - factor * mtx[j][_j]
				 }
			 }
		 }
		} else {
			 _  return false and the rank of the matrix
			return false,j-1
	 }
 }
	 _  stairs right <- left
	for j = rows,1,-1 {
		 _  set element to one
		 _  { division here
		div: mtx[j][j]
		for _j = j+1,columns {
			mtx[j][_j] = mtx[j][_j] / div
	 }
		 _  start parsing rows
		for i = j-1,1,-1 {
			 _  check if element is not already zero			
			if mtx[i][j] ~= zero {
				factor: mtx[i][j]
				for _j = j+1,columns {
					mtx[i][_j] = mtx[i][_j] - factor * mtx[j][_j]
			 }
				mtx[i][j] = copy(zero)
		 }
	 }
		mtx[j][j] = copy(one)
 }
	return true
}

 _ // matrix.invert ( m1 )
 _  Get the inverted matrix or m1
 _  matrix must be square and not singular
 _  on success: returns inverted matrix
 _  on failure: returns nil,'rank of matrix'
func matrix.invert( m1 ){
	assert(#m1 == #m1[1], "matrix not square")
	mtx: matrix.copy( m1 )
	ident: setmetatable( (),matrix_meta )
	e: m1[1][1]
    zero: type(e) == "table" and e.zero or 0
    one: type(e) == "table" and e.one  or 1
	for i = 1,#m1 {
		identi: ()
		ident[i] = identi
		for j = 1,#m1 {
			identi[j] = copy((i == j) and one or zero)
         }
     }
	mtx = matrix.concath( mtx,ident )
    
    done: nil
    rank: nil
	done,rank = matrix.dogauss( mtx )
	if done {
		return matrix.subm( mtx, 1,(#mtx[1]/2)+1,#mtx,#mtx[1] )
	} else {
		return nil,rank
 }
}

 _ // matrix.sqrt ( m1 [,iters] )
 _  calculate the square root of a matrix using "Denman Beavers square root iteration"
 _  condition: matrix rows == matrix columns; must have a invers matrix and a square root
 _  if called without additional arguments, the function finds the first nearest square root to
 _  input matrix, there are others but the error between them is very small
 _  if called with agument iters, the function will return the matrix by number of iterations
 _  the script returns:
 _ 		as first argument, matrix^.5
 _ 		as second argument, matrix^-.5
 _ 		as third argument, the average error between (matrix^.5)^2-inputmatrix
 _  you have to determin for yourself if the result is sufficent enough for you
 _  local average error
get_abs_avg: func ( m1, m2 ){
	dist: 0
	e: m1[1][1]
	abs: type(e) == "table" and e.abs or math.abs
	for i=1,#m1 {
		for j=1,#m1[1] {
			dist = dist + abs(m1[i][j]-m2[i][j])
	 }
 }
	 _  norm by numbers of entries
	return dist/(#m1*2)
}
 _  square root function
func matrix.sqrt( m1, iters ){
	assert(#m1 == #m1[1], "matrix not square")
	iters: iters or math.huge
	y: matrix.copy( m1 )
	z: matrix(#y, 'I')
	dist: math.huge
	 _  iterate, and get the average error
	for n=1,iters {
        lasty: y
        lastz: z
		 _  calc square root
		 _  y, z = (1/2)*(y + z^-1), (1/2)*(z + y^-1)
		y, z = matrix.divnum((matrix.add(y,matrix.invert(z))),2),
				matrix.divnum((matrix.add(z,matrix.invert(y))),2)
		dist1: get_abs_avg(y,lasty)
		if iters == math.huge {
			if dist1 >= dist {
				return lasty,lastz,get_abs_avg(matrix.mul(lasty,lasty),m1)
		 }
	 }
		dist = dist1
 }
	return y,z,get_abs_avg(matrix.mul(y,y),m1)
}

 _ // matrix.root ( m1, root [,iters] )
 _  calculate any root of a matrix
 _  source: http://www.dm.unipi.it/~cortona04/slides/bruno.pdf
 _  m1 and root have to be given;(m1 = matrix, root = number)
 _  conditions same as matrix.sqrt
 _  returns same values as matrix.sqrt
func matrix.root( m1, root, iters ){
	assert(#m1 == #m1[1], "matrix not square")
	iters: iters or math.huge
	mx: matrix.copy( m1 )
	my: matrix.mul(mx.invert(),mx.pow(root-1))
	dist: math.huge
	 _  iterate, and get the average error
	for n=1,iters {
        lastx: nil
        lasty: nil
		lastx,lasty = mx,my
		 _  calc root of matrix
		 _ mx,my = ((p-1)*mx + my^-1)/p,
		 _ 	((((p-1)*my + mx^-1)/p)*my^-1)^(p-2) *
		 _ 	((p-1)*my + mx^-1)/p
		mx,my = mx.mulnum(root-1).add(my.invert()).divnum(root),
			my.mulnum(root-1).add(mx.invert()).divnum(root)
				.mul(my.invert().pow(root-2)).mul(my.mulnum(root-1)
				.add(mx.invert())).divnum(root)
		dist1: get_abs_avg(mx,lastx)
		if iters == math.huge {
			if dist1 >= dist {
				return lastx,lasty,get_abs_avg(matrix.pow(lastx,root),m1)
		 }
	 }
		dist = dist1
 }
	return mx,my,get_abs_avg(matrix.pow(mx,root),m1)
}


 _ // Norm functions // _ 

 _ // matrix.normf ( mtx )
 _  calculates the Frobenius norm of the matrix.
 _    ||mtx||_F = sqrt(SUM_(i,j) |a_(i,j)|^2)
 _  http://en.wikipedia.org/wiki/Frobenius_norm#Frobenius_norm
func matrix.normf(mtx){
	mtype: matrix.type(mtx)
	result: 0
	for i = 1,#mtx {
	for j = 1,#mtx[1] {
		e: mtx[i][j]
		if mtype ~= "number" { e = e.abs() }
		result = result + e^2
    }
    }
	msqrt: (type(result) == "number")  and math.sqrt  or result.sqrt
	return msqrt(result)
}

 _ // matrix.normmax ( mtx )
 _  calculates the max norm of the matrix.
 _    ||mtx||_(max) = max(|a_(i,j)|)
 _  Does not work with symbolic matrices
 _  http://en.wikipedia.org/wiki/Frobenius_norm#Max_norm
func matrix.normmax(mtx){
	abs: (matrix.type(mtx) == "number") and math.abs or mtx[1][1].abs
	result: 0
	for i = 1,#mtx {
	for j = 1,#mtx[1] {
		e: abs(mtx[i][j])
		if e > result { result = e }
 }
 }
	return result
}


 _ // only for number and complex type // _ 
 _  Functions changing the matrix itself

 _ // matrix.round ( mtx [, idp] )
 _  perform round on elements
numround: func( num,mult ){
	return math.floor( num * mult + 0.5 ) / mult
}
tround: func( t,mult ){
	for i,v in ipairs(t) {
		t[i] = math.floor( v * mult + 0.5 ) / mult
 }
	return t
}
func matrix.round( mtx, idp ){
	mult: 10^( idp or 0 )
	fround: matrix.type( mtx ) == "number" and numround or tround
	for i = 1,#mtx {
		for j = 1,#mtx[1] {
			mtx[i][j] = fround(mtx[i][j],mult)
	 }
 }
	return mtx
}

 _ // matrix.random( mtx [,start] [, stop] [, idip] )
 _  fillmatrix with random values
numfill: func( __,start,stop,idp ){
	return math.random( start,stop ) / idp
}
tfill: func( t,start,stop,idp ){
	for i in ipairs(t) {
		t[i] = math.random( start,stop ) / idp
 }
	return t
}
func matrix.random( mtx,start,stop,idp ){
    start: start or -10
    stop: stop or 10
    idp: idp or 1
	ffill: matrix.type( mtx ) == "number" and numfill or tfill
	for i = 1,#mtx {
		for j = 1,#mtx[1] {
			mtx[i][j] = ffill( mtx[i][j], start, stop, idp )
	 }
 }
	return mtx
}


 _ //////////////////////////////
 _ // Object Utility Functions //
 _ //////////////////////////////

 _ // for all types and matrices // _ 

 _ // matrix.type ( mtx )
 _  get type of matrix, normal/complex/symbol or tensor
func matrix.type( mtx ){
	e: mtx[1][1]
	if type(e) == "table" {
		if e.type {
			return e.type()
	 }
		return "tensor"
 }
	return "number"
}
	
 _  local functions to copy matrix values
num_copy: func( num ){
	return num
}
t_copy: func( t ){
	newt: setmetatable( (), getmetatable( t ) )
	for i,v in ipairs( t ) {
		newt[i] = v
 }
	return newt
}

 _ // matrix.copy ( m1 )
 _  Copy a matrix
 _  simple copy, one can write other functions oneself
func matrix.copy( m1 ){
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	mtx: ()
	for i = 1,#m1[1] {
		mtx[i] = ()
		for j = 1,#m1 {
			mtx[i][j] = docopy( m1[i][j] )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.transpose ( m1 )
 _  Transpose a matrix
 _  switch rows and columns
func matrix.transpose( m1 ){
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	mtx: ()
	for i = 1,#m1[1] {
		mtx[i] = ()
		for j = 1,#m1 {
			mtx[i][j] = docopy( m1[j][i] )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.subm ( m1, i1, j1, i2, j2 )
 _  Submatrix out of a matrix
 _  input: i1,j1,i2,j2
 _  i1,j1 are the start element
 _  i2,j2 are the } element
 _  condition: i1,j1,i2,j2 are elements of the matrix
func matrix.subm( m1,i1,j1,i2,j2 ){
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	mtx: ()
	for i = i1,i2 {
		_i: i-i1+1
		mtx[_i] = ()
		for j = j1,j2 {
			_j: j-j1+1
			mtx[_i][_j] = docopy( m1[i][j] )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.concath( m1, m2 )
 _  Concatenate two matrices, horizontal
 _  will return m1m2; rows have to be the same
 _  e.g.: #m1 == #m2
func matrix.concath( m1,m2 ){
	assert(#m1 == #m2, "matrix size mismatch")
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	mtx: ()
	offset: #m1[1]
	for i = 1,#m1 {
		mtx[i] = ()
		for j = 1,offset {
			mtx[i][j] = docopy( m1[i][j] )
	 }
		for j = 1,#m2[1] {
			mtx[i][j+offset] = docopy( m2[i][j] )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.concatv ( m1, m2 )
 _  Concatenate two matrices, vertical
 _  will return	m1
 _ 					m2
 _  columns have to be the same; e.g.: #m1[1] == #m2[1]
func matrix.concatv( m1,m2 ){
	assert(#m1[1] == #m2[1], "matrix size mismatch")
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	mtx: ()
	for i = 1,#m1 {
		mtx[i] = ()
		for j = 1,#m1[1] {
			mtx[i][j] = docopy( m1[i][j] )
	 }
 }
	offset: #mtx
	for i = 1,#m2 {
		_i: i + offset
		mtx[_i] = ()
		for j = 1,#m2[1] {
			mtx[_i][j] = docopy( m2[i][j] )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.rotl ( m1 )
 _  Rotate Left, 90 degrees
func matrix.rotl( m1 ){
	mtx: matrix.new( #m1[1],#m1 )
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	for i = 1,#m1 {
		for j = 1,#m1[1] {
			mtx[#m1[1]-j+1][i] = docopy( m1[i][j] )
	 }
 }
	return mtx
}

 _ // matrix.rotr ( m1 )
 _  Rotate Right, 90 degrees
func matrix.rotr( m1 ){
	mtx: matrix.new( #m1[1],#m1 )
	docopy: matrix.type( m1 ) == "number" and num_copy or t_copy
	for i = 1,#m1 {
		for j = 1,#m1[1] {
			mtx[j][#m1-i+1] = docopy( m1[i][j] )
	 }
 }
	return mtx
}

tensor_tostring: func( t,fstr ){
	if not fstr { return "[".. .table.concat(t,",").."]" }
	tval: ()
	for i,v in ipairs( t ) {
		tval[i] = .string.format( fstr,v )
 }
	return "[".. .table.concat(tval,",").."]"
}
number_tostring: func(e,fstr ){
	return fstr and .string.format( fstr,e ) or e
}

 _ // matrix.tostring ( mtx, formatstr )
 _  tostring function
func matrix.tostring( mtx, formatstr ){
    _ mtx: my
	ts: ()
	mtype: matrix.type( mtx )
	e: mtx[1][1]
	thistostring: mtype == "tensor" and tensor_tostring or
	      type(e) == "table" and e.tostring or number_tostring
	for i = 1,#mtx {
		tstr: ()
		for j = 1,#mtx[1] {
	 		tstr[j] = thistostring(mtx[i][j],formatstr)

	 }
		ts[i] = .table.concat(tstr, "\t")
 }
	return .table.concat(ts, "\n")
}

 _ // matrix.print ( mtx [, formatstr] )
 _  print out the matrix, just calls tostring
func matrix.print( ... ){
	print( matrix.tostring( ... ) )
}

 _ // matrix.latex ( mtx [, align] )
 _  LaTeX output
func matrix.latex( mtx, align ){
	 _  align : option to align the elements
	 _ 		c = center; l = left; r = right
	 _ 		\usepackage(dcolumn); D(.)(,)(-1); aligns number by . replaces it with ,
	align: align or "c"
	str: "$\\left( \\begin(array)("..string.rep( align, #mtx[1] )..")\n"
	getstr: matrix.type( mtx ) == "tensor" and tensor_tostring or number_tostring
	for i = 1,#mtx {
		str = str.."\t"..getstr(mtx[i][1])
		for j = 2,#mtx[1] {
			str = str.." & "..getstr(mtx[i][j])
	 }
		 _  close line
		if i == #mtx {
			str = str.."\n"
		} else {
			str = str.." \\\\\n"
	 }
 }
	return str.."\\end(array) \\right)$"
}


 _ // Functions not changing the matrix

 _ // matrix.rows ( mtx )
 _  return number of rows
func matrix.rows( mtx ){
	return #mtx
}

 _ // matrix.columns ( mtx )
 _  return number of columns
func matrix.columns( mtx ){
	return #mtx[1]
}

 _ //  matrix.size ( mtx )
 _  get matrix size as string rows,columns
func matrix.size( mtx ){
	if matrix.type( mtx ) == "tensor" {
		return #mtx,#mtx[1],#mtx[1][1]
 }
	return #mtx,#mtx[1]
}

 _ // matrix.getelement ( mtx, i, j )
 _  return specific element ( row,column )
 _  returns element on success and nil on failure
func matrix.getelement( mtx,i,j ){
	if mtx[i] and mtx[i][j] {
		return mtx[i][j]
 }
}

 _ // matrix.setelement( mtx, i, j, value )
 _  set an element ( i, j, value )
 _  returns 1 on success and nil on failure
func matrix.setelement( mtx,i,j,value ){
	if matrix.getelement( mtx,i,j ) {
		 _  check if value type is number
		mtx[i][j] = value
		return 1
 }
}

 _ // matrix.ipairs ( mtx )
 _  iteration, same for complex
func matrix.ipairs( mtx ){
    i: 1
    j: 0
    rows: #mtx
    columns: #mtx[1]
	iter: func(){
		j = j + 1
		if j > columns {  _  return first element from next row
			i,j = i + 1,1
	 }
		if i <= rows {
			return i,j
	 }
 }
	return iter
}

 _ ///////////////////////////////
 _ // matrix 'vector' functions //
 _ ///////////////////////////////

 _  a vector is defined as a 3x1 matrix
 _  get a vector; vec = matrix(( 1,2,3 ))^'T'

 _ // matrix.scalar ( m1, m2 )
 _  returns the Scalar Product of two 3x1 matrices (vectors)
func matrix.scalar( m1, m2 ){
	return m1[1][1]*m2[1][1] + m1[2][1]*m2[2][1] +  m1[3][1]*m2[3][1]
}

 _ // matrix.cross ( m1, m2 )
 _  returns the Cross Product of two 3x1 matrices (vectors)
func matrix.cross( m1, m2 ){
	mtx: ()
	mtx[1] = ( m1[2][1]*m2[3][1] - m1[3][1]*m2[2][1] )
	mtx[2] = ( m1[3][1]*m2[1][1] - m1[1][1]*m2[3][1] )
	mtx[3] = ( m1[1][1]*m2[2][1] - m1[2][1]*m2[1][1] )
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.len ( m1 )
 _  returns the Length of a 3x1 matrix (vector)
func matrix.len( m1 ){
	return math.sqrt( m1[1][1]^2 + m1[2][1]^2 + m1[3][1]^2 )
}


 _ // matrix.replace (mtx, func, ...)
 _  for each element e in the matrix mtx, replace it with func(mtx, ...).
func matrix.replace( m1, funct, ... ){
	mtx: ()
	for i = 1,#m1 {
		m1i: m1[i]
		mtxi: ()
		for j = 1,#m1i {
			mtxi[j] = funct( m1i[j], ... )
	 }
		mtx[i] = mtxi
 }
	return setmetatable( mtx, matrix_meta )
}

 _ // matrix.remcomplex ( mtx )
 _  set the matrix elements to strings
 _  IMPROVE: tostring v.s. tostringelements confusing
func matrix.elementstostrings( mtx ){
	e: mtx[1][1]
	tostring: type(e) == "table" and e.tostring or tostring
	return matrix.replace(mtx, tostring)
}

 _ // matrix.solve ( m1 )
 _  solve; tries to solve a symbolic matrix to a number
func matrix.solve( m1 ){
	assert( matrix.type( m1 ) == "symbol", "matrix not of type 'symbol'" )
	mtx: ()
	for i = 1,#m1 {
		mtx[i] = ()
		for j = 1,#m1[1] {
			mtx[i][j] = tonumber( loadstring( "return "..m1[i][j][1] )() )
	 }
 }
	return setmetatable( mtx, matrix_meta )
}

 _ //////////////////////// _ 
 _ // METATABLE HANDLING // _ 
 _ //////////////////////// _ 

 _ // MetaTable
 _  as we declaired on top of the page
 _  local/shared metatable
 _  matrix_meta

 _  note '...' is always faster than 'arg1,arg2,...' if it can be used

 _  Set add "+" behaviour
matrix_meta.__add = func( ... ){
	return matrix.add( ... )
}

 _  Set subtract "-" behaviour
matrix_meta.__sub = func( ... ){
	return matrix.sub( ... )
}

 _  Set multiply "*" behaviour
matrix_meta.__mul = func( m1,m2 ){
	if getmetatable( m1 ) ~= matrix_meta {
		return matrix.mulnum( m2,m1 )
	} elseif getmetatable( m2 ) ~= matrix_meta {
		return matrix.mulnum( m1,m2 )
 }
	return matrix.mul( m1,m2 )
}

 _  Set division "/" behaviour
matrix_meta.__div = func( m1,m2 ){
	if getmetatable( m1 ) ~= matrix_meta {
		return matrix.mulnum( matrix.invert(m2),m1 )
	} elseif getmetatable( m2 ) ~= matrix_meta {
		return matrix.divnum( m1,m2 )
 }
	return matrix.div( m1,m2 )
}

 _  Set unary minus "-" behavior
matrix_meta.__unm = func( mtx ){
	return matrix.mulnum( mtx,-1 )
}

 _  Set power "^" behaviour
 _  if opt is any integer number will { mtx^opt
 _    (returning nil if answer doesn't exist)
 _  if opt is 'T' then it will return the transpose matrix
 _  only for complex:
 _     if opt is '*' then it returns the complex conjugate matrix
	option: (
		 _  only for complex
		["*"] : func( m1 ){ return matrix.conjugate( m1 ) },
		 _  for both
		["T"] : func( m1 ){ return matrix.transpose( m1 ) },
	)
matrix_meta.__pow = func( m1, opt ){
	return option[opt] and option[opt]( m1 ) or matrix.pow( m1,opt )
}

 _  Set equal "==" behaviour
matrix_meta.__eq = func( m1, m2 ){
	 _  check same type
	if matrix.type( m1 ) ~= matrix.type( m2 ) {
		return false
 }
	 _  check same size
	if #m1 ~= #m2 or #m1[1] ~= #m2[1] {
		return false
 }
	 _  check elements equal
	for i = 1,#m1 {
		for j = 1,#m1[1] {
			if m1[i][j] ~= m2[i][j] {
				return false
		 }
	 }
 }
	return true
}

 _  Set tostring "tostring( mtx )" behaviour
matrix_meta.__tostring = func( ... ){
	return matrix.tostring( ... )
}

 _  set __call "mtx( [formatstr] )" behaviour, mtx [, formatstr]
matrix_meta.__call = func( ... ){
	matrix.print( ... )
}

 _ // __index handling
matrix_meta.__index = ()
for k,v in pairs( matrix ) {
	matrix_meta.__index[k] = v
}


 _ /////////////////////////////////
 _ // symbol class implementation
 _ /////////////////////////////////

 _  access to the symbolic metatable
symbol_meta: () 
symbol_meta.__index = symbol_meta
symbol: symbol_meta

func symbol_meta.new(o){
	return setmetatable((tostring(o),), symbol_meta)
}
symbol_meta.to = symbol_meta.new

 _  symbol( arg )
 _  same as symbol.to( arg )
 _  set __call behaviour of symbol
setmetatable( symbol_meta, ( __call: func( __,s ){ return symbol_meta.to( s ) } ) )


 _  Converts object to string, optionally with formatting.
func symbol_meta.tostring( e,fstr ){
	return string.format( fstr,e[1] )
}

 _  Returns "symbol" if object is a symbol type, else nothing.
func symbol_meta.type(){
	if getmetatable(my) == symbol_meta {
		return "symbol"
 }
}

 _  Performs string.gsub on symbol.
 _  for use in matrix.replace
func symbol_meta.gsub(from, to){
	return symbol.to( string.gsub( my[1],from,to ) )
}

 _  creates function that replaces one letter by something else
 _  makereplacer( "a",4,"b",7, ... )(x)
 _  will replace a with 4 and b with 7 in symbol x.
 _  for use in matrix.replace
func symbol_meta.makereplacer( ... ){
	tosub: ()
	args: (...)
	for i = 1,#args,2 {
		tosub[args[i]] = args[i+1]
    }
	funct: func( a ){ return tosub[a] or a }
	return func(sym){
		return symbol.to( string.gsub( sym[1], "%a", funct ) )
 }
}

 _  applies abs function to symbol
func symbol_meta.abs(a){
	return symbol.to("(" .. a[1] .. ").abs()")
}

 _  applies sqrt function to symbol
func symbol_meta.sqrt(a){
	return symbol.to("(" .. a[1] .. ").sqrt()")
}

func symbol_meta.__add(a,b){
	return symbol.to(a .. "+" .. b)
}

func symbol_meta.__sub(a,b){
	return symbol.to(a .. "-" .. b)
}

func symbol_meta.__mul(a,b){
	return symbol.to("(" .. a .. ")*(" .. b .. ")")
}

func symbol_meta.__div(a,b){
	return symbol.to("(" .. a .. ")/(" .. b .. ")")
}

func symbol_meta.__pow(a,b){
	return symbol.to("(" .. a .. ")^(" .. b .. ")")
}

func symbol_meta.__eq(a,b){
	return a[1] == b[1]
}

func symbol_meta.__tostring(a){
	return a[1]
}

func symbol_meta.__concat(a,b){
	return tostring(a) .. tostring(b)
}

matrix.symbol = symbol


 _  return matrix
return matrix

 _ /////////////// _ 
 _ // chillcode // _ 
 _ /////////////// _ 
