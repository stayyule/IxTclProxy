source IxProxy.tcl

set testName "IxLoad-HTTP"
set rxfName  "IxLoad-HTTP-137"
if { [ catch {
    # The proxy port range is from 4555 to 4574,  we'll automatically try to
    # use them one by one when we connect to the proxy server
    #IxiaTcl ixia localhost
    IxiaTcl ixia "172.16.174.137" 4556
    
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
    
    #
    # Load the repository
    #
    set repositoryName "Z:/Ixia/Workspace/IxTclProxy/Resources/Configs/$rxfName.rxf"
    ixia exec Init $repositoryName

    ixia exec StartTraffic
    ixia exec StopTraffic
    ixia exec CleanUp
    
    # Get and save log
    set log [ixia exec GetRunLog $testName]
    ixia save ${testName}.txt $log
    
    # Get and save test results
    set results [ixia exec GetRunResults $testName $rxfName "HTTP_Client.csv"]
    ixia save "HTTP_Client.csv" $results
} err ] } {
	puts "Run test case failed:$err"
}