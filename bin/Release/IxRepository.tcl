package provide IxRepository  1.4

####################################################################################################
# IxRepository.tcl--
#   This file implements the Tcl encapsulation of IxRepository interface for Netgear.
#
# Copyright (c) Ixia technologies, Inc.
# Change made
# Version 1.0
# a. Le Yu-- Create
# Version 1.1
# b. Le Yu-- Merge with Netgear code
# Version 1.3
# c. Le Yu-- Add stop method
# Version 1.4
# e. Judo Xu-- Change to fullmeet Huawei requests
#################################################################################################### 


namespace eval IXIA {
    namespace export *
    
    package require registry  
    
    proc GetEnvTcl { product } {       
        set productKey     "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
        if { [ catch {
            set versionKey     [ registry keys $productKey ]
        } err ] } {
            return ""
        }        
        set latestKey      [ lindex $versionKey end ]
        if { $latestKey == "Multiversion" } {
            set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
            if { $latestKey == "InstallInfo" } {
                set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 3 ] ]
            }
        } elseif { $latestKey == "InstallInfo" } {
            set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
        }
        
        set installInfo    [ append productKey \\ $latestKey \\ InstallInfo ]            
        return             "[ registry get $installInfo  HOMEDIR ]/TclScripts/bin/ixiawish.tcl"   
    }

    # Must make sure IxLoad is installed properly
    set ixPath [ GetEnvTcl IxLoad ]
    if { [file exists $ixPath] == 1 } {
        source $ixPath
    } else {
        error "IxLoad doesn't install properly on this system"
    }
    
    package require IxLoad
    package require statCollectorUtils
    
    variable NS                 statCollectorUtils
    variable Debug              1
    variable repository         ""
    variable testController     ""
    variable tcName             ""
    variable logFile            "ixRepository@[clock format [ clock seconds ] -format %Y%m%d%H%M%S].txt"
    variable isTrafficStart     false
    
    #--
    # Load the repository
    #--
    # Parameters:
    #       repPath: the repository file absolute path
    # Return:
    #       repository obj if got success
    #       raise error and return nil if failed
    #--
    proc loadRepository { repPath } {
        set tag "proc loadRepository [info script]"
        Deputs "----- TAG: $tag -----"
   
        if { ![ file exists $repPath ] } {
            error "Repository: $repPath file not found..."
        } 
        set IXIA::repository [ ::IxLoad new ixRepository -name $repPath ]
        Deputs "repository = $IXIA::repository "
        return $IXIA::repository
    }
   
    #--
    # Reboot port CPU
    #--
    # Parameters: 
    #       chasIndex: chassis index in chassis chain
    #       portList: port list to be rebooted
    #       reset: whether to reset to default factory configuration
    # Return:
    #        0 if got success
    #        raise error if failed
    #--
    proc reboot { chasIndex portList { reset 0 } { block 0 } } {
        set tag "proc reboot [info script]"
        Deputs "----- TAG: $tag -----"
        
        set chassisChain [ $IXIA::repository cget -chassisChain ]
        if { [ llength $chassisChain ] == 0 } {
            Deputs "There's no chassis added into chassis chain, please make sure add one like 192.168.0.111..."
            return
        }
        if { [ llength $chassisChain ] <= $chasIndex } {
            Deputs "Out of index for chassis chain(length:[llength $chassisChain])...$chasIndex "
            set chasIndex 0
        }
        set chassis      [ lindex [ $chassisChain getChassisNames ] $chasIndex ]
        Deputs "connect to chassis:$chassis"
        ixConnectToChassis $chassis
        Deputs "connecting done..."
        #-- create port group
        set grpId 1
        while { ![ portGroup canUse $grpId ] } {
            incr grpId
        }
        portGroup create $grpId
        #-- add port list
        foreach port $portList {
            Deputs "port:$port"
            if { [ regexp {[\/|\.]} $port spliter ] } {
                set portInfo [ split $port $spliter ]
                eval portGroup add $grpId $portInfo
                if { $reset } {
                    eval port setFactoryDefaults  $portInfo
                    eval port write $portInfo
                }
                #-- if run in a block way,
                #    un-comment following line and comment
                #    command for portGroup reset CPU
                if { $block } {
                    eval portCpu reset $portInfo
                }
            } else {
                Deputs "Wrong format of port...$port"
            }
        }
        #-- reset CPU
        if { !$block } {
           portGroup setCommand $grpId rebootLocalCPU
        }
        
        #-- delete port group
        portGroup destroy $grpId
        
        ixDisconnectFromChassis $chassis
        return 0
      
    }
   
    #--
    # Modify the repository
    #--
    # Parameters: |key, value|
    #       - chassis: chassis IP address or hostname
    #       - user   : login user
    # Return:
    #        0 if got success
    #        raise error if failed 
    #--  
    proc configRepository { args } {
        set tag "proc configRepository [info script]"
        Deputs "----- TAG: $tag -----"
       
        set activeTest [ getActiveTest ]
        # Param collection --      
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key---$value"
            switch -exact -- $key {
                -chassis {
                    set chassis $value
                }
                -user {
                    set user $value
                }
            }
        }
       
        if { [ info exists chassis ] } {
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            set chasList [$chassisChain getChassisNames]
            foreach chasName $chasList {
                # Removed all Chassises in current configuration, otherwise we may get
                # refresh error message in run 
                $chassisChain deleteChassisByName $chasName
            }
            
            # Add new Chassises into chassisChain
            foreach chas $chassis {            
                Deputs "add chas = $chas into the chassischain!"
                $chassisChain addChassis $chas
            } 
        }
       
        if { [ info exists user ] } {
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            $chassisChain setLoginName $user 
        }
        return 0
    }
    
    #--
    # Clear chassis chain in repository
    #--
    # Parameters: 
    #        chassisChain, chassis chain obj
    # Return:
    #        0 if got success
    #        raise error if failed 
    #--  
    proc clearChassisChain { chassisChain } {  
        set chassis [ $chassisChain getChassisNames ]
 
        foreach chas $chassis { 
            $chassisChain deleteChassisByName $chas
        }
        return 0 
    }
    
    #--
    # Get test object
    #--
    #Parameters:
    #        none
    # Return:
    #        Active Test object if got success
    #        raise error if failed 
    #--  
    proc getActiveTest {} {
        set tag "proc GetActiveTest [info script]"
        Deputs "----- TAG: $tag -----"
   
        set activeTest [ $IXIA::repository  cget -activeTest ]
        Deputs "active test name: $activeTest"
   
        return [ $IXIA::repository testList.getItem $activeTest ]
    }
    
    #--
    # Get Activity object by given name
    #--
    #Parameters:
    #       actName: activity name
    #Return:
    #       activity object if got success
    #       raise error if failed 
    #--
    proc getActivity { actName } {
        set tag "proc GetActivity [info script]-->find <$actName> "
        Deputs "----- TAG: $tag -----"
 
        set activeTest [ getActiveTest ]
    
        set clientCnt [ $activeTest clientCommunityList.indexCount ]    
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set actCnt [ $activeTest clientCommunityList($index).activityList.indexCount ]
            for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                set clientActName [ $activeTest clientCommunityList($index).activityList($actIndex).cget -name ]
                if { $clientActName == $actName } {
                    return [ $activeTest clientCommunityList($index).activityList.getItem $actIndex ]
                }
            }
        }
       
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set actCnt [ $activeTest serverCommunityList($index).activityList.indexCount ] 
            for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                set serverActName [ $activeTest serverCommunityList($index).activityList($actIndex).cget -name ]
                if { $serverActName == $actName } {
                    return [ $activeTest serverCommunityList($index).activityList.getItem $actIndex ]
                }
            }
        }   
        error "Activity not found..."
    }
         
    #--
    # Get DNSServerUrl in current rxf
    #--
    # Return:
    #        DNSServerUrl NAME if got success
    #        raise error if failed 
    #--
    proc getDNSServerUrl {} {
        set tag "proc getDNSServerUrl [info script] "
        Deputs "----- TAG: $tag -----"

        set activeTest [ getActiveTest ]
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
                set trafficName    [ $activeTest serverCommunityList($index).traffic.name ]
                set actCnt [ $activeTest serverCommunityList($index).activityList.indexCount ] 
                for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                        set serverActName \
                                [ $activeTest serverCommunityList($index).activityList($actIndex).cget -name ]
                        if { [ regexp {DNSServer} $serverActName ] } {
                                set port [ $activeTest \
                                        serverCommunityList($index).activityList($actIndex).agent.pm.advancedOptions.cget -listeningPort ]
                                return ${trafficName}_${serverActName}:$port
                        }
                }
        } 
        return None
    }
 
    #--
    # Get Network object by given name
    #--
    #Parameters:
    #      networkName: network name
    #Return:
    #        network object if got success
    #        raise error if failed
    #--
    proc getNetwork { networkName } {
        set tag "proc GetActivity [info script]"
        Deputs "----- TAG: $tag -----"
 
        set activeTest [ getActiveTest ]
        set clientCnt [ $activeTest clientCommunityList.indexCount ]    
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set clientNetName [ $activeTest clientCommunityList($index).network.name ]
            if { $networkName == $clientNetName } {
                return [ $activeTest clientCommunityList($index).network ]
            }
        }      
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set serverNetName [ $activeTest serverCommunityList($index).network.name ] 
            if { $networkName == $serverNetName } {
                return [ $activeTest serverCommunityList($index).network ]
            }
        }   
        error "Network not found..."
    }
    
    #--
    # Config Network param
    #--
    #Parameters:
    #      networkName: network name 
    #      args: |key, value|
    #         -auto_nego : auto negoniation ,can be true or false
    #         -speed     : when the auto_nego is false,set the speed for the port, can be "10M","100M"
    #         -port      : ports of chassis
    #         -media     :phy medium,can be "copper","fiber","auto"
    #         -gratuitous_arp: allow to receive and send arp response for free,true/false
    #         -gateway   : gateway ip
    #         -gatewayincrby: gateway increasment
    #         -netmask   : prefix
    #         -ipincrby  : ip increase step
    #         -ipcount   : ip count
    #         -ip        : ip address
    #         -vlan_id   : vlan id
    #         -vlancount :vlan count
    #         -vlanincrby: vlan increasment by
    #         -mac       : mac address
    #         -maccount  :mac count
    #         -macincrby : mac increase by
    #         -dns_domain: domain
    #         -dns_server: server ip 
    #         -ipsec_remote_gateway: ipsec remote gateway
    #         -ipsec_local_gateway : ipsec local gateway
    #
    #Return  :
    #          0 , if got success
    #          raise error if failed
    #--
    proc configNetwork { networkName args } {     
        set network [ getNetwork $networkName ]
        Deputs "network:$network"
        set tag "proc configNetwork [info script]"
        Deputs "----- TAG: $tag -----"
    
        # Param collection --
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key---$value"      
            switch -exact -- $key {
                -ipsec_local_gateway {
                    set ipsec_local_gateway $value
                }
                -ipsec_remote_gateway {
                    set ipsec_remote_gateway $value
                }
                -dns_server {
                    set dns_server $value
                }
                -dns_domain {
                    set dns_domain $value
                }
                -mac {
                    set mac $value
                }
                -maccount {
                    set maccount $value
                }
                -macincrby {
                    set macincrby $value
                }
                -vlan_id {
                    set vlan_id $value
                }
                -vlancount {
                    set vlancount $value
                }
                -vlanincrby {
                    set vlanincrby $value
                }
                -ip {
                    set ip $value
                }
                -ipcount {
                    set ipcount $value
                }
                -ipincrby {
                    set ipincrby $value
                }
                -netmask {
                    set netmask $value
                }
                -gateway {
                    set gateway $value
                }
                -gatewayincrby {
                    set gatewayincrby $value
                }
                -gratuitous_arp {
                    set gratuitous_arp $value
                }
                -media {
                    set phy $value
                    puts "celia phy = $value"
                }
                -port {
                    set portList $value
                }
                -speed {
                    set speed $value
                }
                -auto_nego {
                    set autoneg $value
                    puts "celia autoneg = $value"
                }
                -arp_response {
                    set arpresponse $value
                }
            }
        }      
          
        set ethernet_1 [ $network getL1Plugin ]
        set mac_vlan_1 [$ethernet_1 childrenList(0)]
        set ip_1 [$mac_vlan_1 childrenList(0) ]         
        set ip_r1 [$ip_1 rangeList(0)] 
              
        if {[info exists ip]} {                            
            if {[info exists ipcount]==0} {
                set ipcount 100
            }
            if {[info exists ipincrby]==0} {
                set ipincrby "0.0.0.1"
            }
            if {[info exists netmask]==0} {
                set netmask 24
            }
            if {[info exists gateway]==0} {
                set gateway "0.0.0.0"
            }
            if {[info exists gatewayincrby]==0} {
                set gatewayincrby  "0.0.0.0"
            }
            $ip_r1  config \
                -count                                   $ipcount \
                -enableGatewayArp                        false \
                -generateStatistics                      false \
                -autoCountEnabled                        false \
                -enabled                                 true \
                -autoMacGeneration                       true \
                -incrementBy                             $ipincrby \
                -prefix                                  $netmask \
                -gatewayIncrement                        $gatewayincrby \
                -gatewayIncrementMode                    "perSubnet" \
                -mss                                     1460 \
                -gatewayAddress                          $gateway \
                -ipAddress                               $ip \
                -ipType                                  "IPv4" 
        }
              
        if {[info exists mac]} {
            if {[info exists maccount]==0} {
                if {[info exists ipcount]==1} {
                    set maccount $ipcount
                } else {
                    set maccount  100
                }
            }
            if {[info exists macincrby]==0} {
                set macincrby  "00:00:00:00:00:01"
            }

            set mac_r1 [$ip_r1 getLowerRelatedRange "MacRange"]
            $ip_r1  config    -autoMacGeneration         false
            $mac_r1 config \
                -count                                   $maccount \
                -mac                                     $mac \
                -mtu                                     1500 \
                -enabled                                 true \
                -incrementBy                             $macincrby
        }
          
        if {[info exists vlan_id]} {
            if {[info exists vlanincrby]==0} {
                set vlanincrby  1
            }
            if {[info exists vlancount]==0} {
                set vlancount  4094
            }

            set vlan_r1 [$ip_r1 getLowerRelatedRange "VlanIdRange"]              
            $vlan_r1 config  \
                -incrementStep                           $vlanincrby \
                -innerIncrement                          1 \
                -firstId                                 $vlan_id \
                -uniqueCount                             $vlancount \
                -idIncrMode                              2 \
                -enabled                                 true \
                -innerFirstId                            1 \
                -innerIncrementStep                      1 \
                -priority                                1 \
                -increment                               1 \
                -innerUniqueCount                        4094 \
                -innerEnable                             false \
                -innerPriority                           1 
        } else {
            set vlan_r1 [$ip_r1 getLowerRelatedRange "VlanIdRange"]              
            $vlan_r1 config    -enabled                  false  
        }
          
        if {[info exists gratuitous_arp]} {
            Deputs "gratuitous_arp config"
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {
                set name [$network globalPlugins($i).name]
                if { [regexp {GratARP} $name total] } {
                    set gratarp [$network globalPlugins($i)]                  
                    $gratarp config -enabled $gratuitous_arp
                    break
                }
                set i [ expr $i + 1 ]
            }
            Deputs "gratuitous_arp config over"
        }
          
        if {[info exists dns_domain]} {            
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {
                set name [$network globalPlugins($i).name]
                if { [regexp {DNS} $name total] } {  
                    set dns1 [$network globalPlugins($i)]                  
                    $dns1 config -domain $dns_domain
                    $dns1 config -timeout 5 
                    break
                }
                set i [expr $i+1]
            }
        }
          
        if {[info exists dns_server]} {
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {               
                set name [$network globalPlugins($i).name]               
                if { [regexp {DNS} $name total] } {
                    set dns1 [$network globalPlugins($i)] 
                    $dns1 nameServerList.clear
                    set my_ixNetDnsNameServer [::IxLoad new ixNetDnsNameServer]
                    $dns1 nameServerList.appendItem -object $my_ixNetDnsNameServer
                    $my_ixNetDnsNameServer config -nameServer $dns_server
                    
                    break
                }
                set i [expr $i+1]               
            }
        }
          
        if {[info exists ipsec_local_gateway]} {
            set ipsec_1 [::IxLoad new ixNetIPSecPlugin]
            $ip_1 childrenList.clear
            $ip_1 childrenList.appendItem -object $ipsec_1
            $ipsec_1 childrenList.clear
            $ipsec_1 extensionList.clear
            $ipsec_1 rangeList.clear
    
            set ipsec_R1 [::IxLoad new ixNetIPSecRange]
            # ixNet objects needs to be added in the list before they are configured.
            $ipsec_1 rangeList.appendItem -object $ipsec_R1
            $ipsec_R1 config -enabled      true \
                            -emulatedSubnet $ipsec_local_gateway
                
            if { [info exists ipsec_remote_gateway] } {
                $ipsec_R1  config  -protectedSubnet  $ipsec_remote_gateway
            }
        }
          
        if { [ info exists phy ] } {
            puts "celia --config phy = $phy .."
            set ethernet_1 [ $network getL1Plugin ] 
            $ethernet_1 cardDualPhy.config -medium $phy
        }
        
        #delete by celia on version 1.1 start
        #if there indefend this statistic : configNetwork -media auto ; configNetwork .. (there is no -media),
        # the first configuration will be overlapped by the second configuration
        #else {
        #    puts "celia --auto config phy = copper.."
        #    set ethernet_1 [ $network getL1Plugin ] 
        #   $ethernet_1 cardDualPhy.config -medium copper
        #}
        ##delete by celia on version 1.1 end
          
        if {[info exists autoneg]} { 
            set ethernet_1 [ $network getL1Plugin ]
            if { $autoneg == "true" } {
                puts "celia --- autoneg is true! "
                $ethernet_1 config -autoNegotiate true
                $ethernet_1 config -advertise100Half true
                $ethernet_1 config -advertise100Full true
                $ethernet_1 config -advertise10Full true
                $ethernet_1 config -advertise10Half true
                $ethernet_1 config -advertise1000Full true 
            } elseif {$autoneg == "false" } {
                puts "celia --- autoneg is false! "
                $ethernet_1 config -autoNegotiate false
                if { [ info exists speed ] } {                 
                    if { [ regexp 10m $speed ] } {
                        $ethernet_1 config -advertise10Full true
                        $ethernet_1 config -advertise100Half false
                        $ethernet_1 config -advertise100Full false
                        $ethernet_1 config -advertise10Half false
                        $ethernet_1 config -advertise1000Full false
                        $ethernet_1 config -speed  "k10FD"
                    }
                    if { [ regexp 100m $speed ] } {
                        puts "celia --- speed = 100m ! "
                        $ethernet_1 config -advertise100Full true
                        $ethernet_1 config -advertise100Half false
                        $ethernet_1 config -advertise10Full false
                        $ethernet_1 config -advertise10Half false
                        $ethernet_1 config -advertise1000Full false
                        $ethernet_1 config -speed  "k100FD"
                    } 
                }
            }
        } 
        
        if { [ info exists portList ] } { 
            Deputs " info exists portList -<$portList> "
            
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            set chasList [$chassisChain getChassisNames]
            
            $network portList.clear
            foreach port $portList {
                Deputs "port:$port"
                if { [ regexp {(.*)\/(\d+)\/(\d+)} $port result chassis cardId portId ] } {
                    if {[lsearch $chasList $chassis]!=-1} {
                        set chasId [expr [lsearch $chasList $chassis] + 1]
                    } else {
                        set chasId 1
                    }
                    $network portList.appendItem \
                        -chassisId $chasId \
                        -cardId $cardId \
                        -portId $portId
                } else {
                    Deputs "Wrong format of port...$port"
                }
            }
        }
        Deputs "configNetwork over"
        
        return 0
    }
    
    #get the activity rampuptime only when the timlinetype is basic mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          ramp up time , if got success
    #          raise error if failed
    #--
    proc getActivityRampupTime {actName args} {
        set tag "proc getActivityRampupTime [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set rampuptime [$timeline1 cget -rampUpTime]
        return $rampuptime
    }
    
    proc configActivitycustomPortMap {actName args} {
        set tag "proc getActivitycustomPortMap [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set desObj [$actObj cget -destinations]
        set mapObj [$desObj cget -customPortMap]
        set Ipv4mapObj [$mapObj cget -submapsIPv4]
        #set desRangList [$Ipv4mapObj cget -destinationRanges]
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -enable_id_list {
                    foreach id $value {
                        Deputs "enable destination ID $id"
                        set desportIndex [$Ipv4mapObj destinationRanges.find exact -id $id]
                        set desPortObj [$Ipv4mapObj destinationRanges.getItem $desportIndex]
                        $desPortObj config -enable 1
                    }
                        
                }
                -disable_id_list {
                    foreach id $value {
                        Deputs "disable destination ID $id"
                        set desportIndex [$Ipv4mapObj destinationRanges.find exact -id $id]
                        set desPortObj [$Ipv4mapObj destinationRanges.getItem $desportIndex]
                        $desPortObj config -enable 0
                    }
                }       
            }
        }
    }
    
    #--
    #get the activity timelineType  
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          timeline type , if got success
    #          raise error if failed
    #--
    proc getActivityTimelineType {actName args} {
        set tag "proc getActivityTimelineType [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set timelinetype [$timeline1 cget -timelineType]
        return $timelinetype
    }
    
    #--
    # getActivitySustainTime : get the activity Sustain time  only when the timlinetype is basic mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          Sustain time , if got success
    #          raise error if failed
    #--
    proc getActivitySustainTime {actName } {       
        set tag "proc getActivitySustainTime [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set sustaintime [$timeline1 cget -sustainTime]
        return $sustaintime
    }
    
    #--
    # getAdvSeg0Duration : get the activity rampuptime only when the timlinetype is advance mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          ramp up time , if got success   
    #          -1, error if failed 
    #--
    proc getAdvSeg0Duration {actName} {
        set tag "proc getAdvSeg0Duration [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
        set linetype [$timelineObj cget -timelineType]
        if {$linetype == 1} {
            set advanceObj [$timelineObj cget -advancedIteration]
            set segment0Obj [$advanceObj segmentList.getItem 0]
            set duration [$segment0Obj cget -duration] 
            return $duration
       }
       Deputs " $actName linetype is 1!"
       return -1
    }
    
    #--
    # getAdvSeg1Duration : get the activity sustain time  only when the timlinetype is advance mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          sustain time , if got success   
    #          -1, error if failed 
    #--
    proc getAdvSeg1Duration {actName} {
        set tag "proc getAdvSeg1Duration [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
        set linetype [$timelineObj cget -timelineType]
        if {$linetype == 1} {
            set advanceObj [$timelineObj cget -advancedIteration]
            set segment1Obj [$advanceObj segmentList.getItem 1]
            set duration [$segment1Obj cget -duration]
            return $duration
        }
        Deputs " $actName linetype is 1!"
        return -1
    }
   
    #--
    #config activity timeline
    #-- 
    #Parameters:
    #         -- actName , activity name , such as "HTTPClient1"
    #         -- args  |key, value|
    #           - rampupvalue   , ramp up value, only when timelinetype is 0,it will be available,
    #           - rampuptype    , value can be 0/1/2 ,meaning <users interval >,<max pending users >and <Smooth users/ interval >,only when timelinetype is 0,this will be available,
    #           - rampdowntime  , ramp down time,only when timelinetype is 0,it will be available, 
    #           - rampdownvalue , ramp down value,only when timelinetype is 0,it will be available,
    #           - iterations    , iterations ,only when timelinetype is 0,it will be available,
    #           - rampupinterval, ramp up interval ,only when timelinetype is 0,it will be available,
    #           - sustaintime   , sustaintime , only when timelinetype is 0,it will be available,
    #           - name ,timeline object name 
    #           - timelinetype  0 or 1 ,0 is basic mode,1 is advance mode
    #           - segment0duration , it is ramp up time ,only when timelinetype is 1,it will be available, 
    #           - segment1duration , it is sustain time ,only when timelinetype is 1,it will be available, 
    #           - segment2duration , it is ramp down ime ,only when timelinetype is 1,it will be available,  
    #Return  :
    #          0 , if got success   
    #          raise error if failed 
    #--
    proc configActivityTimeline { actName args } {
        set tag "proc configActivityTimeline [info script]"
        Deputs "----- TAG: $tag -----"
 
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
  
        # Param collection --       
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -rampupvalue {
                    set rampUpValue $value
                    Deputs "rampUpValue is $value"
                    $timelineObj config -rampUpValue $value
                }
                -rampuptype {
                    set rampUpType $value
                    Deputs "rampUpType $value"
                    $timelineObj config -rampUpType $value
                }
                -offlinetime {
                    set offline $value
                    Deputs "offline $value"
                    $timelineObj config  -offlineTime $value
                }
                -rampdowntime {
                    set rampDownTime $value
                    Deputs "  rampDownTime $value"
                    #$timelineObj config   $value
                }
                -standbytime {
                    set standby $value
                    Deputs "standby $value"
                    $timelineObj config -standbyTime  $value
                }
                -rampdownvalue {
                    set rampDownValue $value
                    Deputs "timelineObj config  -rampDownTime $value"
                    $timelineObj config  -rampDownTime $value
                }
                -iterations {
                    set iterations $value
                    Deputs "timelineObj config -iterations  $value"
                    $timelineObj config -iterations  $value
                }
                -rampupinterval {
                    set rampUpInterval $value
                    Deputs "timelineObj config -rampUpInterval  $value"
                    $timelineObj config -rampUpInterval  $value
                }
                -sustaintime {
                    set sustain $value
                    Deputs "timelineObj config -sustainTime  $value"
                    $timelineObj config -sustainTime  $value
                }
                -name {
                    set name $value
                    Deputs "timelineObj config -name $value"
                    $timelineObj config -name $value
                }
                -timelinetype {
                    set type $value               
                    #config the timelineType ,0 is basic mode,1 is advance mode
                    Deputs "timelineObj config -timelineType $value "
                    $timelineObj config -timelineType $value
                   
                }
                -segment0duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment0Obj [$advanceObj segmentList.getItem 0]
                    #this is for advance mode, config the rampup time 
                    $segment0Obj config -duration  $value
                    Deputs "segment0Obj config -duration  $value "
                }
                -segment1duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment1Obj [$advanceObj segmentList.getItem 1]
                    #this is for advance mode ,config the duration time
                    $segment1Obj config -duration  $value               
                    Deputs "segment1Obj config -duration  $value "
                }
                -segment2duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment2Obj [$advanceObj segmentList.getItem 2]
                    #this is for advance mode ,config the duration time
                    $segment2Obj config -duration  $value               
                    Deputs "segment2Obj config -duration  $value "
                }            
            }
        }
        return 0
    }
    
   
   
    #--
    # Config Objective
    #--
    # Parameters :
    #       - actName  ,activity name , such as "HTTPClient1"
    #       - Args , |key, value|
    #         -- enableconstraint  , true or false
    #         -- constraintvalue   , constraint value,the minimum is 1
    #         -- userobjectivetype ,  objective type ,can be simulatedUsers,connectionRate,connectionAttemptRate,
    #                                 transactionRate ,concurrentSessions ,throughputKbps ,throughputMbps,
    #                                 throughputGbps
    #         -- userobjectivevalue,  objective value,
    #Return :
    #      0 if it got success
    #      raise error if it failed
    #--
    #    
    proc configObjective { actName args } {
        set tag "proc configObjective [info script]"
        Deputs "----- TAG: $tag -----"
 
        set actObj [ getActivity $actName ]
       
        # Param collection --         
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -enableconstraint {
                    set enable_constraint $value
                    $actObj config -enableConstraint $value
                       Deputs "$actObj config -enableConstraint $value"
                }
                -constraintvalue {
                    $actObj config -constraintValue $value
                    Deputs "$actObj config -constraintValue $value"
                }
                -userobjectivetype {
                    $actObj config -userObjectiveType $value
                    Deputs "$actObj config -userObjectiveType $value"
                }
                -userobjectivevalue {
                    $actObj config -userObjectiveValue $value
                    Deputs "$actObj config -userObjectiveValue $value"
                }
            }
        }
       
        if {[info exists enable_constraint] == 0} {
            $actObj config -enableConstraint false
        }
        return 0
    }
    
    #--
    # Save the repository
    #--
    # Args:
    #       -repPath: the repository file absolute path
    #       -overwrite: whether override the existing file, default is '1'
    proc save { repPath {overwrite 1}} {
        set tag "proc save [info script]"
        Deputs "----- TAG: $tag -----"
        return [ $IXIA::repository write -destination $repPath -overwrite $overwrite]
    }
    
    #--
    # apply the configuration in repository
    #--
    proc apply {} {
        set tag "proc apply [info script]"
        Deputs "----- TAG: $tag -----"
    
        set activeTest [ getActiveTest ]    
        $IXIA::testController applyConfig $activeTest
        Deputs "  proc apply over  "
    }
    
    #--
    # run test
    #--
    proc run {} {
        set tag "proc run [info script]"
        Deputs "----- TAG: $tag -----"
        
        set chassisChain    [ $IXIA::repository cget -chassisChain ]
        $chassisChain  refresh
        set repName         [ $IXIA::repository cget -name ]
        set activeTest      [ getActiveTest ]
        set name            [ $activeTest cget -name ]
        
        $activeTest config \
            -enableNetworkDiagnostics                    false \
            -statsRequired                               true \
            -showNetworkDiagnosticsAfterRunStops         false \
            -showNetworkDiagnosticsFromApplyConfig       false \
            -enableForceOwnership                        true \
            -enableResetPorts                            true \
            -enableReleaseConfigAfterRun                 true
        
        set activeTest [ getActiveTest ]
        
        set ::ixTestControllerMonitor ""
        set IXIA::isTrafficStart false
        
        $IXIA::testController run $activeTest
        Deputs "  proc run over  "
    }
    
    #--
    # stop test
    # Parameters :
    #    none
    #--
    proc stop {} {
        set tag "proc stop [info script]"
        Deputs "----- TAG: $tag -----"
        $IXIA::testController stopRun
        ${IXIA::NS}::StopCollector
        Deputs "  proc stop over  "
    }
        
    #--
    # Wait for the test stopped
    # RETURN: if run successfully 1
    #           etherwise 0
    #--
    proc waitForTestStop { { timeout 120 } } {
        set tag "proc waitForTestStop [info script]"
        Deputs "----- TAG: $tag -----"
        #vwait ::ixTestControllerMonitor
        set timeout $timeout
        while { [lsearch $::ixTestControllerMonitor TEST_STOPPED] == -1 && $timeout > 0 } {
            incr timeout -1
            after 1000 set wakeup 1
            vwait wakeup
        }
        Deputs "  proc  waitForTestStop over  "
        return 1   
    } 

    #--
    # Wait for the first stats returned
    # RETURN: if run successfully 1
    #           etherwise 0
    #--
    proc waitTillGetStats {} {
        set tag "proc waitTillGetStats [info script]"
        Deputs "----- TAG: $tag -----"
        
        set timeout 120
        while { [lsearch $::ixTestControllerMonitor TEST_STOPPED] == -1 && !$IXIA::isTrafficStart && $timeout > 0 } {
            incr timeout -1
            after 1000 set wakeup 1
            vwait wakeup
        }
        
        Deputs "  proc  waitTillGetStats over  "
        return 1   
    }
    
    #-- connect to lib
    proc connect {} {
        ::IxLoad connect localhost
        set IXIA::testController [::IxLoad new ixTestController -outputDir 1]
    }
    
    #-- disconnect to lib
    proc disconnect {} {
        $IXIA::testController releaseConfigWaitFinish
        ::IxLoad disconnect
    }
    
    #--
    # Debug puts
    #--
    proc Deputs { value } {
        set timeVal  [ clock format [ clock seconds ] -format %T ]
        set clickVal [ clock clicks ]
       if { $IXIA::Debug } {
            set logIO [open $IXIA::logFile a+]
            puts $logIO "\[<IXIA>TIME:$timeVal\]$value"
            close $logIO
       } else {
            puts "\[<IXIA>TIME:$timeVal\]$value"
       }
    }

    #--
    # Enable debug puts
    #--
    proc IxDebugOn { { log 0 } } {
        set IXIA::Debug 1
    } 
      
    #--
    # Disable debug puts
    #--
    proc IxDebugOff {} {
        set IXIA::Debug 0
    }
    
    # Start the collector (runs in the tcl event loop) 
    #
    
    #--
    # Select the stats for testing
    #--
    # Parameters: 
    #        statList: Protocol stats List
    #        interval: Stats subscribe interval 
    # Return:
    #        0 if got success
    #        raise error if failed
    #--
    proc selectStats { statList { interval 2 } } {
        set tag "proc selectStats $statList $interval"
        Deputs "----- TAG: $tag -----"
        
        set activeTest [ getActiveTest ]
        set test_server_handle [$IXIA::testController getTestServerHandle]
        ${IXIA::NS}::Initialize -testServerHandle $test_server_handle
        ${IXIA::NS}::ClearStats
        $activeTest clearGridStats

        set caption         "Watch_Stat"
        set statSourceType  [lindex $statList 0]
        set statName        [lindex $statList 1]
        set aggregationType [lindex $statList 2]
        Deputs "----- TAG: [llength $statList]-----"
        Deputs "----- TAG: caption: $caption statSourceType: $statSourceType statName: $statName aggregationType: $aggregationType-----"
        if { [ catch {
            ${IXIA::NS}::AddStat \
            -caption            $caption \
            -statSourceType     $statSourceType \
            -statName           $statName \
            -aggregationType    $aggregationType \
            -filterList         {}
        } err ] } {
            Deputs "Add stats $statSourceType $statName error:$err"
        }
 
        ${IXIA::NS}::StartCollector -command IXIA::collectStats -interval $interval
        Deputs "  proc selectStats over  "
    }

    # Proc Name        : collect the protocol stats when running and put the data in global varibale stats_info_list and  call
    #                    function statsCal to calculate the average value
    #                    
    # Parameters       : args , is the value of Stats when running 
    # Parameter Example: statcollectorutils {timestamp 110000 stats {{kInt 166966415} {{kInt 166966415}}} {{{kInt 166966415}} {{kInt 1669664}}} ... ... }
    # Return Value     : none
    #
    proc collectStats {args} {
        # If results is returned, it means traffic is started
        set IXIA::isTrafficStart true 
        Deputs "=====================================" 
        Deputs "INCOMING STAT RECORD >>> $args" 
        Deputs "Len = [llength $args]" 
        Deputs  [lindex $args 0] 
        Deputs  [lindex $args 1] 
        Deputs "=====================================" 
    }

}

