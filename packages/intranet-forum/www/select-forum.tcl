# /packages/intranet-forum/www/delete.tcl

ad_page_contract {} {
    topic_id
    object_id
    return_url
}


set thread_name [db_string select_subject {
    SELECT subject FROM im_forum_topics WHERE topic_id = :topic_id
} -default ""]

template::list::create \
    -name forums \
    -multirow forums \
    -key topic_id \
    -elements {
	subject {
	    label "[_ intranet-forum.Forum_Name]"
	    display_col subject
	    link_url_col topic_url
	}
    }


db_multirow -extend { topic_url } forums select_forums {
    SELECT topic_id AS parent_id, subject FROM im_forum_topics
    WHERE object_id = :object_id AND parent_id IS NULL
    ORDER BY subject ASC
} {

    set topic_url [export_vars -base select-forum-2 {return_url topic_id parent_id}]
}



#ad_script_abort

