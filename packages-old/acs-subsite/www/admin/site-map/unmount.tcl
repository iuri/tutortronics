# packages/acs-core-ui/www/admin/site-nodes/unmount.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-09-12
    @cvs-id $Id: unmount.tcl,v 1.4 2015/12/04 13:50:09 cvs Exp $

} {
    node_id:naturalnum,notnull
    {expand:integer,multiple ""}
    root_id:naturalnum,optional
}

site_node::unmount -node_id $node_id

ad_returnredirect [export_vars -base . {expand:multiple root_id}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
