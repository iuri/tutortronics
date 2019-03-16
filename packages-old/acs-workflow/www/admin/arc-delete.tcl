ad_page_contract {
    delete an arc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 1 October 2000
    @cvs-id $Id: arc-delete.tcl,v 1.2 2015/11/19 20:18:57 cvs Exp $
} {
    workflow_key
    transition_key
    place_key
    direction
    {return_url "define?[export_vars -url { workflow_key transition_key}]"}
}

wf_delete_arc \
	-workflow_key $workflow_key \
	-transition_key $transition_key \
	-place_key $place_key \
	-direction $direction

ad_returnredirect $return_url
