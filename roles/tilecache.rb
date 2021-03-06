name "tilecache"
description "Role applied to all tile cache servers"

default_attributes(
  :accounts => {
    :groups => {
      :proxy => {
        :members => [:tomh, :grant, :matt, :jburgess]
      }
    }
  },
  :apt => {
    :sources => ["nginx"]
  },
  :nginx => {
    :access_log => false
  },
  :sysctl => {
    :network_conntrack_time_wait => {
      :comment => "Only track completed connections for 30 seconds",
      :parameters => {
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" => "30"
      }
    },
    :network_conntrack_max => {
      :comment => "Increase max number of connections tracked",
      :parameters => {
        "net.netfilter.nf_conntrack_max" => "262142"
      }
    },
    :network_local_port_range => {
      :comment => "Increase available local port range",
      :parameters => {
        "net.ipv4.ip_local_port_range" => "4096 64000"
      }
    },
    :kernel_tfo_listen_enable => {
      :comment => "Enable TCP Fast Open for listening sockets",
      :parameters => {
        "net.ipv4.tcp_fastopen" => 3
      }
    },
    :squid_swappiness => {
      :comment => "Prefer not to swapout to free memory",
      :parameters => {
        "vm.swappiness" => "30"
      }
    }
  }
)

run_list(
  "recipe[tilecache]"
)