# -- Changes made on v1.4
proc GetStandardReturnHeader { { status true } { msg "" } } {
    set ret "\{Status:$status###Log:$msg###\}"
    IXIA::Deputs "----- RETURN: $ret -----"
    return $ret
}

#--
# GetRunLog - Return test run log after test
#--
# Parameters :
#       - name: Test name which is running
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is test logs
#--
#  
proc GetRunLog { tcName } {
    set tag "proc GetRunLog $tcName"
    IXIA::Deputs "----- TAG: $tag -----"
    
	set mtime 0
	set matchedFileName ""
	foreach f [glob nocomplain "log/*.*"] {
		if { [regexp "^log/${tcName}@.*" $f ] } {
			if { [file mtime $f] > $mtime } {
		set mtime [file mtime $f]
				set matchedFileName $f
			}
		}
	}
	
	set retLogStr ""
	if { $matchedFileName != "" } {
        IXIA::Deputs "Matched log file is: $matchedFileName"
		if { [catch {open $matchedFileName r }  f ] } {
            IXIA::Deputs "  proc GetRunLog over  "
			return [GetStandardReturnHeader false $f]
		} else {
			set retLogStr [string map {"\n" "###"} [read $f ]]
			close $f
            IXIA::Deputs "  proc GetRunLog over  "
            return [GetStandardReturnHeader true $retLogStr]
		}
	}
    
    IXIA::Deputs "  proc GetRunLog over  "
}

