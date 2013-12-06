
CysLua based on Lua 5.2.1
================

Cyslua is Lua with the Cystem grammar. It is bytecode compatible so that 
lua 5.2.1 modules and programs compiled to bytecode can be imported and
used directly by cyslua. 


Cystem Grammar
==============

The cystem grammer is meant to increase readability and reduce the learning
curve of a language.

Cyslua is an experiment to test how well the grammar can overlay an existing
'laguage'.


A PEG description of cystem (applied to lua) can be found in
./cystem/cystemlua.peg

A summary of the differences between the languages follows:

Comments:
---------
```
-----
myvar = 3
---
Block comments are started with 3 or more '-' characters and are completed with
the same number of '=' characters. They can be nested by increasing the number
of characters.

End of line comments are started with " _ " and continue to the end of the line.
===

(This outer block comment was to remove the myvar=3 statement)
=====

test_var = 8  _ This variable is for test

```

Blocks:
-------

Lua blocks are ```do ... end```

CysLua blocks use curly brackets ```{ ... }```

The last statement of a block is implied to be a return statement.

```

dec = func(param){ param-1 } _ Create decrement function

idx = 5
while (idx > 0) { print(a)  dec(a) }
```


Tables:
-------

Tables are enclosed be parenthesis instead of braces. Where the syntax in 
unambiguous, comma seperators may be left out, using only spaces instead.

Keys are defined with the cystem label syntax: ''' (mykey: value) ''' which
is an identifier followed by a colon.

```
myTable = ( key1: ( subkey1: 3  subkey2: 4)  key2: 55 )
```

Local:
------

Local variables are designated with the cystem label syntax.

```
myglobal = 4
idx = 5
while(idx > 0) {
  idx: 2  _ This idx is local and will shadow the global idx
  print(idx,_G['idx'])  
  _G['idx'] = _G['idx']-1  _ access global variables via the _G table
}
```

Modules and Methods:
--------------------

Cyslua alters the focus of method functions vs module functions.

A function call is assumed to be a method call if it accessed as a table slot.
Method function invokation collides with this approach and thus method functions
must be invoked by adding a leading '.'.

By default all methods have an implied 'this' or 'self' parameter named 'my'.

With this adjustment, functions and methods are defined and called with the 
same syntax.

```
a = .string.lower('HeLLo')  _ Call the string module function 'lower'

mytable = ( data1: 45 )
func mytable.mymethod(){ print( my.data1 ) } _ Define method for mytable
```






