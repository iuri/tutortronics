<if @show_master_p@>
<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">projects</property>
</if>

<style>
.fullwidth-list .component table.taskboard td {
     vertical-align:top;
}
</style> 

<table class="taskboard">
<tr>
@top_html;noquote@
</tr>
<if @task_count@ eq 0>
<tr><td colspan=99>
	<%= [lang::message::lookup "" intranet-agile.No_tasks_defined_yet "No tasks defined yet"] %>
</td></tr>
</if>
<tr>
@body_html;noquote@
</tr>
</table>


<ul>
<!-- 
<li><a href="<%= [export_vars -base "/intranet-agile/add-new-tasks" {project_id return_url}] %>"><%= [lang::message::lookup "" intranet-agile.Add_New_TaskTask "Add New Task"] %></a></li>
-->
<li><a href="<%= [export_vars -base "/intranet-agile/add-existing-tasks" {project_id return_url}] %>"><%= [lang::message::lookup "" intranet-agile.Add_Existing_Task "Add Existing Task"] %></a></li>
<if @admin_p@>
<li><a href="<%= [export_vars -base "/intranet/admin/categories/index" {{select_category_type $agile_category_type} return_url}] %>"><%= [lang::message::lookup "" intranet-agile.Add_Existing_Task "Admin '$agile_category_type' category range"] %></a></li>
</if>

</ul>
