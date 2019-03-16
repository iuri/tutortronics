# /packages/intranet-sql-selectors/tcl/intranet-sql-selectors-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Selectors

    @author frank.bergann@project-open.com
}

# ---------------------------------------------------------------
# Stati and Types
# ---------------------------------------------------------------

# Frequently used Stati
ad_proc -public im_sql_selector_status_active {} { return 11000 }
ad_proc -public im_sql_selector_status_deleted {} { return 11002 }

# Frequently used Types
ad_proc -public im_sql_selector_type_sql {} { return 11020 }
ad_proc -public im_sql_selector_type_manual_list {} { return 11022 }
ad_proc -public im_sql_selector_type_conditions {} { return 11024 }


# -----------------------------------------------------------
# Package Routines
# -----------------------------------------------------------

ad_proc -public im_package_sql_selectors_id { } {
} {
    return [util_memoize [list im_package_sql_selectors_id_helper]]
}

ad_proc -private im_package_sql_selectors_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-sql-selectors'
    } -default 0]
}


# -----------------------------------------------------------
# Selectors & Options
# -----------------------------------------------------------

ad_proc -public im_selector_options {
    {-include_empty_p 1}
    {-status_id 0 }
    {-type_id 0 }
} {
    Returns a list of all selector tuples (name - id)
} {

    set selector_options_sql "
	select	short_name,
		selector_id
	from	im_sql_selectors
    "

    set options [db_list_of_lists selector_options $selector_options_sql]
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }
    return $options
}


ad_proc -public im_selector_select { 
    {-include_empty_p 1 }
    {-status_id 0}
    {-type_id 0}
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with the list of all avaiable selectors
} {
    set selector_options [im_selector_options \
		     -include_empty_p $include_empty_p \
		     -status_id $status_id \
		     -type_id $type_id \
		    ]

    set options ""
    foreach option $selector_options {
	set name [lindex $option 0]
	set id [lindex $option 1]
	set selected ""
	if {$id eq $default} {
	    set selected "selected=selected"
	}
	append options "<option value=\"$id\" $selected>$name</option>\n"
    }

    set select_box "<select name=\"$select_name\">\n$options\n</select>\n"
    return $select_box
}
