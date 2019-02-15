-- packages/acs-events/sql/postgresql/test/utest-drop.sql
--
-- Drop the unit test package
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id: utest-drop.sql,v 1.4 2015/12/04 13:50:03 cvs Exp $

-- For now, we require openacs4 installed.
select drop_package('ut_assert');




