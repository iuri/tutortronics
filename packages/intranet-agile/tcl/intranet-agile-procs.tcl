# /packages/intranet-agile/tcl/intranet-agile.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Library for ]po[ specific agile functionality
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# States and Types
# ----------------------------------------------------------------------

# project types moved to intranet-core/tcl/intranet-project-procs.tcl
# ad_proc -public im_project_type_agile {} { return 88000 }
# ad_proc -public im_project_type_scrum {} { return 88010 }
# ad_proc -public im_project_type_kanban {} { return 88020 }

ad_proc -public im_agile_scrum_status_default {} { return 88100 }



# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_agile_id {} {
    Returns the package id of the intranet-agile module
} {
    return [util_memoize [list db_string im_package_agile_id "select package_id from apm_packages where package_key = 'intranet-agile'" -default 0]]
}

# ----------------------------------------------------------------------
# Agile States
# ---------------------------------------------------------------------

# 88000-88999  Agile Methodologies (1000)
# 88000-88099  Intranet Project Type extensions (100)
# 88100-88199  Intranet Agile SCRUM States (100)
# 88200-88299  Intranet Agile Kanban States (100)
# 88300-88999  still free


# ----------------------------------------------------------------------
# Agile Components
# ---------------------------------------------------------------------

ad_proc -public im_agile_project_component {
    -project_id
    -return_url
} {
    Returns a list of agile tasks associated to the current project
} {
    if {![im_project_has_type $project_id "Agile Project"]} { return "" }
    set params [list \
	[list project_id $project_id] \
	[list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-agile/lib/view-list-display"]
    return $result
}


ad_proc -public im_agile_task_board_component {
    -project_id
} {
    Shows an interactive task board with agile tasks
} {
    if {![im_project_has_type $project_id "Agile Project"]} { return "" }
    set params [list \
	[list project_id $project_id] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-agile/lib/task-board"]
    return $result
}


ad_proc -public im_agile_burn_down_component {
    -project_id
    {-diagram_width ""}
    {-diagram_height ""}
} {
    Returns a Sencha ExtJS component with a burn-down chart
} {
    # Check Sencha installation and project type
    if {![im_project_has_type $project_id "Agile Project"]} { return "" }
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    set params [list \
	[list project_id $project_id] \
	[list diagram_width $diagram_width] \
	[list diagram_height $diagram_height] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-agile/lib/burn-down-chart"]
    return $result
}



# ----------------------------------------------------------------------
# Projects with reference to this agile
# ---------------------------------------------------------------------

ad_proc -public im_agile_referencing_projects_component {
    -project_id
    -return_url
} {
    Returns a list of projects referencing to this agile
} {
    # Is this a "Software Agile" Project
    set agile_category [parameter::get -package_id [im_package_ganttproject_id] -parameter "AgileProjectType" -default "Software Agile"]
    if {![im_project_has_type $project_id $agile_category]} { return "" }
    
    set params [list \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-agile/www/referencing-projects"]
    return $result
}

