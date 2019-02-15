ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id: unmap.tcl,v 1.2 2015/12/04 13:49:59 cvs Exp $

} {
    extension:notnull
    mime_type:notnull
    {return_url ""}
}

if { $return_url eq "" } {
    set return_url "index"
}

db_dml extension_unmap {}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
