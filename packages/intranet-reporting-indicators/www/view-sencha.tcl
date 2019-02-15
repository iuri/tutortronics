# /packages/intranet-reporting-indicators/www/view-sencha.tcl
#
# Copyright (c) 2003-2016 ]project-open[
# frank.bergmann@project-open.com
# klaus.hofeditz@project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show the results of a single "dynamic" report or indicator
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {
    indicator_id:integer
    { start_date "2010-01-01" }
    { end_date "2030-12-31" }
    {return_url "/intranet-reporting-indicators/index"}
}

# ---------------------------------------------------------------
# Defaults & Security

set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "select im_object_permission_p(:indicator_id, :current_user_id, 'read')" -default 'f']
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

set add_reports_p [im_permission $current_user_id "add_reports"]

if { "" != $start_date } {
    if {[catch {
        if { $start_date != [clock format [clock scan $start_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}


# ---------------------------------------------------------------
# Get Report Info
db_1row report_info "
        select  r.*,
                i.*,
                im_category_from_id(report_type_id) as report_type
        from    im_reports r,
                im_indicators i
        where   r.report_id = :indicator_id
                and r.report_id = i.indicator_id
"

set title "$report_type: $report_name"
set page_title $title
set context [im_context_bar $title]

set label_x ""
set label_y ""
set dateFormat "j M Y"

# Set Labels
if { "" != $indicator_labels } {
    foreach kv $indicator_labels {
        set cmd "set [lindex $kv 0] [lang::message::lookup "" intranet-reporting-indicators.[lindex $kv 1] [lindex $kv 1]]"
        eval $cmd
    }
}

# Set Attributes
if { "" != $indicator_attributes } {
    foreach kv $indicator_attributes {
        set cmd "set [lindex $kv 0] \"[lindex $kv 1]\""
        eval $cmd
    }
}

# Calculate earliest date
if { "" != $indicator_timeline_max_days_backwards } {
    set today [clock format [clock seconds] -format {%Y-%m-%d}]
    set offset "-$indicator_timeline_max_days_backwards days"
    set initial_date [clock format [clock scan $offset -base [clock scan $today] ] -format %Y-%m-%d]
    set max_days_backwards_where "result_date::date > :initial_date::date"
} else {
    set max_days_backwards_where "1=1"
    set initial_date "1970-01-01"
}


# Set additional where
switch $indicator_timeline_default_periodic {
    monthly {
        set periodic_where "to_char(result_date, 'DD') = '01'"
    }
    yearly {
        set periodic_where "to_char(result_date, 'DDMM') = \'0101\'"
    }
    default {
        set periodic_where "1=1"
    }
}

#  Inform user that due to indicator configuration data set is limited
set msg_inital_date_applied ""
if { [info exists initial_date] } {
    set msg_inital_date_applied [lang::message::lookup "" intranet-reporting-indicators.BackwardsMsg "Please note: History Data only available from $initial_date on"]
}

set history_html ""
set history_html [im_indicator_timeline_widget_sencha \
                      -report_id $report_id \
                      -name $report_name \
                      -initial_date $initial_date \
                      -periodic_where $periodic_where \
                      -start_date $start_date \
                      -end_date $end_date \
                      -diagram_width 800 \
                      -diagram_height 400 \
                      -title $title \
                      -render_to "diagram_container" \
                      -label_x $label_x \
                      -label_y $label_y \
                      -dateFormat $dateFormat \
		      ]

set page_body "$history_html <br><br>$msg_inital_date_applied"

# ---------------------------------------------------------------
# Left Navbar
# ---------------------------------------------------------------

 set filter_html "
 <form method=get action='/intranet-reporting-indicators/view-sencha' name=filter_form>
 [export_form_vars return_url indicator_id]
 <table border=0 class='filter-table'>
 <tr>
   <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.Start_Date "Start Date"] </td>
   <td valign=top><input type=text name=start_date value=\"$start_date\"></td>
 </tr>
 <tr>
   <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.End_Date "End Date"] </td>
   <td valign=top><input type=text name=end_date value=\"$end_date\"></td>
 </tr>
 <tr>
   <td valign=top>&nbsp;</td>
   <td valign=top><input type=submit value='[_ intranet-timesheet2.Go]' name=submit></td>
 </tr>
 </table>
 </form>
"

set admin_html "<li><a href='/intranet-reporting-indicators/'>[lang::message::lookup "" intranet-reporting-indicators.ShowAllIndicators "Show all indicators"]</a></li>"
if {$add_reports_p} {
    append admin_html "<li><a href='/intranet-reporting-indicators/new?form%5fmode=edit'>[lang::message::lookup "" intranet-reporting-indicators.EditIndicators "Add indicator"]</a></li>"
}
append admin_html "
        <li><a href='/intranet-reporting-indicators/new?indicator_id=$indicator_id'>[lang::message::lookup "" intranet-reporting-indicators.EditIndicators "Edit indicator"]</a></li>
        <li><a href='/intranet-reporting-indicators/perms?object_id=$indicator_id'>[lang::message::lookup "" intranet-reporting-indicators.SetPermissions "Set Permissions"]</a></li>
"

set left_navbar_html "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                        [lang::message::lookup "" intranet-reporting-indicators.Filter_Indicator "Filter Indicator"]
                </div>
                $filter_html
            </div>

            <div class=\"filter-block\">
                <div class=\"filter-title\">[lang::message::lookup "" intranet-reporting-indicators.AdminLinks "Admin"]</div>
                <ul>$admin_html </ul>
            </div>
            <hr/>
"


