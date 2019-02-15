--
-- A simple mail queue
--
-- @author <a href="mailto:eric@openforce.net">eric@openforce.net</a>
-- @version $Id: acs-mail-lite-drop.sql,v 1.4 2015/12/04 13:50:05 cvs Exp $
--

drop table acs_mail_lite_queue;
drop sequence acs_mail_lite_id_seq;
drop table acs_mail_lite_mail_log; 
drop table acs_mail_lite_bounce; 
drop table acs_mail_lite_bounce_notif;
