ad_page_contract {

    @cvs-id $Id: unsubscribe.tcl,v 1.4 2015/12/04 13:50:09 cvs Exp $
}

set user_id [auth::get_user_id -account_status closed]

set system_name [ad_system_name]

set page_title [_ acs-subsite.Close_your_account]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set pvt_home [ad_pvt_home]
set pvt_home_name [ad_pvt_home_name]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
