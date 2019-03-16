# /packages/intranet-task-management/tcl/intranet-task-management-procs.tcl
#
# Copyright (c) 2016 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Task Management
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

# Distances of the major and minor elements of the task management widgets
ad_proc -public im_task_management_major_height {} { return 30 }
ad_proc -public im_task_management_minor_height {} { return 22 }
ad_proc -public im_task_management_major_offset {} { return 15 }
ad_proc -public im_task_management_minor_offset {} { return 5 }

ad_proc -public im_task_management_legend_width {} { return 130 }
ad_proc -public im_task_management_task_type_text_width {} { return 150 }


# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

ad_proc -public im_task_management_user_tasks {
    { -diagram_width 600 }
    { -diagram_height 200 }
} {
    Returns a Portlet with the user's tasks
} {
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    # Call the portlet page
    set params [list \
                    [list diagram_width $diagram_width] \
                    [list min_diagram_height $diagram_height] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-task-management/lib/user-tasks"]
    return [string trim $result]
}


ad_proc -public im_task_management_project_tasks {
    { -diagram_width 600 }
    { -diagram_height 300 }
    -project_id:required
} {
    Returns a Portlet with the user's tasks
} {
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    # Check permissions
    set current_user_id [auth::require_login]
    im_project_permissions $current_user_id $project_id view_p read_p write_p admin_p
    if {!$read_p} { return "" }

    # Call the portlet page
    set params [list \
                    [list project_id $project_id] \
                    [list diagram_width $diagram_width] \
                    [list min_diagram_height $diagram_height] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-task-management/lib/project-tasks"]
    return [string trim $result]
}


# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

ad_proc -public im_task_management_color_code_gif {
    {-size 16}
    progress_status
    { alt_text "" }
} {
    Returns a traffic light GIF in blue, green, yellow, red, grey or purple, 
    depending on the progress status 0..5
} {
    switch $progress_status {
	0 { 
	    set color "blue" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_blue_blurb "Not started yet"]
	}
	1 { 
	    set color "green" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_green_blurb "In process (OK)"]
	}
	2 { 
	    set color "yellow" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_yellow_blurb "In process (late)"]
	}
	3 { 
	    set color "red" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_red_blurb "Late"]
	}
	4 { 
	    set color "grey" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_grey_blurb "Finished"]
	}
	5 { 
	    set color "purple" 
	    set alt [lang::message::lookup "" intranet-task-management.Status_purple_blurb "Undefined"]
	}
	default { return "" }
    }

    set url "http://www.project-open.net/en/package-intranet-task-management#task_status"
    set border 0
    return "<a href='$url' target='_blank'><img src='/intranet-task-management/images/status_$color' title='$alt' alt='$alt' border=0 width=16 height=16></a>"
}

