
# -------------------------------------------------------------
# intranet-agile/www/view-list-display.tcl
#
# (c) 2003-2007 ]project-open[
# All rights reserved
# Author: frank.bergmann@project-open.com
#
# Display component - this component is being used both by a 
# ]po[ "component" and by the normal list page.

# -------------------------------------------------------------
# Variables:
# project_id:integer
# return_url

set page_title [lang::message::lookup "" intranet-agile.Tasks "Tasks"]
set package_url "/intranet-agile"
set project_id $project_id
set return_url [im_url_with_query]
set add_task_url [export_vars -base "/intranet-agile/add-tasks" {project_id return_url}]

# -------------------------------------------------------------
# Permissions
#
# The project admin can do everything.
# The managers of the individual tasks can change _their_ agile states

set user_id [auth::require_login]
im_project_permissions $user_id $project_id view read write admin
set edit_all_tasks_p $write


# ------------------------------------------------------------
# Determine what agile state set to display

set project_type_id [db_string ptype_id "select project_type_id from im_projects where project_id = :project_id" -default 0]
set agile_category_type [db_string category_type_id "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
<<<<<<< HEAD


ns_log Notice "CAT TYPE $agile_category_type | $project_type_id ***"
=======
ns_log Notice "CAT TYPE $agile_category_type"
>>>>>>> 528929904d7e2ccb082474d1a1d5c38a081b0d3f
if {"" eq $agile_category_type} { 
    ad_return_complaint 1 "Could not determine default agile state range for project_type=[im_category_from_id $project_type_id]"
}


# -------------------------------------------------------------
# Create the list

set bulk_actions_list [list]
lappend bulk_actions_list "Save Status Changes" "$package_url/save-tasks" "Save status of tasks"
if {$edit_all_tasks_p} { lappend bulk_actions_list "Delete Checked Tasks" "$package_url/del-tasks" "Removed checked tasks" }

set elements {
	task_name {
	    display_col task_name
	    label "Task"
	    link_url_eval $agile_task_url
	}
	project_lead_id {
	    display_col project_lead_name
	    label "Project Manager"
	    link_url_eval $project_lead_url
	}
    }


set custom_cols [parameter::get_from_package_key -package_key "intranet-agile" -parameter "TaskCustomColumns" -default ""]
foreach col $custom_cols {
    set col_title [lang::message::lookup "" intranet-agile.[lang::util::suggest_key $col] $col]
    lappend elements $col
    lappend elements [list label $col_title ]
}

lappend elements agile_status 
lappend elements {
	    label "Agile Status"
	    display_template {
		@agile_tasks.agile_status_template;noquote@
	    }
	}

lappend elements sort_order 
lappend elements {
	    label "Ord"
	    display_template { @agile_tasks.sort_order_template;noquote@ }
	}

lappend elements task_chk 
lappend elements {
	    label "<input type=\"checkbox\"
			  name=\"_dummy\"
			  onclick=\"acs_ListCheckAll('task_list', this.checked)\"
			  title=\"Check/uncheck all rows\">"
	    display_template {
		@agile_tasks.task_chk;noquote@
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
    -bulk_action_export_vars  {
	project_id
	return_url
    } \
    -bulk_action_method GET \
    -elements $elements


set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_project'
"
db_foreach column_list_sql $column_sql {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]

db_multirow -extend { 
	agile_task_url 
	agile_status_template 
	task_chk 
	project_lead_url
	sort_order_template
} agile_tasks select_agile_tasks "
	select
		perm.admin_p,
		i.agile_status_id,
		im_category_from_id(i.agile_status_id) as agile_status,
		p.project_name as task_name,
		p.project_id as task_id,
		im_name_from_user_id(p.project_lead_id) as project_lead_name,
		p.*,
		i.sort_order,
		$extra_select
 	from
		im_projects p
		LEFT OUTER JOIN (
			select	count(*) as admin_p,
				r.object_id_one as project_id
			from	acs_rels r,
				im_biz_object_members m
			where	object_id_two = 624
				and m.rel_id = r.rel_id
				and m.object_role_id = 1301
			group by
				project_id
		) perm ON (p.project_id = perm.project_id),
		acs_rels r,
		im_agile_task_rels i
	where
		r.rel_id = i.rel_id
		and r.object_id_two = p.project_id
		and r.object_id_one = :project_id
	order by
		i.sort_order
" {
    set agile_task_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]

    set project_lead_url [export_vars -base "/intranet/users/view?" {{user_id $project_lead_id} return_url}]

    set agile_status_template $agile_status
    if {$edit_all_tasks_p || ("" != $admin_p && $admin_p)} {
	set agile_status_template [im_category_select $agile_category_type "agile_status_id.$task_id" $agile_status_id]
    }

    set task_chk "<input type=\"checkbox\"
	name=\"task_id\"
	value=\"$task_id\"
	id=\"task_list,$task_id\">
    "

#    set sort_order_template "
#	<nobr>
#	<a href=\"[export_vars -base "/intranet-agile/order-task" {{dir up} project_id project_id return_url} ]\">[im_gif arrow_comp_up]</a>
#	<a href=\"[export_vars -base "/intranet-agile/order-task" {{dir down} project_id project_id return_url} ]\">[im_gif arrow_comp_down]</a>
#	</nobr>
#    "

    set sort_order_template "
	<input type=text name=\"agile_sort_order.$task_id\" size=5 value=\"$sort_order\">
    "
}
