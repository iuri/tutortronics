# /packages/intranet-rule-engine/www/notes-del.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete Rules
    @author frank.bergmann@project-open.com
} {
    rule_id:multiple,optional
    { return_url "/intranet-rule-engine/index"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [auth::require_login]

if {[info exists rule_id]} {
    foreach id $rule_id {
	db_dml del_rule_log "delete from im_rule_logs where rule_log_rule_id = :id"
	db_string del_rule "select im_rule__delete(:id)"
    }
}

ad_returnredirect $return_url
