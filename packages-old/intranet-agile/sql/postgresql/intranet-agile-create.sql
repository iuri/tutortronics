-- /packages/intranet-agile/sql/postgresql/intranet-agile-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- --------------------------------------------------------
-- Agile Task - Agile Releationship
--
-- This relationship connects "Agile" projects with other 
-- "Agile Task" projects. The agile_status_id determines
-- the readyness for the task in the parent agile.
-- --------------------------------------------------------


create table im_agile_task_rels (
	rel_id		integer
			constraint im_agile_task_rels_rel_fk
			references acs_rels (rel_id)
			constraint im_agile_task_rels_rel_pk
			primary key,
	agile_status_id	integer not null
			constraint im_agile_task_rels_role_fk
			references im_categories,
	sort_order	integer
);

select acs_rel_type__create_type (
	'im_agile_task_rel',		-- relationship (object) name
	'Agile Task Rel',		-- pretty name
	'Agile Task Rel',		-- pretty plural
	'relationship',			-- supertype
	'im_agile_task_rels',		-- table_name
	'rel_id',			-- id_column
	'intranet-agile',		-- package_name
	'im_project',			-- object_type_one
	'member',			-- role_one
	0,				-- min_n_rels_one
	null,				-- max_n_rels_one
	'acs_object',			-- object_type_two
	'member',			-- role_two
	0,				-- min_n_rels_two
	null				-- max_n_rels_two
);


create or replace function im_agile_task_rel__new (
integer, varchar, integer, integer, integer, integer, varchar, integer, integer)
returns integer as $body$
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_agile_task_rel
	p_agile_id		alias for $3;
	p_task_id		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_agile_status_id	alias for $8;
	p_sort_order		alias for $9;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_agile_id,
		p_task_id,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_agile_task_rels (
		 rel_id, agile_status_id, sort_order
	) values (
		 v_rel_id, p_agile_status_id, p_sort_order
	);

	return v_rel_id;
end;$body$ language 'plpgsql';


create or replace function im_agile_task_rel__delete (integer)
returns integer as $body$
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_agile_task_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;$body$ language 'plpgsql';


create or replace function im_agile_task_rel__delete (integer, integer)
returns integer as $body$
DECLARE
	  p_object_id	 alias for $1;
	p_user_id	  alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_object_id
		and object_id_two = p_user_id;

	PERFORM im_agile_task_rel__delete(v_rel_id);
	return 0;
end;$body$ language 'plpgsql';




---------------------------------------------------------
-- Agile Components
--

-- Show the forum component in project page
--

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Agile Task List',			-- plugin_name
	'intranet-agile',		-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	30,				-- sort_order
	'im_agile_project_component -project_id $project_id -return_url $return_url',
	'lang::message::lookup "" intranet-agile.Agile_Tasks "Agile Tasks"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Agile Task List' and package_name = 'intranet-agile'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-- Task Board component
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Plain Task Board',		-- plugin_name
	'intranet-agile',		-- package_name
	'top',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order - top one of the "bottom" portlets
	'im_agile_task_board_component -project_id $project_id',
	'lang::message::lookup "" intranet-agile.Task_Board "Task Board"'
);


SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Plain Task Board' and package_name = 'intranet-agile'),
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
	'Burn Down Chart',		-- plugin_name
	'intranet-agile',		-- package_name
	'top',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	70,				-- sort_order
	'im_agile_burn_down_component -project_id $project_id',
	'lang::message::lookup "" intranet-agile.Burn_Down_Chart "Burn Down Chart"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Burn Down Chart' and package_name = 'intranet-agile'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



---------------------------------------------------------
-- Add category types
---------------------------------------------------------


-- 88000-88999  Agile Methodologies (1000)
-- 88000-88099  Intranet Project Type extensions (100)
-- 88100-88199  Intranet Agile SCRUM States (100)
-- 88200-88299  Intranet Agile Kanban States (100)
-- 88300-88999  still free

SELECT im_category_new(88000, 'Agile Project', 'Intranet Project Type',null);
SELECT im_category_new(88010, 'SCRUM Sprint', 'Intranet Project Type',null);
SELECT im_category_new(88020, 'Kanban', 'Intranet Project Type',null);

SELECT im_category_hierarchy_new(88010, 88000);
SELECT im_category_hierarchy_new(88020, 88000);

-- Define the category types with the states for each of the agile project types
update im_categories set 
	category_description = 'Project using an agile methodology'
where category_id = 88000;
update im_categories set 
	aux_string1 = 'Intranet Agile SCRUM States',
	category_description = 'Project using SCRUM agile methodology',
	sort_order = 10
where category_id = 88010;
update im_categories set 
	aux_string1 = 'Intranet Agile Kanban States',
	category_description = 'Project using Kanban agile methodology',
	sort_order = 20
where category_id = 88020;





-- 88100-88199  Intranet Agile SCRUM States (100)
SELECT im_category_new(88110, 'To Do', 'Intranet Agile SCRUM States', null);
SELECT im_category_new(88120, 'In Progress', 'Intranet Agile SCRUM States', null);
SELECT im_category_new(88170, 'Testing', 'Intranet Agile SCRUM States', null);
SELECT im_category_new(88180, 'Review', 'Intranet Agile SCRUM States', null);
SELECT im_category_new(88190, 'Done', 'Intranet Agile SCRUM States', null);
update im_categories set sort_order = (category_id - 88100) where category_id between 88100 and 88199;



-- 88200-88299  Intranet Agile Kanban States (100)
SELECT im_category_new(88210, 'To Do', 'Intranet Agile Kanban States', null);
SELECT im_category_new(88220, 'Analysis', 'Intranet Agile Kanban States', null);
SELECT im_category_new(88250, 'Development', 'Intranet Agile Kanban States', null);
SELECT im_category_new(88280, 'Testing', 'Intranet Agile Kanban States', null);
SELECT im_category_new(88290, 'Done', 'Intranet Agile Kanban States', null);
update im_categories set sort_order = (category_id - 88200) where category_id between 88200 and 88299;



create or replace view im_agile_scrum_status as
select category_id as status_id, category as status
from im_categories
where category_type = 'Intranet Agile SCRUM Status';

create or replace view im_agile_kanban_status as
select category_id as status_id, category as status
from im_categories
where category_type = 'Intranet Agile Kanban Status';



---------------------------------------------------------
-- DynField to mark agile tasks
---------------------------------------------------------

create or replace function inline_0 ()
returns integer as $body$
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_acs_attrib_id		integer;
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := 'agile_task_p';
	v_attrib_pretty := 'Agile Task';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		'im_project',
		v_attrib_name,
		'boolean',
		v_attrib_pretty,
		v_attrib_pretty,
		'im_projects',
		NULL, NULL, '0', '1',
		NULL, NULL, NULL
	);
	alter table im_projects add agile_task_p varchar(1);
	v_attrib_id := acs_object__new (
		 null,
		 'im_dynfield_attribute',
		 now(),
		 null, null, null
	);
	insert into im_dynfield_attributes
	(attribute_id, acs_attribute_id, widget_name, deprecated_p) values
	( v_attrib_id, v_acs_attrib_id, 'checkbox', 'f');

	insert into im_dynfield_type_attribute_map (
		 attribute_id, object_type_id, display_mode
	) values (
		v_attrib_id, 4599, 'edit'
	);

	return 0;
end;$body$ language 'plpgsql';
-- select inline_0 ();
-- drop function inline_0();
