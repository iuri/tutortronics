-- /packages/intranet-task-management/sql/postgresql/intranet-task-management-create.sql
--
-- Copyright (c) 2016 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Component Plugin
--
-- Home page component showing the user tasks in all projects

SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,				-- context_id
	'Tasks for User',		-- plugin_name - shown in menu
	'intranet-task-management',	-- package_name
	'right',			-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_task_management_user_tasks', -- component_tcl
	'lang::message::lookup "" intranet-task-management.Tasks_for_User "Tasks for User"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Tasks for User' and package_name = 'intranet-task-management'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




-----------------------------------------------------------
-- Component Plugin
--
-- Project page component showing the tasks of all users

SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,	-- context_id
	'Tasks in Project',					-- plugin_name - shown in menu
	'intranet-task-management',				-- package_name
	'right',						-- location
	'/intranet/projects/view',				-- page_url
	null,							-- view_name
	10,							-- sort_order
	'im_task_management_project_tasks -project_id $project_id', -- component_tcl
	'lang::message::lookup "" intranet-task-management.Tasks_in_Projec "Tasks in Project"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Tasks in Project' and package_name = 'intranet-task-management'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-----------------------------------------------------------
-- Procedurs for determining the task progress status
--


create or replace function im_task_management_ticket_interval (integer) 
returns interval as $body$
DECLARE
	v_ticket_type_id	alias for $1;
BEGIN
	IF v_ticket_type_id in (select * from im_sub_categories(30122)) THEN return '1 minute'::interval; END IF; 	-- 1 minute for Nagios alerts
	IF v_ticket_type_id in (select * from im_sub_categories(30150)) THEN return '1 day'::interval; END IF;		-- 1 day for incident tickets
	IF v_ticket_type_id in (select * from im_sub_categories(30152)) THEN return '3 days'::interval; END IF;		-- 3 days for problem tickets
	IF v_ticket_type_id in (select * from im_sub_categories(30180)) THEN return '3 days'::interval; END IF;		-- 1 month for ideas
	return '1 week'::interval;
end;$body$ language 'plpgsql';



create or replace function im_task_management_color_code (integer) 
returns integer as $body$
DECLARE
	v_child_id			alias for $1;
	
	v_ticket_interval		interval;

	v_creation_date			timestamptz;
	v_project_status_id		integer;
	v_start_date			timestamptz;
	v_end_date			timestamptz;
	v_percent_completed		numeric;

	v_ticket_id			integer;
	v_ticket_status_id		integer;
	v_ticket_type_id		integer;
	v_ticket_alarm_date		timestamptz;
	v_ticket_customer_deadline	timestamptz;

	v_past_days			integer;
	v_future_days			integer;
	row				record;
	v_result			integer;
BEGIN
	select	o.creation_date,
		p.project_status_id, p.start_date, p.end_date, coalesce(p.percent_completed, 0.0),
		t.ticket_id, t.ticket_status_id, t.ticket_type_id, t.ticket_alarm_date, t.ticket_customer_deadline,
		im_task_management_ticket_interval(t.ticket_type_id)
	into	v_creation_date,
		v_project_status_id, v_start_date, v_end_date, v_percent_completed,
		v_ticket_id, v_ticket_status_id, v_ticket_type_id, v_ticket_alarm_date, v_ticket_customer_deadline,
		v_ticket_interval
	from	acs_objects o,
		im_projects p
		LEFT OUTER JOIN im_tickets t ON (p.project_id = t.ticket_id)
	where	o.object_id = p.project_id and
		p.project_id = v_child_id;

	----------------------------------------------
	-- Fix invalid data or return 5=undefined in case something important is missing
	IF v_start_date is null THEN return 5; END IF;							-- 5=undefined
	-- Ticket: fix end date if NULL
	IF v_end_date is null and v_ticket_id is not null THEN
		v_end_date = v_start_date + v_ticket_interval;
	END IF;


	----------------------------------------------
	-- 0=Not stated yet, determined by potential status_id or not start_date > now()
	-- There are no potential tickets, so we only check for project status
	IF v_project_status_id in (select * from im_sub_categories(71)) THEN return 0; END IF;
	IF v_start_date > now() THEN return 0; END IF;							-- still to be started

	-- 4=Finished, determined by closed status_id
	IF v_project_status_id in (select * from im_sub_categories(81)) THEN return 4; END IF;		-- closed project
	IF v_ticket_status_id in (select * from im_sub_categories(30001)) THEN return 4; END IF;	-- closed ticket
	IF v_percent_completed >= 99.9 THEN return 4; END IF;						-- done...

	-- 3=Late, determined by end_date < now()
	-- Requires that we check closed and potential projects before.
	IF v_end_date < now() THEN return 3; END IF;							-- late task
	IF v_ticket_alarm_date < now() THEN return 3; END IF;						-- late ticket
	IF v_ticket_customer_deadline < now() THEN return 3; END IF;					-- late ticket
	IF v_ticket_id is not null THEN
		IF v_creation_date + v_ticket_interval < now() THEN return 3; END IF; 			-- late ticket
	END IF;

	-- 1=Green Ongoing or 2=Yellow Ongoing: 
	-- Status open, start_date in the past and end_date in the future.
	IF 	v_start_date < now() and v_end_date > now() and (
		v_project_status_id in (select * from im_sub_categories(76))				-- open project/task
		OR v_ticket_status_id in (select * from im_sub_categories(30000)))			-- open ticket
	THEN 
		-- Count the working days spent vs. working days to work for the task
		v_past_days := 0;
		v_future_days := 0;
		FOR row IN 

			select working_days from im_absences_working_days_period_weekend_only(
				(v_start_date::date)::varchar, 
				(v_end_date::date)::varchar
			) f(working_days date)

		LOOP
			IF row.working_days <= now()::date
			THEN v_past_days := v_past_days + 1;
			ELSE v_future_days := v_future_days + 1;
			END IF;
		END LOOP;
		
		IF v_past_days + v_future_days = 0 THEN return 5; END IF;				-- undefined
		
		IF 100.0 * v_past_days / (v_past_days + v_future_days) > v_percent_completed
		THEN return 2;										-- yellow if trending late
		ELSE return 1;										-- green if trending in-time
		END IF;
	END IF;

	-- 5=Undefined, anything else is an error
	return 5;
end;$body$ language 'plpgsql';


-- Test cases
-- select working_days from im_absences_working_days_period_weekend_only('2016-08-01', '2016-09-01') f(working_days date);
-- select im_task_management_color_code(43384);
-- select im_task_management_color_code(39065);








-----------------------------------------------------------
-- New column for Task List view
--

alter table im_view_columns alter column column_name type text;

delete from im_view_columns where column_id = 91000;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91000,910,NULL,
'"<a href=http://www.project-open.net/en/package-intranet-task-management#task_status target=_blank>[im_gif help "Progress Status"]</a>"',
'[im_task_management_color_code_gif $progress_status_color_code]','im_task_management_color_code(t.task_id) as progress_status_color_code','',0,'');


