ad_page_contract {
    Shows a comparison of basic financial figures
    between the baseline and the current project
} {

}

# parameters from calling page:
# baseline_id

set date_format "YYYY-MM-DD"


db_1row baseline_current_info "
	select	p.project_id as main_project_id,
		p.project_budget as current_project_budget,
		p.project_budget_hours as current_budget_hours,
		to_char(p.start_date, :date_format) as current_start_date,
		to_char(p.end_date, :date_format) as current_end_date
	from	im_projects p,
		im_baselines b
	where	b.baseline_project_id = p.project_id and
		b.baseline_id = :baseline_id
"


db_1row baseline_baseline_info "
	select	im_audit_value_baseline(:main_project_id, 'project_budget', :baseline_id) as baseline_project_budget,
		im_audit_value_baseline(:main_project_id, 'project_budget_hours', :baseline_id) as baseline_budget_hours,
		im_audit_value_baseline(:main_project_id, 'start_date', :baseline_id) as baseline_start_date,
		im_audit_value_baseline(:main_project_id, 'end_date', :baseline_id)  as baseline_end_date
	from	dual
"

set undef [lang::message::lookup "" intranet-baseline.Undef "<undef>"]
if {"" == $baseline_project_budget} { set baseline_project_budget $undef }
if {"" == $current_project_budget} { set current_project_budget $undef }

if {"" == $baseline_budget_hours} { set baseline_budget_hours $undef }
if {"" == $current_budget_hours} { set current_budget_hours $undef }


