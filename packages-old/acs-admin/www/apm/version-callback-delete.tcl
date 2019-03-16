ad_page_contract {

    @author Peter Marklund
    @creation-date 28 January 2003
    @cvs-id $Id: version-callback-delete.tcl,v 1.5 2015/12/04 13:49:56 cvs Exp $  
} {
    version_id:naturalnum,notnull    
    type:notnull
}

set package_key [apm_package_key_from_version_id $version_id]
apm_remove_callback_proc -type $type -package_key $package_key

ad_returnredirect "version-callbacks?version_id=$version_id"
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
