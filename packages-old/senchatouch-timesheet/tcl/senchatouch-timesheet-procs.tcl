

ad_proc -public senchatouch_timesheet_home_component {} {
    Home component advertizing Mobile Timesheet
} {
    # Redirect mobile browsers to 
    set mobile_p [im_browser_is_mobile_p]
    set mobile_url [parameter::get_from_package_key -package_key "intranet-core" -parameter RedirectMobileBrowsersUrl -default "default"]
    if {"default" eq $mobile_url} {
	# Check if senchatouch-timesheet is installed
	set senchatouch_ts_sql "select count(*) from apm_enabled_package_versions where package_key = 'senchatouch-timesheet'"
	set senchatouch_ts_installed_p [util_memoize [list db_string senchatouch_installed_p $senchatouch_ts_sql -default 0]]
	if {$senchatouch_ts_installed_p} { set mobile_url "/senchatouch-timesheet" }
    }
    if {$mobile_p && ($mobile_url ne "")} {
	ad_returnredirect $mobile_url
    }

    return "

<table>
<tr valign=top>
<td>    
    <a href='/senchatouch-timesheet/'><img 
    src='/senchatouch-timesheet/resources/screenshot/mobile_timesheet.318x480.png'
    ></a>
</td>
<td>
    <h1>Experimental</h1>
    <p>
    <a href='/senchatouch-timesheet/'>\]po\[ Mobile Timesheet</a> 
    is a timesheet logging application for mobile devices
    (Android, iPhone, iPad...) written in HTML5 and available as 
    part of every \]po\[ server.
    We have included this application in 
    <nobr>\]project-open\[</nobr> V5.0 as a preview in order to 
    show you what is possible, while the mobile app may not yet be
    ready for production use.
    </p><p>
    We will continue to develop this mobile app and provide 
    you with a more mature system in the next release of \]po\[.
    </p><p>
    Please visit our
    <a href='http://www.project-open.com/en/tutorial-building-sencha-touch-applications'
    target='_blank'>Mobile HTML5 Development Tutorial</a>. 
    You can modify this app by editing the the files here on this server
    in ~projop/packages/senchatouch-timesheet/www/app.js
</td>
</tr>
</table>
"
}
