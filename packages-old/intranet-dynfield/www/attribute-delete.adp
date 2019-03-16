<master src="master">

<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>


#intranet-dynfield.Warning#!!!!!

@html_warning;no_quote@

<br/>
#intranet-dynfield.Do_you_want_continue#? <a href="?<%= [export_vars -url -override {{continue_p 1}} {return_url object_type continue_p attribute_ids}]%>"> #intranet-dynfield.Yes#</a>
								 <a href="@return_url@"> #intranet-dynfield.No#</a>