-- packages/acs-events/sql/activity-drop.sql
--
-- $Id: activity-drop.sql,v 1.4 2015/12/04 13:50:03 cvs Exp $

drop package acs_activity;
drop table   acs_activity_object_map;
drop table   acs_activities;

begin
    acs_object_type.drop_type ('acs_activity');
end;
/
show errors



