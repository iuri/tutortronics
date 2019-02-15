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
set project_name [acs_object_name $project_id]
set page_title [lang::message::lookup "" intranet-task-management.Tasks_in_project_name "Tasks in %project_name%"]
set context_bar [im_context_bar [list /intranet/projects/ $page_title $page_title]]
set main_project_id $project_id

# Create a random ID for the diagram
set diagram_rand [expr {round(rand() * 100000000.0)}]
set diagram_id "project_tasks_$diagram_rand"
set diagram_title $page_title

# Get all information about gantt tasks, agile tasks, tickets and projects assigned to the current user
set base_sql "
	select	u.user_id,
		child.project_id,
		child.project_name,
		child.start_date,
		child.end_date,
		child.tree_sortkey,
		round(10.0 * child.percent_completed) / 10.0 as percent_completed,
		ticket.ticket_alarm_date, 
		ticket.ticket_customer_deadline,
		coalesce(ticket.ticket_type_id, child.project_type_id) as type_id,
		coalesce(ticket.ticket_status_id, child.project_status_id) as status_id,
		task.uom_id,
		task.planned_units
	from	users u,
		acs_objects o,
		im_projects main,
		im_projects child
		LEFT OUTER JOIN im_timesheet_tasks task ON (child.project_id = task.task_id)
		LEFT OUTER JOIN im_tickets ticket ON (child.project_id = ticket.ticket_id)
		LEFT OUTER JOIN acs_rels r ON (child.project_id = r.object_id_one)
		LEFT OUTER JOIN group_distinct_member_map gdmm ON (gdmm.group_id = r.object_id_two)
	where	main.project_id = $main_project_id and
		child.project_id = o.object_id and
		child.parent_id is not null and
		child.project_type_id not in (
			[im_project_type_opportunity],
			[im_project_type_campaign], 
			[im_project_type_program]
		) and
		not exists (  	      						-- skip projs or tasks with children
			select	sub.project_id
			from	im_projects sub
			where	sub.parent_id = child.project_id
		) and
		main.tree_sortkey = tree_root_key(child.tree_sortkey) and
		-- Do not show skill profiles (users representing a group of users with specific skills)
		u.user_id not in (select member_id from group_distinct_member_map where group_id = [im_profile_skill_profile]) and
		u.user_id = coalesce(gdmm.member_id, r.object_id_two, 0)
"

# ad_return_complaint 1 [im_ad_hoc_query -format html $base_sql]

# --------------------------------------------
# Determine the size of the portlet
#
set size_sql "
	select
		user_id,
		type_id,
		count(*) as cnt
	from	($base_sql) t
	group by
		user_id,
		type_id
	order by
		user_id,
		type_id
"
set object_type_cnt 0
set max_tasks 0
set user_cnt 0
set old_user_id ""
db_foreach size $size_sql {
    if {$cnt > $max_tasks} { set max_tasks $cnt }
    if {$user_id != $old_user_id} {
	set old_user_id $user_id
	incr user_cnt
    }
    incr object_type_cnt
}

# ad_return_complaint 1 $user_cnt

set name_height [im_task_management_major_height]
set name_offset [im_task_management_major_offset]
set type_height [im_task_management_minor_height]
set type_offset [im_task_management_minor_offset]
set legend_width [im_task_management_legend_width]
set task_type_text_width [im_task_management_task_type_text_width]


set diagram_height [expr int($name_height * (1+$user_cnt) + $type_height * (1+$object_type_cnt))]
if {$diagram_height < $min_diagram_height} { set diagram_height $min_diagram_height }
if {$max_tasks < 1} { set max_tasks 1 }


set store_json [im_sencha_sql_to_store -sql "
	select	im_task_management_color_code(project_id) as color_code,
		type_id,
		im_category_from_id(type_id) as type,
		user_id,
		CASE WHEN user_id = 0 THEN 999999999 ELSE user_id END as user_id_sort,		-- sort with user 0 (unassigned) last
		im_name_from_user_id(user_id) as user_name,
		CASE WHEN user_id in (
			select	m.member_id
			from	group_member_map m,
				membership_rels mr
			where	m.rel_id = mr.rel_id and
				m.group_id = acs__magic_object_id('registered_users') and
				m.container_id = m.group_id and
				mr.member_state != 'approved'
		) THEN 1 ELSE 0 END as deleted_p,
		project_id,
		project_name,
		start_date,
		end_date,
		percent_completed
	from	($base_sql) t
	order by
		user_id_sort,
		type_id,
		color_code,
		tree_sortkey
"]

