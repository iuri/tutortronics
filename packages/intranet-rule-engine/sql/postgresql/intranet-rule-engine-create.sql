-- /packages/intranet-rule-engine/sql/postgresql/intranet-rule-engine-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author various@project-open.com

-----------------------------------------------------------
-- Rules
--
-- A rule is a condition - action combination, where a change in an object 
-- attribute triggers the execution of a rule that has a matching
-- condition (=left hand side).


SELECT acs_object_type__create_type (
	'im_rule',			-- object_type - only lower case letters and "_"
	'Rule',				-- pretty_name - Human readable name
	'Rules',			-- pretty_plural - Human readable plural
	'acs_object',			-- supertype - "acs_object" is topmost object type.
	'im_rules',			-- table_name - where to store data for this object?
	'rule_id',			-- id_column - where to store object_id in the table?
	'intranet-rule-engine',		-- package_name - name of this package
	'f',				-- abstract_p - abstract class or not
	null,				-- type_extension_table
	'im_rule__name'			-- name_method - a PL/SQL procedure that
					-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_rule object.
update acs_object_types set
        status_type_table = 'im_rules',		-- which table contains the status_id field?
        status_column = 'rule_status_id',	-- which column contains the status_id field?
        type_column = 'rule_type_id'		-- which column contains the type_id field?
where object_type = 'im_rule';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_rule object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_rule', 'im_rules', 'rule_id');



-- Generic URLs to link to an object of type "im_rule".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_rule','view','/intranet-rule-engine/new?display_mode=display&rule_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_rule','edit','/intranet-rule-engine/new?display_mode=edit&rule_id=');


-- Add a column to biz_objects that saves the last value of the rule engine.
-- This way we can be sure to execute rules exactly ONCE if a value has changed.
alter table im_biz_objects add column rule_engine_old_value text;
alter table im_biz_objects add column rule_engine_last_modified timestamptz;


-- This table stores one object per row. Links to super-type "acs_object" 
-- using the "rule_id" field, which contains the same object_id as 
-- acs_objects.object_id.
create table im_rules (
					-- The object_id: references acs_objects.object_id.
					-- So we can lookup object metadata such as creation_date,
					-- object_type etc in acs_objects.
	rule_id				integer
					constraint im_rule_id_pk
					primary key
					constraint im_rule_id_fk
					references acs_objects,
					-- Short name of rule
	rule_object_type		varchar(100)
					constraint im_rule_object_type_nn
					not null
					constraint im_rule_object_type_fk
					references acs_object_types,
					-- Every ]po[ object should have a "status_id" to control
					-- its lifecycle. Status_id reference im_categories, where 
					-- you can define the list of stati for this object type.
	rule_status_id			integer 
					constraint im_rule_status_nn
					not null
					constraint im_rule_status_fk
					references im_categories,
					-- Every ]po[ object should have a "type_id" to allow creating
					-- sub-types of the object. Type_id references im_categories
					-- where you can define the list of subtypes per object type.
	rule_type_id			integer 
					constraint im_rule_type_nn
					not null
					constraint im_rule_type_fk
					references im_categories,
					-- Is the rule invoked after the creation or after the update of
					-- an object?
	rule_invocation_type_id		integer default 85200
					constraint im_rule_invocation_type_nn
					not null
					constraint im_rule_invocation_type_fk
					references im_categories,
					-- Short name of rule
	rule_name			text
					constraint im_rule_rule_nn
					not null,
	rule_sort_order			integer 
					default(0),				
					-- Description for rule
	rule_description		text,
					-- Condition = Left Hand Side of the rule - a TCL expression returning 0 or 1
	rule_condition_tcl		text
					constraint im_rule_rule_nn
					not null,
					-- TCL expression for action = right hand side
	rule_action_tcl			text,
					-- TCL expression returning a list of email addresses
	rule_action_email_to_tcl	text,
					-- Text with %varname% substitution
	rule_action_email_subject	text,
					-- Text with %varname% substitution
	rule_action_email_body		text
					-- There may be additional fields for actions to be performed on rule firing
);

-- Speed up (frequent) queries to find all rules for a specific object.
create index im_rules_object_idx on im_rules(rule_object_type);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Rule" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_rules_object_rule_idx on im_rules(rule_object_type, lower(trim(rule_name)));





create sequence im_rule_log_seq start 1;

-- Store for rule error messages and results
create table im_rule_logs (
	rule_log_id			integer
					default(nextval('im_rule_log_seq'))
					constraint im_rule_log_id_pk
					primary key,
					-- Offending object
	rule_log_object_id		integer
					constraint im_rule_log_object_id_nn
					not null
					constraint im_rule_log_object_id_fk
					references acs_objects,
					-- Short name of rule
	rule_log_rule_id		integer
					constraint im_rule_log_rule_id_nn
					not null
					constraint im_rule_log_rule_id_fk
					references im_rules,
	rule_log_date			timestamptz
					constraint rule_log_date_nn
					not null
					default now(),
	rule_log_user_id		integer
					constraint im_rule_log_user_id_fk
					references persons,
	rule_log_ip			varchar(100)
					constraint im_rule_log_ip_nn
					not null,
	rule_log_error_source		text
					constraint im_rule_log_error_source_nn
					not null,
					-- A copy of the offending statement.
					-- The rule may be modified afterwards...
	rule_log_error_statement	text
					constraint im_rule_log_error_statement_nn
					not null,
	rule_log_error_message		text
					constraint im_rule_log_error_message_nn
					not null,
					-- Variable environment of the error_statement
	rule_log_error_env		text
					constraint im_rule_log_error_env_nn
					not null
);

-- Speed up (frequent) queries to find all logs for a specific object.
create index im_rules_log_object_idx on im_rule_logs(rule_log_object_id);

-- Avoid duplicate entries.
create unique index im_rule_logs_object_date_idx on im_rule_logs(rule_log_object_id, rule_log_rule_id, rule_log_date);




-----------------------------------------------------------
-- PL/SQL functions to Create and Delete rules and to get
-- the name of a specific rule.
--
create or replace function im_rule__name(integer)
returns varchar as $body$
DECLARE
	p_rule_id		alias for $1;
	v_name			varchar;
BEGIN
	select	rule_name into v_name
	from	im_rules where rule_id = p_rule_id;
	return v_name;
end; $body$ language 'plpgsql';


-- Create a new rule.
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a rule with
-- the required fields of the im_rules table.
create or replace function im_rule__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	text, varchar, integer, integer, text
) returns integer as $body$
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_rule_id		alias for $1;		-- rule_id  default null
	p_object_type   	alias for $2;		-- object_type default im_rule
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_rules table
	p_rule_name		alias for $7;		-- im_rules.rule_name - short name
	p_rule_object_type	alias for $8;		-- associated object type (im_project, person, ...)
	p_rule_type_id		alias for $9;		-- type (email, http, text comment, ...)
	p_rule_status_id 	alias for $10;		-- status ("active" or "deleted").
	p_rule_condition_tcl	alias for $11;		-- TCL expression returning 1 for firing

	-- This is a variable for the PL/SQL function
	v_rule_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the rule.
	-- acs_object__new returns the object_id of the new object.
	v_rule_id := acs_object__new (
		p_rule_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_rule"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		't'			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_rules table with the same v_rule_id from acs_objects.object_id
	insert into im_rules (
		rule_id, rule_object_type, rule_type_id, rule_status_id, rule_condition_tcl, rule_name
	) values (
		v_rule_id, p_rule_object_type, p_rule_type_id, p_rule_status_id, p_rule_condition_tcl, p_rule_name
	);

	return v_rule_id;
END;$body$ language 'plpgsql';


-- Delete a rule from the system.
create or replace function im_rule__delete(integer)
returns integer as $body$
DECLARE
	p_rule_id		alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_rules
	where	rule_id = p_rule_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_rule_id);

	return 0;
