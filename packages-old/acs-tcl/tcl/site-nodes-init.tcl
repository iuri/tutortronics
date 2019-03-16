ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-07
  @cvs-id $Id: site-nodes-init.tcl,v 1.4 2015/12/04 13:50:11 cvs Exp $

}

nsv_set site_nodes_mutex mutex [ns_mutex create oacs:site_nodes]

site_node::init_cache

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
