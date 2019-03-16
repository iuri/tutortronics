# /packages/intranet-earned-value-management/tcl/intranet-earned-value-management-fake-audit-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Project EVA Diagram
# ---------------------------------------------------------------------

ad_proc im_audit_fake_history {
} {
    Create project audit entries for all projects.
    Should be run every hour or two on demo servers.
} {
   set project_ids [db_list pids "select project_id from im_projects where parent_id is null"]
   foreach pid $project_ids {
	im_audit_fake_history_for_project -project_id $pid
   }   
}

ad_proc im_audit_fake_history_for_project {
    -project_id
    {-steps 50}
} {
    Creates im_projects_audit entries for the project
    by splitting the time between start_date and end_date
    in $intervals pieces and calculates new im_projects_audit
    entries for the dates based on the information of
    timesheet hours and financial documents
} {
    set default_currency [im_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set default_hourly_rate [im_parameter -package_id [im_package_cost_id] "DefaultTimesheetHourlyCost" "" "30.0"]
    set target_margin_percentage [im_parameter -package_id [im_package_cost_id] "TargetMarginPercentage" "" "30.0"]

    # Extract max values from the project
    db_1row start_end "
	select
		max(trunc(project_budget::numeric, 2)) as project_budget_max,
		-- The cost side - thee different types - ts, bills and expenses
		max(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_max,
		max(cost_bills_cache) as cost_bills_cache_max,
		max(cost_expense_logged_cache) as cost_expense_logged_cache_max,
		-- The income side - quotes and invoices
		max(cost_invoices_cache) as cost_invoices_cache_max,
		max(cost_quotes_cache) as cost_quotes_cache_max,
		-- Delivered value
		max(cost_delivery_notes_cache) as cost_delivery_notes_cache_max
        from    im_projects_audit
        where   project_id = :project_id
    "

    if {"" == $project_budget_max} { set project_budget_max 0 }
    if {"" == $cost_timesheet_logged_cache_max} { set cost_timesheet_logged_cache_max 0 }
    if {"" == $cost_bills_cache_max} { set cost_bills_cache_max 0 }
    if {"" == $cost_expense_logged_cache_max} { set cost_expense_logged_cache_max 0 }
    if {"" == $cost_invoices_cache_max} { set cost_invoices_cache_max 0 }
    if {"" == $cost_quotes_cache_max} { set cost_quotes_cache_max 0 }
    if {"" == $cost_delivery_notes_cache_max} { set cost_delivery_notes_cache_max 0 }

    set cost_max [expr $cost_timesheet_logged_cache_max + $cost_bills_cache_max + $cost_expense_logged_cache_max]
    set widget_max $cost_max
    if {$project_budget_max > $widget_max} { set widget_max $project_budget_max}
    if {100.0 > $widget_max} { set widget_max 100.0}

    # Get start- and end date in Julian format (as integer)
    db_1row start_end "
        select	p.*,
		to_char(coalesce(start_date, now()), 'J') as start_date_julian,
		to_char(coalesce(end_date, now()), 'J') as end_date_julian,
		to_char(now(), 'J') as now_julian,
		to_char(end_date, 'J')::integer - to_char(start_date, 'J')::integer as duration_days
        from	im_projects p
        where	project_id = :project_id
    "
    
    set cost_start_date_julian [db_string cost_start_date "
	select	to_char(min(c.effective_date), 'J')
	from	im_costs c
	where	c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
		)
    "]


    if {"" != $cost_start_date_julian && $cost_start_date_julian < $start_date_julian} { 
	set start_date_julian $cost_start_date_julian 
    }
    set modifying_action "update"
    if {$now_julian < $end_date_julian} { set end_date_julian $now_julian }
    if {$now_julian < $start_date_julian } { set start_date_julian [expr $now_julian - 10] }
    set duration_days [expr $end_date_julian - $start_date_julian]
    set increment [expr round($duration_days / $steps)]

    # Let's increase the %done value every 3-5th step
    # by a random amount, so that it reaches more or less
    # total_cost / budget
    set percent_completed_final [expr 100.0 * $cost_max / $widget_max]
    set percent_completed 0.0
    ns_log Notice "im_audit_fake_history_for_project: percent_completed_final=$percent_completed_final"

    # Delete the entire history
    db_dml del_audit "delete from im_projects_audit where project_id = :project_id"

    # Loop for every day and calculate the sum of all cost types
    # per cost type
    for { set i $start_date_julian} {$i < $end_date_julian} { set i [expr $i + 1 + $increment] } {

	# Don't go further then today + 30 days
	if {$i > $now_julian + 90} { return }

	# Increase the percent_completed every 5th step
	# by a random percentage
	if {[expr rand()] < 0.2} {
	    set now_done [expr ($percent_completed_final - $percent_completed) * 5.0 / ($steps * 0.2) * rand()]
	    set now_done [expr ($now_done + abs($now_done)) / 2.0]
	    set percent_completed [expr $percent_completed + $now_done]
	    ns_log Notice "im_audit_fake_history_for_project: percent_completed=$percent_completed"
	}

	set cost_timesheet_planned_cache 0.0
	set cost_expense_logged_cache 0.0
	set cost_expense_planned_cache 0.0
	set cost_quotes_cache 0.0
	set cost_bills_cache 0.0
	set cost_purchase_orders_cache 0.0
	set cost_delivery_notes_cache 0.0
	set cost_invoices_cache 0.0
	set cost_timesheet_logged_cache 0.0

	set cost_sql "
		select	sum(c.amount) as amount,
			c.cost_type_id
		from	im_costs c
		where	c.effective_date < to_date(:i, 'J') and
			c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
		group by
			cost_type_id
	"
	db_foreach costs $cost_sql {
	    switch $cost_type_id {
		 3726 { set cost_timesheet_planned_cache $amount }
		 3722 { set cost_expense_logged_cache $amount }
		 3728 { set cost_expense_planned_cache $amount }
		 3702 { set cost_quotes_cache $amount }
		 3704 { set cost_bills_cache $amount }
		 3706 { set cost_purchase_orders_cache $amount }
		 3724 { set cost_delivery_notes_cache $amount }
		 3700 { set cost_invoices_cache $amount }
		 3718 { set cost_timesheet_logged_cache $amount }
	    }
	}
	set ts_sql "
		select	sum(h.hours) as hours
		from	im_hours h
		where	h.day < to_date(:i, 'J') and
			h.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
	"
	set reported_hours_cache [db_string hours $ts_sql]

	db_dml insert "
		insert into im_projects_audit (
			modifying_action,
			last_modified,
			last_modifying_user,
			last_modifying_ip,
			project_id,
			project_name,
			project_nr,
			project_path,
			parent_id,
			company_id,
			project_type_id,
			project_status_id,
			description,
			billing_type_id,
			note,
			project_lead_id,
			supervisor_id,
			project_budget,
			corporate_sponsor,
			percent_completed,
			on_track_status_id,
			project_budget_hours,
			end_date,
			start_date,
			company_contact_id,
			cost_invoices_cache,
			cost_quotes_cache,
			cost_delivery_notes_cache,
			cost_bills_cache,
			cost_purchase_orders_cache,
			cost_timesheet_planned_cache,
			cost_timesheet_logged_cache,
			cost_expense_planned_cache,
			cost_expense_logged_cache,
			reported_hours_cache
		) values (
			:modifying_action,
			to_date(:i,'J'),
			'[ad_conn user_id]',
			'[ns_conn peeraddr]',
			:project_id,
			:project_name,
			:project_nr,
			:project_path,
			:parent_id,
			:company_id,
			:project_type_id,
			:project_status_id,
			:description,
			:billing_type_id,
			:note,
			:project_lead_id,
			:supervisor_id,
			:project_budget,
			:corporate_sponsor,
			:percent_completed,
			:on_track_status_id,
			:project_budget_hours,
			:end_date,
			:start_date,
			:company_contact_id,
			:cost_invoices_cache,
			:cost_quotes_cache,
			:cost_delivery_notes_cache,
			:cost_bills_cache,
			:cost_purchase_orders_cache,
			:cost_timesheet_planned_cache,
			:cost_timesheet_logged_cache,
			:cost_expense_planned_cache,
			:cost_expense_logged_cache,
			:reported_hours_cache
		)
	"		    
    }
}


