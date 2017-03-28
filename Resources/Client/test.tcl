lappend ::auto_path [file dirname [pwd]]

puts "Loading IXIA libraries"
#package require IxRepository
source C:/Ixia/Workspace/IxTclProxy/Resources/IxRepository.tcl
set testName "sctp"
puts "Connecting to Serveer..."
IXIA::connect

puts "Loading configuration file: C:/Ixia/Configs/$testName.rxf"
IXIA::loadRepository "C:/Ixia/Configs/$testName.rxf"

puts "Hello world!!!"





