# /packages/intranet-task-management/www/index.tcl
#
# Copyright (C) 1998-2008 ]project-open[

ad_page_contract {
    Show tasks and their status for each user.
    @author frank.bergmann@project-open.com
} {
    { project_id:integer "" }
    { diagram_width "600" }
    { min_diagram_height "400" }
    { return_url "" }
}

set current_user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-task-management.Task_Management "Task Management"]
set context_bar [im_context_bar [list /intranet/projects/ $page_title $page_title]]

