package req Itcl
namespace import itcl::*

class IxiaTcl {
	public variable ip
	public variable port
    public variable portList
	
	constructor { _ip { _port 4555 } } {
		set ip $_ip
		set port $_port
        set portList [list 4556 4557 4558 4559 4560 4561 4562 4563 4564 4565 4566 4567 4568 4569 4570 4571 4572 4573 4574]
	}
	
	method exec { args } {
        set channel [ socket $ip $port ]
        puts $channel $args
        flush $channel
        set result [ gets $channel ]
        close $channel
        return [$this format $result]
	}
	
	method format { str } {
		return [string map {"###" "\n"} $str]
	}
    
    method available {} {
        set is_ready false
        # Use configured port to try to connect to the remote proxy server
        if { [ catch {
            if { ![ $this exec info exist ::testName ] } {
                set is_ready true 
            }
        } err ] } {
            # User configured port is not available,
            # so we'll try to use the port pool to find an available proxy server
            foreach p $portList {
                if { $p == $port } {
                    continue
                } else {
                    if { [ catch {
                        if { ![ $this exec info exist ::testName ] } {
                            set is_ready true
                            break
                        }
                    } err ] } {
                        continue
                    }
                }
            }
        }
        
        return $is_ready
    }
    
    method save { name stream } {
		if { [catch {open ${name} w }  f ] } {
			puts "Could not open initialisation file ${name}"
		} else {
			puts $f $stream
			close $f
		}
    }
}