--
-- a mechanism for associating location (url) with a certain chunk of data.
--
-- @author Ben Adida (ben@openforce)
-- @version $Id: site-node-object-map-drop.sql,v 1.4 2015/12/04 13:49:25 cvs Exp $
--

drop function site_node_object_map__del (integer);
drop function site_node_object_map__new (integer,integer);
drop table site_node_object_mappings;