end;$body$ language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for Rule type and status.
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--

-- 85000-85999  Rule Engine (1000)
-- 85000-85099	Intranet Rule Status
-- 85100-85199	Intranet Rule Type
-- 85200-85299	Intranet Rule Invocation Type


-- Status
SELECT im_category_new (85000, 'Active', 'Intranet Rule Status');
SELECT im_category_new (85002, 'Deleted', 'Intranet Rule Status');

-- Type
SELECT im_category_new (85100, 'TCL Rule', 'Intranet Rule Type');
SELECT im_category_new (85102, 'Email Rule', 'Intranet Rule Type');

-- Invocation Type
SELECT im_category_new (85200, 'After Update', 'Intranet Rule Invocation Type');
SELECT im_category_new (85202, 'After Creation', 'Intranet Rule Invocation Type');
SELECT im_category_new (85204, 'Cron24', 'Intranet Rule Invocation Type');




-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_rule_status as
select	category_id as rule_status_id, category as rule_status
from	im_categories
where	category_type = 'Intranet Rule Status'
	and enabled_p = 't';

create or replace view im_rule_types as
select	category_id as rule_type_id, category as rule_type
from	im_categories
where	category_type = 'Intranet Rule Type'
	and enabled_p = 't';

create or replace view im_rule_invocation_types as
select	category_id as rule_invocation_type_id, category as rule_invocation_type
from	im_categories
where	category_type = 'Intranet Rule Invocation Type'
	and enabled_p = 't';



