-- $Id: acs-sc-object-types-drop.sql,v 1.4 2015/12/04 13:50:06 cvs Exp $
begin
   delete from acs_objects where object_type ='acs_sc_implementation';
   acs_object_type.drop_type('acs_sc_implementation');

   delete from acs_objects where object_type ='acs_sc_operation';
   acs_object_type.drop_type('acs_sc_operation');
 
   delete from acs_objects where object_type ='acs_sc_contract';
   acs_object_type.drop_type('acs_sc_contract');   
end;
/
show errors

