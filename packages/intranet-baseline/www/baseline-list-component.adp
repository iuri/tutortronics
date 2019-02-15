        <form action=/intranet-baseline/action method=POST>
	<%= [export_vars -form {return_url}] %>
	<table class="table_list_page">
	<thead>
	  <tr>
	    <td>&nbsp;</td>
	    <td><%= [lang::message::lookup "" intranet-baseline.Baselines_Baseline "Baseline"] %></td>
	    <td><%= [lang::message::lookup "" intranet-baseline.Baseline_Type "Type"] %></td>
	    <td><%= [lang::message::lookup "" intranet-baseline.Baseline_Status "Status"] %></td>
	    <td><%= [lang::message::lookup "" intranet-baseline.Baseline_Creation_Date "Creation Date"] %></td>
	  </tr>
	  </thead>
	  <tbody>
	  <multiple name="baselines">
	    <if @baselines.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><input type=checkbox name=baseline.@baselines.baseline_id@></td>
		<td><a href="@baselines.baselines_view_url;noquote@">@baselines.baseline_name@</a></td>
		<td>@baselines.baseline_type@</td>
		<td>@baselines.baseline_status@</td>
		<td>@baselines.baseline_creation_date_pretty@</td>
	    </tr>
	  </multiple>

<if @baselines:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan=2>
		<%= [lang::message::lookup "" intranet-baseline.No_Baselines_Available "No Baselines Available"] %>
	    </td>
	</tr>
</if>
	</tbody>
	<tfoot>
	<tr class="rowodd">
	    <td colspan=3 align=left>
		<select name=action>
			<option value=del_baselines><%= [lang::message::lookup "" intranet-baseline.Delete_Baselines "Delete Baselines"] %></option>
		</select>	
		<input type=submit value=Apply>
	    </td>
	</tr>
	</tfoot>
	</table>
	</form>	

<if @object_write@>
	<ul>
	<li><a href="@new_baseline_url;noquote@"
	><%= [lang::message::lookup "" intranet-baseline.Create_new_Baseline "Create a new Baseline"] %></a>
	</ul>
</if>

