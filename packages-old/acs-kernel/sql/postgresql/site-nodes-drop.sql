--
-- packages/acs-kernel/sql/site-nodes-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-06
-- @cvs-id $Id: site-nodes-drop.sql,v 1.4 2015/12/04 13:49:25 cvs Exp $
--

\t
select drop_package('site_node');
drop table site_nodes;

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
  PERFORM acs_object_type__drop_type ('site_node');
  returns null;
END;
$$ LANGUAGE plpgsql;
select inline_0 ();
drop function inline_0 ();
\t
