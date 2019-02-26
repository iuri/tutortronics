ad_page_contract {}


# Session timeout parameter is in seconds and JS code is in milliseconds. Thus, * 1000 is added in the formula.

set session_timeout [expr [expr [parameter::get -package_id [apm_package_id_from_key acs-kernel] -parameter "SessionTimeout" -default 1200] - 5] * 1000]
set session_timeout 5000

set alert_timeout [expr $session_timeout - 30000]
set alert_timeout 1000 
ns_log Notice "TIMEOUT $session_timeout"


template::head::add_css -href "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
template::head::add_css -href "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css"
