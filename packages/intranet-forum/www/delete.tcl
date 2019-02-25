# /packages/intranet-forum/www/delete.tcl

ad_page_contract {} {
    topic_id
    return_url
}



if {![db_0or1row exist_children_p {
    SELECT topic_id FROM im_forum_topics
    WHERE parent_id = :topic_id LIMIT 1
}] } {
    

    db_dml delete_im_forum_user_map {
	DELETE FROM im_forum_topic_user_map
	WHERE topic_id = :topic_id
    }
    
    db_dml delete_im_forum_topics {
	DELETE FROM im_forum_topics
	WHERE topic_id = :topic_id
    }
    
    ad_returnredirect $return_url
    
} else {
    
    ad_return_complaint 1 "<li>[_ intranet-forum.lt_You_cannot_delete_forum_thread_with_children_topics]"
    
}



ad_script_abort

