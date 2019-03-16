ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-09-04
    @cvs-id $Id: index.tcl,v 1.3 2015/11/23 20:02:19 cvs Exp $

} {
    {orderby "name"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set title "Selectors"
set context [list $title]
set return_url [ad_conn url]?[ad_conn query]


set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

lappend action_list "New SQL Selector" "[export_vars -base "new" { return_url }]" "Create a new SQL Selector"

list::create \
    -name selectors \
    -multirow selectors \
    -key selector_id \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions $action_list \
    -bulk_actions {
            "Del" "del-selector" "Delete checked items"
    } \
    -bulk_action_method GET \
    -bulk_action_export_vars { return_url } \
    -elements {
        short_name {
            display_col short_name
            label "Short Name"
            link_url_eval $selector_url
        }
        name {
            display_col name
            label "Pretty Name"
        }
        selector_type {
            display_col selector_type
            label "Type"
        }
        selector_status {
            display_col selector_status
            label "Status"
        }
 	object_type {
            display_col object_type
            label "Object Type"
        }
        objects {
            label "Results"
            hide_p 0
            display_eval { $num_results }
            link_url_eval $view_objects_url
        }
    } -filters {
	selector_id {}
	return_url {}
    }


db_multirow -extend { selector_url view_objects_url num_results } selectors selectors {

	select 
		s.*,
		im_category_from_id(s.selector_status_id) as selector_status,
		im_category_from_id(s.selector_type_id) as selector_type
	from 
		im_sql_selectors s
	order by 
		lower(name)
} {
    set selector_url [export_vars -base new { selector_id return_url}]
    set view_objects_url [export_vars -base view-results {selector_id return_url}]

    if {[catch {
	set num_results [db_string num_results "select count(*) from ($selector_sql) t"]
    } err_msg]} {
	set num_results "<pre>$err_msg</pre>"
    }

}

ad_return_template
