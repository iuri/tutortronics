-- /package/intranet-sql-selectors/sql/postgresql/intranet-sql-selectors-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Selectors module
--
-- Defines:
--	im_sql_selectors			Selector biz object container
--	im_sql_selector_conditions		Selector lines

-- A selector basically is a SQL statement that selects
-- a set of object_ids for a specific object type.
-- Selectors serve in order to select users for sending
-- them email in CRM Mailing Campaigns, and they serve
-- as a support in generic reporting.
-- 
-- There are several ways to define a selector:
--
-- 1. sql_selector:
-- 	A plain SQL statement.
--	This statement can only be edited by an administrator
--	because of security issues.
--
-- 2. manual_list_selector:
--	Exlicitely enumerates a number of objects from the 
--	list of objects of another selector.
--	This list is edited manually.
--	lists are implemented using acs_rels.
--
-- 3. condition_selector:
--	Allows building a SQL statement using a number
--	of user-defined conditions based on object attributes.
--
-- However, we're implementing all three of these selector
-- types using a single object in order to minimize sql
-- DDL overhead:
-- 	- All types must produce an SQL statement at the
--	  end, so this is the "abstract" interface of the
--	  class.
--	- Permissions are handeled by the default OpenACS
--	  permission scheme



---------------------------------------------------------
-- Selectors
--

create table im_sql_selectors (
	selector_id		integer
				constraint im_sql_selectors_pk
				primary key
				constraint im_sql_selectors_id_fk
				references acs_objects on delete cascade,
	name			varchar(1000) not null
				constraint im_sql_selectors_name_un unique,
	short_name		varchar(1000) not null
				constraint im_sql_selectors_short_name_un unique,
	selector_status_id	integer
				constraint im_sql_selectors_status_nn
				not null
				constraint im_sql_selectors_status_fk
				references im_categories,
	selector_type_id	integer
				constraint im_sql_selectors_type_nn
				not null
				constraint im_sql_selectors_type_fk
				references im_categories,
	object_type		varchar(1000)
				constraint im_selectors_otype_fk
				references acs_object_types
				constraint im_selectors_otype_nn
				not null,
	selector_sql		text,
	description		text
);



-----------------------------------------------------------
-- Selector Conditions
--
-- ToDo: Fully Implement
--
-- - Selector conditions allow users to specify conditions on
--   objects. 
-- - Users don't need to be SysAdmins to specifiy
--   these conditions, because they are not directly exposed
--   to SQL.


create sequence im_sql_selector_conditions_seq start 1;
create table im_sql_selector_conditions (
	condition_id		integer
				constraint im_sql_selectors_conditions_pk
				primary key,
	selector_id		integer
				constraint  im_sql_selectors_conditions_selector_fk
				references im_sql_selectors,
	type			varchar(255)
				constraint im_sql_selectors_conditions_type_nn 
				not null,
	var_list		text
				constraint im_sql_selectors_conditions_var_list_nn 
				not null
);



---------------------------------------------------------
-- Selector Object
---------------------------------------------------------

-- Nothing spectactular, just to be able to use acs_rels
-- between projects and selectors and to add custom fields
-- later. We are not even going to use the permission
-- system right now.

-- begin

select acs_object_type__create_type (
	'im_sql_selector',	-- object_type
	'SQL Selector',		-- pretty_name
	'SQL Selectors',	-- pretty_plural
	'acs_object',		-- supertype
	'im_sql_selectors',	-- table_name
	'selector_id',		-- id_column
	'im_sql_selector',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_sql_selector.name'	-- name_method
);








-- Selector Status
INSERT INTO im_categories VALUES (11000,'Active',
'','Intranet SQL Selector Status','category','t','f');
INSERT INTO im_categories VALUES (11002,'Deleted',
'','Intranet SQL Selector Status','category','t','f');



INSERT INTO im_categories VALUES (11020,'Manual SQL Selector',
'Administrator can edit the SQL query',
'Intranet SQL Selector Type','category','t','f');

INSERT INTO im_categories VALUES (11022,'Manual List Selector',
'User can manually select members',
'Intranet SQL Selector Type','category','t','f');