#--
# GetRunResults - Return test results
#--
# Parameters :
#       - tcName: Test name which is running
#       - rxfName: The name of rxf configuration file
#       - csvName: The name of csv results 
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is results
#--
#  
proc GetRunResults { tcName rxfName resultsFileName } {
    set tag "proc GetRunResults $tcName $rxfName $resultsFileName"
    IXIA::Deputs "----- TAG: $tag -----"
    
	set mtime 0
	set matchedDirectoryName ""
	foreach f [glob nocomplain "${tcName}/*"] {
		if { [file isdirectory $f] } {
            if { [regexp "^${tcName}/${rxfName}@.*" $f ] } {
                if { [file mtime $f] > $mtime } {
                    set mtime [file mtime $f]
                    set matchedDirectoryName $f
                }
            }
        }
	}
	
	set retResultsStr ""
	if { $matchedDirectoryName != "" } {
        IXIA::Deputs "Matched results file is: [file join $matchedDirectoryName $resultsFileName]"
		if { [catch {open [file join $matchedDirectoryName $resultsFileName] r }  f ] } {
			return [GetStandardReturnHeader false $f]
		} else {
			set retResultsStr [string map {"\n" "###"} [read $f ]]
			close $f
            return [GetStandardReturnHeader true $retResultsStr]
		}
	}
    
    IXIA::Deputs "  proc GetRunResults over  "
}

