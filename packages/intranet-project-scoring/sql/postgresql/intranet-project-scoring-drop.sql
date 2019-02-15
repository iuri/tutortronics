-- /packages/intranet-project-scoring/sql/postgresql/intranet-project-scoring-drop.sql
--
-- Copyright (c) 2015 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-project-scoring');
select  im_menu__del_module('intranet-project-scoring');



-- Add a numeric_weight field to survsimp_questions
-- for weighting the choices they made
create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		 integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = 'survsimp_questions' and
		lower(column_name) = 'numeric_weight';
	IF (v_count = 0) THEN return 1; END IF;

	alter table survsimp_questions drop column numeric_weight;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


-- Create a number of predefined score_* fields
-- create or replace function inline_0 ()
-- returns integer as $body$
-- declare
-- 	row		RECORD;
-- 	v_count		integer;
-- 	v_sql		varchar;
-- 	v_attribute_id	integer;
-- BEGIN
-- 	FOR row IN
-- 		select 'score_strategic' as field, 'numeric' as widget, 'Score: Strategic' as name UNION
-- 		select 'score_strategic_alignment' as field, 'numeric' as widget, 'Score: Strategic' as name UNION
-- 		select 'score_revenue' as field, 'numeric' as widget, 'Score: Revenue' as name UNION
-- 		select 'score_cost_work_days' as field, 'numeric' as widget, 'Score: Work Days' as name UNION
-- 		select 'score_risk' as field, 'numeric' as widget, 'Score: Risk' as name UNION
-- 		select 'score_cost_risk' as field, 'numeric' as widget, 'Score: Risk' as name UNION
-- 		select 'score_cost_change' as field, 'numeric' as widget, 'Score: Change Impact' as name UNION
-- 		select 'score_cost_resources' as field, 'numeric' as widget, 'Score: Change Impact' as name UNION
-- 		select 'score_customers' as field, 'numeric' as widget, 'Score: Customer Related Benefits' as name UNION
-- 		select 'score_infrastructure' as field, 'numeric' as widget, 'Score: Infrastructure Related Benefits' as name UNION
-- 		select 'score_finance_npv' as field, 'numeric' as widget, 'Financial Score: NPV' as name UNION
-- 		select 'score_finance_cost' as field, 'numeric' as widget, 'Financial Score: Cost' as name UNION
-- 		select 'score_finance_risk_weighted' as field, 'numeric' as widget, 'Financial Score: Risk' as name
-- 	LOOP
-- 		select	count(*) into v_count from user_tab_columns
-- 		where	lower(table_name) = 'im_projects' and
-- 			lower(column_name) = row.field;
-- 		IF (v_count > 0) THEN
-- 			v_sql = 'alter table im_projects drop column ' || row.field;
-- 			EXECUTE v_sql;
-- 		END IF;
-- 
-- 		select attribute_id into v_attribute_id 
-- 		from im_dynfield_attributes 
-- 		where acs_attribute_id in (
-- 			select	attribute_id
-- 			from	acs_attributes
-- 			where	attribute_name = row.field and
-- 				object_type = 'im_project'
-- 		);
-- 
-- 		PERFORM im_dynfield_attribute__del (v_attribute_id);
-- 	END LOOP;
-- 	return 0;
-- end;$body$ language 'plpgsql';
-- select inline_0();
-- drop function inline_0();



