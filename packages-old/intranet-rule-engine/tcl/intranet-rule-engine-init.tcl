ad_library {

    Initialization for intranet-rule-engine module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 April, 2014
    @cvs-id $Id: intranet-rule-engine-init.tcl,v 1.3 2017/08/30 15:46:09 cvs Exp $
}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_rule_engine sweeper_p 0
nsv_set intranet_rule_engine cron24_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-rule-engine -parameter RuleEngineSweeperInterval -default 61] im_rule_engine_sweeper

# Run a sweeper once per day
ad_schedule_proc -thread t [expr 24*3600] im_rule_engine_cron24_sweeper

