proc hello {name nickname} 
{
	puts "Hello $name $nickname"
}

set name "john"
set nickname "smith"
hello $name "foobar"
