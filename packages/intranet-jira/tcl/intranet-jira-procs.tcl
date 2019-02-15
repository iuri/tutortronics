# /packages/intranet-jira/tcl/intranet-jira-procs.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_jira_resolution_type_fixed {} { return 89300 }


# ----------------------------------------------------------------------
# Check for new tickets from Jira
# ----------------------------------------------------------------------

ad_proc -public im_jira_import_sweeper { } {
    Check for new mail to be converted into tickets
} {
    ns_log Notice "im_jira_import_sweeper: Starting"

    set jira_host [parameter::get_from_package_key -package_key intranet-jira -parameter JiraHost -default ""]
    if {"" == [string trim $jira_host]} { return }

    set serverroot [acs_root_dir]
    set cmd "$serverroot/packages/intranet-jira/perl/import-jira.perl"
    ns_log Notice "im_jira_import_sweeper: cmd=$cmd"

    # Make sure that only one thread is working at a time
    if {[nsv_incr im_jira_import_sweeper sweeper_p] > 1} {
        nsv_incr im_jira_import_sweeper sweeper_p -1
        ns_log Notice "im_jira_import_sweeper: Aborting. There is another process running"
        return
    }
    set result ""
    if {[catch {
	set result [im_exec bash -c $cmd]
	ns_log Notice "im_jira_import_sweeper: Result: $result"	
    } err_msg]} {

	# Error during import-jira.perl execution
	ns_log Error "im_jira_import_sweeper: Error: $err_msg"

	# Send out a warning email
	set email [parameter::get_from_package_key -package_key "intranet-helpdesk" -parameter "HelpdeskOwner" -default ""]
	set email "fraber@fraber.de"
	set sender_email [im_parameter -package_id [ad_acs_kernel_id] SystemOwner "" [ad_system_owner]]
	set subject "Error Importing Jira Tickets"
	set message "Error executing: $cmd
Please search for 'Error:' in the text below.
No customer emails are lost, however the
offending ticket may get duplicated.
$err_msg"
	if [catch {
	    ns_sendmail $email $sender_email $subject $message
	} errmsg] {
	    ns_log Error "im_jira_import_sweeper: Error sending to \"$email\": $errmsg"
	}
    }

    nsv_incr im_jira_import_sweeper sweeper_p -1
}

