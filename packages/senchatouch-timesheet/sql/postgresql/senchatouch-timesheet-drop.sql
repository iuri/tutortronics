-- /packages/senchatouch-timesheet/sql/postgresql/senchatouch-timesheet-drop.sql
--
-- Copyright (c) 2013-2015 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



select  im_component_plugin__del_module('senchatouch-timesheet');
select  im_report__del_module('senchatouch-timesheet');
select  im_menu__del_module('senchatouch-timesheet');

