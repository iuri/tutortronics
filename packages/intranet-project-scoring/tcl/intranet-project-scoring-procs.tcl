# /packages/intranet-project-scoring/tcl/intranet-project-scoring-procs.tcl
#
# Copyright (c) 2015 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_project_scoring_bla {} { return 30000 }


# ----------------------------------------------------------------------
# PackageID
# ----------------------------------------------------------------------

ad_proc -public im_package_project_scoring_id {} {
    Returns the package id of the intranet-project-scoring module
} {
    return [util_memoize im_package_helpdesk_id_helper]
}

ad_proc -private im_package_project_scoring_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-project-scoring'
    } -default 0]
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_ticket_scoring_matrix {
    -project_id:required
    {-diagram_width 400 }
    {-diagram_height 400 }
    {-diagram_caption "" }
} {
    Shows a 2x2 matrix for scoring tickets along various dimensions.
    The portlet appears in Ticket Containers only.
} {
    if {[im_security_alert_check_integer -location "im_project_scoring_component" -value $project_id]} { return }
    set project_type_id [util_memoize [list db_string project_type \
	"select project_type_id from im_projects where project_id = $project_id"]]
    if {![im_category_is_a $project_type_id [im_project_type_ticket_container]]} { return }


    # Sencha check and permissions
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    set params [list \
                    [list project_id $project_id] \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption]
    ]

    set result [ad_parse_template -params $params "/packages/intranet-project-scoring/lib/scoring-matrix"]
    return [string trim $result]
}



ad_proc -public im_project_scoring_component {
    -project_id:required
} {
    Shows a list of DynFields with links to the
    scoring SimpSurvs. Only for projects of type "Gantt".
} {
    if {[im_security_alert_check_integer -location "im_project_scoring_component" -value $project_id]} { return }
    set project_type_id [util_memoize [list db_string project_type "select project_type_id from im_projects where project_id = $project_id"]]
    if {![im_category_is_a $project_type_id [im_project_type_gantt]]} { return }

    set params [list \
                    [list project_id $project_id] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-project-scoring/lib/project-scoring"]
    return [string trim $result]
}



ad_proc -public im_project_scoring_score_survey {
    -response_id:required
} {
    Calculate a weighted score from a survey
} {
    set response_sql "
	select	sqc.numeric_value,
		sq.numeric_weight
	from	survsimp_surveys ss,
		survsimp_responses sr,
		survsimp_questions sq,
		survsimp_question_responses sqr,
		survsimp_question_choices sqc
	where	ss.survey_id = sr.survey_id and
		sqr.response_id = sr.response_id and
		sqr.question_id = sq.question_id and
		sqr.choice_id = sqc.choice_id and
		sqc.question_id = sq.question_id and
		sr.response_id = :response_id
    "
    set sum_numeric_value 0.0
    set sum_numeric_weight 0.0
    db_foreach score_survey $response_sql {
	set sum_numeric_value [expr {$sum_numeric_value + $numeric_value * $numeric_weight}]
	set sum_numeric_weight [expr {$sum_numeric_weight + $numeric_weight}]
    }

    if {0 == $sum_numeric_weight} { return 0.0 }
    set weighted_value [expr {$sum_numeric_value / $sum_numeric_weight}]
    return $weighted_value
}
