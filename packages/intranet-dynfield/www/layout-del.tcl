ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-08
    @cvs-id $Id: layout-del.tcl,v 1.5 2015/11/25 16:58:10 cvs Exp $

} {
    object_type:notnull
    page_url:notnull
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

# ******************************************************
# Delete page layout
# ******************************************************

db_transaction {
    db_dml delete_page_attributes {
	delete from im_dynfield_layout
        where page_url = :page_url
    }
    db_dml delete_page_layout {
	delete from im_dynfield_layout_pages
	where page_url = :page_url
    }
} on_error {
    ad_return_complaint 1 "<b>This page could not be deleted</b>:<br><pre>$errmsg</pre>"
    ns_log Warning "\[TCL\]dynfield/www/layout-del.tcl --------> $errmsg"
}

ad_returnredirect [export_vars -base layout-manager {object_type}]

