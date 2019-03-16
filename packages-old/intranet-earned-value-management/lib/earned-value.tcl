# Called from intranet-earned-value-management-procs.tcl
#
# project_id ID of the main project to be tracked

set work_planned_l10n [lang::message::lookup "" intranet-earned-value-management.work_planned_hours "Work Planned (hours)"]
set work_logged_l10n [lang::message::lookup "" intranet-earned-value-management.work_logged_hours "Work Logged (hours)"]
set work_done_l10n [lang::message::lookup "" intranet-earned-value-management.work_completed_hours "Work Done (hours)"]


set start_time [clock clicks -milliseconds]

if {"" eq $project_id} { set project_id 0 }
set main_project_id $project_id
if {"" eq $diagram_width} { set diagram_width 600 }
if {"" eq $diagram_height} { set diagram_height 400 }

# Create a random ID for the diagram
set diagram_id "project_eva_[expr round(rand() * 100000000.0)]"
set error_html ""

# Get some basic information about the project and skip the diagram if the project doesn't exist.
db_0or1row project_info "
	select	to_char(coalesce(main_p.start_date::date - 1, now()::date - 1), 'J') as main_project_start_julian,
		to_char(coalesce(main_p.end_date::date + 1, now()::date + 1), 'J') as main_project_end_julian,

		(select	to_char(min(start_date), 'J') from im_projects p
		where	p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) as sub_project_start_julian,
		(select	to_char(max(end_date), 'J') from im_projects p
		where	p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) as sub_project_end_julian,

		(select	to_char(min(day::date), 'J') from im_projects p, im_hours h
		where	p.project_id = h.project_id and p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) as hours_start_julian,
		(select	to_char(max(day::date), 'J') from im_projects p, im_hours h
		where	p.project_id = h.project_id and p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) as hours_end_julian

	from	im_projects main_p
	where	main_p.project_id = :main_project_id
"
set show_diagram_p [info exists main_project_start_julian]

# Determine step-width for the diagram:
# Steps shouldn't be too small, otherwise the diagram gets very slow.
# Steps shouldn't be too large, otherwise it will loose precision
set diagram_duration_days [expr $main_project_end_julian - $main_project_start_julian]
set step_uom "Ext.Date.MONTH"
set step_units 1
if {$diagram_duration_days > 3650} {
    # more than 10 years
    set step_uom "Ext.Date.YEAR"
    set step_units 1
}
if {$diagram_duration_days < 365} {
    set step_uom "Ext.Date.DAY"
    set step_units 7
}
if {$diagram_duration_days < 33} {
    set step_uom "Ext.Date.DAY"
    set step_units 1
}


if {$diagram_duration_days > 10000} { 
    set show_diagram_p 0 
    set error_html [lang::message::lookup "" intranet-earned-value-management.Project_duration_longer_than_10_years "Project duration is > 10 Years, skipping."]
}

# ad_return_complaint 1 "[expr [clock clicks -milliseconds] - $start_time]"


# -----------------------------------------------------
# Calculate start and end date for the diagram
#
set diagram_start_julian $main_project_start_julian
if {"" ne $hours_start_julian && $hours_start_julian < $diagram_start_julian} { set diagram_start_julian $hours_start_julian }
if {"" ne $sub_project_start_julian && $sub_project_start_julian < $diagram_start_julian} { set diagram_start_julian $sub_project_start_julian }

set diagram_end_julian $main_project_end_julian
if {"" ne $hours_start_julian && $hours_end_julian > $diagram_end_julian} { set diagram_end_julian $hours_end_julian }
if {"" ne $sub_project_start_julian && $sub_project_end_julian > $diagram_end_julian} { set diagram_end_julian $sub_project_end_julian }

# ad_return_complaint 1 "<pre>\nmain_project_start_julian=$main_project_start_julian\nsub_project_start_julian=$sub_project_start_julian\nhours_start_julian=$hours_start_julian\ndiagram_start_julian=$diagram_start_julian\n</pre>"

