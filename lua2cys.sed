s/--\[\[/-=-= /g
s/--\]\]/==== /g
s/--/ _ /g
s/-=-=/----/g
#Methods are regular calls now
s/:/./g 

#Table are enclosed by parenthesis
s/{/(/g
s/}/)/g

#Functions are indicated by func and opened with {
s/function\([^)]*)\)/func\1{/g

s/\sdo$/ {/g
s/\sdo\s/ { /g
s/\send\s/ } /g
s/\send$/ }/g

s/local\s\s*\(\w\w*\)\s*=/\1:/g


