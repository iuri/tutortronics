-- /packages/intranet-project-scoring/sql/postgresql/intranet-project-scoring-create.sql
--
-- Copyright (c) 2015 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Add a numeric_weight field to survsimp_questions
-- for weighting the choices they made
create or replace function inline_0 ()
returns integer as $body$
declare
        v_count                 integer;
BEGIN
        select  count(*) into v_count
        from    user_tab_columns
        where   lower(table_name) = 'survsimp_questions' and
                lower(column_name) = 'numeric_weight';
        IF (v_count > 0) THEN return 1; END IF;

        alter table survsimp_questions
        add numeric_weight numeric default 1.0;

        return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


-----------------------------------------------------------
-- Component Plugin
--
-- Forum component on the ticket page itself

SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,
	'Ticket Scoring Matrix',	-- plugin_name - shown in menu
	'intranet-project-scoring',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_ticket_scoring_matrix -project_id $project_id -diagram_width 1000 -diagram_height 500',	-- component_tcl
	'lang::message::lookup "" "intranet-project-scoring.Ticket_Scoring_Matrix" "Ticket Scoring Matrix"'
);

SELECT acs_permission__grant_permission(
	(	select	plugin_id 
		from	im_component_plugins
		where	plugin_name = 'Ticket Scoring Matrix' and
			package_name = 'intranet-project-scoring'
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Scoring',		-- plugin_name - shown in menu
	'intranet-project-scoring',	-- package_name
	'left',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_project_scoring_component -project_id $project_id',	-- component_tcl
	'lang::message::lookup "" "intranet-project-scoring.Project_Scoring" "Project Scoring"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Project Scoring' and package_name = 'intranet-project-scoring'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-- Create a number of predefined score_* fields
create or replace function inline_0 ()
returns integer as $body$
declare
	row		RECORD;
	v_count		integer;
	v_sql		varchar;
	v_y_pos		integer;
BEGIN
	v_y_pos	:= 1000;
	FOR row IN
		select 'score_strategic' as field, 'numeric' as widget, 'Score: Strategic' as name UNION
		select 'score_revenue' as field, 'numeric' as widget, 'Score: Revenue' as name UNION

		select 'score_cost_work_days' as field, 'numeric' as widget, 'Score: Work Days' as name UNION
		select 'score_cost_risk' as field, 'numeric' as widget, 'Score: Risk' as name UNION
		select 'score_cost_change' as field, 'numeric' as widget, 'Score: Change Impact' as name UNION

		select 'score_customers' as field, 'numeric' as widget, 'Score: Customer Related Benefits' as name UNION
		select 'score_infrastructure' as field, 'numeric' as widget, 'Score: Infrastructure Related Benefits' as name UNION

		select 'score_finance_npv' as field, 'numeric' as widget, 'Financial Score: NPV' as name UNION
		select 'score_finance_cost' as field, 'numeric' as widget, 'Financial Score: Cost' as name UNION
		select 'score_finance_risk_weighted' as field, 'numeric' as widget, 'Financial Score: Risk' as name
	LOOP
		select	count(*) into v_count from user_tab_columns
		where	lower(table_name) = 'im_projects' and
			lower(column_name) = row.field;
		IF (v_count = 0) THEN
			v_sql = 'alter table im_projects add ' || row.field || ' numeric';
			EXECUTE v_sql;
		END IF;

		-- DynField - a float value defined as also_hard_coded_p in table im_projects
		PERFORM im_dynfield_attribute_new (
			'im_project', row.field, row.name, row.widget, 'float', 'f', v_y_pos, 't', 'im_projects'
		);

		v_y_pos := v_y_pos + 10;
	END LOOP;
	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


