-- upgrade-5.0.2.3.4-5.0.2.3.5.sql
SELECT acs_log__debug('/packages/intranet-crm-opportunities/sql/postgresql/upgrade/upgrade-5.0.2.3.4-5.0.2.3.5.sql','');


update im_view_columns set column_name = 'Probability' where column_name = 'Probability (%)';


update im_component_plugins set component_tcl = '
	im_dashboard_histogram_sql -diagram_width 300 -sql "
		select  im_lang_lookup_category(''[ad_conn locale]'', p.opportunity_sales_stage_id) as project_status,
			round(sum(coalesce(presales_probability,0) * coalesce(presales_value,project_budget,0)) / 100.0 / 1000.0) as value,
			(select sort_order from im_categories where category_id = p.opportunity_sales_stage_id) as sort_order
		from	im_projects p
		where   p.parent_id is null
			and p.project_status_id not in (select * from im_sub_categories(84018))
			and project_type_id = 102
		group by opportunity_sales_stage_id
		order by
			sort_order,
			p.opportunity_sales_stage_id
	"' 
where plugin_name = 'Sales Pipeline by Volume' and package_name = 'intranet-crm-opportunities'; 


update im_component_plugins
set component_tcl =
        'im_dashboard_histogram_sql -diagram_width 300 -sql "
                select  im_lang_lookup_category(''[ad_conn locale]'', p.opportunity_sales_stage_id) as project_status,
                        count(*) as cnt,
                        (select sort_order from im_categories where category_id = p.opportunity_sales_stage_id) as sort_order
                from    im_projects p
                where   p.parent_id is null
                        and p.project_status_id not in (select * from im_sub_categories(84018))
                        and project_type_id = 102
                group by opportunity_sales_stage_id
                order by sort_order, p.opportunity_sales_stage_id
        "'
where package_name = 'intranet-crm-opportunities' and plugin_name ='Sales Pipeline by Number';
