ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-09-04
    @cvs-id $Id: view-results.tcl,v 1.4 2015/11/23 20:02:19 cvs Exp $

} {
    selector_id:integer
    { return_url "/intranet-sql-selectors/" }
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set title "Selector Results"
set context [list $title]
set return_url [ad_conn url]?[ad_conn query]

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set rows [db_0or1row selector_info "
	select
		s.*,
		aot.*
	from 
		im_sql_selectors s,
		acs_object_types aot
	where 
		selector_id = :selector_id
		and s.object_type = aot.object_type
"]

if {!$rows} {
    ad_return_complaint 1 "No SQL Selector Found"
    return
}

set view_url [db_string view_url "select url from im_biz_object_urls where object_type = :object_type and url_type = 'view'" -default ""]
set edit_url [db_string view_url "select url from im_biz_object_urls where object_type = :object_type and url_type = 'edit'" -default ""]


# ------------------------------------------------------------------
# Display the list of all objects matching the selector
# ------------------------------------------------------------------

list::create \
    -name objects \
    -multirow objects \
    -key object_id \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -elements {
 	object_id {
            display_col object_id
            label "Oid"
            link_url_eval $view_object_url
        }
        object_name {
            display_col object_name
            label "Name"
            link_url_eval $view_object_url
        }
    }


set object_sql "
select 
	o.$id_column as object_id,
        acs_object__name(o.$id_column) as object_name,
	'asdf' as object_url
from 
	$table_name o
where
	o.$id_column in (
$selector_sql
	)
order by 
	o.$id_column
"

set ctr 0
db_multirow -extend { view_object_url edit_object_url } objects objects $object_sql {
    set oobject_url [export_vars -base new {object_id return_url}]

    set view_object_url "$view_url$object_id"
    set edit_object_url "$edit_url$object_id"

    incr ctr
}

