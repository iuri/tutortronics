# /packages/intranet-rule-engine/www/new.tcl
#
# Copyright (C) 2003-2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    New page is basic...
    @author all@devcon.project-open.com
} {
    rule_id:integer,optional
    {rule_object_type "" }
    {return_url "/intranet-rule-engine/index"}
    {form_mode "edit"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-rule-engine.New_Rule "New Rule"]
if {[info exists rule_id]} { set page_title [lang::message::lookup "" intranet-rule-engine.Rule Rule] }
set context_bar [im_context_bar $page_title]

set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$admin_p} { 
    ad_return_complaint 1 "This page is only accessible for System Administrators" 
    ad_script_abort
}


# We can determine the ID of the "container object" from the
# rule data, if the rule_id is there (viewing an existing rule).
if {[info exists rule_id] && "" == $rule_object_type} {
    set rule_object_type [db_string oid "select rule_object_type from im_rules where rule_id = :rule_id" -default ""]
}


# ---------------------------------------------------------------
# Create the Form
# ---------------------------------------------------------------

set object_type_options [im_rule_object_type_options]
set rule_type_id [im_rule_type_tcl]

set base_l10n [lang::message::lookup "" intranet-rule-engine.Base_Information "Base Information"]
set condition_l10n [lang::message::lookup "" intranet-rule-engine.Rule_Condition "Rule Condition"]
set action_tcl_l10n [lang::message::lookup "" intranet-rule-engine.Rule_Action "Rule TCL Action"]
set action_email_l10n [lang::message::lookup "" intranet-rule-engine.Rule_Email_Action "Rule Email Action"]

set rule_name_help [lang::message::lookup "" intranet-rule-engine.Rule_Name_Help "A short human readable name for the rule"]
set rule_sort_order_help [lang::message::lookup "" intranet-rule-engine.Rule_Sort_Order_Help "A number between 0 and 1000 that specifies the order or execution of the rule per object"]
set rule_object_type_help [lang::message::lookup "" intranet-rule-engine.Rule__Help "Specifies the object type for which to execute the rule."]
set rule_type_help [lang::message::lookup "" intranet-rule-engine.Rule_Type_Help "The rule type is currently not supported."]
set rule_invocation_type_help [lang::message::lookup "" intranet-rule-engine.Rule_Invocation_Type_Help "Fire the rule after the creation of the object or after each update of the object? The rule will be executed exactly once when choosing 'After Creation', while it may become executed multiple times when choosing 'After Update'."]
set rule_status_help [lang::message::lookup "" intranet-rule-engine.Rule_Status_Help "Used to temporarily deactivate rules. Only active rules are executed."]
set rule_condition_tcl_help [lang::message::lookup "" intranet-rule-engine.Rule_Condition_TCL_Help "A TCL expression that returns 0 or 1. For details please see <a href=http://www.project-open.com/en/package-intranet-rule-engine>Rule Engine Package</a>"]
set rule_action_tcl_help [lang::message::lookup "" intranet-rule-engine.Rule_Action_TCL_Help "A TCL command to be executed if condition is true. For details please see <a href=http://www.project-open.com/en/package-intranet-rule-engine>Rule Engine Package</a>"]
set rule_action_email_to_tcl_help [lang::message::lookup "" intranet-rule-engine.Rule_Action_Email_To_TCL_Help "A TCL expression that returns a list of email addresses. For details please see <a href=http://www.project-open.com/en/package-intranet-rule-engine>Rule Engine Package</a>"]
set rule_action_email_subject_help [lang::message::lookup "" intranet-rule-engine.Rule_Action_Email_Subject_Help "A string with &#36;varname; substitution. For details please see <a href=http://www.project-open.com/en/package-intranet-rule-engine>Rule Engine Package</a>"]
set rule_action_email_body_help [lang::message::lookup "" intranet-rule-engine.Rule_Action_Email_Body_Help "A string with &#36;varname substitution. For details please see <a href=http://www.project-open.com/en/package-intranet-rule-engine>Rule Engine Package</a>"]
set rule_description_help [lang::message::lookup "" intranet-rule-engine.Rule_Description_Help "A human readable description. Usefull for debugging by somebody who didn't write the rule."]

