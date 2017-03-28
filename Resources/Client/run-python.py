#!/usr/bin/env python
import Tkinter
tcl=Tkinter.Tcl()

#Source client side lib
tcl.eval("source Z:/Ixia/Workspace/IxTclProxy/Resources/Client/IxProxy.tcl")
tcl.eval("set tcName HTTPB2B")
tcl.eval("set rxfName HTTPB2B")
#Create connect object to send command to IxProxyServer
tcl.eval("IxiaTcl ixia 172.16.174.129 4555")
#Set test name here
tcl.eval("ixia exec set ::tcName $rxfName")
#Set repository full path
tcl.eval("set repositoryName Z:/Ixia/Configs/$rxfName.rxf")
#Load repository
tcl.eval("ixia exec Init $repositoryName")
#Configure SCTP
tcl.eval("ixia exec ConfigSCTP Network1 -alphaRTO 11")
#configure UDP
tcl.eval("ixia exec ConfigUDP StatelessPeer1 -parallelcmdcnt 1111")
#Map ports
tcl.eval("set networkPortMap [list Network1:172.16.174.129/1/1 Network2:172.16.174.129/2/1]")
tcl.eval("ixia exec Config $tcName $rxfName $networkPortMap")
#Save configuration file to check whether SCTP configuration is conrrect. This is a debug command,
#we can use it when we want to debug the case 
tcl.eval("ixia exec IXIA::save Z:/Ixia/Configs/${rxfName}_debug.rxf")
#Configure stats which you want to check in automation scripts
#tcl.eval("ixia exec ConfigStats {'HTTP Client' 'TCP Connections Established' 'kMax'}")
#Start test
tcl.eval("ixia exec StartTraffic")
#Wait test to end
tcl.eval("ixia exec waitTestToFinish 60")
#Stop test
tcl.eval("ixia exec StopTraffic")
#Clean up test
tcl.eval("ixia exec CleanUp")
tcl.eval("ixia exec unset ::tcName")
#Read log from server side
tcl.eval("set log [ixia exec GetRunLog $tcName]")
#Save log to local system
tcl.eval("ixia save ${tcName}.txt $log")
#Read results from server side
tcl.eval("set results [ixia exec GetRunResults $tcName $rxfName 'HTTP_Client.csv']")
#Save results to local system
tcl.eval("ixia save HTTP_Client.csv $results")