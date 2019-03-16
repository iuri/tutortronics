--
-- Set the context ID of existing calendars to the package_id
--
-- @cvs-id $Id: upgrade-2.0d1-2.0b2.sql,v 1.5 2015/12/04 14:02:54 cvs Exp $
--


update acs_objects
set    context_id = package_id
from   calendars
where  calendar_id = object_id;
