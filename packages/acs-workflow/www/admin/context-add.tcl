ad_page_contract {
    Add new context.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 September 2000
    @cvs-id $Id: context-add.tcl,v 1.2 2015/11/18 14:37:05 cvs Exp $
} {
    {workflow_key ""}
    {return_url ""}
} -properties {
    context
    export_vars
}

set context [list "Add Context"]
set export_vars [export_vars -form {workflow_key return_url}]
ad_return_template