# Don't show diagram if too short
if {[expr abs($diagram_end_julian - $diagram_start_julian)] < 3} { set show_diagram_p 0 }

# Handle the case that the interval is too long
if {[expr abs($diagram_end_julian - $diagram_start_julian)] > 400} {
    set diagram_start_julian $sub_project_start_julian
}

if {[expr abs($diagram_end_julian - $diagram_start_julian)] > 400} {
    set diagram_end_julian $sub_project_end_julian
}


# ad_return_complaint 1 "$diagram_end_julian - $diagram_start_julian"

# -----------------------------------------------------
# Create a hash to convert between julian and ISO dates
#
set julian_sql "
    	select	im_day_enumerator as day_date,
		to_char(im_day_enumerator, 'J') as day_julian
	from	im_day_enumerator(to_date(:diagram_start_julian, 'J'), to_date(:diagram_end_julian, 'J')+1)
"
db_foreach julian $julian_sql {
    set julian_hash($day_julian) $day_date
    set julian_hash($day_date) $day_julian
}

# ad_return_complaint 1 "<pre>diagram_start_julian=$diagram_start_julian\n diagram_end_julian=$diagram_end_julian\n[array get julian_hash]"

# -----------------------------------------------------
# Get resource assignments and planned units per task
#
set planned_hours_sql "
		select	parent.project_id as parent_project_id,
			to_char(parent.start_date, 'J') as parent_start_julian,
			to_char(parent.end_date, 'J') as parent_end_julian,
			child.project_id,
			to_char(child.start_date, 'J') as child_start_julian,
			to_char(child.end_date, 'J') as child_end_julian,
			coalesce(t.planned_units,0) as child_planned_hours
		from	im_projects parent,
			im_projects child
			LEFT OUTER JOIN im_timesheet_tasks t ON (child.project_id = t.task_id)
		where	parent.project_id = :project_id and
			child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
			child.start_date is not null and
			child.end_date is not null
"
array set planned_hours_hash {}
set total_planned_hours 0.0
db_foreach planned_hours $planned_hours_sql {
    set total_planned_hours [expr $total_planned_hours + $child_planned_hours]
    set child_duration_days [expr $child_end_julian - $child_start_julian]
    if {$child_duration_days <= 1} { set child_duration_days 1 }; # Avoid divison by zero or negative...
    for {set j $child_start_julian} {$j <= $child_end_julian} {incr j} {
	set key "$j"
	
	set hours 0.0
	if {[info exists planned_hours_hash($key)]} { set hours $planned_hours_hash($key) }
	set hours [expr $hours + $child_planned_hours / $child_duration_days]
	set planned_hours_hash($key) $hours
    }
}

# -----------------------------------------------------
# Get logged hours
#
set logged_hours_sql "
		select	sum(h.hours) as hours,
			to_char(h.day::date, 'J') as day_julian
		from	im_hours h,
			im_projects p,
			im_projects main_p
		where	main_p.project_id = :main_project_id and
			h.project_id = p.project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		group by h.day::date
		order by h.day::date
"
array set logged_hours_hash {}
db_foreach hours $logged_hours_sql {
    set key "$day_julian"
    set logged_hours_hash($key) $hours
}

# --------------------------------------------------------------
# Determine audit values
# --------------------------------------------------------------

# Which attributes should be stored?
set attribute_list {percent_completed}

set audit_sql "
	select	to_char(a.audit_date, 'J') as audit_date_julian,
		a.audit_value		
	from	im_audits a
	where	a.audit_object_id = :main_project_id and
		a.audit_date >= to_date(:diagram_start_julian, 'J') and
		a.audit_date <= to_date(:diagram_end_julian, 'J')
	order by a.audit_date
