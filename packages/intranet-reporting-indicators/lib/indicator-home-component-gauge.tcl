# /packages/intranet-reporting-indicators/www/indicator-home-component-gauge.tcl
#
# Copyright (c) 2016 ]project-open[
# All rights reserved
#

ad_page_contract {
    
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {
    { return_url "" }
    { object_id "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

if {![info exists module]} { set module "" }

set current_user_id [auth::require_login]
set add_reports_p [im_permission $current_user_id "add_reports"]
set view_reports_all_p [im_permission $current_user_id "view_reports_all"]

if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""

# Evaluate indicators every X hours:
set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

# Did the user specify an object? Then show only indicators designed
# to be shown with that object.
if {![info exists object_type]} { set object_type "" }
if {"" != $object_id} { set object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""] }

# ------------------------------------------------------
# SQL
# ------------------------------------------------------

set permission_sql "and 't' = im_object_permission_p(r.report_id, :current_user_id, 'read')"
#if {$view_reports_all_p} { set permission_sql "" }

set object_type_sql "and (indicator_object_type is null OR indicator_object_type = '')"
if {"" != $object_type} { set object_type_sql "and lower(indicator_object_type) = lower(:object_type)" }

set indicator_cnt 0
set html_output ""

set sql "
        select
                r.report_id,
                r.report_name,
                r.report_description,
                r.report_sql,
                i.*,
                im_category_from_id(i.indicator_section_id) as section,
                ir.result
        from
                im_reports r,
                im_indicators i
                LEFT OUTER JOIN (
                        select  avg(result) as result,
                                result_indicator_id
                        from    im_indicator_results
                        where   result_date >= now() - '$eval_interval_hours hours'::interval
                        group by result_indicator_id
                ) ir ON (i.indicator_id = ir.result_indicator_id)
        where
                r.report_id = i.indicator_id and
                r.report_type_id = [im_report_type_indicator]
                $object_type_sql
                $permission_sql
        order by
                section
"

db_foreach r $sql {

    incr indicator_cnt
    
    set report_view_url [export_vars -base "/intranet-reporting-indicators/view" {indicator_id return_url}]
    set report_edit_url [export_vars -base "/intranet-reporting-indicators/new" {indicator_id return_url}]
    set perms_url [export_vars -base "/intranet-reporting-indicators/perms" {{object_id $indicator_id} return_url}]
    set edit_html "
        <a href='$report_edit_url'>[im_gif "wrench"]</a>
        <a href='$perms_url'>[im_gif "lock"]</a>
    "
    
    set report_description [string map {{"} {}} $report_description]; #"
    set help_gif [im_gif help $report_description]
    set indicator_color "black"
    
    set error_occured_p 0
    if {"" == $result} {
	set error_occured_p [catch {set result [db_string value $report_sql]} err_msg]
    } else {
        db_dml insert "
                insert into im_indicator_results (
                        result_id,result_indicator_id,result_date,result
                ) values (
                        nextval('im_indicator_results_seq'),:report_id,now(),:result
                )
            "
    }
    
    set value $result

    if { "" == $value || $error_occured_p } {
        append html_div_output "<div class='gauge_box'><br/>$report_name:<br/>"
	if { $error_occured_p } {
	    append html_div_output $err_msg	
	} else {
	    append html_div_output "[lang::message::lookup "" intranet-reporting-indicators.Query_did_not_return_value "Query did not <br/>return any value."] "	
	}
        if { [im_is_user_site_wide_or_intranet_admin $user_id] } {
            append html_div_output "<br/><a href='$report_edit_url'>[lang::message::lookup "" intranet-reporting-indicators.Edit "Edit"]</a>"
        }
        append html_div_output "</div>"

    } else {

	# Defaults 
	set chart_color_value ""
	set value_txt $value
	set ranges ""

	# Don't destroy charts due to value > indicator_widget_max
	if { $value > $indicator_widget_max } { set indicator_widget_max $value}	

	# Handle missing indicator attributes 
	if { ![info exists indicator_widget_min] || "" == $indicator_widget_min } { set indicator_widget_min 0 }
	if { ![info exists indicator_low_warn] || "" == $indicator_low_warn } { set indicator_low_warn $indicator_widget_min }
	if { ![info exists indicator_low_critical] || "" == $indicator_low_critical } { set indicator_low_critical $indicator_widget_min }
	if { ![info exists indicator_high_warn] || "" == $indicator_high_warn } { set indicator_high_warn $indicator_widget_max }
	if { ![info exists indicator_high_critical] || "" == $indicator_high_critical } { set indicator_high_critical $indicator_widget_max }
	
	if { $indicator_low_warn != $indicator_low_critical } {
	    append ranges "\{ from: $indicator_widget_min, to: $indicator_low_critical, color: '#[im_color_code red_dark ""]'\},"
	    append ranges "\{ from: $indicator_low_critical, to: $indicator_low_warn, color: '#[im_color_code yellow_light ""]'\},"
	}
	
	append ranges "\{ from: $indicator_low_warn, to: $indicator_high_warn, color: '#[im_color_code green_light ""]'\},"
	
	if { $indicator_high_warn != $indicator_high_critical } {
	    append ranges "\{ from: $indicator_high_warn, to: $indicator_high_critical, color: '#[im_color_code yellow_light ""]'\},"
	    append ranges "\{ from: $indicator_high_critical, to: $indicator_widget_max, color: '[im_color_code red_dark ""]'\},"
	}
	
	# Set Context Menu 
	set context_menu_items "{ text: '[lang::message::lookup "" intranet-reporting-indicators.ViewTimeline "View Timeline"]',
                                  icon: '/intranet/images/navbar_default/chart_curve.png',
                                  handler: function(button, event, opts){
                                    document.location.href ='/intranet-reporting-indicators/view-sencha?indicator_id=$report_id';
                                  }
                                }"
	if { [im_is_user_site_wide_or_intranet_admin $user_id] } {
	    append context_menu_items ",{ text: '[lang::message::lookup "" intranet-reporting-indicators.EditIndicator "Edit Indicator"]',
                                          icon: '/intranet/images/navbar_default/wrench.png',
                                          handler: function(button, event, opts){
                                            document.location.href ='/intranet-reporting-indicators/new?indicator_id=$report_id';
                                          }
                                        }"
	    append context_menu_items ",{ text: '[lang::message::lookup "" intranet-reporting-indicators.SetPermissions "Set Permissions"]',
                                          icon: '/intranet/images/navbar_default/lock.png',
                                          handler: function(button, event, opts){
                                            document.location.href ='/intranet-reporting-indicators/perms?object_id=$report_id';
                                          }
                                        }"
	}
	
	# Create single Gauge 
	set params [list \
			[list id $report_id] \
			[list value $value] \
			[list min $indicator_widget_min] \
			[list max $indicator_widget_max] \
			[list chart_color_value $chart_color_value] \
			[list indicator_low_warn $indicator_low_warn] \
			[list indicator_low_critical $indicator_low_critical] \
			[list indicator_high_warn $indicator_high_warn] \
			[list indicator_high_critical $indicator_high_critical] \
			[list ranges $ranges] \
			[list context_menu_items $context_menu_items] \
		       ]
	append html_js_output [ad_parse_template -params $params "/packages/intranet-reporting-indicators/lib/single-gauge"]
	append html_div_output "
                <div class='gauge_box'>
                        <div id='div_gauge_${report_id}'></div>
                        <div class='gauge_title'>
                                <div class='gauge_value'>$value</div>
                                <span id='component_gauge_more_$report_id' class='component_gauge_more'>$report_name</span>
                        </div>
                </div>
        "
    }
}

if { $indicator_cnt } {
    im_sencha_extjs_load_libraries
    template::head::add_css -href "/intranet-reporting-indicators/css/style.css" -media "screen" -order 10000
}

