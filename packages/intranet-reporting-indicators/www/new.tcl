# /packages/intranet-reporting-indicators/www/new.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    New page is basic...
    @author frank.bergmann@project-open.com
} {
    indicator_id:integer,optional
    {return_url "/intranet-reporting-indicators/index"}
    { indicator_object_type "" }
    { indicator_widget_bins 5 }
    { indicator_low_warn:float,optional }
    { indicator_low_critical:float,optional }
    { indicator_high_warn:float,optional }
    { indicator_high_critical:float,optional }
    { indicator_widget_min:float,optional }
    { indicator_widget_max:float,optional }
    { also_add_rel_to_objects {} }
    { also_add_rel_type "" }
    { form_mode "display" }
    { formbutton:optional}
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-reporting.New_Indicator "New Indicator"]
set context [im_context_bar $page_title]
set action_url "/intranet-reporting-indicators/new"
set form_id "form"

set add_reports_p [im_permission $user_id "add_reports"]
if {!$add_reports_p} {
    im_security_alert \
	-location "/intranet-reporting-indicators/new" \
	-message "User trying to modify an indicator"

    ad_return_complaint 1 "You don't have permissions to see this screen"
    ad_script_abort
}

# ------------------------------------------------------------------
# Delete pressed?
# ------------------------------------------------------------------

set button_pressed [template::form get_action $form_id]
switch $button_pressed {
    "delete" {
	db_dml refresh "delete from im_indicator_results where result_indicator_id = :indicator_id"
	db_string del_indicator "select im_indicator__delete(:indicator_id)"
	ad_returnredirect $return_url
    }
    "refresh" {
	db_dml refresh "delete from im_indicator_results where result_indicator_id = :indicator_id"
	ad_returnredirect [export_vars -base "/intranet-reporting-indicators/new" {indicator_id return_url}]
    }
}

# ------------------------------------------------------------------
# Validate
# ------------------------------------------------------------------

ad_proc -private im_validate_indicators {
    indicator_high_warn
    indicator_high_critical
    indicator_low_warn 
    indicator_low_critical
    indicator_widget_max
    indicator_widget_min
} {} {

    # Validate indicators "Low" 
    if {
	([info exists indicator_low_warn] && "" ne $indicator_low_warn) &&
	([info exists indicator_low_critical] && "" ne $indicator_low_critical) &&
	$indicator_low_warn < $indicator_low_critical
    } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Low_Validation_Failed "Value for 'Low Warn' needs to be greater than 'Low Critical'"]
	ad_script_abort
    }
    
    # Validate indicators "High" 
    if {
	([info exists indicator_high_warn] && "" ne $indicator_high_warn)  &&
	([info exists indicator_high_critical] && "" ne $indicator_high_critical) &&
	$indicator_high_warn > $indicator_high_critical
    } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Low_Validation_Failed "Value for 'High Critical' needs to be greater than 'High Warn'"]
	ad_script_abort
    }

    ###    
    # Validate indicator "Max"
    #
    if { ([info exists indicator_high_warn] && "" ne $indicator_high_warn) && $indicator_high_warn > $indicator_widget_max } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Max_Validation_Failed_Warn "Value for 'Indicator Widget Max' needs to be equal or greater than 'High Warn'"]
	ad_script_abort
    }
    
    if { ([info exists indicator_high_critical] && "" ne $indicator_high_critical) && $indicator_high_critical > $indicator_widget_max } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Max_Validation_Failed_Critical "Value for 'Indicator Widget Max' needs to be equal or greater than 'High Critical'"]
	ad_script_abort
    }

    if { ([info exists indicator_low_warn] && "" ne $indicator_low_warn) && $indicator_low_warn > $indicator_widget_max } {
        ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Max_Validation_Failed_Critical "Value for 'Indicator Widget Max' needs to be equal or greater than 'Low Warning'"]
        ad_script_abort
    }

    if { ([info exists indicator_low_critical] && "" ne $indicator_low_critical) && $indicator_low_critical > $indicator_widget_max } {
        ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Min_Validation_Failed_Critical "Value for 'Indicator Widget Min' needs to be equal or greater than 'Low Critical'"]
        ad_script_abort
    }
    
    ###
    # Validate indicator "Min"
    #
    if { ([info exists indicator_high_warn] && "" ne $indicator_high_warn) && $indicator_high_warn < $indicator_widget_min } {
        ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Max_Validation_Failed_Warn "Value for 'Indicator Widget Min' needs to be equal or less than 'High Warn'"]
        ad_script_abort
    }

    if { ([info exists indicator_high_warn] && "" ne $indicator_low_warn) && $indicator_low_warn < $indicator_widget_min } {
        ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Max_Validation_Failed_Warn "Value for 'Indicator Widget Min' needs to be equal or less than 'Low Warn'"]
        ad_script_abort
    }

    if { ([info exists indicator_low_warn] && "" ne $indicator_low_warn) && $indicator_low_warn < $indicator_widget_min } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Min_Validation_Failed_Warn "Value for 'Indicator Widget Min' needs to be equal or less than 'Low Warn'"]
	ad_script_abort
    }
    
    if { ([info exists indicator_low_critical] && "" ne $indicator_low_critical) && $indicator_low_critical < $indicator_widget_min } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-reporting-indicators.Min_Validation_Failed_Critical "Value for 'Indicator Widget Min' needs to be equal or less than 'Low Critical'"]
	ad_script_abort
    }

}

# ---------------------------------------------------------------
# Options

