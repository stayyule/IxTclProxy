source ../IxRepository.tcl

set tcName "IxLoad-HTTP"
set rxfName  "IxLoad-HTTP-128"
if { [ catch {
    #
    # Load the repository
    #
    set repositoryName "C:/Ixia/Workspace/IxTclProxy/Resources/Configs/$rxfName.rxf"
    Init $repositoryName
    Config $tcName $rxfName "Network1:172.16.174.137/1/1" "Network2:172.16.174.137/2/1"
    ConfigStats {"HTTP Client" "TCP Connections Established" "kMax"}
    StartTraffic
    waitTestToFinish 60
    StopTraffic
    CleanUp
    ## Get and save log
    #set log [ixia exec GetRunLog $tcName]
    #ixia save ${tcName}.txt $log
    #
    ## Get and save test results
    #set results [ixia exec GetRunResults $tcName $rxfName "HTTP_Client.csv"]
    #ixia save "HTTP_Client.csv" $results
} err ] } {
	puts "Run test case failed:$err"
}