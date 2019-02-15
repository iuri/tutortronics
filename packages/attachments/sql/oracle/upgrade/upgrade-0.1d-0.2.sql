--
-- upgrade attachments to include approved_p column
--
-- @author <a href="mailto:yon@openforce.net">yon@openforce.net</a>
-- @creation-date 2002-08-29
-- @version $Id: upgrade-0.1d-0.2.sql,v 1.3 2015/12/04 14:02:53 cvs Exp $
--

alter table attachments add (
    approved_p                      char(1)
                                    default 't'
                                    constraint attachments_approved_p_ck
                                    check (approved_p in ('t', 'f'))
                                    constraint attachments_approved_p_nn
                                    not null
);
