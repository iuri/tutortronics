
ad_page_contract {}

ad_proc delete_audit {
    -audit_last_id
} {
    Deletes audit_id recursively

} {

    ns_log notice "Running delete_audit $audit_last_id"

    set audit_id [db_string select_audit_id {
	select audit_id FROM im_audits WHERE audit_last_id = :audit_last_id
    } -default 0]

    if {$audit_id ne 0} {
	delete_audit -audit_last_id $audit_id
    }

    ns_log Notice "DO DELETE IT $audit_id"
    
    db_dml delete_audit {
	DELETE FROM im_audits WHERE audit_id = :audit_last_id
    }
    
    return
}



db_foreach select_grantees {
    SELECT grantee_id FROM acs_permissions a
    LEFT JOIN parties p
    ON p.party_id = a.grantee_id
    WHERE p.party_id IS NULL;
    
} {
    ns_log Notice "GRANTEEID $grantee_id"

    db_transaction {
	db_dml delete_user_preferences {
	    DELETE FROM user_preferences WHERE user_id = :grantee_id
	}
	
	db_dml delete_employees {
	    delete from im_employees where employee_id = :grantee_id
	}
	
	db_dml delete_permissions {
	    DELETE FROM acs_permissions WHERE object_id = grantee_id OR grantee_id = :grantee_id;
	}
	
	db_dml delete_party_approved_member_map {
	    DELETE from party_approved_member_map WHERE member_id = :grantee_id
	}
	
	db_dml delete_object_indexes {
	    DELETE FROM  acs_object_context_index WHERE object_id = :grantee_id OR ancestor_id = :grantee_id;
	}
	
	db_dml delete_group_indexes {
	    DELETE FROM group_element_index WHERE element_id = :grantee_id
	}
	
	delete_audit -audit_last_id $grantee_id
	
	
	# calendar::item::delete -cal_item_id $event_id
	# ::xo::db::sql::acs_activity delete -activity_id $event_id

	set rel_id [db_string select_acs_rel {
	    SELECT rel_id FROM acs_rels WHERE object_id_two = :grantee_id
	} -default ""]
	
	db_dml delete_membership_rel {
	    DELETE FROM membership_rels WHERE rel_id = :rel_id
	}
	
	db_dml delete_rel {
	    DELETE FROM acs_rels WHERE rel_id = :rel_id
	}

	::xo::db::sql::acs_object delete -object_id $grantee_id
	
	
	#db_foreach select_tables {
	#    SELECT tablename, columnname FROM search_columns(:grantee_id);
	#} {	
	
	#    ns_log notice "TABLENAME $tablename COLUMN $columnname"
	
	#}
	
	#    if {[db_0or1row select_object_type {
	#	SELECT object_id FROM acs_objects WHERE object_id = :grantee_id AND object_type = 'user'
	#    }] } {
	#    }
    }
}