INSERT INTO im_categories VALUES (11024,'Condition Selector',
'User can define selection conditions',
'Intranet SQL Selector Type','category','t','f');

-- reserved until 11099


-- Add links to edit im_sql_selectors objects...

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_sql_selector','view','/intranet-sql-selectors/view?selector_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_sql_selector','edit','/intranet-sql-selectors/new?selector_id=');



create or replace function im_sql_selector__new (
	integer,
	varchar,
	timestamptz,
	integer,
	varchar,
	integer,
	varchar,
	varchar,
	integer,
	integer,
	varchar,
	varchar,
	varchar
    ) 
returns integer as '
declare
	p_selector_id		alias for $1;		-- selector_id default null
	p_object_type		alias for $2;		-- object_type default im_sql_selector
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_name			alias for $7;		-- name
	p_short_name		alias for $8;		-- short_name
	p_selector_status_id	alias for $9;		-- selector_status_id
	p_selector_type_id	alias for $10;		-- selector_type_id default 700
	p_selector_object_type	alias for $11;		-- object_type
	p_selector_sql		alias for $12;		-- selector_sql
	p_description		alias for $13;		-- description

	v_selector_id		integer;
    begin
	v_selector_id := acs_object__new (
		p_selector_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_sql_selectors (
		selector_id,
		name,
		short_name,
		selector_status_id,
		selector_type_id,
		object_type,
		selector_sql
	) values (
		v_selector_id,
		p_name,
		p_short_name,
		p_selector_status_id,
		p_selector_type_id,
		p_selector_object_type,
		p_selector_sql
	);

	return v_selector_id;
end;' language 'plpgsql';


-- Delete a single selector (if we know its ID...)
create or replace function  im_sql_selector__delete (integer)
returns integer as '
declare
	p_selector_id alias for $1;	-- selector_id
begin
	-- Erase the im_sql_selector_condition associated with the id
	delete from 	im_sql_selector_conditions
	where		selector_id = p_selector_id;

	-- Erase the selector itself
	delete from 	im_sql_selectors
	where		selector_id = p_selector_id;

	-- Erase the Object 
	PERFORM acs_object__delete(p_selector_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_sql_selector__name (integer)
returns varchar as '
declare
	p_selector_id alias for $1;	-- selector_id
	v_name	varchar;
begin
	select	name
	into	v_name
	from	im_sql_selectors
	where	selector_id = p_selector_id;

	return v_name;
end;' language 'plpgsql';


------------------------------------------------------
-- Selectors <-> Element Map
--
-- Several elements may be associated with a single 
-- selector in a manual_list_selector.
-- This map is implemented using acs_rels.



------------------------------------------------------
-- Permissions and Privileges
--
-- Implemented using default OpenACS permissions




------------------------------------------------------
-- Views to Business Objects
--
-- all selectors that are not deleted (600) nor that have
-- been lost during creation (612).
create or replace view im_sql_selectors_active as 
select
	i.*
from 
	im_sql_selectors i
where
	i.selector_status_id not in (3712);


create or replace view im_sql_selector_type as 
select category_id as selector_type_id, category as selector_type
from im_categories 
where category_type = 'Intranet SQL Selector Type';

create or replace view im_sql_selector_status as 
select category_id as selector_status_id, category as selector_status
from im_categories 
where category_type = 'Intranet SQL Selector Status';


---------------------------------------------------------
-- Selector Menus
--
-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...
-- delete the intranet-payments menus because they are 
-- located below intranet-sql-selectors modules and would
-- cause a RI error.


select im_component_plugin__del_module('intranet-sql-selectors');
select im_menu__del_module('intranet-sql-selectors');

-- Setup the "Admin Selectors" menu
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,					-- menu_id
	''im_menu'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''intranet-sql-selectors'',		-- package_name
	''selectors_admin'',			-- label
	''Selectors'',				-- name
	''/intranet-sql-selectors/'',		-- url
	30,					-- sort_order
	v_admin_menu,				-- parent_menu_id
	null					-- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
