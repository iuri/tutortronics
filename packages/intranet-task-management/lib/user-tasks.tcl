# /packages/intranet-task-management/www/index.tcl
#
# Copyright (C) 1998-2008 ]project-open[

# Expects the following parameters:
#
# project_id
# diagram_width
# min_diagram_height
#
# Permissions are already checked by the portlet procedure

set current_user_id [auth::require_login]
set user_name [im_name_from_user_id $current_user_id]
set page_title [lang::message::lookup "" intranet-task-management.Tasks_for_user_name "Tasks for %user_name%"]
set context_bar [im_context_bar [list /intranet/projects/ $page_title $page_title]]


# Create a random ID for the diagram
set diagram_rand [expr {round(rand() * 100000000.0)}]
set diagram_id "user_tasks_$diagram_rand"
set diagram_title $page_title

# Get all information about gantt tasks, agile tasks, tickets and projects assigned to the current user
set task_sql "
	select	main.project_id as main_project_id,
		main.project_name as main_project_name,
		o.object_type,
		child.project_id,
		child.project_name,
		child.start_date,
		child.end_date,
		child.tree_sortkey,
		child.percent_completed,
		ticket.ticket_alarm_date, 
		ticket.ticket_customer_deadline,
		coalesce(ticket.ticket_type_id, child.project_type_id) as type_id,
		coalesce(ticket.ticket_status_id, child.project_status_id) as status_id,
		im_category_from_id(coalesce(ticket.ticket_type_id, child.project_type_id)) as type,
		im_category_from_id(coalesce(ticket.ticket_status_id, child.project_status_id)) as status,
		task.uom_id,
		task.planned_units
	from	im_projects main,
		acs_objects o,
		im_projects child
		LEFT OUTER JOIN im_timesheet_tasks task ON (child.project_id = task.task_id)
		LEFT OUTER JOIN im_tickets ticket ON (child.project_id = ticket.ticket_id)
	where	main.parent_id is null and
		main.project_status_id in (select * from im_sub_categories(76)) and		-- open
		main.project_type_id not in (102) and	 					-- CRM Opportunity
		-- fraber 170615 - Re-enablding sub-projects for legacy installers (SG)
		-- o.object_type not in ('im_project') and						-- skip sub-projects
		not exists (  	     		    						-- skip projs or tasks with children
			select	sub.project_id
			from	im_projects sub
			where	sub.parent_id = child.project_id
		) and
		child.project_type_id not in (102) and	 					-- CRM Opportunity
		child.parent_id is not null and
		child.project_type_id not in ([im_project_type_opportunity],[im_project_type_campaign], [im_project_type_program]) and
		main.tree_sortkey = tree_root_key(child.tree_sortkey) and
		child.project_id = o.object_id and
		(	-- project manager of the project
			child.project_lead_id = $current_user_id
		OR
			-- project/task/ticket directly assigned to user
			child.project_id in (
				select	r.object_id_one
 				from	acs_rels r
				where	r.object_id_two = $current_user_id
			)
		OR	-- assigned to a group to which user belongs
			child.project_id in (
				select	r.object_id_one
				from	acs_rels r,
					groups g
				where	r.object_id_two = g.group_id and
					g.group_id in (select group_id from group_distinct_member_map where member_id = $current_user_id)
			)
		OR	ticket.ticket_assignee_id = $current_user_id
		OR	(	-- Ticket in queue, but not yet assigned to somebody particularly
			ticket.ticket_queue_id in (select group_id from group_distinct_member_map where member_id = $current_user_id) and
			ticket.ticket_assignee_id is null)
		)
"

# --------------------------------------------
# Determine the size of the portlet
#
set size_sql "
	select
		main_project_id,
		object_type,
		type_id,
		count(*) as cnt
	from	($task_sql) t
	group by
		main_project_id,
		object_type,
		type_id
	order by
		main_project_id,
		object_type,
		type_id
"
set object_type_cnt 0
set max_tasks 0
set main_project_cnt 0
set old_main_project_id ""
db_foreach size $size_sql {
    if {$cnt > $max_tasks} { set max_tasks $cnt }
    if {$main_project_id != $old_main_project_id} {
	set old_main_project_id $main_project_id
	incr main_project_cnt
    }
    incr object_type_cnt
}

set name_height [im_task_management_major_height]
set name_offset [im_task_management_major_offset]
set type_height [im_task_management_minor_height]
set type_offset [im_task_management_minor_offset]
set legend_width [im_task_management_legend_width]
set task_type_text_width [im_task_management_task_type_text_width]

# ad_return_complaint 1 "set diagram_height \[expr int($name_height * (1+$main_project_cnt) + $type_height * (1+$object_type_cnt))\]"


set diagram_height [expr int($name_height * (1+$main_project_cnt) + $type_height * (1+$object_type_cnt))]
if {$diagram_height < $min_diagram_height} { set diagram_height $min_diagram_height }
if {$max_tasks < 1} { set max_tasks 1 }


set store_json [im_sencha_sql_to_store -sql "
	select	
		im_task_management_color_code(project_id) as color_code,
		type_id,
		im_category_from_id(type_id) as type,
		main_project_id,
		main_project_name,
		project_id,
		project_name,
		start_date,
		end_date,
		percent_completed
from	($task_sql) t
	order by
		main_project_id,
		type_id,
		color_code,
		tree_sortkey
"]

