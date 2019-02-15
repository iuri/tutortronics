-- /package/intranet-forum/sql/intranet-helpdesk-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-jira');
select  im_menu__del_module('intranet-jira');

alter table im_forum_topics drop column jira_comment_id;

alter table im_projects drop column jira_prefix;
alter table im_projects drop column jira_project_id;
alter table im_projects drop column jira_project_key;

alter table im_tickets drop column ticket_resolution_type_id;
alter table im_tickets drop column jira_incident_id;


-- Create a dynfield attribute for the new field
SELECT	im_dynfield_attribute__delete(da.attribute_id)
from	im_dynfield_attributes da,
	acs_attributes aa
where	da.acs_attribute_id = aa.attribute_id and
	aa.attribute_name in ('jira_prefix', 'jira_project_id', 'jira_project_key', 'ticket_resolution_type_id');

SELECT	im_dynfield_widget__delete(widget_id)
from	im_dynfield_widgets
where	widget_name = 'ticket_resolution_type';



delete from im_category_hierarchy where parent_id in (89000) or child_id in (89000);
delete from im_categories where category_id in (89000);

delete from im_category_hierarchy 
where	parent_id in (89300, 89310, 89320, 89330, 89340, 89350, 89360) 
	or child_id in (89300, 89310, 89320, 89330, 89340, 89350, 89360);
delete from im_categories where category_id in (89300, 89310, 89320, 89330, 89340, 89350, 89360);

