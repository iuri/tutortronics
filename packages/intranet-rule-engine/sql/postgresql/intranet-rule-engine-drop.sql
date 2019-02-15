-- /package/intranet-rule-engine/sql/intranet-rule-engine-drop.sql
--
-- Copyright (c) 2003-2014 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-rule-engine');
select  im_menu__del_module('intranet-rule-engine');


-----------------------------------------------------------
-- Drop main structures info

-- Drop functions
drop function im_rule__name(integer);
drop function im_rule__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	text, varchar, integer, integer, text
);
drop function im_rule__delete(integer);


-- Drop the main table
drop table im_rule_logs;
drop table im_rules;


alter table im_biz_objects
drop column rule_engine_old_value;

drop sequence im_rule_log_seq;



-- Delete entries from acs_objects
delete from acs_objects where object_type = 'im_rule';


-----------------------------------------------------------
-- Drop Categories
--

drop view im_rule_status;
drop view im_rule_types;

delete from im_categories where category_type = 'Intranet Rule Status';
delete from im_categories where category_type = 'Intranet Rule Type';



-----------------------------------------------------------
-- Completely delete the object type from the
-- object system
--

delete from im_biz_object_urls where object_type = 'im_rule';
delete from acs_object_type_tables where object_type = 'im_rule';
SELECT acs_object_type__drop_type ('im_rule', 't');

