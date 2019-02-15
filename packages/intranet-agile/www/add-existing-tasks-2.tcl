# /packages/intranet-agile/www/add-tasks.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new agile task to a project

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    task_id:integer,multiple
    return_url
    { agile_status_id "" }
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"]

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Agile Manager) can do everything.
# The managers of the individual Agile Tasks can change 
# _their_ agile stati.

im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}


# -------------------------------------------------------------
# What is the default initial agile state?
#
if {"" eq $agile_status_id} {
    set project_type_id [db_string ptype_id "select project_type_id from im_projects where project_id = :project_id" -default 0]
    set category_type [db_string category_type_id "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
    set agile_status_id [db_string def "select category_id from im_categories where category_type = :category_type order by sort_order limit 1" -default ""]
}

if {"" eq $agile_status_id} { 
    ad_return_complaint 1 "Could not determine default agile state.<br>
	<b>Details:</b><br>
	Project #: $project_id<br>
	Project Type: [im_category_from_id $project_type_id]<br>
	Agile Category Type: '$category_type'"
}


# Loop through all selected tasks (tickets and Gantt tasks)
# and add the task to the project as an agile task
foreach pid $task_id {

    set exists_p [db_string count "
	select	count(*)
	from	im_agile_task_rels i,
		acs_rels r
	where	i.rel_id = r.rel_id
		and r.object_id_one = :project_id
		and r.object_id_two = :pid
    "]

    if {!$exists_p} {

	    set max_sort_order [db_string max_sort_order "
	        select  coalesce(max(i.sort_order),0)
	        from    im_agile_task_rels i,
	                acs_rels r
	        where   i.rel_id = r.rel_id and
	                r.object_id_one = :project_id
	    " -default 0]

	    db_string add_user "
		select im_agile_task_rel__new (
			null,
			'im_agile_task_rel',
			:project_id,
			:pid,
			null,
			:user_id,
			'[ad_conn peeraddr]',
			:agile_status_id,
                        [expr {$max_sort_order + 10}]
		)
	    "
    }
}

ad_returnredirect $return_url
