# /packages/intranet-rule-engine/tcl/intranet-rule-engine-procs.tcl
#
# Copyright (C) 2003-2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_rule_status_active {} { return 85000 }
ad_proc -public im_rule_status_deleted {} { return 85002 }

ad_proc -public im_rule_type_tcl {} { return 85100 }
ad_proc -public im_rule_type_email {} { return 85102 }

ad_proc -public im_rule_type_after_update {} { return 85200 }
ad_proc -public im_rule_type_after_create {} { return 85202 }
ad_proc -public im_rule_type_cron24 {} { return 85204 }



# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

ad_proc -public im_rule_object_type_options {
    {-include_empty_p 0}
    {-include_empty_name ""}
} {
    Returns a list of supported object_types for rules
} {
    set list [list \
		[list "Project" im_project] \
		[list "Ticket" im_ticket] \
		[list "Gantt Task" im_timesheet_task] \
		[list "Financial Document" im_invoice] \
    ]

    # Keep GUI clean 
    if { [apm_package_enabled_p intranet-translation] } {
	set list [linsert $list 3 [list "Translation Task" "im_trans_task"]]
    }

    if {$include_empty_p} {
	set list [linsert $list 0 [list $include_empty_name ""]]
    }

    return $list
}

# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_rule_audit_component {
    -object_id
} {
    Returns a HTML component to show all past rule actions related to the object_id
} {
    set current_user_id [ad_conn user_id]
    set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

    # Skip this portlet for non-admins
    if {!$admin_p} { return "" }

    # Skip the portlet if there are no entries
    set log_count [db_string log_count "select count(*) from im_rule_logs where rule_log_object_id = :object_id"]
    if {!$log_count} { 
	return [lang::message::lookup "" intranet-rule-engine.Currently_No_Log_Entries "There are currently no log entries for this object #$object_id"] 
	return ""
    }

    set params [list \
		    [list base_url "/intranet-rule-engine/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-rule-engine/lib/rules-audit-component"]
    return [string trim $result]
}



# ----------------------------------------------------------------------
# Nuke a rule
# ---------------------------------------------------------------------

ad_proc -public im_rule_nuke {
    {-current_user_id 0}
    rule_id
} {
    Nuke a rule object
} {
    db_string im_rule_nuke "SELECT im_rule__delete(:rule_id) from dual"
}



# ----------------------------------------------------------------------
# Debugging output
# ---------------------------------------------------------------------

ad_proc im_rule_callback_log {
    -object_id:required
    -rule_id:required
    -source:required
    -message:required
    -statement:required
    -env:required
} {
    Records a log entry
} {
    set ip_address '0.0.0.0'
    set current_user_id 0
    catch {
	set current_user_id [ad_conn user_id]
	set ip_address [ns_conn peeraddr]
    }
    if {"" == $message} { set message "ok" }
    set env "-"

    if {[catch {
	db_dml $source "
		insert into im_rule_logs (
			rule_log_id, rule_log_object_id, rule_log_date, rule_log_user_id, rule_log_ip, rule_log_rule_id,
			rule_log_error_source, rule_log_error_message, rule_log_error_statement, rule_log_error_env
		) values (
			nextval('im_rule_log_seq'), :object_id, now(), :current_user_id, :ip_address, :rule_id,
			:source, :message, :statement, :env
		)      
        "
    } err_msg]} {
	ns_log Notice "im_rule_callback_log: Error: $source: oid=$object_id, rid=$rule_id, msg=$message, cmd=$statement"
	ns_log Notice "im_rule_callback_log: Error: $err_msg"
    }
    ns_log Notice "im_rule_callback_log: $source: oid=$object_id, rid=$rule_id, msg=$message, cmd=$statement"
}



# ----------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------

ad_proc im_rule_callback {
    { -debug_p 0}
    { -action ""}
    -object_id:required
    { -type_id ""}
} {
    Check if the fields of the underlying object have changed since the last 
    call and apply the appropriate rule heads.
} {
    if {$debug_p} { ns_log Notice "im_rule_callback: " }
    if {$debug_p} { ns_log Notice "im_rule_callback: -------------------------------------------------------------------" }
    if {$debug_p} { ns_log Notice "im_rule_callback: " }
    if {$debug_p} { ns_log Notice "im_rule_callback: object_id=$object_id, action='$action'" }
    if {$debug_p} { ns_log Notice "im_rule_callback: "  }

    # Create im_biz_object entry if not already there...
    set biz_object_exists_p [db_string bom_p "select count(*) from im_biz_objects where object_id = :object_id"]
    if {!$biz_object_exists_p} {
	db_dml new_bom "insert into im_biz_objects (object_id) values (:object_id)"
    }

    set old_value [db_string old_value "select rule_engine_old_value from im_biz_objects where object_id = :object_id" -default ""]
    set new_value [im_audit_object_value -object_id $object_id]

    # Update the old value, together with the update time
    db_dml old_value_update "
	update im_biz_objects set 
		rule_engine_old_value = :new_value,
		rule_engine_last_modified = now()
	where object_id = :object_id
    "

    # Determine the invocation type based on action
    switch $action {
	after_update { set actual_invocation_type_id [im_rule_type_after_update] }
	after_create { set actual_invocation_type_id [im_rule_type_after_create] }
	cron24 { set actual_invocation_type_id [im_rule_type_cron24] }
	default { set actual_invocation_type_id [im_rule_type_after_update] }
    }

    # Exception: If the object didn't exist before, then override by after_creation
    if {"" eq $old_value && $actual_invocation_type_id eq [im_rule_type_after_update]} {
	ns_log Notice "im_rule_callback: Didn't find old_value for object_id=$object_id: after_create invocation type"
	set actual_invocation_type_id [im_rule_type_after_create]
	set old_value $new_value
    }

    set new_values [split $new_value "\n"]
    foreach new_item $new_values {
	set new_pieces [split $new_item "\t"]
	set new_var [lindex $new_pieces 0]
	set new_val [lindex $new_pieces 1]
	if {[info exists new($new_var)]} {
	    # This can happen for example in im_timesheet_tasks, if no entry exists
	    # in im_gantt_projects. Don't overwrite with empty values
	    if {"" eq $new_val} { continue }
	}
	set new($new_var) $new_val
	if {$debug_p} { ns_log Notice "im_rule_callback: new($new_var) = $new_val" }
	set changed($new_var) 0
    }

    set old_values [split $old_value "\n"]
    foreach old_item $old_values {
	set old_pieces [split $old_item "\t"]
	set old_var [lindex $old_pieces 0]
	set old_val [lindex $old_pieces 1]
	if {[info exists old($old_var)]} {
	    # This can happen for example in im_timesheet_tasks, if no entry exists
	    # in im_gantt_projects. Don't overwrite with empty values
	    if {"" eq $old_val} { continue }
	}
	set old($old_var) $old_val
	if {$debug_p} { ns_log Notice "im_rule_callback: old($old_var)=$old_val" }
	set changed($old_var) 0
    }

    set version_diff [im_audit_calculate_diff -old_value $old_value -new_value $new_value]
    if {$debug_p} { ns_log Notice "im_rule_callback:" }
    if {$debug_p} { ns_log Notice "im_rule_callback: version_diff=[string map {"\n" " "} $version_diff]" }
    if {$debug_p} { ns_log Notice "im_rule_callback:" }

    set diff_values [split $version_diff "\n"]
    foreach diff_item $diff_values {
	set diff_pieces [split $diff_item "\t"]
        set diff_var [lindex $diff_pieces 0]
        set diff_val [lindex $diff_pieces 1]
        set diff($diff_var) $diff_val
        set changed($diff_var) 1
	if {$debug_p} { ns_log Notice "im_rule_callback: changed($diff_var)=1" }
    }

    # Add (constant) sender information to the substitution_list
    db_0or1row user_info "
	select	pe.person_id as sender_user_id,
		im_name_from_user_id(pe.person_id) as sender_name,
		first_names as sender_first_names,
		last_name as sender_last_name,
		email as sender_email,
		1 as found_sender_p
	from	persons pe,
		parties pa
	where	pe.person_id = pa.party_id and
		pe.person_id = [im_sysadmin_user_default]
    "
    set new(sender_user_id) $sender_user_id
    set new(sender_name) $sender_name
    set new(sender_first_names) $sender_first_names
    set new(sender_last_name) $sender_last_name
    set new(sender_email) $sender_email

    set env [list [array get old] [array get new] [array get changed]]

    # --------------------------------------------------------------------------------------
    # Load the list of active rules
    set rule_sql "
	select	r.*,
		im_category_from_id(r.rule_type_id) as rule_type
	from	im_rules r,
		acs_objects o
	where	o.object_id = :object_id and
		r.rule_object_type = o.object_type and
		r.rule_status_id in (select * from im_sub_categories([im_rule_status_active]))
	order by
		r.rule_sort_order, r.rule_name
    "
    db_foreach rules $rule_sql {

	if {$debug_p} { ns_log Notice "im_rule_callback: -----------------------------------------" }
	ns_log Notice "im_rule_callback: rule_name=$rule_name"
	if {$debug_p} { ns_log Notice "im_rule_callback: " }
	# Execute the rule ONLY if the type matches.
	# That means that the after_update is NOT fired during after_create.
	if {$rule_invocation_type_id != $actual_invocation_type_id} {
	    continue
	}

	set error_msg ""
	set fire_p 0
	set error_p [catch {
	    set fire_p [expr $rule_condition_tcl]
	} error_msg]
	ns_log Notice "im_rule_callback: fire_p=$fire_p, condition=$rule_condition_tcl"

	if {$error_p} {
	    global errorInfo
	    ns_log Notice "im_rule_callback: Error in: $rule_action_tcl: $error_msg"
	    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "condition_error" \
		-message "$error_msg - $errorInfo" -statement $rule_condition_tcl -env $env
	    continue
	}

	if {$fire_p} {
	    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "condition_fire" \
		-message $fire_p -statement $rule_condition_tcl -env $env

	    # Check if there is a TCL action to execute
	    if {"" != [string trim $rule_action_tcl]} {
		im_rule_callback_fire_action -action_tcl $rule_action_tcl -object_id $object_id -rule_id $rule_id -env $env
	    }

	    # Check if there are emails to be sent
	    if {"" != [string trim $rule_action_email_to_tcl]} {
		im_rule_callback_fire_email -email_tcl $rule_action_email_to_tcl -object_id $object_id -rule_id $rule_id -env $env
	    }
	}
    }

}



ad_proc im_rule_callback_fire_action {
    -action_tcl:required
    -object_id:required
    -rule_id:required
    -env:required
} {
    Execute the action_tcl of a rule
} {
    set action_tcl [string map {"\\\r\n" " "} $action_tcl]
    ns_log Notice "im_rule_callback_fire_action: -object_id $object_id -rule_id $rule_id -action_tcl $action_tcl -env $env"

    # set env [list [array get old] [array get new] [array get changed]]
    array set old [lindex $env 0]
    array set new [lindex $env 1]
    array set changed [lindex $env 2]

    # Execute the action - copied from /ds/shell
    if {[catch {set out [uplevel 1 $action_tcl]}]} {
	global errorInfo
	set out "ERROR:\n$errorInfo"
	set out "ERROR:\n$errorInfo"
	im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_error" \
	    -message $out -statement $action_tcl -env $env

	ns_log Notice "im_rule_callback_fire_action: aborted: Error=$out"
	return
    }

    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_fire" \
	-message $out -statement $action_tcl -env $env
    ns_log Notice "im_rule_callback_fire_action: finished: object_id=$object_id, rule_id="
}



ad_proc im_rule_callback_fire_email {
    -email_tcl:required
    -object_id:required
    -rule_id:required
    -env:required
    {-debug_p 0}
} {
    Send out an email to the users specified
} {
    ns_log Notice "im_rule_callback_fire_email: -object_id $object_id -rule_id $rule_id"

    # set env [list [array get old] [array get new] [array get changed]]
    array set old [lindex $env 0]
    array set new [lindex $env 1]
    array set changed [lindex $env 2]

    db_1row rule_info "
	select	r.*
	from	im_rules r
	where	rule_id = :rule_id
    "

    # --------------------------------------------------------------------------------------
    # Execute the email action
    #
    if {"" != [string trim $rule_action_email_to_tcl]} {
	if {[catch {
	    set cmd "set out \[$rule_action_email_to_tcl\]"
	    eval $cmd
	}]} {
	    global errorInfo
	    set out "ERROR:\n$errorInfo"
	    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_email_to_error" \
		-message $out -statement $rule_action_email_to_tcl -env $env
	    return
	}
		
	# Log the result of the command
	im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_email_to_fire" \
	    -message $out -statement $rule_action_email_to_tcl -env $env
	set email_error_p 0
	foreach email $out {
	    if {$email_error_p} { return }
		    
	    set found1_p 0
	    db_0or1row user_info "
				select	pe.person_id as user_id,
					im_name_from_user_id(pe.person_id) as name,
					first_names,
					last_name,
					email,
					1 as found1_p
				from	persons pe,
					parties pa
				where	pe.person_id = pa.party_id and
					lower(pa.email) = lower(:email)
	    "
	    if {!$found1_p} {
		ns_log Error "im_rule_callback_fire_email: Didn't find email=$email"
		continue
	    }
		    
	    set auto_login [im_generate_auto_login -user_id $user_id]
	    set system_url [im_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
	    set object_url [im_biz_object_url $object_id]
	    set substitution_list [array get new]
	    lappend substitution_list \
		user_id $user_id \
		name $name \
		first_names $first_names \
		last_name $last_name \
		email $email \
		auto_login $auto_login \
		system_url $system_url \
		object_url $object_url

	    array set subs_hash $substitution_list
	    foreach key [array names subs_hash] {
		set $key $subs_hash($key)
	    }

	    # Substitute the mail's subject
	    if {[catch {
		set cmd "set subject \"$rule_action_email_subject\""
		eval $cmd
	    } err_msg]} {
		global errorInfo
		im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_email_subject_error" \
		    -message "$err_msg - $errorInfo" -statement $rule_action_email_subject -env $env
		set email_error_p 1
		continue
	    }
		    
	    # Substitute the mail's body
	    if {[catch {
		set cmd "set body \"$rule_action_email_body\""
		eval $cmd
	    } err_msg]} {
		global errorInfo
		im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "action_email_body_error" \
		    -message "$err_msg - $errorInfo" -statement $rule_action_email_body -env $env
		set email_error_p 1
		continue
	    }
	    
	    ns_log Notice "im_rule_callback_fire_email: Sending email to $email: $subject\n$body"
	    
	    if {$debug_p} {
		ad_return_complaint 1 "<pre> acs_mail_lite::send
                        -send_immediately
                        -to_addr $email
                        -from_addr $new(sender_email)
                        -subject $subject
                        -body $body"
		ad_script_abort
	    } else {
		if {[catch {
		    acs_mail_lite::send \
			-send_immediately \
			-to_addr $email \
			-from_addr $new(sender_email) \
			-subject $subject \
			-body $body
		    
		    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "email_sent" \
			-message "ok" -statement acs_mail_lite::send -env $env
		} err_msg]} {
		    im_rule_callback_log -object_id $object_id -rule_id $rule_id -source "email_send_error" \
			-message $err_msg -statement acs_mail_lite::send -env $env
		    ns_log Error "im_rule_callback_fire_email: Error sending to email=$email: $err_msg"
		    set email_error_p 1
		    continue
		}
	    }
	}
    }

    ns_log Notice "im_rule_callback_fire_email: finished: object_id=$object_id, rule_id="
}



# ----------------------------------------------------------------------
# Sweeper
# ---------------------------------------------------------------------

ad_proc -public im_rule_engine_sweeper {
} {
    Checks for changed objects.
    This is important for the case that objects are created or modified
    outside of the TCL code with its callbacks.
} {
    ns_log Notice "im_rule_engine_sweeper: Entering sweeper"
    set result ""

    # Make sure that only one thread is working at a time
    if {[nsv_incr intranet_rule_engine sweeper_p] > 1} {
        nsv_incr intranet_rule_engine sweeper_p -1
	set result "im_rule_engine_sweeper: Aborting. There is another process running"
        ns_log Error $result
        return
    }
    if {[catch {
	set result [im_rule_engine_sweeper_helper]
	ns_log Notice "im_rule_engine_sweeper: Result: $result"
    } err_msg]} {
	ns_log Error "im_rule_engine_sweeper: Error: $err_msg"
    }

    nsv_incr intranet_rule_engine sweeper_p -1
    ns_log Notice "im_rule_engine_sweeper: Leaving sweeper"
    return $result
}


ad_proc -public im_rule_engine_sweeper_helper {
} {
    Implementation of Rule Engine sweeeper: Checks for changed objects.
    This is important for the case that objects are created or modified
    outside of the TCL code with its callbacks.
} {
    set s [parameter::get_from_package_key -package_key intranet-rule-engine -parameter RuleEngineSweeperInterval -default 61]
    set sweeper_limit [parameter::get_from_package_key -package_key intranet-rule-engine -parameter RuleEngineSweeperLimit -default 20]
    set sweeper_object_types [list im_project im_ticket im_timesheet_task]

    # All objects that have never been indexed before
    set never_checked_oids [db_list never_checked_oids "
		select	o.object_id
		from	acs_objects o,
			im_biz_objects bo
		where	o.object_id = bo.object_id and
			object_type in ('[join $sweeper_object_types "','"]') and
			o.creation_date < now() - '$s seconds'::interval and		-- Exclude objects younger than 1 sweeper interval...
			bo.rule_engine_last_modified is null 		   		-- ... that have not been checked yet
    "]
    set last_checked_oids [db_list last_checked_oids "
		select	o.object_id
		from	acs_objects o,
			im_biz_objects bo
		where	o.object_id = bo.object_id and
			object_type in ('[join $sweeper_object_types "','"]') and
			o.creation_date < now() - '$s seconds'::interval		-- Exclude objects younger than 1 sweeper interval...
		order by
			bo.rule_engine_last_modified					-- ... ordered by the oldest first
		limit $sweeper_limit
    "]
    set oids [set_union $never_checked_oids $last_checked_oids]
    set len_oids [llength $oids]

    set cnt 1
    foreach oid $oids {
	ns_log Notice "im_rule_engine_sweeper: Sweeping object #$oid as $cnt of $len_oids"
	im_rule_callback -object_id $oid -action after_update
	ns_log Notice "im_rule_engine_sweeper: Finished sweeping object #$oid"
	incr cnt
    }

}






# ----------------------------------------------------------------------
# 24h "Cron"
# ---------------------------------------------------------------------

ad_proc -public im_rule_engine_cron24_sweeper {
} {
    Runs once per day and executes rules for all objects in the system.
} {
    ns_log Notice "im_rule_engine_cron24_sweeper: Entering sweeper"
    set result ""

    # Make sure that only one thread is working at a time
    if {[nsv_incr intranet_rule_engine cron24_p] > 1} {
        nsv_incr intranet_rule_engine cron24_p -1
	set result "im_rule_engine_cron24_sweeper: Aborting. There is another process running"
        ns_log Error $result
        return
    }
    if {[catch {
	set result [im_rule_engine_cron24_sweeper_helper]
	ns_log Notice "im_rule_engine_cron24_sweeper: Result: $result"
    } err_msg]} {
	ns_log Error "im_rule_engine_cron24_sweeper: Error: $err_msg"
    }

    nsv_incr intranet_rule_engine cron24_p -1
    ns_log Notice "im_rule_engine_cron24_sweeper: Leaving sweeper"
    return $result
}


ad_proc -public im_rule_engine_cron24_sweeper_helper {
} {
    Implementation of Rule Engine Cron24: 
    Executes rules for all objects in the system.
} {
    # Projects - just go for parent projects
    set pids [db_list projects "select project_id from im_projects where parent_id is null"]
    set len_pids [llength $pids]
    set cnt 1
    foreach pid $pids {
	ns_log Notice "im_rule_engine_cron24_sweeper: Sweeping object #$pid as $cnt of $len_pids"
	im_rule_callback -object_id $pid -action cron24
	ns_log Notice "im_rule_engine_cron24_sweeper: Finished sweeping object #$pid"
	incr cnt
    }

}



# ----------------------------------------------------------------------
# Callback Interfaces
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# After Update
#
#    Callback to be executed after the update of any project.
#    The callback checks if the fields of the underlying object have
#    changed since the last call and will apply the appropriate rule
#    heads.

ad_proc -callback im_project_after_update -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_project_after_update -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_update
    ns_log Notice "im_project_after_update -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_ticket_after_update -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_ticket_after_update -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_update
    ns_log Notice "im_ticket_after_update -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_timesheet_task_after_update -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_timesheet_task_after_update -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_update
    ns_log Notice "im_timesheet_task_after_update -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_invoice_after_update -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_invoice_after_update -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_update
    ns_log Notice "im_invoice_after_update -impl im_rule_engine: Leaving callback code"
}





# ---------------------------------------------------------------------
# After Create
#

ad_proc -callback im_project_after_create -impl im_rule_engine { -object_id -status_id -type_id } { } { 
    ns_log Notice "im_project_after_create -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_create
    ns_log Notice "im_project_after_create -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_ticket_after_create -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_ticket_after_create -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_create
    ns_log Notice "im_ticket_after_create -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_timesheet_task_after_create -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_timesheet_task_after_create -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_create
    ns_log Notice "im_timesheet_task_after_create -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_invoice_after_create -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_invoice_after_create -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action after_create
    ns_log Notice "im_invoice_after_create -impl im_rule_engine: Leaving callback code"
}


# ---------------------------------------------------------------------
# View
#

ad_proc -callback im_project_view -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_project_view -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action view
    ns_log Notice "im_project_view -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_ticket_view -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_ticket_view -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action view
    ns_log Notice "im_ticket_view -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_timesheet_task_view -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_timesheet_task_view -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action view
    ns_log Notice "im_timesheet_task_view -impl im_rule_engine: Leaving callback code"
}

ad_proc -callback im_invoice_view -impl im_rule_engine { -object_id -status_id -type_id } { } {
    ns_log Notice "im_invoice_view -impl im_rule_engine: Entering callback code"
    im_rule_callback -object_id $object_id -action view
    ns_log Notice "im_invoice_view -impl im_rule_engine: Leaving callback code"
}


