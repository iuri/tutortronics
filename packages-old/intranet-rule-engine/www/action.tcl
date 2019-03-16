# /packages/intranet-rule-engine/www/action.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-rule-engine/index page or 
    the notes-list-compomponent and perform the selected 
    action an all selected notes.
    @author frank.bergmann@project-open.com
} {
    action
    { rule_log_id:multiple ""}
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [auth::require_login]
if {0 == [llength $rule_log_id]} { ad_returnredirect $return_url }

switch $action {
    del_logs {
	foreach id $rule_log_id {
	    db_dml del_rule_logs "delete from im_rule_logs where rule_log_id = :id"
	}
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

