source IxProxy.tcl

set tcName "IxLoad-HTTP"
set rxfName  "IxLoad-HTTP-137"
if { [ catch {
    # The proxy port range is from 4555 to 4574,  we'll automatically try to
    # use them one by one when we connect to the proxy server
    #IxiaTcl ixia localhost 4558
    IxiaTcl ixia "172.16.174.137" 4558
    
    # Below code to check/find an available proxy server to start the test
    if { ![ixia available] } {
        error "Proxy server: [ixia cget -ip] is busy on \
        port: [ixia cget -port], please wait a while and try again."
    } else {
        puts "Connect to proxy server: [ixia cget -ip] on port: [ixia cget -port]"
    }
    
    # This "::tcName" must be set, we have to use to identify the test in Proxy Server side.
    # It should be the first command to log all follow commands.
    ixia exec set ::tcName $tcName
    
    #
    # Load the repository
    #
    set repositoryName "Z:/Ixia/Workspace/IxTclProxy/Resources/Configs/$rxfName.rxf"
    ixia exec Init $repositoryName
    ixia exec Config $tcName $rxfName
    ixia exec StartTraffic
    ixia exec waitTestToFinish 60
    ixia exec StopTraffic
    ixia exec CleanUp
    ixia exec unset ::tcName
    # Get and save log
    set log [ixia exec GetRunLog $tcName]
    ixia save ${tcName}.txt $log
    
    # Get and save test results
    set results [ixia exec GetRunResults $tcName $rxfName "HTTP_Client.csv"]
    ixia save HTTP_Client.csv $results
} err ] } {
	puts "Run test case failed:$err"
}