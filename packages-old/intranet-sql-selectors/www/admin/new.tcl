# /packages/intranet-sql-selectors/www/new.tcl
#
ad_page_contract {
    Purpose: Create a new selctors or edit an existing selector
    @author frank.bergmann@selector-open.com
} {
    selector_id:optional,integer
    return_url:optional
    { short_name "" }
}

ad_proc -public var_contains_quotes { var } {
    if {[regexp {"} $var]} { return 1 }
    if {[regexp {'} $var]} { return 1 }
    return 0
}


set user_id [auth::require_login]
set required_field "<font color=red size=+1><B>*</B></font>"

if {(![info exists return_url] || $return_url eq "")} {
    set return_url "[im_url_stub]/intranet/admin/"
}


set page_title "[_ intranet-sql-selectors.One_Selector]"
set context_bar [im_context_bar [list /intranet-sql-selectors/ "[_ intranet-sql-selectors.Selectors]"]  $page_title]


# object types for the selector
#
set object_types [list [list "[_ intranet-sql-selectors.--_Please_select_--]" ""]]
lappend object_types [list "Person" "person"]
lappend object_types [list "Company" "im_company"]
lappend object_types [list "Project" "im_project"]
lappend object_types [list "Ticket" "im_ticket"]


     
# create form
#
set form_id "sql_selector"

template::form::create $form_id
template::form::section $form_id [_ intranet-sql-selectors.Selector_Base_Data]
template::element::create $form_id selector_id -widget "hidden"
template::element::create $form_id name -datatype text \
    -label "[_ intranet-sql-selectors.Name]" \
    -html {size 40} \
    -after_html [im_gif -translate_p 0 help [_ intranet-sql-selectors.Name_must_be_unique]]
template::element::create $form_id short_name -datatype text \
    -label "[_ intranet-sql-selectors.Short_Name]" \
    -html {size 40} \
    -after_html [im_gif -translate_p 0 help [_ intranet-sql-selectors.Short_name_must_be_unique]]
template::element::create $form_id selector_status_id -datatype integer \
    -label "[_ intranet-sql-selectors.Selector_Status]" \
    -widget "im_category_tree" \
    -custom {category_type "Intranet SQL Selector Status"}
template::element::create $form_id selector_type_id -datatype integer \
    -label "[_ intranet-sql-selectors.Selector_Type]" \
    -widget "im_category_tree" \
    -custom {category_type "Intranet SQL Selector Type"}
template::element::create $form_id object_type -datatype text \
    -label "[_ intranet-sql-selectors.Object_Type]" \
    -widget "select" \
    -options $object_types \
    -after_html "[im_gif -translate_p 0 help [_ intranet-sql-selectors.What_type_of_objects]]"
template::element::create $form_id description -optional -datatype text \
    -widget textarea \
    -label "[_ intranet-sql-selectors.Description]" \
    -html {rows 2 cols 80}
template::element::create $form_id selector_sql -optional -datatype text \
    -widget textarea \
    -label "[_ intranet-sql-selectors.Selector_SQL]" \
    -html {rows 30 cols 80}
template::element::create $form_id return_url -widget "hidden" -optional -datatype text


# Check if we are editing an already existing selector
#
set button_text "[_ intranet-sql-selectors.Save_Changes]"

if {[form is_request $form_id]} {
    if { ([info exists selector_id] && $selector_id ne "") } {

	# We are editing an already existing selector
	db_1row selectors_info_query { 
	    select
		s.*
	    from
		im_sql_selectors s
	    where 
		s.selector_id = :selector_id
	}
	set page_title "[_ intranet-sql-selectors.Edit_Selector]"
	set context_bar [im_context_bar [list /intranet-sql-selectors/ "[_ intranet-sql-selectors.Selectors]"] [list [export_vars -base /intranet-sql-selectors/view { selector_id}] "One selector"] $page_title]
	
	set button_text "[_ intranet-sql-selectors.Save_Changes]"
	    
    } else {
	
	# Setup a new selector
	set selector_id [im_new_object_id]
	set name ""
#	set short_name ""
	set selector_status_id ""
	set selector_type_id ""
	set object_type ""
	set description ""
	set selector_sql "select\n\tu.user_id\nfrom\n\tcc_users u\nwhere\n\tu.first_names like 'A%'\n"

	set page_title "[_ intranet-sql-selectors.New_Selector]"
	set context_bar [im_context_bar [list /intranet-sql-selectors/ "[_ intranet-sql-selectors.Selectors]"] $page_title]
	set button_text "[_ intranet-sql-selectors.New_Selector]"

    }	

    template::element::set_value $form_id selector_id $selector_id
    template::element::set_value $form_id name $name
    template::element::set_value $form_id short_name $short_name

    template::element::set_value $form_id selector_status_id $selector_status_id
    template::element::set_value $form_id selector_type_id $selector_type_id
    template::element::set_value $form_id selector_sql $selector_sql
    template::element::set_value $form_id object_type $object_type
    template::element::set_value $form_id description $description

    template::element::set_value $form_id return_url $return_url   
}

template::form::set_properties $form_id edit_buttons "[list [list "$button_text" ok]]"
 
if {[form is_submission $form_id]} {
    form get_values $form_id
    
    set n_error 0
    # check that no variable contains double or single quotes
    if {[var_contains_quotes $name]} { 
	template::element::set_error $form_id name "[_ intranet-sql-selectors.No_Quotes_Allowed]"
	incr n_error
    }
    if {[var_contains_quotes $short_name]} { 
	template::element::set_error $form_id short_name "[_ intranet-sql-selectors.No_Quotes_Allowed]"
	incr n_error
    }

    set name_exists [db_string name_exists "
	select 	count(*)
	from	im_sql_selectors
	where	name = :name
	        and selector_id <> :selector_id
    "]
    if { $name_exists > 0 } {
	incr n_error
	template::element::set_error $form_id name "[_ intranet-sql-selectors.Selector_name_already_exists]"
    }
	
    set short_name_exists [db_string short_name_exists "
	select 	count(*)
	from	im_sql_selectors
	where	upper(trim(short_name)) = upper(trim(:short_name))
	        and selector_id <> :selector_id
    "]
    if { $short_name_exists > 0 } {
	incr n_error
	template::element::set_error $form_id short_name "[_ intranet-sql-selectors.Selector_short_name_already_exists]"
    }

    # Make sure the selector short_name has a minimum length
    if { [string length $short_name] < 5} {
	incr n_error
	template::element::set_error $form_id short_name "[_ intranet-sql-selectors.Selector_short_name_too_short]
	   [_ intranet-sql-selectors.Please_use_a_different_value]"
    }
    
    if {$n_error >0} { return }
 
}
 
if {[form is_valid $form_id]} {
    
    # Double-Click protection: the selector Id was generated at the new.tcl page
    set id_count [db_string id_count "
	select count(*) 
	from im_sql_selectors 
	where selector_id = :selector_id
    "]
    if {0 == $id_count} {
	db_exec_plsql selector_insert {}
    }

    set selector_update_sql "
	update im_sql_selectors set
		name =			:name,
		short_name =		:short_name,
		selector_status_id =	:selector_status_id,
		selector_type_id =	:selector_type_id,
		object_type =		:object_type,
		selector_sql =		:selector_sql,
		description =		:description
	where
		selector_id = :selector_id
    "
    db_dml selector_update $selector_update_sql
    
    ad_returnredirect $return_url
    
}


