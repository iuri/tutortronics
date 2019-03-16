	<form action=/intranet-rule-engine/action method=POST>
	<%= [export_vars -form {return_url}] %>
	<table class="table_list_page">
	<thead>	  
	  <tr class="rowtitle">
	    <td><input type="checkbox" name="_dummy" onclick="acs_ListCheckAll('rule_log_id',this.checked)"></td>
	    <td><%= [lang::message::lookup "" intranet-rule-engine.Rule_Date "Date"] %></td>
	    <td><%= [lang::message::lookup "" intranet-rule-engine.Rule_Name "Name"] %></td>
	    <td><%= [lang::message::lookup "" intranet-rule-engine.Rule_Log_Source "Source"] %></td>
	    <td><%= [lang::message::lookup "" intranet-rule-engine.Rule_Statement "Statement"] %></td>
	    <td><%= [lang::message::lookup "" intranet-rule-engine.Rule_Message "Message"] %></td>
	  </tr>
	</thead>	  
	<tbody>
	  <multiple name="rule_logs">
	    <if @rule_logs.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><input type="checkbox" name="rule_log_id" id="rule_log_id.@rule_logs.rule_log_id@" value="@rule_logs.rule_log_id@"></td>
		<td>@rule_logs.rule_log_date_pretty@</td>
		<td><a href="@rule_url@">@rule_logs.rule_name@</a></td>
		<td>@rule_logs.rule_log_error_source@</td>
		<td>@rule_logs.rule_log_error_statement@</td>
		<td>@rule_logs.rule_log_error_message@</td>
	    </tr>
	  </multiple>

<if @rule_logs:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan="2">
		<%= [lang::message::lookup "" intranet-rule-engine.No_Rule_Logs_Available "No Rule Logs Available"] %>
	    </td>
	</tr>
</if>
	</tbody>
	<tfoot>
	<tr class="rowodd">
	    <td colspan="3" align="left">
		<select name=action>
			<option value=del_logs><%= [lang::message::lookup "" intranet-rule-engine.Delete_Logs "Delete Logs"] %></option>
		</select>	
		<input type="submit" value="<%= [lang::message::lookup "" intranet-core.Apply "Apply"] %>">
	    </td>
	</tr>
	</tfoot>
	</table>
	</form>	
