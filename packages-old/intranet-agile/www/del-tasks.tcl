# /packages/intranet-agile/www/del-tasks.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new agile task to a project

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    task_id:integer,multiple
    return_url
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"]

im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

foreach pid $task_id {
    im_exec_dml del_agile_task "im_agile_task_rel__delete(:project_id, :pid)"
}

ad_returnredirect $return_url