"
db_foreach audit_loop $audit_sql {
    set fields [split $audit_value "\n"]
    foreach field $fields {
	set key_val [split $field "\t"]
	set attribute_name [lindex $key_val 0]
	set attribute_value [lrange $key_val 1 end]
	if {[lsearch $attribute_list $attribute_name] < 0} { continue }
	set key "$audit_date_julian"
	set cmd "set ${attribute_name}_hash($key) \$attribute_value"
	eval $cmd
    }
}

# ad_return_complaint 1 [array get completed_hours_hash]

# --------------------------------------------------------------
# Calculate the aggregated values
# --------------------------------------------------------------

set accumulated_planned_hours 0.0
set accumulated_logged_hours 0.0
set max_percent_completed 0.0
for {set i $diagram_start_julian} {$i < $diagram_end_julian} {incr i} {
    set key "$i"

    set val 0
    if {[info exists planned_hours_hash($key)]} { set val $planned_hours_hash($key) }
    set accumulated_planned_hours [expr $accumulated_planned_hours + $val]
    set accumulated_planned_hours_hash($key) $accumulated_planned_hours

    set val 0
    if {[info exists logged_hours_hash($key)]} { set val $logged_hours_hash($key) }
    set accumulated_logged_hours [expr $accumulated_logged_hours + $val]
    set accumulated_logged_hours_hash($key) $accumulated_logged_hours

    set percent_completed ""
    if {[info exists percent_completed_hash($key)]} { set percent_completed $percent_completed_hash($key) }
    if {"{}" eq $percent_completed} { set percent_completed "" }
    if {"" ne $percent_completed} { set max_percent_completed $percent_completed }
    set accumulated_completed_hours_hash($key) [expr $max_percent_completed * $total_planned_hours / 100.0]
    
}

if {$accumulated_planned_hours == 0.0} { 
    set error_html [lang::message::lookup "" intranet-earned-management.No_resources_assigned "You didn't assign any resource percentages to any user in any task in this project"]
    set show_diagram_p 0 
}

# ad_return_complaint 1 [array get accumulated_logged_hours_hash]


# --------------------------------------------------------------
# Build the JSON data for the diagram stores
# --------------------------------------------------------------

# Initialize attribute values
foreach att $attribute_list { set $att 0.0 }

set step_width [expr round(($diagram_end_julian - $diagram_start_julian) / 20)]
if {$step_width < 1} { set step_width 1 }

set data_lines [list]
for {set i $diagram_start_julian} {$i < $diagram_end_julian} {set i [expr $i + $step_width]} {
    set key "$i"
    set iso_date $julian_hash($i)
    set data_line "{date: new Date('$iso_date')"

    set v $accumulated_planned_hours_hash($key)
    append data_line ", 'planned_hours': $v"

    set v $accumulated_logged_hours_hash($key)
    append data_line ", 'logged_hours': $v"

    set v $accumulated_completed_hours_hash($key)
    append data_line ", 'completed_hours': $v"

    # Loop through all attributes and add attribute to the list of values
    if {0} {
    foreach att $attribute_list {
	if {[info exists ${att}_hash($key)]} { 
	    # Write the new value to the attribute named variable
	    set v [expr "\$${att}_hash($key)"]
	    # Skip if the new values is "" for some reasons.
	    # This way, the value from the last iteration will be used,
	    # which makes for a smooth curve.
	    if {"" != $v} { set $att $v }
	}
	set v [expr "\$${att}"]
	append data_line ", '$att': $v"
    }
    }

    append data_line "}"
    lappend data_lines $data_line
}

set data_json "\[\n"
append data_json [join $data_lines ",\n"]
append data_json "\n\]\n"

set fields_json "'date', 'planned_hours', 'logged_hours', 'completed_hours'"


# --------------------------------------------------------------
# Build some JS auxillary fields
# --------------------------------------------------------------

set attributes_js ""
foreach att $attribute_list { 
    append attributes_js ", '$att'"
}



# ad_return_complaint 1 "<pre>$fields_json<br><br>$data_json</pre>"
