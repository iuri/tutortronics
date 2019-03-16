<% set page_title "V[string range [im_core_version] 0 5]" %>
<%= [im_header -loginpage $page_title] %>
<%= [im_navbar -loginpage_p 1] %>

<div id="slave">
<div id="fullwidth-list-no-side-bar" class="fullwidth-list-no-side-bar" style="visibility: visible;">

<table cellSpacing=2 cellPadding=2 width="100%" border="0">
<tr valign="top">
<td>

	<table cellSpacing=1 cellPadding=1 border="0">
	<tr><td class=tableheader><b>Login</b></td></tr></tr>
	<tr><td class=tablebody>
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">
	</td></tr>
	</table>
<td>
</tr>
</table>


<table cellSpacing=0 cellPadding=5 width="100%" border="0">
  <tr><td>
	<br><br><br>
	Comments? Contact: 
	<A href="mailto:support@project-open.com">support@project-open.com</A>
  </td></tr>
</table>


</div>
</div>

<%= [im_footer] %>
