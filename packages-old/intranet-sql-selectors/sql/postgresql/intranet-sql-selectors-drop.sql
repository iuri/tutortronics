-- /packages/intranet-sql-selectors/sql/oracle/intranet-sql-selectors-drop.sql
--
-- Copyright (C) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Cleanup SQL Selectors
--
create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select selector_id
        from im_sql_selectors
    loop
        im_sql_selector__delete(row.selector_id);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

delete from im_categories where category_type = 'Intranet SQL Selector Status';
delete from im_categories where category_type = 'Intranet SQL Selector Type';

select im_component_plugin__del_module('intranet-sql-selectors');
select im_menu__del_module('intranet-sql-selectors');


delete from im_biz_object_urls where object_type='im_sql_selector';
select acs_object_type__drop_type('im_sql_selector', 'f');
delete from acs_rels where object_id_two in (select selector_id from im_sql_selectors);
delete from im_sql_selector_conditions;
delete from im_sql_selectors;

-- drop sequence im_selectors_seq;
drop sequence im_sql_selector_conditions_seq;

drop table im_sql_selector_conditions;

-- drop table im_selectors_audit;
drop view im_sql_selectors_active;
drop table im_sql_selectors;


