-- 5.0.2.3.4-5.0.2.3.5.sql

SELECT acs_log__debug('/packages/intranet-reporting-finance/sql/postgresql/upgrade/upgrade-5.0.2.3.4-5.0.2.3.5.sql','');



select im_menu__delete(
       (select menu_id from im_menus where label = 'reporting-finance-expenses-cube' and package_name = 'intranet-reporting-finance')
);




