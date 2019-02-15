ad_page_contract {
    Schedules all -procs.tcl and xql files of a package to be watched.


    @author Peter Marklund
    @cvs-id $Id: package-watch.tcl,v 1.5 2015/12/04 13:49:56 cvs Exp $
} {
    package_key
    {return_url "index"}
} 

apm_watch_all_files $package_key

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
