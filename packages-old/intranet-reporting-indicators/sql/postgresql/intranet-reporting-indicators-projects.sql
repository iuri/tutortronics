-- indicators-projects.sql
	


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''New projects per month'',
		''new_project_per_month'',
		15110,
		15000,
''select count(*) from im_projects where parent_id is null and start_date > now()::date-30 and start_date <= now()::date'',
		0,
		300,
		5
	);

	update im_indicators set indicator_section_id = 15205
	where indicator_id = v_id;

	update im_reports set report_description = 
''Main projects (no subprojects) started in the last 30 days.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Late Projects'',
		''late_projects'',
		15110,
		15000,
		''select count(*)
from im_projects p
where p.parent_id is null and
p.project_status_id in (select * from im_sub_categories(76)) and
p.end_date < now()'',
		0,
		3,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of open projects with an end date earlier then now.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    
    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Open Projects'',
		''open_projects'',
		15110,
		15000,
		''select count(*)
from im_projects
where parent_id is null and
project_status_id = 76'',
		0,
		50,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of main projects with status ''''open''''.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Average Project Duration'',
		''project_duration'',
		15110,
		15000,
		''
select  round(avg(end_date::date - start_date::date),1) as duration
from    im_projects
where   project_status_id in (select * from im_sub_categories(76))
;'',
		0,
		30,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates the average duration (end_date - start_date) in days of all currently open projects.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    

-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=10, indicator_low_warn=20, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'new_project_per_month');




--------------------------------------------------------
-- Timeline indicators for the various dashboards
--------------------------------------------------------


SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Project Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet/projects/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_pm]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Project Indicators Timeline' and 
		page_url = '/intranet/projects/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);

SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Customer Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet/companies/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_customers]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Customer Indicators Timeline' and 
		page_url = '/intranet/companies/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);



SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Ticket Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet-helpdesk/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_helpdesk]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Ticket Indicators Timeline' and 
		page_url = '/intranet-helpdesk/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);


SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Timesheet Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet-timesheet2/hours/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_timesheet]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Timesheet Indicators Timeline' and 
		page_url = '/intranet-timesheet2/hours/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);


SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Absences Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet-timesheet2/absences/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_absences]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
select im_category_new (15260, 'Absences', 'Intranet Indicator Section');
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Absences Indicators Timeline' and 
		page_url = '/intranet-timesheet2/absences/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);






SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Users Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet/users/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_hr]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Users Indicators Timeline' and 
		page_url = '/intranet/users/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);



SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- system params
	'Conf Items Indicators Timeline',				-- plugin_name
	'intranet-reporting-indicators',			-- package_name
	'right',						-- location
	'/intranet-confdb/dashboard',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_confdb]',
	'lang::message::lookup "" intranet-reporting-dashboard.Indicators_Timeline "Indicators Timeline"'
);
select im_category_new (15265, 'Conf Items', 'Intranet Indicator Section');
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins 
	 where plugin_name = 'Conf Items Indicators Timeline' and 
		page_url = '/intranet-confdb/dashboard'
	),
	(select group_id from groups where group_name = 'Employees'), 
	'read'
);


