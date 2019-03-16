# /packages/intranet-agile/www/task-board.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

# Expected variables:
# project_id

set show_master_p 0
if {![info exists project_id]} {
    set show_master_p 1
    ad_page_contract {
	Show agile tasks with their status
	@author Frank Bergmann (frank.bergmann@project-open.com)
	@creation-date May 29, 2002
	@cvs-id $Id: task-board.tcl,v 1.5 2016/05/30 09:56:00 cvs Exp $
    } {
	project_id:integer
    }
}

# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------

set user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
im_project_permissions $user_id $project_id view read write admin
if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# ------------------------------------------------------------
# Page Title & Help Text

set page_title [lang::message::lookup "" intranet-agile.Task_Board "Task Board"]
set return_url [im_url_with_query]
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------------
# Defaults

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-agile/task-board" {project_id} ]
set task_board_action_url "/intranet-agile/task-board-action"


# ------------------------------------------------------------
# Determine what agile state set to display

set project_type_id [db_string ptype_id "select project_type_id from im_projects where project_id = :project_id" -default 0]
set agile_category_type [db_string category_type_id "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
if {"" eq $agile_category_type} { 
    ad_return_complaint 1 "Could not determine default agile state range for project_type=[im_category_from_id $project_type_id]"
}


# ------------------------------------------------------------
# Define the tasks to be displayed

set tasks_sql "
	select	task.project_id as task_id,
		task.project_name,
		task.project_type_id,
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

# ------------------------------------------------------------
# Get Top Dimension (Agile Status)

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
set top_html ""
set top_states_list [list]
db_foreach top_states $top_states_sql {
    append top_html "<td class=rowtitle>$category</td>\n"
    lappend top_states_list $category_id
}

# ------------------------------------------------------------
# Calculate the tasks to be displayed

set task_count 0
db_foreach tasks $tasks_sql {
    set cell ""
    if {[info exists cell_hash($agile_status_id)]} { set cell $cell_hash($agile_status_id) }

    switch $project_type_id {
	100 { set project_link "<a href='[export_vars -base "/intranet-timesheet2-tasks/new" {task_id}]'>$project_name</a>" }
	101 { set project_link "<a href='[export_vars -base "/intranet-helpdesk/new" {{ticket_id $task_id} {form_mode display}}]'>$project_name</a>" }
	default { set project_link "<a href='[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]'>$project_name</a>" }
    }

    set color "grey"
    set left_url [export_vars -base $task_board_action_url {task_id return_url {action left} project_id}]
    set right_url [export_vars -base $task_board_action_url {task_id return_url {action right} project_id}]
    set up_url [export_vars -base $task_board_action_url {task_id return_url {action up} project_id}]
    set down_url [export_vars -base $task_board_action_url {task_id return_url {action down} project_id}]
    append cell "
	<table width=150 cellspacing=0 bgcolor=$color>
	<tr><td colspan=3 align=center><a href='$up_url'>[im_gif arrow_up]</a></td></tr>
	<tr>
	<td><a href='$left_url'>[im_gif arrow_left]</a></td>
	<td align=center>$project_link</a></td>
	<td><a href='$right_url'>[im_gif arrow_right]</a></td>
	</tr>
	<tr><td colspan=3 align=center><a href='$down_url'>[im_gif arrow_down]</a></td></tr>
	</table>
	<br>
    "
    set cell_hash($agile_status_id) $cell
    incr task_count
}

# ------------------------------------------------------------
# Render the table body

set body_html ""
foreach agile_status_id $top_states_list {
    set cell ""
    if {[info exists cell_hash($agile_status_id)]} { set cell $cell_hash($agile_status_id) }
    append body_html "<td>$cell</td>"
}

# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set show_context_help_p 0
set parent_menu_id [im_menu_id_from_label "project"]
set menu_label "agile_tasks"
set sub_navbar_html [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 

