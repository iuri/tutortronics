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
    -name threads \
    -multirow threads \
    -key topic_id \
    -elements {
	forum_name {
	    label "[_ intranet-forum.Forum_Name]"
	    display_col forum_name
	}
	subject {
	    label "[_ intranet-forum.Thread_Name]"
	    display_col subject
	    link_url_col topic_url
	}

    }

db_multirow -extend { topic_url forum_name } threads select_threads {
    WITH RECURSIVE topics_cte(topic_id, subject, object_id, parent_id, depth, path) AS (
      SELECT ft.topic_id, ft.subject, ft.object_id, ft.parent_id, 1::INT AS depth, ft.topic_id::TEXT AS path
      FROM im_forum_topics AS ft WHERE ft.parent_id IS NULL
      UNION ALL
      SELECT t.topic_id, t.subject, t.object_id, t.parent_id, p.depth + 1 AS depth, (p.path || '->' || t.topic_id::TEXT)
      FROM topics_cte AS p, im_forum_topics AS t WHERE t.parent_id = p.topic_id
    )
    SELECT t.topic_id AS tid, t.subject, t.object_id, t.parent_id, t.depth, t.path
    FROM topics_cte AS t
    WHERE object_id = :object_id AND parent_id IS NOT NULL
    ORDER BY path ASC
} {
    
    
    ns_log Notice "PATH $path"
    
    set forum_id [lindex [split $path "->"] 0]
    
    
    set forum_name [db_string select_subject {
	SELECT subject FROM im_forum_topics WHERE topic_id = :forum_id 
    } -default ""]
    
    set topic_url [export_vars -base select-forum-2 {return_url topic_id {parent_id $tid}}]
}



#ad_script_abort

