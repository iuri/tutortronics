-- 
-- Upgrade script from 5.0d6 to 5.0d7
--
-- Adds auth_token to users table
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id: upgrade-5.0d6-5.0d7.sql,v 1.4 2015/12/04 13:49:25 cvs Exp $
--

alter table users add (auth_token varchar2(100));

