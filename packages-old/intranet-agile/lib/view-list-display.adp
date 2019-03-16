
<listtemplate name="agile_tasks"></listtemplate>


<ul>
<li><a href="<%= [export_vars -base "/intranet-agile/add-existing-tasks" {project_id return_url}] %>"><%= [lang::message::lookup "" intranet-agile.Add_Existing_Task "Add Existing Task"] %></a></li>
<if @edit_all_tasks_p@>
<li><a href="<%= [export_vars -base "/intranet/admin/categories/index" {{select_category_type $agile_category_type} return_url}] %>"><%= [lang::message::lookup "" intranet-agile.Add_Existing_Task "Admin '$agile_category_type' category range"] %></a></li>
</if>
</ul>