#--
# Config - Configure network <-> port mapping
#--
# Parameters :
#       - tcName: Test name which is running
#       - rxfName: The name of rxf configuration file
#       - network_ports: It should be formated:  networkName:chassisIp/cardIndex/portIndex, eg: networkName1:192.168.0.10/1/1
#       - network_port2: It should be formated:  networkName:chassisIp/cardIndex/portIndex, eg: networkName1:192.168.0.10/1/1
#       - network_port3: It's an option. It should be formated:  networkName:chassisIp/cardIndex/portIndex, eg: networkName1:192.168.0.10/1/1
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc Config { tcName rxfName { network_ports "" } { network_port2 "" } { network_port3 "" } } {
    set tag "proc Config $tcName $rxfName $network_ports $network_port2 $network_port3"
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        $IXIA::testController setResultDir "$tcName/$rxfName@[clock format [ clock seconds ] -format %Y%m%d%H%M%S]"

        set chassisList [list]
        set networkList [list]
        set portList    [list]
        foreach network_port $network_ports {
            set splitStr [split $network_port ":"]
            if { [llength $splitStr] != 2 } {
                error "Parameter $network_port should be with format networkName:chassisIp/cardIndex/portIndex"
            } else {
                if { [llength [split [lindex $splitStr 1] "/"] ] != 3 } {
                   error "Parameter $network_port should be with format networkName:chassisIp/cardIndex/portIndex" 
                }
                set network [lindex $splitStr 0]
                if { [lsearch $networkList $network ] == -1 } {
                    lappend networkList $network
                }
                set chassis [lindex [split [lindex $splitStr 1] "/"] 0]
                if { [lsearch $chassisList $chassis] == -1 } {
                    lappend chassisList $chassis
                }
                set port [lindex $splitStr 1]
                if { [lsearch $portList $port] == -1 } {
                    lappend portList $port
                }
            }
        }
        if { $network_port2 != "" } {
            set splitStr [split $network_port2 ":"]
            if { [llength $splitStr] != 2 } {
                error "Parameter $network_port2 should be with format networkName:chassisIp/cardIndex/portIndex"
            } else {
                if { [llength [split [lindex $splitStr 1] "/"] ] != 3 } {
                   error "Parameter $network_port2 should be with format networkName:chassisIp/cardIndex/portIndex" 
                }
                set network [lindex $splitStr 0]
                if { [lsearch $networkList $network ] == -1 } {
                    lappend networkList $network
                }
                set chassis [lindex [split [lindex $splitStr 1] "/"] 0]
                if { [lsearch $chassisList $chassis] == -1 } {
                    lappend chassisList $chassis
                }
                set port [lindex $splitStr 1]
                if { [lsearch $portList $port] == -1 } {
                    lappend portList $port
                }
            }
        }
        if { $network_port3 != "" } {
            set splitStr [split $network_port3 ":"]
            if { [llength $splitStr] != 2 } {
                error "Parameter $network_port3 should be with format networkName:chassisIp/cardIndex/portIndex"
            } else {
                if { [llength [split [lindex $splitStr 1] "/"] ] != 3 } {
                   error "Parameter $network_port3 should be with format networkName:chassisIp/cardIndex/portIndex" 
                }
                set network [lindex $splitStr 0]
                if { [lsearch $networkList $network ] == -1 } {
                    lappend networkList $network
                }
                set chassis [lindex [split [lindex $splitStr 1] "/"] 0]
                if { [lsearch $chassisList $chassis] == -1 } {
                    lappend chassisList $chassis
                }
                set port [lindex $splitStr 1]
                if { [lsearch $portList $port] == -1 } {
                    lappend portList $port
                }
            }
        }
        
        IXIA::Deputs "----- TAG: $chassisList, $networkList, $portList -----"
        
        if { [llength $chassisList] != 0 } {
            IXIA::configRepository -chassis $chassisList
        }
        
        foreach network $networkList port $portList {
            IXIA::configNetwork $network -port $port
        }
        
        IXIA::save "rxfName.rxf"
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc Config over  "
    return [GetStandardReturnHeader true]
}

