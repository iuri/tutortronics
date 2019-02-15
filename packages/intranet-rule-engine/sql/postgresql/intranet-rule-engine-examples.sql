
SELECT im_rule__new(
	null,
	'im_rule',
	now(),
		0,
	'127.0.0.1',
	null,

	'Task scheduled to start notification',
	'im_timesheet_task',
	85100,
	85000,
	'[db_string task_start_notification_cond "
select count(*) from im_timesheet_tasks t, im_projects p where
t.task_id = p.project_id and t.task_id = $new(task_id) and
not exists (select count(*) from im_rule_logs where rule_log_object_id = t.task_id and rule_log_error_source = ''task_start_notification'') and
p.start_date <= now() and p.end_date >= now()
"]'
);

update im_rules set
	rule_sort_order = 20,
	rule_action_tcl = 'insert into rule_logs (
	rule_log_object_id, rule_log_rule_id, rule_log_user_id, 
	rule_log_ip, rule_log_error_source, rule_log_error_statement, 
	rule_log_error_message, rule_log_error_env
) values (
	$new(task_id), $new(rule_id), $new(user_id), 
	''0.0.0.0'', ''task_start_notification'', ''-'', 
	''ok'', ''-'')',
	rule_action_email_to_tcl = 'db_list members "select email from parties where party_id in (select object_id_two from acs_rels where object_id_one = $new(task_id))"',
	rule_action_email_subject = 'Task $new(project_name) starts now',
	rule_action_email_body = 'Dear $first_names,

Your project or task: $new(project_name)
should start today.

For details please visit the link below:
[export_vars -base "$system_url/intranet/auto-login" {{user_id $user_id} {auto_login $auto_login} {url $object_url}}]

Best regards
$sender_first_names
',
	rule_description = 'Notifies task members that a task is scheduled to start'
where rule_name = 'Task scheduled to start notification';








SELECT im_rule__new(
	null,
	'im_rule',
	now(),
		0,
	'127.0.0.1',
	null,
	'Close a task that reaches 100% done',
	'im_timesheet_task',
	85100,
	85000,
	'$changed(percent_completed) && $new(percent_completed) == 100.0'
);

update im_rules set
	rule_sort_order = 10, 
	rule_action_tcl = 'db_dml close "update im_projects set project_status_id = 81 where project_id=$new(project_id)"',
	rule_action_email_to_tcl = 'db_list members "select email from parties where party_id in (select object_id_two from acs_rels where object_id_one = $new(project_id))"',
	rule_action_email_subject = 'Project/Task $new(project_name) has been closed',
	rule_action_email_body = 'Dear $first_names,

Your project or task: $new(project_name)
was marked as 100% done and has been set to status closed.

For details please visit the link below:
[export_vars -base "$system_url/intranet/auto-login" {{user_id $user_id} {auto_login $auto_login} {url $object_url}}]

Best regards
$sender_first_names',
	rule_description = 'Once a task reaches 100% completion, it is set to closed and an email is sent out to all users assigned to the task.
'
where rule_name = 'Close a task that reaches 100% done';


