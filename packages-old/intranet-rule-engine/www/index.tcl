# /packages/intranet-rule-engine/www/index.tcl
#
# Copyright (C) 2003 - 2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { object_id:integer 0}
    { rule_object_type ""}
    { rule_type_id:integer 0}
    { rule_invocation_type_id:integer 0}
    { rule_status_id:integer 0}
    { start_date "2000-01-01" }
    { end_date "2100-01-01" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-rule-engine.Rules "Rules"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set org_rule_type_id $rule_type_id
set org_rule_invocation_type_id $rule_invocation_type_id
set org_rule_status_id $rule_status_id
set date_format "YYYY-MM-DD"
set org_rule_object_type $rule_object_type

set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$admin_p} { 
    ad_return_complaint 1 "This page is only accessible for System Administrators" 
    ad_script_abort
}

# ---------------------------------------------------------------
# Compose the List
# ---------------------------------------------------------------
set ttt {
    rule_type {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Type Type]"
    }
    rule_action_email_subject {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Email_Subject {Email Subject}]"
    }
}

# The columns to be shown in the RuleListPage
set elements_list {
    rule_chk {
	label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('rule_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	display_template {
	    @rule_lines.rule_chk;noquote@
	}
    }
    rule_sort_order {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Sort_Order {Nr}]"
    }
    rule_name {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Name {Name}]"
	link_url_eval $rule_url
    }
    rule_status {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Status Status]"
    }
    rule_object_type {
	label "[lang::message::lookup {} intranet-rule-engine.Type {Type}]"
	display_template {
	    @rule_lines.rule_object_type@/<br><nobr>@rule_lines.rule_invocation_type@</nobr>/<br>@rule_lines.rule_status@
	}
    }
    rule_condition_tcl_pretty {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Condition_TCL {Condition Tcl}]"
    }
    rule_action_tcl_pretty {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Action_TCL {Action Tcl}]"
    }
    rule_action_email_to_tcl_pretty {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Email_To {Email To}]"
    }
    rule_description {
	label "[lang::message::lookup {} intranet-rule-engine.Rule_Description {Description}]"
    }
}

# The list of "bulk actions" to perform on the list of rule
set bulk_actions_list [list]
lappend bulk_actions_list [lang::message::lookup {} intranet-rule-engine.Delete Delete] "rule-del" [lang::message::lookup {} intranet-rule-engine.Remove_checked_items "Remove checked items"]

set action_list [list]
lappend action_list [lang::message::lookup "" intranet-rule-engine.New_Rule "New Rule"] [export_vars -base "/intranet-rule-engine/new" {rule_object_type}] [lang::message::lookup "" intranet-rule-engine.Create_new_rule "Create a new rule"]


template::list::create \
    -name "rule_list" \
    -multirow rule_lines \
    -key rule_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { object_id } \
    -actions $action_list \
    -row_pretty_plural [lang::message::lookup {} intranet-rule-engine.Rule_Items "Items"] \
    -elements $elements_list



# ---------------------------------------------------------------
# Determine the data to be shown
# ---------------------------------------------------------------


set where_clause ""
if {0 != $rule_object_type && "" != $rule_object_type} { 
    append where_clause "\tand r.rule_object_type = :rule_object_type\n" 
}
if {0 != $rule_type_id && "" != $rule_type_id} { 
    append where_clause "\tand r.rule_type_id in (select * from im_sub_categories(:rule_type_id))\n" 
}
if {0 != $rule_invocation_type_id && "" != $rule_invocation_type_id} { 
    append where_clause "\tand r.rule_invocation_type_id in (select * from im_sub_categories(:rule_invocation_type_id))\n" 
}
if {0 != $rule_status_id && "" != $rule_status_id} { 
    append where_clause "\tand r.rule_status_id in (select * from im_sub_categories(:rule_status_id))\n" 
}

db_multirow -extend {rule_chk return_url rule_url rule_condition_tcl_pretty rule_action_tcl_pretty rule_action_email_to_tcl_pretty} rule_lines rule_lines "
select
	r.*,
        im_category_from_id(r.rule_type_id) as rule_type,
        im_category_from_id(r.rule_invocation_type_id) as rule_invocation_type,
        im_category_from_id(r.rule_status_id) as rule_status
from
        im_rules r
where
	1=1
        $where_clause
order by
	rule_sort_order
" {
    set rule_chk "<input type=\"checkbox\" name=\"rule_id\" value=\"$rule_id\" id=\"rule_list,$rule_id\">"
    set return_url [im_url_with_query]
    set rule_url [export_vars -base "/intranet-rule-engine/new" {rule_id {mode display}}]

    set rule_condition_tcl_pretty [string map {"(" "( " ")" " )"} $rule_condition_tcl]
    set rule_action_tcl_pretty [string map {"(" "( " ")" " )"} $rule_action_tcl]
    set rule_action_email_to_tcl_pretty [string range $rule_action_email_to_tcl 0 60]
    if {[string len $rule_action_email_to_tcl_pretty] >= 60} { append rule_action_email_to_tcl_pretty "..."}
}


# ---------------------------------------------------------------
# Filter for Rules
# ---------------------------------------------------------------

set rule_object_type $org_rule_object_type
set object_type_options [im_rule_object_type_options -include_empty_p 1 -include_empty_name ""]

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            [lang::message::lookup "" intranet-rule-engine.Filter_Rules "Filter Rules"]
         </div>
	<form method=POST action='/intranet-rule-engine/index'>
	<table>
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-rule-engine.Object_Type "Object Type"]</td>
	    <td class=form-widget>
		[im_select \
		     -translate_p 1 \
		     -ad_form_option_list_style_p 1 \
		     -package_key "intranet-core" \
		     rule_object_type \
		     $object_type_options \
		     $rule_object_type \
		]
	    </td>
	</tr>
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-rule-engine.Rule_Type "Type"]</td>
	    <td class=form-widget>[im_category_select -translate_p 1 -package_key "intranet-rule-engine" -include_empty_p 1  "Intranet Rule Invocation Type" rule_invocation_type_id $org_rule_invocation_type_id]</td>
	</tr>
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-rule-engine.Rule_Status "Status"]</td>
	    <td class=form-widget>[im_category_select -translate_p 1 -package_key "intranet-rule-engine" -include_empty_p 1  "Intranet Rule Status" rule_status_id $org_rule_status_id]</td>
	</tr>
	<tr>
	    <td class=form-label></td>
	    <td class=form-widget><input type=submit></td>
	</tr>
	</table>
	</form>
      </div>
"
