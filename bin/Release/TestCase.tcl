gets stdin port

package req registry

proc runTcl { chan addr port } {
	set cin [gets $chan]
    puts "$addr:$port - $cin"

	set timeVal  [ clock format [ clock seconds ] -format %T ]
	puts "<TIME:$timeVal><=\n${cin}"
	
	set result ""
	if { [ catch {
		set result [ eval $cin ]
	} err ] } {
		puts "<TIME:$timeVal>Err=>\n$err"
	} else {
		puts "<TIME:$timeVal>=>\n$result"
	}

	puts $chan $result
	close $chan

}

puts "socket on $port running:[ socket -server runTcl $port ]"

if { [ catch {
	source IxRepository.tcl
} err ] } {
	puts "Load IxRepository package fail:$err"
}

vwait forever
