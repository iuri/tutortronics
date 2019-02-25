ad_page_contract {} {
    topic_id
    parent_id
    return_url
}



db_transaction {
    db_dml update_topic {
	UPDATE im_forum_topics SET parent_id = :parent_id WHERE topic_id = :topic_id
	
    }
}


ad_returnredirect $return_url
ad_script_abort
