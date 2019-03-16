# packages/intranet-demo-data/tcl/intranet-demo-data-project-procs.tcl
ad_library {

    Project support for demo-data generation
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2012-10-06
    
    @vss $Workfile: intranet-dynfield-procs.tcl $ $Revision: 1.19 $ $Date: 2017/04/10 14:13:59 $
}


ad_proc -public im_demo_data_project_sales_pipeline_advance {
    {-day ""}
    {-advance_probability 10.0}
    {-cancel_probability 0.5}
} {
    Check for "potential" main projects including sub-type of potential.
    Advance these projects to the next sales pipeline state according to
    some transition probability function
} {
    if {"" == $day} {
        set day [db_string default_day "select max(day)::date + 1 from im_hours" -default ""]
        if {"" == $day} { set day "2010-01-01" }
    }

    set potential_projects_sql "
	select	project_id,
		project_status_id
	from	im_projects p
	where	p.parent_id is null and
		p.project_status_id in (select * from im_sub_categories([im_project_status_potential]))
    "
    db_foreach pot $potential_projects_sql {
    	set project_status_hash($project_id) $project_status_id
    }

    # We now have a list of projects together with the days since
    # when they have the current status.
    # Loop through the project and advance their status if appropriate.
    #
    foreach pid [array names project_status_hash] {
    	set project_status_id $project_status_hash($pid)
	set project_needs_shift_p 0
	ns_log Notice "im_demo_data_project_sales_pipeline_advance: status=$project_status_id"

	# Default potential project states.
	# There may be added states with higher IDs which we'll ignore
	#        71 | Potential
	#        72 | Inquiring
	#        73 | Qualifying
	#        74 | Quoting
	#        75 | Quote Out
	#        76 | Open

	if {$project_status_id < 71 || $project_status_id > 75} {
	    # Some other user-defined status. Set the status immediately to 71.
	    ns_log Notice "im_demo_data_project_sales_pipeline_advance: updating project #$pid from status '$project_status_id' to status 'inquiring'"
	    db_dml status_other "update im_projects set project_status_id = 71 where project_id = :pid"
	    im_audit -object_id $pid -comment "sales pipeline advance: Found an unknown project status, setting to 72"
	}
	
	# Advance the project to the next state with a certain probability.
	# 4.0% corresponds to 25/2 days for every status change
	set rand_perc [expr rand() * 100.0]
	ns_log Notice "im_demo_data_project_sales_pipeline_advance: advance status: status=$project_status_id, advance_probability=$, rand_perc=$rand_perc"
	if {$rand_perc < $advance_probability} {
	    # Change the status to the next status.
	    # Take advantage of the linear numbering and that 76=Open is the status after 75.
	    ns_log Notice "im_demo_data_project_sales_pipeline_advance: advacding project=$pid to status [expr $project_status_id + 1]"
	    set project_status_id [expr $project_status_id + 1]
	    db_dml status_other "update im_projects set project_status_id = :project_status_id where project_id = :pid"
	    im_audit -object_id $pid -comment "sales pipeline advance: Advancing project"

	    # Special actions for special states
	    switch $project_status_id {
		74 {
		    # Quoting: Create a quote document
		    ns_log Notice "im_demo_data_project_sales_pipeline_advance: im_demo_data_cost_create_quote -day $day -project_id $project_id"
		    im_demo_data_cost_create -day $day -cost_type_id [im_cost_type_quote] -project_id $project_id
		}
	    }
	}

	# Include the possibility that the project will be canceled.
	# 1.0% corresponds to 100/2 days in average to cancel a project
	set rand_perc [expr rand() * 100.0]
	ns_log Notice "im_demo_data_project_sales_pipeline_advance: cancel project: status=$project_status_id, cancel_probability=$cancel_probability, rand_perc=$rand_perc"
	if {$rand_perc < $cancel_probability} {
	    # Cancel the project
	    ns_log Notice "im_demo_data_project_sales_pipeline_advance: advacding project=$pid to status 83"
	    db_dml status_other "update im_projects set project_status_id = [im_project_status_canceled] where project_id = :pid"
	    im_audit -object_id $pid -comment "sales pipeline advance: Canceling project"
	}	
    }
}



