# -------------------------------------------------------------
# /packages/intranet-rule-engine/www/rules-audit-component.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	object_id:integer
#	return_url

if {![info exists object_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	object_id:integer
    }
}

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [auth::require_login]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd


# ----------------------------------------------------
# Create a "multirow" to show the results

multirow create rule_logs

set rule_log_sql "
	select	rl.*,
		r.*,
		to_char(rl.rule_log_date, 'YYYY-MM-DD HH24:MI') as rule_log_date_pretty
	from	im_rule_logs rl,
		im_rules r
	where	rl.rule_log_object_id = :object_id and
		rl.rule_log_rule_id = r.rule_id
	order by 
	      rl.rule_log_date DESC
	LIMIT 50
"

db_multirow -extend { rule_url } rule_logs rule_log_query $rule_log_sql {
    set rule_url [export_vars -base "/intranet-rule-engine/new" {rule_id return_url}]
}


if {$object_read} { }
