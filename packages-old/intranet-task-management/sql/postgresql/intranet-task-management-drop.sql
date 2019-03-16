-- /packages/intranet-task-management/sql/postgresql/intranet-task-management-drop.sql
--
-- Copyright (c) 2016 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select  im_component_plugin__del_module('intranet-task-management');
select  im_menu__del_module('intranet-task-management');