#--
# StopTraffic - Stop traffic
#--
# Parameters :
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc StopTraffic {} {
    set tag "proc StopTraffic...."
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        IXIA::stop
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc StopTraffic over  "
    return [GetStandardReturnHeader true]
}

#--
# ConfigStats - Configure which stats should be printed in run-time
#--
# Parameters :
#       - statList: The stats which you want to check the value is returned at first time,
#                    the formation of this parameter is like: {"HTTP Client" "TCP Connections Established" "kMax"}
#       - interval: The interval to check the results with unit seconds
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc ConfigStats { statList { interval 1 } } {
    set tag "proc ConfigStats $statList $interval"
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        IXIA::selectStats $statList $interval
    } err ] } {
        IXIA::Deputs "  proc ConfigStats over  "
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc ConfigStats over  "
    return [GetStandardReturnHeader true]
}

#--
# StartTraffic - Start traffic
#--
# Parameters :
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc StartTraffic {} {
    set tag "proc StartTraffic...."
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        IXIA::run
        IXIA::waitTillGetStats
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc StartTraffic over  "
    return [GetStandardReturnHeader true]
}

#--
# waitTestToFinish - Wait for test to finish
#--
# Parameters :
#       - timeout: The timeout time before we wait for test to finish, it has default value 120 seconds
#Return :
#      Status: true/false
#      Log   : 
#--
#
proc waitTestToFinish { { timeout 120 } } {
    set tag "proc waitTestToFinish $timeout "
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        IXIA::waitForTestStop $timeout
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc waitTestToFinish over  "
    return [GetStandardReturnHeader true]
}

