ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-09-04
    @cvs-id $Id: index.tcl,v 1.6 2015/11/23 20:02:19 cvs Exp $

} {
    {orderby "name"}
    {filter_object_type "im_project"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set title "Selectors"
set context [list $title]
set return_url [ad_conn url]?[ad_conn query]
set current_user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name selectors \
    -multirow selectors \
    -key selector_id \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -bulk_action_method GET \
    -bulk_action_export_vars { return_url } \
    -elements {
        short_name {
            display_col short_name
            label "[lang::message::lookup {} intranet-sql-selectors.Selector_Name {Name}]"
            link_url_eval $selector_url
        }
        num_result_total {
            label "[lang::message::lookup {} intranet-sql-selectors.Total_Results {Total Results}]"
            hide_p 0
            display_eval { $num_results_total }
            link_url_eval $view_results_url
        }
        num_result_mine {
            label "[lang::message::lookup {} intranet-sql-selectors.My_Results {My Results}]"
            hide_p 0
            display_eval { $num_results_mine }
            link_url_eval $view_results_url
        }
    } -filters {
	selector_id {}
	return_url {}
    }


set ttt {
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
}


db_multirow -extend { selector_url view_results_url num_results_total num_results_mine } selectors selectors {
	select 
		s.*,
		im_category_from_id(s.selector_status_id) as selector_status,
		im_category_from_id(s.selector_type_id) as selector_type
	from 
		im_sql_selectors s
	where
		(s.object_type = :filter_object_type or :filter_object_type is NULL)
	order by 
		lower(name)
} {
    set selector_url [export_vars -base new {selector_id return_url}]
    set view_results_url [export_vars -base "/intranet-helpdesk/index" {{mine_p $short_name}}]

    if {[catch {
	set num_results_total [db_string num_results "
		select	count(*)
		from 	($selector_sql) t"]
    } err_msg]} {
	set num_results_total "<pre>$err_msg</pre>"
    }

    switch $object_type {
	im_ticket {
	    set mine_where "where ticket_id in (
		select	t.ticket_id
		from	im_tickets t
		where	
			t.ticket_assignee_id = :current_user_id 
			OR t.ticket_customer_contact_id = :current_user_id
			OR t.ticket_assignee_id in (
				select	group_id 
				from	acs_rels r, groups g
				where	r.object_id_one = g.group_id and 
					object_id_two = :current_user_id
			)
			OR t.ticket_queue_id in (
				select distinct
					g.group_id
				from	acs_rels r, groups g 
				where	r.object_id_one = g.group_id and
					r.object_id_two = :current_user_id
			) OR t.ticket_id in (
				-- cases with user as task_assignee
				select distinct wfc.object_id
				from	wf_task_assignments wfta,
					wf_tasks wft,
					wf_cases wfc
				where	wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id and
					wfta.task_id = wft.task_id and
					wfta.party_id in (
						select	group_id
						from	group_distinct_member_map
						where	member_id = :current_user_id
					    UNION
						select	:current_user_id
					)
			) OR t.ticket_id in (	
				-- cases with user as task holding_user
				select distinct wfc.object_id
				from	wf_tasks wft,
					wf_cases wfc
				where	wft.holding_user = :current_user_id and
					wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id
			)
	    )"
	}
	im_project {
	    set mine_where ""
	}
	user {
	    set mine_where ""
	}
	default {
	    ad_return_complaint 1 "Found a SQL selector with object_type=$object_type which is not yet supported"
	    ad_script_abort
	}
    }

    if {[catch {
	set num_results_mine [db_string num_results "
		select	count(*)
		from	($selector_sql) t
		$mine_where
	"]
    } err_msg]} {
	set num_results_mine "<pre>$err_msg</pre>"
    }

}


# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set letter ""
set menu_select_label ""
set next_page_url ""
set prev_page_url ""
set ticket_navbar_html [im_ticket_navbar $letter "/intranet-helpdesk/index" $next_page_url $prev_page_url [list start_idx order_by how_many view_name letter ticket_status_id] $menu_select_label]



# ---------------------------------------------------------------
# Left-Navbar
# ---------------------------------------------------------------

set dynamic_fields_p 1
set form_id "selector_filter"
set object_type "im_sql_selector"
set action_url "/intranet-sql-selectors/index"
set form_mode "edit"

set object_type_options {}
lappend object_type_options [list "" ""]
lappend object_type_options [list [lang::message::lookup "" intranet-sql-selectors.Object_Type_Tickets "Tickets"] "im_ticket"]
lappend object_type_options [list [lang::message::lookup "" intranet-sql-selectors.Object_Type_Projects "Projects"] "im_project"]
lappend object_type_options [list [lang::message::lookup "" intranet-sql-selectors.Object_Type_Projects "Users"] "user"]


ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method POST \
    -form {
    	{filter_object_type:text(select),optional {label "[lang::message::lookup {} intranet-sql-selectors.Object_Type {Object Type}]"} {options $object_type_options }}
    }

im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id 0 \
    -advanced_filter_p 1 \
    -search_p 1 \
    -page_url "/intranet-sql-selectors/index"


# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="selector_filter"></formtemplate>}]
set filter_html $__adp_output


set left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-sql-selectors.Filter_Selectors "Filter Selectors"]
		</div>
		$filter_html
	    </div>
	    <hr/>
"


if {$user_is_admin_p} {
    set admin_html "<ul><li><a href=\"[export_vars -base "/intranet-sql-selectors/admin/index"]\">[lang::message::lookup "" intranet-sql-selectors.Admin_Selectors "Admin Selectors"]</a></li></ul>"
    append left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-sql-selectors.Admin "Admin"]
		</div>
		$admin_html
	    </div>
	    <hr/>
    "
}



ad_return_template
