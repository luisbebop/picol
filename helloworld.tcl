proc say {string} {
	puts $string
}

proc hello {name} 
{
	if {eq $name "luis"} {
		puts "Hello my master $name"
	} else {
		say "Hello poor insignificant being $name"
	}
}
