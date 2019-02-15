-- $Id: acs-sc-msg-types-drop.sql,v 1.4 2015/12/04 13:50:05 cvs Exp $

drop package acs_sc_msg_type;
drop table acs_sc_msg_type_elements;
drop table acs_sc_msg_types;


delete from acs_objects where object_type = 'acs_sc_msg_type';

begin
   acs_object_type.drop_type('acs_sc_msg_type');
end;
/
show errors



