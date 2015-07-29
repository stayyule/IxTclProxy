gets stdin port

package req registry

proc GetEnvTcl { product } {
   
   set productKey     "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
   set versionKey     [ registry keys $productKey ]

   set latestKey ""
   foreach version $versionKey {
		if { [ regexp {^\d} $version ] } {
			set latestKey $version
		}
   }

   set installInfo    [ append productKey \\ $latestKey \\ InstallInfo ]            
   return             [ registry get $installInfo  HOMEDIR ]

}

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
	source [ GetEnvTcl IxLoad ]tclscripts/bin/ixiawish.tcl
} err ] } {
	puts "load IxLoad package fail:$err"
}

vwait forever