set object_type_options [db_list_of_lists otype_options "
	select	pretty_name, object_type
	from	acs_object_types
	where	object_type in ('user', 'im_project', 'im_sla_parameter')
	order by object_type
"]
set object_type_options [linsert $object_type_options 0 {{Not related to a specific object type} {}} ]

# ---------------------------------------------------------------
# Setup the form

set actions {}
lappend actions [list [lang::message::lookup {} intranet-reporting.Edit_Indicator {Edit Indicator}] edit ]
lappend actions [list [lang::message::lookup {} intranet-reporting.Delete_Indicator {Delete Indicator}] delete ]
lappend actions [list [lang::message::lookup {} intranet-reporting.Delete_Result_History {Delete/Refresh Result History}] refresh ]

# lappend actions [list [lang::message::lookup {} intranet-timesheet2.Delete Delete] delete]
# ad_return_complaint 1 $actions


ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -has_edit 1 \
    -mode $form_mode \
    -export {return_url also_add_rel_to_objects also_add_rel_type } \
    -form {
	indicator_id:key
	{report_name:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Name {Indicator Name}]"} {html {size 60}}}
	{report_code:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Code {Indicator Code}]"} {html {size 10}}}
	{indicator_section_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-reporting.Indicator_Section {Section}]"} {custom {category_type "Intranet Indicator Section" translate_p 1}} }
	{indicator_object_type:text(select),optional {label "[lang::message::lookup {} intranet-reporting.Reports_Object_Type {For Object Type}]"} {options $object_type_options} {help_text {}}}

	{indicator_widget_min:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Widget_Min {Widget Min}]"} {html {size 10}}}
	{indicator_widget_max:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Widget_Max {Widget Max}]"} {html {size 10}}}

	{indicator_low_warn:text(text),optional {label "[lang::message::lookup {} intranet-reporting.Indicator_Low_Warning {Low Warning Level}]"} {html {size 10}}}
	{indicator_low_critical:text(text),optional {label "[lang::message::lookup {} intranet-reporting.Indicator_Low_Critical {Low Critical Level}]"} {html {size 10}}}
	{indicator_high_warn:text(text),optional {label "[lang::message::lookup {} intranet-reporting.Indicator_High_Warning {High Warning Level}]"} {html {size 10}}}
	{indicator_high_critical:text(text),optional {label "[lang::message::lookup {} intranet-reporting.Indicator_High_Critical {High Critical Level}]"} {html {size 10}}}

	{report_sql:text(textarea) {label "[lang::message::lookup {} intranet-reporting.Reports_SQL {Report SQL}]"} {html {cols 60 rows 10} }}
	{report_description:text(textarea),optional {label "[lang::message::lookup {} intranet-reporting.Reports_Description {Description}]"} {html {cols 60 rows 4} }}
    }

# ------------------------------------------------------------------
# Validate 
# ------------------------------------------------------------------

ad_form -extend -name $form_id \
    -select_query {

	select	r.*,
		i.*
	from	im_reports r,
		im_indicators i
	where	i.indicator_id = :indicator_id
		and i.indicator_id = r.report_id
    } -new_data {

	im_validate_indicators $indicator_high_warn $indicator_high_critical $indicator_low_warn $indicator_low_critical $indicator_widget_max $indicator_widget_min

	set indicator_id [db_nextval "acs_object_id_seq"]

	db_exec_plsql create_report "
		SELECT im_indicator__new(
			:indicator_id,
			'im_indicator',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,

			:report_name,
			:report_code,
			[im_report_type_indicator],
			[im_report_status_active],
			:report_sql::text,

			:indicator_widget_min::double precision,
			:indicator_widget_max::double precision,
			:indicator_widget_bins::integer
		)
        "

	db_dml edit_report "
		update im_reports set 
			report_description = :report_description
		where report_id = :indicator_id
	"

	db_dml edit_indicator "
		update im_indicators set 
			indicator_section_id	= :indicator_section_id,
			indicator_object_type   = :indicator_object_type,
			indicator_low_warn      = :indicator_low_warn,
			indicator_low_critical  = :indicator_low_critical,
			indicator_high_warn     = :indicator_high_warn,
			indicator_high_critical = :indicator_high_critical
		where indicator_id = :indicator_id
	"
	set return_url [export_vars -base "/intranet-reporting-indicators/new" {indicator_id}]

    } -edit_data {

	im_validate_indicators $indicator_high_warn $indicator_high_critical $indicator_low_warn $indicator_low_critical $indicator_widget_max $indicator_widget_min 

	db_dml edit_report "
		update im_reports set 
			report_name = :report_name,
			report_code = :report_code,
			report_status_id = [im_report_status_active],
			report_type_id = [im_report_type_indicator],
			report_menu_id = null,
			report_sql = :report_sql,
			report_description = :report_description
		where report_id = :indicator_id
	"

	db_dml edit_indicator "
		update im_indicators set 
			indicator_widget_min    = :indicator_widget_min,
			indicator_widget_max    = :indicator_widget_max,
			indicator_widget_bins   = :indicator_widget_bins,
			indicator_section_id    = :indicator_section_id,
			indicator_object_type   = :indicator_object_type,
			indicator_low_warn      = :indicator_low_warn,
			indicator_low_critical  = :indicator_low_critical,
			indicator_high_warn     = :indicator_high_warn,
			indicator_high_critical = :indicator_high_critical
		where indicator_id = :indicator_id
	"
	set return_url [export_vars -base "/intranet-reporting-indicators/new" {indicator_id}]

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }

