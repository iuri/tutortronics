# /packages/intranet-agile/www/order-tasks.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new agile task to a project

    @param dir Is one of (up, down)

    @author frank.bergmann@project-open.com
} {
    agile_project_id:integer
    project_id:integer
    dir
    return_url
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"]

im_project_permissions $user_id $agile_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# -----------------------------------------------------
# Get the "sort_order" of the current task

set cur_task_ids [db_list cur_sort_order "
		select	rel_id
		from	acs_rels
		where	rel_type = 'im_agile_task_rel'
			and object_id_one = :agile_project_id
			and object_id_two = :project_id
"]
set cur_task_id [lindex $cur_task_ids 0]


set cur_sort_order [db_string cur_sort_order "
	select	sort_order
	from	im_agile_task_rels
	where	rel_id = :cur_task_id
" -default 0]


# ad_return_complaint 1 "<pre>cur_task_ids=$cur_task_ids \ncur_task_id=$cur_task_id \ncur_sort_order=$cur_sort_order\n</pre>"

# -----------------------------------------------------
# Move the task

switch $dir {
    up {
	# Get the "sort_order" of the task above
	set above_sort_order [db_string above_sort_order "
		select	coalesce(max(i.sort_order),0)
		from	im_agile_task_rels i,
			acs_rels r
		where	r.rel_id = i.rel_id
			and r.object_id_one = :agile_project_id
			and i.sort_order < :cur_sort_order
	" -default 0]

	if {0 != $above_sort_order} {

	    # There is an element above the current one: 
	    # Get the ID of the component above
	    set above_ids [db_list above_list "
		select	i.rel_id
		from	acs_rels r,
			im_agile_task_rels i
		where	i.sort_order = :above_sort_order
			and r.object_id_one = :agile_project_id
			and r.object_id_two = :project_id
	    "]
	    set above_task_id [lindex $above_ids 0]

	    # Exchange the sort orders of the user_map table
	    db_dml update "
			update	im_agile_task_rels
			set	sort_order = :above_sort_order 
			where	rel_id = :cur_task_id
	    "
	    db_dml update "
			update	im_agile_task_rels
			set	sort_order = :cur_sort_order 
			where	rel_id = :above_task_id
	    "
	}
    }

    down {
	# Get the "sort_order" of the task below
	set below_sort_order [db_string below_sort_order "
		select	coalesce(min(i.sort_order),0)
		from	im_agile_task_rels i,
			acs_rels r
		where	r.rel_id = i.rel_id
			and r.object_id_one = :agile_project_id
			and i.sort_order > :cur_sort_order
	" -default 0]

	if {0 != $below_sort_order} {

	    # There is an element below the current one: 
	    # Get the ID of the component below
	    set below_ids [db_list below_list "
		select	i.rel_id
		from	acs_rels r,
			im_agile_task_rels i
		where	i.sort_order = :below_sort_order
			and r.object_id_one = :agile_project_id
			and r.object_id_two = :project_id
	    "]
	    set below_task_id [lindex $below_ids 0]

	    # Exchange the sort orders of the user_map table
	    db_dml update "
			update	im_agile_task_rels
			set	sort_order = :below_sort_order 
			where	rel_id = :cur_task_id
	    "
	    db_dml update "
			update	im_agile_task_rels
			set	sort_order = :cur_sort_order 
			where	rel_id = :below_task_id
	    "
	}
    }
}

ad_returnredirect $return_url
