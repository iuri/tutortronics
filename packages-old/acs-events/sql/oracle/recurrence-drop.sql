-- packages/acs-events/sql/recurrence-drop.sql
--
-- $Id: recurrence-drop.sql,v 1.4 2015/12/04 13:50:03 cvs Exp $

drop package recurrence;

drop table recurrences;
drop table recurrence_interval_types;

drop sequence recurrence_seq;
