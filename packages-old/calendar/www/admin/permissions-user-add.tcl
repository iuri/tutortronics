ad_page_contract {
    Redirect page for adding users to the permissions list.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id: permissions-user-add.tcl,v 1.5 2015/12/04 14:02:54 cvs Exp $
} {
    object_id:naturalnum,notnull
}

set page_title "Add User"

set context [list [list [export_vars -base permissions { object_id }] "Permissions"] $page_title]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
