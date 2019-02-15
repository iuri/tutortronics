-- intranet-demo-date/sql/postgresql/intranet-demo-data-create.sql
--
-- Setup "Tigerpond" company


\i categories.sql
\i users-skills.sql



update im_employees 
set department_id = coalesce((select cost_center_id from im_cost_centers where cost_center_code = 'CoOpPrSA'), department_id)
where employee_id in (select person_id from persons where first_names = 'David' and last_name = 'Developer');

update im_employees 
set department_id = coalesce((select cost_center_id from im_cost_centers where cost_center_code = 'CoOpPrSD'), department_id)
where im_name_from_id(employee_id) = 'Daniel Damnfast';

