# /packages/intranet-agile/www/add-tasks.tcl
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
    { filter_project_id "" }
    { filter_project_type_id "" }
    { filter_project_status_id "[im_project_status_open]" }
    { filter_ticket_type_id "" }
    { filter_ticket_status_id "[im_ticket_status_open]" }
    { filter_agile_status_id 1 }
    return_url
}

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Agile Manager) can do everything.
# The managers of the individual Agile Tasks can change 
# _their_ agile stati.

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"]
if {"" == $filter_project_id} { set filter_project_id $project_id }

# Make sure we start at the top-level of the project hierarchy
set filter_project_id [db_string filter_project_id "
	select	main_p.project_id
	from	im_projects p,
		im_projects main_p
	where	p.project_id = :filter_project_id and 
		main_p.tree_sortkey = tree_root_key(p.tree_sortkey)
"]


im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

if {"" != $filter_project_type_id && "" != $filter_ticket_type_id} {
    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-agile.Ticket_and_project_selected "
	You have selected both a project type and a ticket type.
    "]</b>"
}

# -------------------------------------------------------------
# Create the list of potential agile tasks to add

set bulk_actions_list [list]
lappend bulk_actions_list "Add Agile Tasks" "add-existing-tasks-2" "Add new agile tasks"

set elements {
        project_chk {
	    label "<input type=\"checkbox\"
			  name=\"_dummy\"
			  onclick=\"acs_ListCheckAll('project_list', this.checked)\"
			  title=\"Check/uncheck all rows\">"
	    display_template {
		@agile_tasks.project_chk;noquote@
	    }
	}
        object_type {
	    label ""
	    display_template {
		@agile_tasks.object_type_html;noquote@
	    }
	}
	parent_project_name {
	    display_col parent_project_name
	    label "Parent"
	    link_url_eval $parent_project_url
	}
	project_nr {
	    display_col project_nr
	    label "Nr"
	    link_url_eval $agile_project_url
	}
	project_name {
	    display_col project_name
	    label "Agile Task"
	    link_url_eval $agile_project_url
	}
    }

list::create \
    -name agile_tasks \
    -multirow agile_tasks \
    -key agile_task \
    -row_pretty_plural $page_title \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions { } \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  { project_id return_url } \
    -bulk_action_method GET \
    -elements $elements



# -------------------------------------------------------------
# Prepare the SQL Statement
# -------------------------------------------------------------

set project_agile_task_p_sql ""
if {[im_column_exists im_projects agile_task_p]} {
    set project_agile_task_p_sql "OR p.agile_task_p = 't'"
}

set criteria [list]
set task_criteria [list]
set ticket_criteria [list]

if {"" != $filter_project_status_id} {
    lappend task_criteria "t.project_status_id in ([join [im_sub_categories $filter_project_status_id] ","])"
}
if {"" != $filter_project_type_id} {
    lappend task_criteria "t.project_type_id in ([join [im_sub_categories $filter_project_type_id] ","])"
}

if {"" != $filter_ticket_status_id} {
    lappend ticket_criteria "tt.ticket_status_id in ([join [im_sub_categories $filter_ticket_status_id] ","])"
}
if {"" != $filter_ticket_type_id} {
    lappend ticket_criteria "tt.ticket_type_id in ([join [im_sub_categories $filter_ticket_type_id] ","])"
}

set agile_tasks_sql "
		select	task.project_id
		from	im_projects relp,
			im_projects task,
			acs_rels r,
			im_agile_task_rels ri
		where	relp.project_type_id in ([join [im_sub_categories [im_project_type_agile]] ","]) and
			r.object_id_one = relp.project_id and
			r.object_id_two = task.project_id and
			r.rel_id = ri.rel_id
"
switch $filter_agile_status_id {
    1 {
	# Not part of a agile project yet
	lappend criteria "p.project_id not in ($agile_tasks_sql)"
    }
    2 {
	# Already part of a agile project
	lappend criteria "p.project_id in ($agile_tasks_sql)"
    }
}

set where_clause [join $criteria " and\n            "]
if { $where_clause ne "" } {
    set where_clause " and $where_clause"
}

set task_where_clause [join $task_criteria " and\n            "]
if { $task_where_clause ne "" } {
    set task_where_clause " and $task_where_clause"
}

set ticket_where_clause [join $ticket_criteria " and\n            "]
if { $ticket_where_clause ne "" } {
    set ticket_where_clause " and $ticket_where_clause"
}




db_multirow -extend { object_type_html agile_project_url parent_project_url agile_status_template project_chk } agile_tasks select_agile_tasks "
	select distinct
		p.*,
		p.parent_id as parent_project_id,
		(select parent_p.project_name from im_projects parent_p where parent_p.project_id = p.parent_id) as parent_project_name,
		o.object_type,
		ot.pretty_name,
		ot.object_type_gif
 	from	acs_objects o,
		acs_object_types ot,
		im_projects p,
		im_projects main_p
	where	main_p.project_id = :filter_project_id and
		p.project_id = o.object_id and
		o.object_type = ot.object_type and
		((p.project_id in (
			select	t.project_id
			from	im_projects t,
				im_timesheet_tasks tt
			where	t.project_id = tt.task_id and
				t.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
				$task_where_clause

		)) OR (p.project_id in (
			select	t.project_id
			from	im_projects t,
				im_tickets tt
			where	t.project_id = tt.ticket_id and
				t.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
				$ticket_where_clause
		)))
		$where_clause
	order by project_name
" {
    set agile_project_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]
    set parent_project_url [export_vars -base "/intranet/projects/view?" {{project_id $parent_project_id} return_url}]

    set project_chk "<input type=\"checkbox\"
	name=\"task_id\"
	value=\"$project_id\"
	id=\"project_list,$project_id\">
    "

    set object_type_html [im_gif -translate_p 0 $object_type_gif $pretty_name]
}


# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set show_context_help_p 0
set parent_menu_id [im_menu_id_from_label "project"]
set menu_label "agile_tasks"
set sub_navbar_html [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 


set agile_status_options [list 1 "Not part of a agile project yet" 2 "Already part of a agile project" 3 "Both"]

set filter_project_options [db_list_of_lists filter_project_options "
select	project_name,
	project_id
from	(
	select	p.project_name,
		p.project_id
	from	im_projects p
	where	p.parent_id is null and
		p.project_status_id in (select * from im_sub_categories([im_project_status_open])) and
		p.project_type_id in (
			select * from im_sub_categories([im_project_type_gantt])
		UNION	select * from im_sub_categories([im_project_type_sla])
		)
    UNION
	select	p.project_name,
		p.project_id
	from	im_projects p
	where	p.project_id = :project_id
) t
order by project_name
"]


set left_navbar_html ""
append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
		[lang::message::lookup "" intranet-agile.Filter_Agile_Tasks "Filter Agile Tasks"]
        </div>
	<form action=add-existing-tasks method=GET>
	[export_vars -form {return_url project_id}]
	<table>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Add_Tasks_From_Project "Add Tasks From Project"]</td>
	<td>[im_select -ad_form_option_list_style_p 1 filter_project_id $filter_project_options $filter_project_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Agile_Status "Part of Agile Project?"]</td>
	<td>[im_select filter_agile_status_id $agile_status_options $filter_agile_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Project_Type "Project Type"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Project Type" filter_project_type_id $filter_project_type_id]</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Project_Status "Project Status"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Project Status" filter_project_status_id $filter_project_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Ticket_Type "Ticket Type"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Ticket Type" filter_ticket_type_id $filter_ticket_type_id]</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-agile.Ticket_Status "Ticket Status"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Ticket Status" filter_ticket_status_id $filter_ticket_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td colspan=2><input type=submit name='[lang::message::lookup "" intranet-agile.Select "Select"]'></td>
	</tr>
	</table>
	</form>
	<br>
      	</div>
	<hr/>
"
