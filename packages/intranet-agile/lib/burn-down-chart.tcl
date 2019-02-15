# /packages/intranet-agile/lib/burn-down-chart.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
if {![info exists diagram_width] || "" eq $diagram_width } { set diagram_width 600 }
if {![info exists diagram_height] || "" eq $diagram_height } { set diagram_height 400 }
if {![info exists diagram_title]} { set diagram_title [lang::message::lookup "" intranet-agile.Burn_Down_Chart "Burn Down Chart"] }


# ----------------------------------------------------
# Diagram Setup
# ----------------------------------------------------

# Create a random ID for the diagram
set diagram_rand [expr {round(rand() * 100000000.0)}]
set diagram_id "employee_assignment_pie_chart_$diagram_rand"
set chart_p 0

set project_info_sql "
	select	p.project_id as main_project_id,
		p.start_date::date as main_start_date,
		to_char(p.start_date, 'J') as main_start_julian,
		(greatest(p.end_date, p.start_date + '10 days'::interval))::date as main_end_date,
		to_char(greatest(p.end_date, p.start_date + '10 days'::interval), 'J') as main_end_julian,
		p.tree_sortkey as main_tree_sortkey,
		tree_right(p.tree_sortkey) as main_tree_sortkey_right,
		to_char(now(), 'J') as now_julian,
		'1' as chart_p
	from	im_projects p
	where	p.project_id = :project_id
"
set rows [db_1row project_info $project_info_sql]


# ad_return_complaint 1 "$start_date - $end_date"


# ----------------------------------------------------
# Store Data
# ----------------------------------------------------

set related_tasks_sql "
	select	p.project_id
	from	im_projects p
	where	(p.tree_sortkey between :main_tree_sortkey and :main_tree_sortkey_right OR
		p.project_id in (
			select	r.object_id_two
			from	acs_rels r,
				im_agile_task_rels ri
			where	r.rel_id = ri.rel_id and
				r.object_id_one = :main_project_id
		))
	order by p.project_id
"
set related_task_ids [db_list rel_tasks $related_tasks_sql]


# Calculate the task_hours per task
set task_effort_sql "
	select	p.project_id,
		ta.planned_units,
		ti.ticket_quoted_days
	from	im_projects p
		LEFT OUTER JOIN im_timesheet_tasks ta ON (p.project_id = ta.task_id)	    
		LEFT OUTER JOIN im_tickets ti ON (p.project_id = ti.ticket_id)	    
	where	p.project_id in ($related_tasks_sql)
"
db_foreach task_effort $task_effort_sql {
    set task_hours($project_id) 0
    if {"" ne $planned_units} { set task_hours($project_id) $planned_units }
    if {"" ne $ticket_quoted_days} { set task_hours($project_id) [expr $ticket_quoted_days * 8.0] }
}
# ad_return_complaint 1 "task_hours: [array get task_hours]"


# Calculate percent_completed per task and julian
set audit_sql "
	select	a.audit_object_id,
		a.audit_date,
		to_char(a.audit_date, 'J') as audit_julian,
		a.audit_diff,
		a.audit_object_status_id
	from	im_audits a      
	where	a.audit_object_id in ($related_tasks_sql)
		-- and a.audit_date between :main_start_date and :main_end_date
	order by a.audit_object_id, a.audit_date
"
set last_audit_julian $main_start_julian
db_foreach audit $audit_sql {
#    if {$audit_julian < $main_start_julian} { set main_start_julian $audit_julian }
#    if {$audit_julian > $main_end_julian} { set main_end_julian $audit_julian }
    set key "$audit_object_id-$audit_julian"
    foreach field [split [string map {\" ''} $audit_diff] "\n"] {
	set name [lindex $field 0]
	set value [lrange $field 1 end]
	switch $name {
	    "percent_completed" { 
		if {[im_category_is_a $audit_object_status_id [im_project_status_closed]]} { set value 100.0 }
		if {[im_category_is_a $audit_object_status_id [im_ticket_status_closed]]} { set value 100.0 }
		if {0 != $value} { set task_completed($key) $value }
		
		# Determine the last audit record changing "percent_completed"
		if {$audit_julian > $last_audit_julian} { set last_audit_julian $audit_julian }
	    }
	}
    }
}
# ad_return_complaint 1 "task_completed: [array get task_completed]"


# Initialize percent_completed at the start and end of the period. Use 0.1 to avoid division by zero
set all_hours 0.0001
foreach tid $related_task_ids {
    set key "$tid-$main_start_julian"
    set task_completed($key) 0.0

    # Calculate the sum of all hours to be done in the project
    if {[info exists task_hours($tid)]} {
	set all_hours [expr $all_hours + $task_hours($tid)]
    }
}


# Fill the "holes" in the task-completed hash
foreach tid $related_task_ids {
    set percent_completed 0
    for {set j $main_start_julian} {$j <= $main_end_julian} {incr j} {
	set key "$tid-$j"
	if {[info exists task_completed($key)]} { set percent_completed $task_completed($key) }
	set task_completed($key) $percent_completed
    }
}

# Sum up the percent_completed by day
multirow create burn_down day planned done
set shrink [expr round(($main_end_julian - $main_start_julian) / 500)]
set shrink 0
set ctr 0
for {set j $main_start_julian} {$j <= $main_end_julian} {incr j} {

    incr ctr
    if {$ctr > $shrink} {

	set hours_completed 0
	foreach tid $related_task_ids {
	    set key "$tid-$j"
	    set hours_completed [expr $hours_completed + ($task_hours($tid) * $task_completed($key) / 100.0)]

	    ns_log Notice "xxx: j=$j, tid=$tid, hours_completed=$hours_completed, task_hours=$task_hours($tid), task_completed=$task_completed($key), all_hours=$all_hours"

	}
	
	set planned [expr round(1000.0 * ($main_end_julian - $j) / ($main_end_julian - $main_start_julian)) / 10.0]
	set done [expr round(1000.0 - 1000.0 * $hours_completed / $all_hours) / 10.0]

	if {$j > $last_audit_julian} { set done "" }

	multirow append burn_down [expr $j - $main_start_julian] $planned $done
	set ctr 0
    }
}

# Where to draw a line for "today"?
set now_days [expr $now_julian - $main_start_julian]

