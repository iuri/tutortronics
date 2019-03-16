<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>
  <fullquery name="users_info_query">
    <querytext>

select
	pe.first_names, 
	pe.last_name, 
        im_name_from_user_id(u.user_id) as name,
	pa.email,
        pa.url,
	o.creation_date as registration_date, 
	o.creation_ip as registration_ip,
	to_char(u.last_visit, :date_format) as last_visit,
	u.screen_name,
	u.username,
	(select member_state from membership_rels where rel_id in (
		select rel_id from acs_rels where object_id_two = u.user_id and object_id_one = -2
	)) as member_state,
	o.creation_user as creation_user_id,
	im_name_from_user_id(o.creation_user) as creation_user_name,
	auth.short_name as authority_short_name,
	auth.pretty_name as authority_pretty_name
from	acs_objects o,
	persons pe,
	parties pa,
	users u
	LEFT OUTER JOIN auth_authorities auth ON (u.authority_id = auth.authority_id)
where	u.user_id = :user_id_from_search and
	u.user_id = pe.person_id and
	u.user_id = pa.party_id and
	u.user_id = o.object_id

    </querytext>
  </fullquery>

  <fullquery name="otp_installed">
    <querytext>

        select count(*)
        from apm_enabled_package_versions
        where package_key = 'intranet-otp'

    </querytext>
  </fullquery>

  <fullquery name="get_date_created">
    <querytext>
      select to_char(creation_date, 'Month DD, YYYY') from acs_objects where object_id = :user_id_from_search
    </querytext>
  </fullquery>
</queryset>
