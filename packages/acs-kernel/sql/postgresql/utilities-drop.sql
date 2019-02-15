--
-- /packages/acs-kernel/sql/utilities-drop.sql
--
-- Purges useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id $Id: utilities-drop.sql,v 1.4 2015/12/04 13:49:25 cvs Exp $
--
\t
select drop_package('util');
\t
