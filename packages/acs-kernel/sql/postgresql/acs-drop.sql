--
-- packages/acs-kernel/sql/acs-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id: acs-drop.sql,v 1.4 2015/12/04 13:49:25 cvs Exp $
--

drop view cc_users;
drop view registered_users;
\t
select drop_package('acs');
\t
drop table acs_magic_objects;
