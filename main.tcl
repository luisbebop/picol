proc fib {x} {
  if {<= $x 1} {
    return 1
  } 
  else {
    + [fib [- $x 1]] [fib [- $x 2]]
  }
}
proc add {x y} {
  + $x $y
}
proc sum_one_and_two {} {
  [add 1 2]
}
puts [fib 20]