<%
  # /packages/intranet-dynfield/www/layout-adp.adp
  # $Workfile: layout-adp.adp $ $Revision: 1.7 $ $Date: 2015/11/25 16:58:10 $
%>
<master src="master">

<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<p>
#intranet-dynfield.lt_This_is_the_list_of_a#
<ul>
<multiple name="attributes">
<li>@attributes.attribute_name@(@attributes.widget@)</li>
</multiple>
</ul>
#intranet-dynfield.lt_Remeber_to_also_add_the_core_attributes#
</p>

<p>
#intranet-dynfield.lt_If_you_dont_know_how_# <a href="/doc/acs-templating/tagref" target="_blank">#intranet-dynfield.documentation#</a>
#intranet-dynfield.and_look_at_the# <a href="/doc/acs-templating/demo/#form" target="_blank">#intranet-dynfield.examples#</a>
</p>

<formtemplate id="layout-adp"></formtemplate>


