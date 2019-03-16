ad_page_contract {
    Delete role.

    @author Lars Pind (lars@pinds.com)
    @creation-date Sep 2000
    @cvs-id $Id: role-delete.tcl,v 1.2 2015/11/19 20:18:57 cvs Exp $
} {
    workflow_key
    role_key
    {return_url "define?[export_vars -url { workflow_key}]"}
}

wf_delete_role \
	-workflow_key $workflow_key \
	-role_key $role_key

ad_returnredirect $return_url

