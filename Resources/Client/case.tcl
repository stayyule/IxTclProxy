source IxProxy.tcl

IxiaTcl ixia localhost 4555

ixia exec source [file join "C:/Program Files (x86)/Ixia/IxLoad/6.70-EA/TclScripts/bin" IxiaWish.tcl]
ixia exec package req IxLoad
ixia exec ::IxLoad connect localhost

set testController [ ixia exec ::IxLoad new ixTestController -outputDir 1]

ixia exec $testController setResultDir "RESULTS/reprun"

#
# Load the repository
#
set repositoryName "C:/Ixia/Workspace/IxTclProxy/Resources/Configs/IxLoad-HTTP-137.rxf"
set repository [ ixia exec ::IxLoad new ixRepository -name $repositoryName ]


#
# Loop through the tests, running them
#
#set numTests [ ixia exec $repository testList.indexCount ]
#for {set testNo 0} {$testNo < $numTests} {incr testNo} {
#    
#	set testName [ixia exec $repository testList($testNo).cget -name]
#
#	set test [ixia exec $repository testList.getItem $testName]
#
#	# Start the test
#	ixia exec $testController run $test
#
#	ixia exec vwait ::ixTestControllerMonitor
#	ixia exec puts \$::ixTestControllerMonitor
#
#}
