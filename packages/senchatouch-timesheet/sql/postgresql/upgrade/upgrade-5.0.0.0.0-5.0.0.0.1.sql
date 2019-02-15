-- upgrade-5.0.0.0.0-5.0.0.0.1.sql
SELECT acs_log__debug('/packages/senchatouch-timesheet/sql/postgresql/upgrade/upgrade-5.0.0.0.0-5.0.0.0.1.sql','');


SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,
	'Mobile Timesheet',		-- plugin_name - shown in menu
	'senchatouch-timesheet',	-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	10,				-- sort_order
	'senchatouch_timesheet_home_component',	-- component_tcl
	'lang::message::lookup "" "senchatouch-timesheet.Mobile_Timesheet" "Mobile Timesheet"'
);

SELECT acs_permission__grant_permission(
	(select	plugin_id 
	from	im_component_plugins
	where	plugin_name = 'Mobile Timesheet' and 
		package_name = 'senchatouch-timesheet'
	), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
