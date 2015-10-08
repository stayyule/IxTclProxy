package req Itcl
namespace import itcl::*

class IxiaTcl {
	
	public variable ip
	public variable port
	
	constructor { _ip _port } {
		set ip $_ip
		set port $_port
	}
	
	method exec { args } {
		set channel [ socket $ip $port ]
		puts $channel $args
		flush $channel
		set result [ gets $channel ]
		close $channel
		return $result
	}
	
}