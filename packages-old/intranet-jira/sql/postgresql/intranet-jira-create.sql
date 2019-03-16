-- /packages/intranet-jira/sql/postgresql/intranet-jira-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Jira type and status.
-- Status acutally is not use, so we just define "active"

-- 89000-89999  Jira Integration (1000)
-- 89000-89099  Intranet Project Type extensions (100)
-- 89100-89199  Intranet Jira States (100)
-- 89200-89299  Intranet Jira Types (100)
-- 89300-89399  Intranet Jira Ticket Resolution Type (100)
-- 89300-89999  still free

SELECT im_category_new(89000, 'Jira Project', 'Intranet Project Type',null);
SELECT im_category_hierarchy_new(89000, 88000); -- Jira Project is-a Agile Project
update im_categories set
	aux_string1 = 'Intranet Agile SCRUM States',
	category_description = 'Import tasks from an external Atlassian Jira server. <br>
	Please set import parameters in Admin -> Parameters -> intranet-jira'
where category_id = 89000;

--
-- How is the Ticket closed?
SELECT im_category_new(89300, 'Fixed', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89310, 'Won''t Fix', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89320, 'Duplicate', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89330, 'Incomplete', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89340, 'Cannot Reproduce', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89350, 'Done', 'Intranet Ticket Resolution Type');
SELECT im_category_new(89360, 'Won''t Do', 'Intranet Ticket Resolution Type');


-----------------------------------------------------------
-- DynField Widgets
--

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_resolution_type', 'Ticket Resolution Type', 'Ticket Resolution Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Ticket Resolution Type"}}'
);

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_resolution_type_id', 'Resolution', 'ticket_resolution_type', 'integer', 'f');


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = 'im_tickets' and
		lower(column_name) = 'ticket_resolution_type_id';
	IF (v_count > 0) THEN return 1; END IF;

	alter table im_tickets
	add ticket_resolution_type_id integer
	constraint ticket_resolution_type_fk references im_categories;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = 'im_tickets' and
		lower(column_name) = 'jira_incident_id';
	IF (v_count > 0) THEN return 1; END IF;

	alter table im_tickets add jira_incident_id integer;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = 'im_projects' and
		lower(column_name) = 'jira_prefix';
	IF (v_count > 0) THEN return 1; END IF;

	alter table im_projects add jira_prefix text;
	alter table im_projects add jira_project_id integer;
	alter table im_projects add jira_project_key text;

	-- Create a dynfield attribute for the new field
	PERFORM im_dynfield_attribute_new ('im_project', 'jira_prefix', 'Jira Server', 'textbox_large', 'string', 'f');
	PERFORM im_dynfield_attribute_new ('im_project', 'jira_project_id', 'Jira Project ID', 'integer', 'integer', 'f');
	PERFORM im_dynfield_attribute_new ('im_project', 'jira_project_key', 'Jira Project Key', 'textbox_small', 'string', 'f');

	create unique index im_projects_jira_project_id_un on im_projects (jira_prefix, jira_project_id);
	create unique index im_projects_jira_project_key_un on im_projects (jira_prefix, jira_project_key);

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = 'im_form_topics' and
		lower(column_name) = 'jira_comment_id';
	IF (v_count > 0) THEN return 1; END IF;

	alter table im_forum_topics add jira_comment_id integer;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();

