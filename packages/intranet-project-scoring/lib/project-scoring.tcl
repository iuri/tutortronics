# /packages/intranet-project-scoring/lib/project-scoring.tcl
#
# Copyright (C) 2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# ----------------------------------------------------------------------
# Variables and Parameters
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#
# project_id:required
set org_project_id $project_id
set return_url [im_url_with_query]
set current_user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

# ----------------------------------------------------------------------
# Project info
# ---------------------------------------------------------------------

# Get everything about the project
db_1row project_info "
	select	*
	from	im_projects p,
		acs_objects o
	where	p.project_id = :org_project_id and
		o.object_id = p.project_id
"

# ----------------------------------------------------------------------
# Get the list of score related DynFields
# ---------------------------------------------------------------------

set score_dynfield_sql "
	select	aa.pretty_name,
		aa.attribute_name,
		ss.survey_id,
		(select count(*) from survsimp_responses sr 
		 where sr.survey_id = ss.survey_id and sr.related_object_id = :project_id and sr.related_context_id = :project_id
		) as response_count,
		(select min(response_id) from survsimp_responses sr 
		 where sr.survey_id = ss.survey_id and sr.related_object_id = :project_id and sr.related_context_id = :project_id
		) as response_id
	from	im_dynfield_attributes da,
		acs_attributes aa
		LEFT OUTER JOIN survsimp_surveys ss ON (aa.pretty_name = ss.name)
	where	da.acs_attribute_id = aa.attribute_id and
		da.widget_name = 'numeric' and
		aa.object_type = 'im_project' and
		aa.attribute_name like 'score_%'
	order by lower(aa.pretty_name), aa.sort_order
"

set table_body_html ""
db_foreach score_fields $score_dynfield_sql {

    # Evaluate the attribute name based on the project_info data
    set value ""
    catch {
	set value [set $attribute_name]
    } err_msg

    if {"" == $survey_id} {
	# Survey doesn't exist yet - show error message
	set survey_link [lang::message::lookup "" intranet-project-scoring.Survey_doesnt_exist "Survey '%pretty_name%' does not exist. "]
	if {$admin_p} {
	    set create_url_vars {{name $pretty_name} {description $pretty_name} {desc_html plain} {type general}}
	    set create_url [export_vars -base "/simple-survey/admin/survey-create" $create_url_vars]
	    append survey_link "&nbsp;<a href='$create_url'>Create Survey</a>"
	}

    } else {
	# Survey exists. Check if a value already exists or not
	switch $response_count {
	    0 {
		# No survey completed yet - create link for new survey
		set value [lang::message::lookup "" intranet-project-scoreing.No_score_yet "No score yet"]
		set new_survey_url [export_vars -base "/simple-survey/one" {return_url survey_id {related_object_id $project_id} {related_context_id $project_id}}]
		set survey_link "<a href='$new_survey_url'>[lang::message::lookup "" intranet-project-scoreing.Create_new_score "Create score"]</a>"
	    }
	    1 {
		# Summarize the value of the one survey and update the project
		set score [im_project_scoring_score_survey -response_id $response_id]
		if {$score != $value} {
		    set value $score
		    db_dml update_project_score "
			update im_projects
			set $attribute_name = :score
			where project_id = :project_id   			
		    "
		    im_audit -object_type im_project -action after_update -object_id $project_id -status_id $project_status_id -type_id $project_type_id
		}
		
		# link to the unique survey that created the value
		set edit_survey_url [export_vars -base "/simple-survey/one" {return_url survey_id response_id {related_object_id $project_id} {related_context_id $project_id}} ]
		set survey_link "<a href='$edit_survey_url'>[lang::message::lookup "" intranet-project-scoreing.Edit_score "Edit Score"]</a>"
	    }
	    default {
		set survey_link "[lang::message::lookup "" intranet-project-scoreing.Multiple_scores_error "Multiple scores - 
		                there exists more than one survey for this score"]"
	    }
	}
    }
    
    append table_body_html "
	<tr>
	<td>$pretty_name</td>
	<td>$value</td>
	<td>$survey_link</td>
	<!--<td>$err_msg</td>-->
	</tr>
    "
}



# ---------------------------------------------------------------
# Format the List Table Header
# ---------------------------------------------------------------

set table_header_html "<tr>"
append table_header_html "<td class=rowtitle>[lang::message::lookup "" intranet-project-scoring.Name Name]</td>\n"
append table_header_html "<td class=rowtitle>[lang::message::lookup "" intranet-project-scoring.Value Value]</td>\n"
append table_header_html "<td class=rowtitle>[lang::message::lookup "" intranet-project-scoring.Survey_Link "Survey Link"]</td>\n"
append table_header_html "</tr>"
