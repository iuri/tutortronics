ad_library {

    Initialization for intranet-jira module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 April, 2012
    @cvs-id $Id: intranet-jira-init.tcl,v 1.2 2015/09/02 14:21:33 cvs Exp $
}

# Initialize the sourceforge import "semaphore" to 0.
# There should be only one thread importing at a time...
nsv_set im_jira_import_sweeper sweeper_p 0

# Check for changed data every X seconds
set jira_interval [parameter::get_from_package_key -package_key intranet-jira -parameter JiraSweeperInterval -default 3601]
if {[string is integer $jira_interval] && $jira_interval > 0} {
    ad_schedule_proc -thread t $jira_interval im_jira_import_sweeper
}