ad_proc -public im_demo_data_project_new_from_template {
    {-day ""}
    {-debug_p 0}
    {-company_id ""}
    {-template ""}
    {-new_start_date ""}
} {
    Creates a new project from a template of the intranet-demo-data folder.
} {
    if {"" == $day} { set day [db_string today "select now()::date from dual"] }

    # Remember the current audit_id in order to delete audits later
    set prev_audit_id [db_string prev_audit "select last_value from im_audit_seq"]

    # Determine the template path
    set server_root [acs_root_dir]
    set template_root "$server_root/packages/intranet-demo-data/templates"

    # Select one of the templates in the templates folder
    set template_file "$template_root/$template"
    if {"" == $template} {
	set files ""
	catch { }
	set files [im_exec find $template_root -maxdepth 1 -noleaf -type f] 
	set template_file [util::random_list_element $files]
    }

    # When shold the new project start?
    if {"" == $new_start_date} {
       set new_start_date_list [db_list new_start_date_list "select day from im_day_enumerator(:day::date + 30, :day::date + 480) day"]
       set new_start_date [util::random_list_element $new_start_date_list]
    }
    ns_log Notice "im_demo_data_project_new_from_template: day=$day, company_id=$company_id, new_start_date=$new_start_date, template_file=$template_file"


    # Read the file from the HTTP session's TMP file
    if {[catch {
	set fl [open $template_file]
	fconfigure $fl -encoding "utf-8"
	set binary_content [read $fl]
	close $fl
    } err]} {
	ad_return_complaint 1 "Unable to open file $template_file: <br><pre>\n$err</pre>"
    }

    # Select a random active customer
    if {"" == $company_id} {
        set customer_list [db_list customer_list "
                select  c.company_id
                from    im_companies c
                where   c.company_status_id = [im_company_status_active] and
                        c.company_type_id in (select * from im_sub_categories([im_company_type_customer]))
        "]
        set company_id [util::random_list_element $customer_list]
    }

    # create a new base project for the contents
    set template_body [lrange [split $template_file "/"] end end]
    if {[regexp {^(.*)\.[0-9]+[a-z]\.xml} $template_body match t]} { set template_body $t }
    if {[regexp {^(.*)\.[0-9]+\.xml} $template_body match t]} { set template_body $t }
    regsub -all "\\-" $template_body " " template_body
    set customer_name [db_string customer_name "select company_name from im_companies where company_id = :company_id" -default ""]
    if {"" == $customer_name} { ad_return_complaint 1 "im_demo_data_project_new_from_template: invalid customer #$company_id" }

#    set project_name [concat $customer_name $template_body "($day)"]
    set project_name [concat $template_body "($day)"]

    regsub -all "  " $project_name " " project_name
    
    set project_nr [im_next_project_nr]
    ns_log Notice "im_demo_data_project_new_from_template: im_project::new -project_name $project_name -project_nr $project_nr -project_path $project_nr -company_id $company_id -project_type_id [im_project_type_gantt] -project_status_id [im_project_status_open]"
    set main_project_id [db_string dup "select project_id from im_projects where parent_id is null and project_nr = :project_nr OR project_name = :project_name" -default ""]
    if {"" eq $main_project_id} {
	set main_project_id [im_project::new \
			-project_name $project_name \
			-project_nr $project_nr \
			-project_path $project_nr \
			-company_id $company_id \
			-project_type_id [im_project_type_gantt] \
			-project_status_id [im_project_status_open] \
        ]
    }
    
    # Save the XML contents into a new project
    im_gp_save_xml \
	-debug_p $debug_p \
	-return_url [im_url_with_query] \
	-project_id $main_project_id \
	-file_content $binary_content


    # Delete the audit records written during creation
    set subprojects [db_list subprojects "
			select	sub_p.project_id
			from	im_projects sub_p,
				im_projects main_p
			where	main_p.project_id = :main_project_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
    "]
    foreach pid $subprojects {
	# Reset the last audit record at acs_objects
	db_dml objects "update acs_objects set last_audit_id = null where object_id = :pid"
	db_dml audit_chain "update im_audits set audit_last_id = null where audit_last_id in (select audit_id from im_audits where audit_object_id = :pid)"
	db_dml del_audits "delete from im_audits where audit_object_id = :pid"
    }

    # Update the start- and end_date of the project structure
    set move_days [db_string move_days "select :new_start_date::date - start_date::date from im_projects where project_id = :main_project_id"]
    db_dml move_cloned_project "
	    update im_projects set
	    	project_status_id = [im_project_status_open],
		start_date = start_date + :move_days * '1 day'::interval,
		end_date = end_date + :move_days * '1 day'::interval
	    where
		project_id in (
			select	sub_p.project_id
			from	im_projects sub_p,
				im_projects main_p
			where	main_p.project_id = :main_project_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		)
    "  

    # Update the status of the new project to "potential"
    set status_id [im_project_status_potential]
    set total_main_projects [db_string total_main_projects "select count(*) from im_projects where parent_id is null"]
    if {$total_main_projects < 10} { set status_id [util::random_list_element {72 72 73 74 74 75 75 76}] }
    set project_hours [db_string project_days "
	select	coalesce(sum(coalesce(t.billable_units,0.0)), 50.0)
	from	im_projects main_p,
		im_projects sub_p,
		im_timesheet_tasks t
	where	main_p.project_id = :main_project_id and
		sub_p.project_id = t.task_id and
		sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
    " -default 0]
    set presales_price_per_hour [util::random_list_element {70 90 110 120 130 140 150 180}]
    set presales_value [expr 10.0 * int($project_hours / 10.0) * $presales_price_per_hour]
    set presales_probability [util::random_list_element {30 40 50 60 70 80 85 90 95}]
    db_dml status_potential "
	update im_projects set 
		project_status_id = :status_id,
		presales_probability = :presales_probability,
		presales_value = :presales_value
	where project_id = :main_project_id
    "

    return $main_project_id

}

ad_proc -public im_demo_data_project_clone {
    {-template_id ""}
    {-new_start_date ""}
    {-company_id "" }
    {-project_name "" }
    {-project_nr "" }
} {
    Checks for the average work load in the upcoming days
    and creates randomly projects to keep the work load
    at a certain percentage
} {
    # -----------------------------------------------------
    # Select a random active customer
    if {"" == $company_id} {
	set customer_list [db_list customer_list "
		select	c.company_id
		from	im_companies c
		where	c.company_status_id = [im_company_status_active] and
			c.company_type_id in (select * from im_sub_categories([im_company_type_customer]))
	"]
	set company_id [util::random_list_element $customer_list]
    }

    # Select a random template if not specified
    if {"" == $template_id} {
	set template_list [db_list customer_list "
		select	p.project_id
		from	im_projects p
		where	p.parent_id is null and
			(p.template_p = 't' OR p.project_name like '%Template%') and
			p.project_status_id not in (select * from im_sub_categories([im_project_status_closed])) and
			p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
	"]
	set template_id [util::random_list_element $template_list]
    }

    if {"" == $project_name} {
	set template_project_name [db_string template_name "select project_name from im_projects where project_id = :template_id" -default ""]
	if {"" == $template_project_name} { ad_return_complaint 1 "im_demo_data_project_clone: invalid template #$template_id" }
	if {[regexp {^(.*)Template(.*)$} $template_project_name match tail end]} {
	    set template_project_name [string trim [concat [string trim $tail] " " [string trim $end]]]
	}
	set customer_name [db_string customer_name "select company_name from im_companies where company_id = :company_id" -default ""]
	if {"" == $customer_name} { ad_return_complaint 1 "im_demo_data_project_clone: invalid customer #$company_id" }

	set project_name [concat $customer_name $template_project_name]
    }

    if {"" == $project_nr} {
        set project_nr [im_next_project_nr]
    }

    if {"" == $new_start_date} {
       set new_start_date_list [db_list new_start_date_list "select day from im_day_enumerator(now()::date - 30, now()::date + 180) day"]
       set new_start_date [util::random_list_element $new_start_date_list]
    }

    set parent_project_id ""
    set clone_postfix "Clone"

    set tuple [im_project_clone \
                   -clone_costs_p 0 \
                   -clone_files_p 0 \
                   -clone_subprojects_p 1 \
                   -clone_forum_topics_p 1 \
                   -clone_members_p 1 \
                   -clone_timesheet_tasks_p 1 \
                   -clone_target_languages_p 0 \
                   -company_id $company_id \
                   $template_id \
                   $project_name \
                   $project_nr \
                   $clone_postfix \
    ]
    set cloned_project_id [lindex $tuple 0]
    set cloned_mapping_list [lindex $tuple 1]
    set cloning_errors [lindex $tuple 2]

    # Update the main project's name and nr
    db_dml update_cloned_project "
	update im_projects set
		project_name = :project_name,
		project_nr = :project_nr,
		project_path = :project_nr,
		template_p = 'f'
	where project_id = :cloned_project_id      
    "
    im_audit -object_id $cloned_project_id -comment "project clone: Updating the cloned project"


    # Update the start- and end_date of the project structure
    set move_days [db_string move_days "select :new_start_date::date - p.start_date::date from im_projects p where project_id = :cloned_project_id"]
    db_dml move_cloned_project "
	    update im_projects set
	    	project_status_id = [im_project_status_open],
		start_date = start_date + :move_days * '1 day'::interval,
		end_date = end_date + :move_days * '1 day'::interval
	    where
		project_id in (
			select	sub_p.project_id
			from	im_projects sub_p,
				im_projects main_p
			where	main_p.project_id = :cloned_project_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		)
    "  

    return $cloned_project_id
}



ad_proc -public im_demo_data_project_staff {
    {-day ""}
    -project_id:required
} {
    Assigns the project tasks to "suitable" employees.
} {
    # Get information about the project
    db_1row main_project_info "
	select	start_date as main_project_start_date,
		end_date as main_project_end_date,
		end_date::date - start_date::date as main_project_duration,
		project_lead_id
	from	im_projects
	where	project_id = :project_id
    "

    # Assign a project manager
    if {"" == $project_lead_id} {
	set pms [im_profile::user_options -profile_ids [im_profile_project_managers]]
	set pm [util::random_list_element $pms]
	set pm_id [lindex $pm 1]
	db_dml update_pm "update im_projects set project_lead_id = :pm_id where project_id = :project_id"
	im_audit -object_id $project_id -comment "project staffing: Setting the project manager"
    }

    # -----------------------------------------------------
    # Get the list of employees together with their availability and
    # their assignment to any other tasks during the time 
    set employee_sql "
    	select	t.*,
		t.available_units - t.assigned_units as remaining_units
	from	(
    	select	e.employee_id,
		e.availability,
		round(e.availability * 8.0 * :main_project_duration * (5.0 / 7.0)) as available_units,
		coalesce((
			select	sum(coalesce(t.planned_units, 0.0) * bom.percentage / 100.0 * (100.0 - coalesce(task_p.percent_completed,0.0))) / 100.0
			from	im_projects task_p,
				im_timesheet_tasks t,
				acs_rels r,
				im_biz_object_members bom
			where	task_p.project_id = t.task_id and
				r.rel_id = bom.rel_id and
				r.object_id_two = e.employee_id and
				r.object_id_one = task_p.project_id and
				bom.percentage is not null and
				task_p.project_status_id in (select * from im_sub_categories([im_project_status_open]))
		),0.0) as assigned_units
	from	im_employees e,
		cc_users u
	where	u.user_id = e.employee_id and
		e.availability is not null and e.availability > 0 and
		e.employee_id not in (select member_id from group_distinct_member_map where group_id = [im_profile_skill_profile])
		) t
	order by remaining_units DESC
    "
    set debug_html ""
    db_foreach emps $employee_sql {
	set employee_hash($employee_id) "$available_units - $assigned_units"
	append debug_html "<tr><td>[acs_object_name $employee_id]</td><td>$available_units</td><td>$assigned_units</td><td>[expr $available_units - $assigned_units]</td></tr>\n"
    }
#    ad_return_complaint 1 "<table>$debug_html</table>"

    # Return the uper (less busy) half of the candidate list.
    set candidate_list [db_list cand_list "select employee_id from ($employee_sql) e"]
    set len [llength $candidate_list]
    set candidate_list [lrange $candidate_list 0 [expr round($len / 2.0)]]


    # -----------------------------------------------------
    # Get the list of assigned_profiles used in the project
    set profiles_sql "
	select	p.project_id,
		p.project_name,
		r.object_id_two as profile_id,
		bom.rel_id as rid,
		bom.percentage,
		bom.object_role_id,
		acs_object__name(r.object_id_two) as profile_name,
		(select count(*) from im_biz_object_members bom2 where bom.rel_id = bom2.skill_profile_rel_id) as reference_count
	from	im_projects main_p,
		im_projects p,
		im_timesheet_tasks t,
		acs_rels r,
		im_biz_object_members bom
	where	main_p.project_id = :project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.project_id = t.task_id and
		r.object_id_two in (select member_id from group_distinct_member_map where group_id = [im_profile_skill_profile]) and
		r.object_id_one = p.project_id and
		r.rel_id = bom.rel_id and
		bom.percentage is not null and
		bom.percentage > 0.0
	order by p.project_id
    "

    # ad_return_complaint 1 [im_ad_hoc_query -format html $profiles_sql]
    db_foreach profiles_sql $profiles_sql {
        if {$reference_count > 0} { continue }
    	set employee_id [util::random_list_element $candidate_list]
        set new_rel_id [im_biz_object_add_role -percentage $percentage $employee_id $project_id $object_role_id]
	db_dml update_skill_inst "update im_biz_object_members set skill_profile_rel_id = :rid where rel_id = :new_rel_id"
    }
}

ad_proc -public im_demo_data_project_move_today {
    -day:required
    -project_id:required
} {
    Moves the project to start "soon".
} {
    # Get information about the project
    db_1row main_project_info "
	select	start_date as main_project_start_date,
		end_date as main_project_end_date,
		end_date::date - start_date::date as main_project_duration,
		project_lead_id
	from	im_projects
	where	project_id = :project_id
    "

    # Move the project so that it starts in the next days
    set move_days [db_string move_days "select :day::date - :main_project_start_date::date from dual"]
    set move_days [expr $move_days + 7 + int(rand() * 30.0)]
    db_dml move_project "
	    update im_projects set
	    	project_status_id = [im_project_status_open],
		start_date = start_date + :move_days * '1 day'::interval,
		end_date = end_date + :move_days * '1 day'::interval
	    where
		project_id in (
			select	sub_p.project_id
			from	im_projects sub_p,
				im_projects main_p
			where	main_p.project_id = :project_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		)
    "

}


ad_proc -public im_demo_data_project_close_done_projects {
    -day:required
    -project_id:required
} {
    Check a project whether all of it's sub-projects are closed already.
    In this case close the project and proceed to it's parent.
} {
    ns_log Notice "im_demo_data_project_close_done_projects -project_id $project_id"
    set check_sql "
	select	sub_p.project_id as sub_project_id,
		sub_p.project_status_id,
		sub_p.percent_completed
	from	im_projects sub_p
	where	sub_p.parent_id = :project_id
    "
    set all_closed_p 1
    db_foreach check $check_sql {
    	if {$project_status_id != [im_project_status_closed] && $percent_completed < 100.0} { set all_closed_p 0 }
    }
    
    if {$all_closed_p} {
        ns_log Notice "im_demo_data_project_close_done_projects -project_id $project_id: closing"
	set parent_id [db_string parent "select parent_id from im_projects where project_id = :project_id" -default "0"]
	if {0 == $parent_id} { return }

	# Main projects get the status "delivered" (ready for invoicing), while sub-projects get status "closed"
	if {"" == $parent_id} { set sid [im_project_status_delivered] } else {set sid [im_project_status_closed] }

	db_dml close_project "update im_projects set project_status_id = :sid, percent_completed = 100.0 where project_id = :project_id"
	im_audit -object_id $project_id -action "after_update" -comment "close done projects: closing parents for finished tasks"

	# Write an invoice for the project
	ns_log Notice "im_demo_data_project_close_done_projects: im_demo_data_cost_create -day $day -cost_type_id [im_cost_type_invoice] -project_id $project_id"
	im_demo_data_cost_create -day $day -cost_type_id [im_cost_type_invoice] -project_id $project_id

	if {"" != $parent_id} {
	     # Recursive call to check super-projects
	     im_demo_data_project_close_done_projects -day $day -project_id $parent_id
	}
    }
}


ad_proc -public im_demo_data_project_create_beaches {
    -day:required
} {
    The "Beach" are the projects for non-productive hours.
    These beaches are created per year.
    All users are assigned to the beaches, so that all users
    can log unproductive hours.
} {
    # -----------------------------------------------------
    # Check if there is a beach for day

    set beaches [db_list beach_count "
    	select	  project_id
	from	  im_projects main_p
	where	  main_p.parent_id is null and
		  main_p.start_date <= :day and
		  main_p.end_date >= :day and
		  main_p.company_id = [im_company_internal] and
		  lower(main_p.project_nr) like '%beach%'
    "]

    lappend beaches 0

    db_dml beach_open "
    	update im_projects set 
		project_status_id = [im_project_status_open],
		project_type_id = [im_project_type_other]
	where project_id in ([join $beaches ","])
    "
    foreach pid $beaches { im_audit -object_id $pid -comment "create beaches: Setting default status and type for beaches" }


    db_1row info "
    	select	to_char(now(), 'YYYY') as year
	from	dual     
    "

    # Close all "beaches"
    set open_beaches [db_list open_beaches "
		select	project_id
		from	im_projects
		where	parent_id is null and
			project_status_id = [im_project_status_open] and
			(project_nr like '20%_beach' or project_nr like '20%_op') and
			project_nr not in (:year || '_beach', :year || '_op')
    "]
    foreach pid $open_beaches {
        ToDo: Remove this line once closing old beaches works
        db_dml close_beaches "
		update im_projects
		set	project_status_id = [im_project_status_closed]
		where	project_id = :pid
        "
	im_audit -object_id $pid -comment "create beaches: Set beach to 'closed'"
    }

    # define the list of projects to create
    set beaches [list \
    	[list ""		"Beach $year"			"${year}_beach"			""				] \
    	[list "${year}_beach"	"Beach $year - Vacation"	"${year}_beach_vacation"	[im_profile_employees]		] \
    	[list "${year}_beach"	"Beach $year - Training"	"${year}_beach_training"	[im_profile_employees]		] \
    	[list ""		"Operations $year"		"${year}_op"			""				] \
    	[list "${year}_op"	"Operations $year - Marketing"	"${year}_op_marketing"		[im_profile_sales]		] \
    	[list "${year}_op"	"Operations $year - Sales"	"${year}_op_sales"		[im_profile_sales]		] \
    	[list "${year}_op"	"Operations $year - Other"	"${year}_op_other"		[im_profile_senior_managers] 	] \
    ]

    foreach tuple $beaches {
	set beach_parent [lindex $tuple 0]
	set beach_name [lindex $tuple 1]
	set beach_nr [lindex $tuple 2]
	set beach_group_id [lindex $tuple 3]
	set beach_parent_id [db_string beach_parent "select project_id from im_projects where project_nr = :beach_parent" -default ""]

	# Create new beach for the current year
	set beach_parent_null_sql "parent_id = :beach_parent_id"
	if {"" == $beach_parent_id} { set beach_parent_null_sql "parent_id is null" }

	set main_beach_id [db_string beach_exists "
		select	project_id
		from	im_projects
		where	project_nr = :beach_nr and
			$beach_parent_null_sql
	" -default ""]

	if {"" == $main_beach_id} {
	    set main_beach_id [im_project::new \
				   -project_name $beach_name \
				   -project_nr $beach_nr \
				   -project_path $beach_nr \
				   -company_id [im_company_internal] \
				   -parent_id $beach_parent_id \
				   -project_type_id [im_project_type_other] \
				   -project_status_id [im_project_status_open] \
	    ]
	}

	# Update some addional variables
	db_dml main_beach "
		update im_projects set
			project_lead_id = (select min(user_id) from users where user_id > 0),
			start_date = '${year}-01-01'::date,
			end_date = '${year}-12-31'::date
		where project_id = :main_beach_id
	"
	im_audit -object_id $main_beach_id -comment "create beaches: Set start and end date"

	# Make all employees members of the beach
	im_biz_object_add_role $beach_group_id $main_beach_id [im_biz_object_role_full_member]
    }

}




# ------------------------------------------------------
# Very large project procs
# ------------------------------------------------------


ad_proc -public im_demo_data_create_very_large_project {
    -project_id:required
    { -num_tasks 100}
} {
    Takes a project and creates a number of nested sub-tasks.
} {
    set n 0
    set loop 0
    while {$n < $num_tasks && $loop < 1000} {
	ns_log Notice "im_demo_data_create_very_large_project: n=$n"
	set leaf_task_ids [db_list leaf_task_ids "
	select	p.project_id
	from	im_projects p,
		im_projects main_p
	where	p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		not exists (select * from im_projects pp where pp.parent_id = p.project_id) and
		main_p.project_id = :project_id
        "]
    
	set task_id [util::random_list_element $leaf_task_ids]
	im_demo_data_create_n_subtasks -project_id $task_id

	set n [llength $leaf_task_ids]
	incr loop
    }
    return $task_id
}


ad_proc -public im_demo_data_create_n_subtasks {
    -project_id:required
} {
    Takes a task and creates a number of sub-tasks.
} {
    set n_tasks [expr 2 + int(rand() * 4)]
    set admin_user_id [im_sysadmin_user_default]
    set default_material_id [im_material_default_material_id]

    db_1row project_info "
	select	to_char(p.start_date, 'J') as start_julian,
		to_char(p.end_date, 'J') as end_julian,
		p.parent_id,
		p.project_nr as parent_nr,
		p.project_name as parent_name
	from	im_projects p
	where	project_id = :project_id
    "

    set average_days [expr int(($end_julian - $start_julian) / (1.0 * $n_tasks)) - 1]
    if {$average_days < 2} { return }; # skip when too close together...
    
    set task_start_julian $start_julian
    set task_end_julian $start_julian
    set old_task_start_julian $task_start_julian
    set old_task_end_julian $task_end_julian
    set task_id 0
    set old_task_id 0
    set i 0
    # Loop until reached the end of the task
    while {$i < 10 && $old_task_end_julian < $end_julian} {

	incr i

	# Naming of the new task
	set project_nr "${parent_nr}_t$i"
	set project_name "${parent_name}-t$i"
	if {"" eq $parent_id} { set project_name "t$i" }

	# Duration of the task. Should not exceed the end_julian of the super-task.
	set days [expr int($average_days * (0.7 + rand() * 0.6))]
	if {[expr $task_start_julian + $days] > $end_julian} { set days [expr $end_julian - $task_start_julian]	}
	if {$days < 0} { set days 0 }

	# How to add the new task?
	set action_code [expr int(1 + rand() * 2.0)]
	if {$i eq 0} { set action_code 0 }
	switch $action_code {
	    0 {
		# First task below subtask
		set pred_id 0
		set task_start_julian $start_julian
		set task_end_julian [expr $start_julian + $days]
	    }
	    1 {
		# Just continue behind the last task with end-to-start
		set pred_id $task_id
		set task_start_julian [expr $old_task_end_julian + 1]
		set task_end_julian [expr $task_start_julian + $days]
	    }
	    2 {
		# Continue in parallel to the last task
		set pred_id $old_task_id
		set task_start_julian [expr $old_task_start_julian]
		set task_end_julian [expr $task_start_julian + $days]
	    }
	    default {
		ad_return_complaint 1 "im_demo_data_create_n_subtasks: unknown action_code=$action_code"
	    }

	}

	set old_task_id $task_id
	set task_id [db_string new_task "
		SELECT im_timesheet_task__new (
			null, 'im_timesheet_task', now(), :admin_user_id, '0.0.0.0', null,
			:project_nr, :project_name, :project_id,
			:default_material_id, null, 320,
			[im_project_type_task], [im_project_status_open],null
		)
	"]
	
	db_dml update_task "
		update im_projects set
			start_date = to_date(:task_start_julian, 'J'),
			end_date = to_date(:task_end_julian, 'J'),
			sort_order = :i
		where	project_id = :task_id
	"

	im_audit -user_id $admin_user_id -object_type "im_timesheet_task" -object_id $task_id -action after_create

	# Copy into variables for last task
	set old_task_start_julian $task_start_julian
	set old_task_end_julian $task_end_julian

	if {$pred_id > 0} {
	    set type_id 9662; # Finish-to-start
	    set diff 0
	    db_dml create_dependency "
                insert into im_timesheet_task_dependencies (
			task_id_two, task_id_one, 
			dependency_type_id, difference
		) values (
			:pred_id, :task_id, 
			:type_id, :diff
		)
	    "
	}
    }

    return $n_tasks
}
