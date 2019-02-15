ad_page_contract {
    Delete task.

    @author Lars Pind (lars@pinds.com)
    @creation-date Sep 2000
    @cvs-id $Id: task-delete.tcl,v 1.2 2015/11/19 20:18:57 cvs Exp $
} {
    workflow_key
    transition_key
    {return_url "define?[export_vars -url { workflow_key}]"}
}

wf_delete_transition \
	-workflow_key $workflow_key \
	-transition_key $transition_key

ad_returnredirect $return_url