-----------------------------------------------------------
-- Portlets
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system.


-- Create a Rule plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Project Rule Audit',			-- plugin_name
	'intranet-rule-engine',			-- package_name
	'left',					-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	900,					-- sort_order
	'im_rule_audit_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-rule-engine.Project_Rule_Audit "Project Rule Audit"'
where plugin_name = 'Project Rule Audit';



-- Create a Rule plugin for the TicketViewPage.
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Ticket Rule Audit',			-- plugin_name
	'intranet-rule-engine',			-- package_name
	'left',					-- location
	'/intranet-helpdesk/new',		-- page_url
	null,					-- view_name
	900,					-- sort_order
	'im_rule_audit_component -object_id $ticket_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-rule-engine.Ticket_Rule_Audit "Ticket Rule Audit"'
where plugin_name = 'Ticket Rule Audit';


-- Create a Rule plugin for the GanttTaskViewPage.
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Gantt Task Rule Audit',		-- plugin_name
	'intranet-rule-engine',			-- package_name
	'left',					-- location
	'/intranet-timesheet2-tasks/new',	-- page_url
	null,					-- view_name
	900,					-- sort_order
	'im_rule_audit_component -object_id $task_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-rule-engine.Timesheet_Task_Rule_Audit "Gantt Task Rule Audit"'
where plugin_name = 'Gantt Task Rule Audit';



-- Create a rules plugin for the CompanyViewPage
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Company Rule Audit',			-- plugin_name
	'intranet-rule-engine',			-- package_name
	'left',					-- location
	'/intranet/companies/view',		-- page_url
	null,					-- view_name
	900,					-- sort_order
	'im_rule_audit_component -object_id $company_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-rule-engine.Company_Rule_Audit "Company Rule Audit"'
where plugin_name = 'Company Rule Audit';



-- Create a rules plugin for the UserViewPage
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'User Rule Audit',			-- plugin_name
	'intranet-rule-engine',			-- package_name
	'left',					-- location
	'/intranet/users/view',			-- page_url
	null,					-- view_name
	900,					-- sort_order
	'im_rule_audit_component -object_id $user_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-rule-engine.User_Rule_Audit "User Rule Audit"'
where plugin_name = 'User Rule Audit';



-----------------------------------------------------------
-- Menu for Rules
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.


create or replace function inline_0 ()
returns integer as $body$
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;

BEGIN
	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_admin_menu from im_menus where label='admin';

	-- Create the menu.
	v_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-rule-engine',		-- package_name
		'rules',			-- label
		'Rule Engine',			-- name
		'/intranet-rule-engine/',	-- url
		95,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	return 0;
end; $body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- Source example rules
\i intranet-rule-engine-examples.sql