#--
# Init - Initialize test
#--
# Parameters :
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc Init { rxfFullPathName } {
    set tag "proc Init $rxfFullPathName"
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        set IXIA::tcName $::tcName
        IXIA::connect
        IXIA::loadRepository "$rxfFullPathName"
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc Init over  "
    return [GetStandardReturnHeader true]
}

#--
# CleanUp - Clean up configuration after test
#--
# Parameters :
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc CleanUp { } {
    set tag "proc CleanUp...."
    IXIA::Deputs "----- TAG: $tag -----"
    if { [ catch {
        #if { [info exist ::tcName] } {
        #    if { $IXIA::tcName == $::tcName } {
        #        unset ::tcName
        #    }
        #}
        IXIA::disconnect
    } err ] } {
        return [GetStandardReturnHeader false $err]
    }
    IXIA::Deputs "  proc CleanUp over  "
    return [GetStandardReturnHeader true]
}

#--
# ConfigUDP - Configure UDP parameters in test
#--
# Parameters :
#           -parallelcmdcnt: Parallel command count
#           -enabletos: Enable tos
#           -enableperstreamstats: Enable per stream stats
#           -enableoutoforderstats: Enable out of order stats
#           -enableintegritycheck: Enable checksum check
#           -enabletimestamp: Enable timestamp
#           -typeofservice: Type of service
#           -seedrandom: Random seed
#           -enableheadercachehack: Enable header cache hack
#           -disablepromotion: Disable promotion
#           -cyclethroughinterfaces: Cycle through interfaces
#           -cyclethroughduration: Cycle through duration (sec)
#           -cyclethroughpercentage: Cycle through percentage (%)
#           -trafficgenerator: Traffic mode - 0, 1
#---------------------------------------------------------------------------
#           -usepredefinedqci: 
#           -usepredefinedtft:
#           -gbrd:
#           -mbru:
#           -tft:
#           -defaultbearerfallback:
#           -networkinitiatedbearer:
#           -ignoretft:
#           -gbru:
#           -mbrd:
#           -qci:
#           -usedefaultbearer:
#---------------------------------------------------------------------------
#           -minimuminterval: Static Duration or Min random duration between
#           -maximuminterval: Max random duration between
#---------------------------------------------------------------------------
#           -streamdur: Duration (sec)
#           -enabledestinationportrand: Enable random responder ports
#           -enablesourceportrand: Enable random source ports
#           -rangeimixoption: Traffic mode - 0, 1
#           -remotepeer: Responder peer
#           -destination: Destination
#           -maxpacketfreq: Packet maximum frequency
#           -packetfreq: Packet minmum frequency
#           -destinationport: Responder Port(s)
#           -sourceport: Source port(s)
#           -maxcontentsize: Maximum payload size
#           -contentsize: Minimum payload size
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc ConfigUDP {objName args} {
    set tag "proc ConfigUDP [info script]"
    IXIA::Deputs "----- TAG: $tag -----"
    
    set actObj [ IXIA::getActivity $objName ]
    if { ![info exists actObj] } {
        IXIA::Deputs "No object $objName find in test!!!"
        return 0
    }
    set flowCnt [ $actObj agent.pm.protocolFlows.indexCount ]    
    for { set index 0 } { $index < $flowCnt } { incr index } {
        if { [regexp {displayName} [$actObj agent.pm.protocolFlows($index).getOptions]] } {
            set cmdName [ $actObj agent.pm.protocolFlows($index).cget -displayName ]
        } else {
            set cmdName [ $actObj agent.pm.protocolFlows($index).cget -cmdName ]
        }
        if { [ regexp {APN} $cmdName ] } {
            set apn [ $actObj agent.pm.protocolFlows($index) ]
        } elseif { [ regexp {THINK} $cmdName ] } {
            set think [ $actObj agent.pm.protocolFlows($index) ]
        } elseif { [ regexp {Generate UDP Stream} $cmdName ] } {
            set gudp [ $actObj agent.pm.protocolFlows($index) ]
        }
    }
    foreach { key value } $args {
        IXIA::Deputs "config -$key--$value"
        set key [string tolower $key]
        switch -exact -- $key {
            -parallelcmdcnt {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -parallelCmdCnt $value"
                $actObj agent.pm.advOptions.config -parallelCmdCnt $value
            }
            -enabletos {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enableTOS $value"
                $actObj agent.pm.advOptions.config -enableTOS $value
            }
            -enableperstreamstats {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enablePerStreamStats $value"
                $actObj agent.pm.advOptions.config -enablePerStreamStats $value
            }
            -enableoutoforderstats {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enableOutOfOrderStats $value"
                $actObj agent.pm.advOptions.config -enableOutOfOrderStats $value
            }
            -enableintegritycheck {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enableIntegrityCheck $value"
                $actObj agent.pm.advOptions.config -enableIntegrityCheck $value
            }
            -enabletimestamp {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enableTimestamp $value"
                $actObj agent.pm.advOptions.config -enableTimestamp $value
            }
            -typeofservice {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -typeOfService $value"
                $actObj agent.pm.advOptions.config -typeOfService $value
            }
            -cmdlistloops {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -cmdListLoops $value"
                $actObj agent.pm.advOptions.config -cmdListLoops $value
            }
            -seedrandom {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -seedRandom $value"
                $actObj agent.pm.advOptions.config -parallelCmdCnt $value
            }
            -enableheadercachehack {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -enableHeaderCacheHack $value"
                $actObj agent.pm.advOptions.config -enableHeaderCacheHack $value
            }
            -disablepromotion {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -disablePromotion $value"
                $actObj agent.pm.advOptions.config -disablePromotion $value
            }
            -cyclethroughinterfaces {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -cycleThroughInterfaces $value"
                $actObj agent.pm.advOptions.config -cycleThroughInterfaces $value
            }
            -cyclethroughduration {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -cycleThroughDuration $value"
                $actObj agent.pm.advOptions.config -cycleThroughDuration $value
            }
            -cyclethroughpercentage {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -cycleThroughPercentage $value"
                $actObj agent.pm.advOptions.config -cycleThroughPercentage $value
            }
            -trafficgenerator {
                IXIA::Deputs "$actObj agent.pm.advOptions.config -trafficGenerator $value"
                $actObj agent.pm.advOptions.config -trafficGenerator $value
            }
           -usepredefinedqci {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -usePredefinedQci $value"
                    $apn config -usePredefinedQci $value
                }
            }
           -usepredefinedtft {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -usePredefinedTft $value"
                    $apn config -usePredefinedTft $value
                }
            }
           -gbrd {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -gbrd $value"
                    $apn config -gbrd $value
                }
            }
           -mbru {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -mbru $value"
                    $apn config -mbru $value
                }
            }
           -tft {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -tft $value"
                    $apn config -tft $value
                }
            }
           -defaultbearerfallback {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -defaultBearerFallback $value"
                    $apn config -defaultBearerFallback $value
                }
            }
           -networkinitiatedbearer {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -networkInitiatedBearer $value"
                    $apn config -networkInitiatedBearer $value
                }
            }
           -ignoretft {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -ignoreTFT $value"
                    $apn config -ignoreTFT $value
                }
            }
           -gbru {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -gbru $value"
                    $apn config -gbru $value
                }
            }
           -mbrd {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -mbrd $value"
                    $apn config -mbrd $value
                }
            }
           -qci {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -qci $value"
                    $apn config -qci $value
                }
            }
           -usedefaultbearer {
                if {[ info exists apn ]} {
                    IXIA::Deputs "$apn config -useDefaultBearer $value"
                    $apn config -useDefaultBearer $value
                }
            }
           -minimuminterval {
                if {[ info exists think ]} {
                    IXIA::Deputs "$think config -minimumInterval $value"
                    $think config -minimumInterval $value
                }
            }
           -maximuminterval {
                if {[ info exists think ]} {
                    IXIA::Deputs "$think config -maximumInterval $value"
                    $think config -maximumInterval $value
                }
            }
           -streamdur {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -streamDur $value"
                    $gudp config -streamDur $value
                }
            }
           -enabledestinationportrand {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -enableDestinationPortRand $value"
                    $gudp config -enableDestinationPortRand $value
                }
            }
           -enablesourceportrand {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -enableSourcePortRand $value"
                    $gudp config -enableSourcePortRand $value
                }
            }
           -rangeimixoption {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -rangeImixOption $value"
                    $gudp config -rangeImixOption $value
                }
            }
           -remotepeer {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -remotePeer $value"
                    $gudp config -remotePeer $value
                }
            }
           -destination {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -destination $value"
                    $gudp config -destination $value
                }
            }
           -maxpacketfreq {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -maxPacketFreq $value"
                    $gudp config -maxPacketFreq $value
                }
            }
           -packetfreq {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -packetFreq $value"
                    $gudp config -packetFreq $value
                }
            }
           -destinationport {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -destinationPort $value"
                    $gudp config -destinationPort $value
                }
            }
           -sourceport {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -sourcePort $value"
                    $gudp config -sourcePort $value
                }
            }
           -longerthantimeline {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -longerThanTimeline $value"
                    $gudp config -longerThanTimeline $value
                }
            }
           -maxcontentsize {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -maxContentSize $value"
                    $gudp config -maxContentSize $value
                }
            }
           -contentsize {
                if {[ info exists gudp ]} {
                    IXIA::Deputs "$gudp config -contentSize $value"
                    $gudp config -contentSize $value
                }
            }
        }
    }
    
    IXIA::Deputs "  proc ConfigUDP over  "
    return [GetStandardReturnHeader true]
}

