# /packages/intranet-agile/www/task-board-action.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Task Board Action
    Accepts "events" (clicking on an arrow) from the task-board
    and moves the tasks accordingly.
} {
    project_id:integer
    task_id:integer
    action
    return_url
}

# ------------------------------------------------------------
# Defaults & Permissions
# ------------------------------------------------------------

set user_id [auth::require_login]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}


# ------------------------------------------------------------
# Determine what agile state set to display

set project_type_id [db_string ptype_id "select project_type_id from im_projects where project_id = :project_id" -default 0]
set agile_category_type [db_string category_type_id "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
if {"" eq $agile_category_type} { 
    ad_return_complaint 1 "Could not determine default agile state range for project_type=[im_category_from_id $project_type_id]"
}



# ------------------------------------------------------------
# Get the list of agile states

set tasks_sql "
	select	task.project_id as task_id,
		task.project_name,
		ri.*,
		im_category_from_id(ri.agile_status_id) as agile_status
	from	im_projects relp,
		im_projects task,
		acs_rels r,
		im_agile_task_rels ri
	where	relp.project_id = :project_id and
		r.object_id_one = relp.project_id and
		r.object_id_two = task.project_id and
		r.rel_id = ri.rel_id
	order by ri.sort_order
"

set top_states_sql "
	select	category_id,
		category
	from	im_categories c
	where	((c.enabled_p = 't' OR c.enabled_p is NULL) and category_type = :agile_category_type) 
		OR c.category_id in (
			select agile_status_id from ($tasks_sql) t	 
		)
	order by sort_order, category_id
"

set top_states_list [list]
db_foreach top_states $top_states_sql {
    lappend top_states_list $category_id
}


# ------------------------------------------------------------
# Get information about the affected agile task

set rel_task_info_sql "
	select	ri.*,
		ri.rel_id as task_id,
		im_category_from_id(ri.agile_status_id) as agile_status
	from	im_projects relp,
		im_projects task,
		acs_rels r,
		im_agile_task_rels ri
	where	relp.project_id = :project_id and
		task.project_id = :task_id and
		r.object_id_one = relp.project_id and
		r.object_id_two = task.project_id and
		r.rel_id = ri.rel_id
"
set exists_p [db_0or1row rel_task_info $rel_task_info_sql]

if {!$exists_p} {
    # The project doesn't exist
    ad_return_complaint 1 [lang::message::lookup "" intranet-agile.project_does_not_exist "
	<br>
	<b>The specified task #$task_id does not exist in project #$project_id</b>:<br>
	The task or the project may have been deleted.
	<br>&nbsp;<br>
    "]
} 



# ------------------------------------------------------------
# Update the task according to action

# determine the position of the current status_id in the
# list of agile states
set rel_state_pos [lsearch $top_states_list $agile_status_id]

switch $action {
    left {
	set rel_state_pos [expr {$rel_state_pos - 1}]
    }
    right {
	set rel_state_pos [expr {$rel_state_pos + 1}]
    }
    up {
	# Search for the tasks with the next lower sort_order
	set prev_task_id ""
	set prev_sort_order ""
	db_0or1row prev_sql "
		select	ri.rel_id as prev_task_id,
			ri.sort_order as prev_sort_order
		from	im_projects relp,
			im_projects task,
			acs_rels r,
			im_agile_task_rels ri
		where	relp.project_id = :project_id and
			r.object_id_one = relp.project_id and
			r.object_id_two = task.project_id and
			r.rel_id = ri.rel_id and
			ri.sort_order < :sort_order and
			ri.agile_status_id = :agile_status_id
		order by ri.sort_order DESC
		LIMIT 1
	"
	if {"" != $prev_task_id} {
	    # Exchange the sort_order with the previous task
	    db_dml update_prev "
		update im_agile_task_rels
		set sort_order = :sort_order
		where rel_id = :prev_task_id
	    "
	    db_dml update_prev "
		update im_agile_task_rels
		set sort_order = :prev_sort_order
		where rel_id = :task_id
	    "
	}
    }
    down {
	# Search for the tasks with the next higher sort_order
	set prev_task_id ""
	set prev_sort_order ""

	db_0or1row prev_sql "
		select	ri.rel_id as prev_task_id,
			ri.sort_order as prev_sort_order
		from	im_projects relp,
			im_projects task,
			acs_rels r,
			im_agile_task_rels ri
		where	relp.project_id = :project_id and
			r.object_id_one = relp.project_id and
			r.object_id_two = task.project_id and
			r.rel_id = ri.rel_id and
			ri.sort_order > :sort_order and
			ri.agile_status_id = :agile_status_id
		order by ri.sort_order
		LIMIT 1
	"
	if {"" != $prev_task_id} {
	    # Exchange the sort_order with the previous task
	    db_dml update_prev "
		update im_agile_task_rels
		set sort_order = :sort_order
		where rel_id = :prev_task_id
	    "
	    db_dml update_prev "
		update im_agile_task_rels
		set sort_order = :prev_sort_order
		where rel_id = :task_id
	    "
	}
    }
}

if {$rel_state_pos < 0} { set rel_state_pos 0 }
if {$rel_state_pos > [llength $top_states_list]} { set rel_state_pos [llength $top_states_list] }
set new_status_id [lindex $top_states_list $rel_state_pos]
set new_status [im_category_from_id $new_status_id]

db_dml update_task "
	update im_agile_task_rels
	set agile_status_id = :new_status_id
	where rel_id = :task_id
"

ad_returnredirect $return_url
