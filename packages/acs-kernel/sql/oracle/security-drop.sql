--
-- /packages/acs-kernel/sql/security-drop.sql
--
-- DDL statements to purge the Security data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-07-27
-- @cvs-id $Id: security-drop.sql,v 1.4 2015/12/04 13:49:24 cvs Exp $
--
drop package sec_session_property;

drop sequence sec_id_seq;
drop sequence sec_security_token_id_seq;
drop table sec_session_properties;
drop index sec_sessions_by_server;
drop table secret_tokens;