#--
# ConfigS1 - Configure S1 parameters in test
#--
# Parameters :
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc ConfigS1 {objName args} {
    set tag "proc ConfigS1 [info script]"
    IXIA::Deputs "----- TAG: $tag -----"
    
    set actObj [ getActivity $objName ]

    foreach { key value } $args {
        IXIA::Deputs "config -$key--$value"
        set key [string tolower $key]
        switch -exact -- $key {
            -commandtype {
                
            }
            -duration {
                set duration $value
            }
        }
    }
    
    IXIA::Deputs "  proc ConfigS1 over  "
    return [GetStandardReturnHeader true]
}

#--
# ConfigSCTP - Configure SCTP parameters in test
#--
# Parameters :
#	-usemultihomingtar: If you are configuring SCTP multi-homing for any of
#                           the stacks that are present in the IxLoad test scenario,
#                           then you should also enable this setting. Otherwise,
#                           there is no need to enable it
#	-heartbeatinterval: The value of the HB.interval protocol parameter
#	-maxinitretrans   : The value of the Max.Init.Retransmits protocol parameter
#	-betarto          : The value of the RTO.Beta protocol parameter
#	-initialrto       : The value of the initial timeout 
#	-maxpathpetrans   : The value of the Path.Max.Retrans protocol parameter
#	-minrto           : The value of the minimum timeout 
#	-alpharto         : The value of the RTO.Alpha protocol parameter
#	-cookielife       : The value of the Valid.Cookie.Life protocol parameter
#	-maxrto           : The value of the maximum timeout 
#	-maxassocretrans  : The value of the Association.Max.Retrans protocol parameter
#	-maxburst         : The value of the Max.Burst protocol parameter
#	-heartbeatmaxburst: The value of the Max.Burst protocol parameter
#Return :
#      Status: true/false
#      Log   : If Status is false, it's error information, otherwise is empty
#--
#
proc ConfigSCTP {objName args} {
    set tag "proc ConfigSCTP [info script]"
    IXIA::Deputs "----- TAG: $tag -----"
    
    set network [ IXIA::getNetwork $objName ]
    set cnt [$network globalPlugins.indexCount]
    set i 0
    while { $i < $cnt } {
        set name [$network globalPlugins($i).name]
        if { [regexp {SCTP} $name total] } {
            set sctp [$network globalPlugins($i)]                  
            break
        }
        set i [ expr $i + 1 ]
    }
    
    if { ![info exists sctp] } {
        IXIA::Deputs "No SCTP object find in test!!!"
        return 0
    }
        
    foreach { key value } $args {
        IXIA::Deputs "config -$key--$value"
        set key [string tolower $key]
        switch -exact -- $key {
            -alpharto {
                IXIA::Deputs "$sctp config -alphaRTO $value"
                $sctp config -alphaRTO $value
            }
            -betarto {
                IXIA::Deputs "$sctp config -betaRTO $value"
                $sctp config -betaRTO $value 
            }
            -cookielife {
                IXIA::Deputs "$sctp config -cookieLife $value"
                $sctp config -cookieLife $value
            }
            -heartbeatinterval {
                IXIA::Deputs "$sctp config -heartbeatInterval $value"
                $sctp config -heartbeatInterval $value
            }
            -heartbeatmaxburst {
                IXIA::Deputs "$sctp config -heartbeatMaxBurst $value"
                $sctp config -heartbeatMaxBurst $value
            }
            -initialrto {
                IXIA::Deputs "$sctp config -initialRTO $value"
                $sctp config -initialRTO $value
            }
            -maxassocretrans {
                IXIA::Deputs "$sctp config -maxAssocRetrans $value"
                $sctp config -maxAssocRetrans $value
            }
            -maxburst {
                IXIA::Deputs "$sctp config -maxBurst $value"
                $sctp config -maxBurst $value
            }
            -maxinitretrans {
                IXIA::Deputs "$sctp config -maxInitRetrans $value"
                $sctp config -maxInitRetrans $value
            }
            -maxpathpetrans {
                IXIA::Deputs "$sctp config -maxPathRetrans $value"
                $sctp config -maxPathRetrans $value
            }
            -minrto {
                IXIA::Deputs "$sctp config -minRTO $value"
                $sctp config -minRTO $value
            }
            -maxrto {
                IXIA::Deputs "$sctp config -maxRTO $value"
                $sctp config -maxRTO $value
            }
            -usemultihomingtar {
                IXIA::Deputs "$sctp config -useMultiHomingTar $value"
                $sctp config -useMultiHomingTar $value
            }
        }
    }

    IXIA::Deputs "  proc ConfigSCTP over  "
    return [GetStandardReturnHeader true] 
}

# -- Changes end