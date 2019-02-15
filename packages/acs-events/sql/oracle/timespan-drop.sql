-- packages/acs-events/sql/timespan-drop.sql
--
-- $Id: timespan-drop.sql,v 1.4 2015/12/04 13:50:03 cvs Exp $

drop package timespan;
drop index 	 timespans_idx;
drop table   timespans;

drop package time_interval;
drop table   time_intervals;

drop sequence timespan_seq;
