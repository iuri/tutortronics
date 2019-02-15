# /intranet-demo-date/www/recalculate-day.tcl

ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2012-05-10
    @cvs-id $Id: recalculate-day.tcl,v 1.5 2016/04/14 14:25:10 cvs Exp $

} {
    { day:multiple "" }
    { return_url "" }
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set title "Recalculate Demo-Data"
set context [list [list "/intranet-dynfield/" "DynField"] [list "object-types" "Object Types"] $title]

# ******************************************************
# 
# ******************************************************

foreach d [lsort -increasing $day] {
    im_demo_data_main_loop -start_date $d -max_days 1
}

ad_returnredirect $return_url

