source IxProxy.tcl

set testName "IxLoad-HTTP-137"
set flag false
if { [ catch {
    # The proxy port range is from 4555 to 4574,  we'll automatically try to
    # use them one by one when we connect to the proxy server
    IxiaTcl ixia localhost
    #IxiaTcl ixia "172.16.174.137" 4556
    
    # Below code to check/find an available proxy server to start the test
    if { ![ixia available] } {
        error "Proxy server: [ixia cget -ip] is busy on \
        port: [ixia cget -port], please wait a while and try again."
    } else {
        puts "Connect to proxy server: [ixia cget -ip] on port: [ixia cget -port]"
    }
    
    # This "::testName" must be set, we have to use to identify the test in Proxy Server side.
    # It should be the first command to log all follow commands.
    ixia exec set ::testName $testName
    set flag true
    
    # If we don't use the latest IxLoad version in Proxy Server side,
    # we can load your expecting version here for testing
    #ixia exec source [file join "C:/Program Files (x86)/Ixia/IxLoad/6.70-EA/TclScripts/bin" IxiaWish.tcl]
    
    ixia exec package req IxLoad
    ixia exec ::IxLoad connect localhost
    
    set testController [ ixia exec ::IxLoad new ixTestController -outputDir 1]
    
    ixia exec $testController setResultDir ${testName}@[clock format [ clock seconds ] -format %Y%m%d%H%M%S]
    
    #
    # Load the repository
    #
    set repositoryName "Z:/Ixia/Workspace/IxTclProxy/Resources/Configs/$testName.rxf"
    set repository [ixia exec ::IxLoad new ixRepository -name $repositoryName]

    #
    # Loop through the tests, running them
    #
    set numTests [ ixia exec $repository testList.indexCount ]
    for {set testNo 0} {$testNo < $numTests} {incr testNo} {
    	set name [ixia exec $repository testList($testNo).cget -name]
    	set test [ixia exec $repository testList.getItem $name]

    	# Start the test
    	ixia exec $testController run $test
    	ixia exec vwait ::ixTestControllerMonitor
    }
    
    ixia exec $testController stopRun
    ixia exec unset ::testName
    
    # Get and save log
    set log [ixia exec GetLogByTestName $testName]
    ixia save ${testName}.txt $log
    
    # Get and save test results
    set results [ixia exec GetResultsByName $testName "HTTP_Client.csv"]
    ixia save "HTTP_Client.csv" $results
} err ] } {
	puts "Run test case failed:$err"
    if { $flag } {
        ixia exec unset ::testName
    }
}