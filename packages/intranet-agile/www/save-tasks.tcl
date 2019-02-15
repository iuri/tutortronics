# /packages/intranet-agile/www/save-tasks.tcl
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
    agile_status_id:integer,array
    agile_sort_order:array
    return_url
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"]

im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

foreach task_id [array names agile_status_id] {

    if {[info exists agile_sort_order($task_id)]} {
	set sort_order $agile_sort_order($task_id)
	db_dml update_sort_order "
		update	im_agile_task_rels set
			sort_order = :sort_order
		where rel_id in (
			select	r.rel_id
			from	acs_rels r,
				im_agile_task_rels i
			where	r.rel_id = i.rel_id
				and r.object_id_one = :project_id
				and r.object_id_two = :task_id
		)
	"
    }

    set status_id $agile_status_id($task_id)

    set old_status_id [db_string old_status_id "
	select	agile_status_id
	from	acs_rels r,
		im_agile_task_rels i
	where	r.rel_id = i.rel_id
		and r.object_id_one = :project_id
		and r.object_id_two = :task_id
    " -default ""]

    if {$old_status_id != $status_id} {

	    db_dml update_task "
		update im_agile_task_rels
		set agile_status_id = :status_id
		where rel_id in (
				select	rel_id
				from	acs_rels
				where	object_id_one = :project_id
					and object_id_two = :task_id
			)
	    "
 
	    set status [db_string status "select im_category_from_id(:status_id)"]
	    set old_status [db_string status "select im_category_from_id(:old_status_id)"]
	    set task_nr [db_string task_name "select project_nr from im_projects where project_id = :task_id" -default "unknown"]
    }
}

ad_returnredirect $return_url
