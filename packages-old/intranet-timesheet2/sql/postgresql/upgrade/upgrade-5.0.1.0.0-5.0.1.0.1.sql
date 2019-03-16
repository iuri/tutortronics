-- upgrade-5.0.1.0.0-5.0.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2/sql/postgresql/upgrade/upgrade-5.0.1.0.0-5.0.1.0.1.sql','');

alter table im_hours add column creation_date timestamptz default now();





SELECT im_menu__new (
		null, 'im_menu', now(), null, null, null,
		'intranet-core',		-- package_name
		'timesheet_admin',		-- label
		'Timesheet Admin',		-- name
		'/intranet/admin/object-type-admin?object_type=im_hour',
		900,				-- sort_order
		(select menu_id from im_menus where label = 'timesheet2_timesheet'),
		null
);


SELECT im_menu__new (
		null, 'im_menu', now(), null, null, null,
		'intranet-core',		-- package_name
		'absences_admin',		-- label
		'Absences Admin',		-- name
		'/intranet/admin/object-type-admin?object_type=im_user_absence',	-- url
		900,				-- sort_order
		(select menu_id from im_menus where label = 'timesheet2_absences'),
		null
);


