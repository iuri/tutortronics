<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="selector_insert">
	<querytext>

    BEGIN
	PERFORM im_sql_selector__new (
		null,			-- p_menu_id
		'im_menu',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		:name,
		:short_name,
		:selector_status_id,
		:selector_type_id,
		:object_type,
		:selector_sql,
		:description
	);
	return 0;
    END;

	</querytext>
</fullquery>

</queryset>