ad_form \
    -name rule_form \
    -mode $form_mode \
    -export "return_url" \
    -form {
	rule_id:key
	{-section $base_l10n {legendtext $base_l10n} }
	{rule_name:text(text) {label "[lang::message::lookup {} intranet-rule-engine.Name Name]"} {html {size 40}} {help_text $rule_name_help} }
	{rule_sort_order:integer(text) {label "[lang::message::lookup {} intranet-rule-engine.Sort_Order {Sort Order}]"}  {help_text $rule_sort_order_help}}
	{rule_object_type:text(select) {label "[lang::message::lookup {} intranet-rule-engine.Object_Type {Object Type}]"} {options $object_type_options}  {help_text $rule_object_type_help}}
	{rule_invocation_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-rule-engine.Rule_Invocation_Type {Invocation Type}]"} {custom {category_type "Intranet Rule Invocation Type" translate_p 1 package_key intranet-rule-engine include_empty_p 0}} {help_text $rule_invocation_type_help} }
	{rule_type_id:text(hidden),optional}
	{rule_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-rule-engine.Rule_Status Status]"} {custom {category_type "Intranet Rule Status" translate_p 1 package_key intranet-rule-engine include_empty_p 0}} {help_text $rule_status_help} }
	{-section $condition_l10n {legendtext $condition_l10n}}
	{rule_condition_tcl:text(textarea) {label "[lang::message::lookup {} intranet-rule-engine.Condition_TCL {Condition TCL}]"} {html {cols 120 rows 4}} {help_text $rule_condition_tcl_help} }
	{-section $action_tcl_l10n {legendtext $action_tcl_l10n}}
	{rule_action_tcl:text(textarea),optional {label "[lang::message::lookup {} intranet-rule-engine.Action_TCL {Action TCL}]"} {html {cols 120 rows 4}} {help_text $rule_action_tcl_help} }
	{-section $action_email_l10n {legendtext $action_email_l10n}}
	{rule_action_email_to_tcl:text(textarea),optional {label "[lang::message::lookup {} intranet-rule-engine.Email_To_TCL {Email-To TCL}]"} {html {cols 120 rows 4}} {help_text $rule_action_email_to_tcl_help} }
	{rule_action_email_subject:text(text),optional {label "[lang::message::lookup {} intranet-rule-engine.Email_Subject {Email-Subject}]"} {html {size 120}} {help_text $rule_action_email_subject_help} }
	{rule_action_email_body:text(textarea),optional {label "[lang::message::lookup {} intranet-rule-engine.Email_Body {Email-Body}]"} {html {cols 120 rows 15}} {help_text $rule_action_email_body_help} }
	{rule_description:text(textarea),optional {label "[lang::message::lookup {} intranet-core.Description Description]"} {html {cols 120 rows 4}} {help_text $rule_description_help} }
    }

set ttt {
	{rule_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-rule-engine.Rule_Type Type]"} {custom {category_type "Intranet Rule Type" translate_p 1 package_key intranet-rule-engine include_empty_p 0}} }
}

template::element::set_value rule_form rule_type_id $rule_type_id



# Add DynFields to the form
set my_rule_id 0
if {[info exists rule_id]} { set my_rule_id $rule_id }
im_dynfield::append_attributes_to_form \
    -object_type "im_rule" \
    -form_id "rule_form" \
    -object_id $my_rule_id


# ---------------------------------------------------------------
# Define Form Actions
# ---------------------------------------------------------------

ad_form -extend -name rule_form \
    -select_query {
	select	*
	from	im_rules
	where	rule_id = :rule_id
    } -new_data {

        set rule_name [string trim $rule_name]
        set duplicate_rule_sql "
                select  count(*)
                from    im_rules
                where   rule_object_type = :rule_object_type and rule_name = :rule_name
        "
        if {[db_string dup $duplicate_rule_sql]} {
            ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-rule-engine.Duplicate_rule "Duplicate rule"]</b>:<br>
            [lang::message::lookup "" intranet-rule-engine.Duplicate_rule_msg "
	    	There is already a rule with the same name available for the specified object type.
	    "]"
	    ad_script_abort
        }

	set rule_id [db_exec_plsql create_rule "
		SELECT im_rule__new(
			:rule_id,
			'im_rule',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,

			:rule_name,
			:rule_object_type,
			:rule_type_id,
			:rule_status_id,
			:rule_condition_tcl
		)
        "]

	db_dml rule_update "
		update im_rules set
			rule_object_type = :rule_object_type,
			rule_status_id = :rule_status_id,
			rule_type_id = :rule_type_id,
			rule_invocation_type_id = :rule_invocation_type_id,
			rule_name = :rule_name,
			rule_sort_order = :rule_sort_order,
			rule_description = :rule_description,
			rule_condition_tcl = :rule_condition_tcl,
			rule_action_tcl = :rule_action_tcl,
			rule_action_email_to_tcl = :rule_action_email_to_tcl,
			rule_action_email_subject = :rule_action_email_subject,
			rule_action_email_body = :rule_action_email_body
		where rule_id = :rule_id
	"

        im_dynfield::attribute_store \
            -object_type "im_rule" \
            -object_id $rule_id \
            -form_id rule_form

	# Update the audit information
	db_dml rule_object_update "
		update acs_objects set
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = '[ad_conn peeraddr]'
		where object_id = :rule_id
	"

    } -edit_data {

        set rule_name [string trim $rule_name]
	db_dml rule_update "
		update im_rules set
			rule_object_type = :rule_object_type,
			rule_status_id = :rule_status_id,
			rule_type_id = :rule_type_id,
			rule_invocation_type_id = :rule_invocation_type_id,
			rule_name = :rule_name,
			rule_sort_order = :rule_sort_order,
			rule_description = :rule_description,
			rule_condition_tcl = :rule_condition_tcl,
			rule_action_tcl = :rule_action_tcl,
			rule_action_email_to_tcl = :rule_action_email_to_tcl,
			rule_action_email_subject = :rule_action_email_subject,
			rule_action_email_body = :rule_action_email_body
		where rule_id = :rule_id
	"

        im_dynfield::attribute_store \
            -object_type "im_rule" \
            -object_id $rule_id \
            -form_id rule_form

	# Update the audit information
	# We need the modifying_user information in order to send this guy email with errors
	db_dml rule_object_update "
		update acs_objects set
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = '[ad_conn peeraddr]'
		where object_id = :rule_id
	"
	
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


